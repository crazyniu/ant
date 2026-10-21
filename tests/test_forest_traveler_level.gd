extends SceneTree
## Bounded rules-only authoring proof. Uses the untouched production RescueRules.
## Does not import or load a scene, render GL, use player saves, or synthesize clicks.
const Rules=preload("res://scripts/rescue_rules.gd")
const LEVEL="res://data/serpent-levels/serpent-08.json"
const SOURCE_HASH="14a5b20efdf237fbf271ea8749b35580d012485aee8a529a30e53487852c7c23"
var checks:=0
var failures:Array=[]
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures.append(label);push_error(label)
func _initialize()->void:call_deferred("run")
func save_json(path:String,value:Variant)->void:
	var f:=FileAccess.open(path,FileAccess.WRITE)
	assert(f!=null,"Cannot write bounded report")
	f.store_string(JSON.stringify(value,"\t")+"\n");f.close()
func check_path(r,task:Dictionary)->void:
	var path:Array=task.path
	check(path.front()==[5,8] and path.size()==int(task.distance_cells)+1,"route starts at authored entrance and has real edge length")
	for i in range(1,path.size()):
		var a:Array=path[i-1];var b:Array=path[i]
		check(absi(int(a[0])-int(b[0]))+absi(int(a[1])-int(b[1]))==1,"cardinal route edge")
		if i<path.size()-1 and b[0]>=0 and b[0]<10 and b[1]>=0 and b[1]<8:
			check(not r.board.has(int(b[1])*10+int(b[0])),"route interior is actually clear at dispatch")
	check(int(path.back()[1])*10+int(path.back()[0])==int(task.cell_id),"route endpoint matches reservation")
func track_wait(r,state:Dictionary)->void:
	var blocked:bool=r.status=="running" and (r.tasks.size()>=Rules.CARRIER_LIMIT or r.reachable_cell_ids().is_empty())
	if blocked and int(state.wait_start)<0:state.wait_start=int(r.time_us)
	elif not blocked and int(state.wait_start)>=0:
		var duration:int=int(r.time_us)-int(state.wait_start)
		if duration>0:state.waits.append({"start_us":state.wait_start,"end_us":r.time_us,"duration_us":duration})
		state.wait_start=-1
func advance(r,target_us:int,state:Dictionary)->void:
	while r.status=="running" and int(r.time_us)<target_us:
		track_wait(r,state)
		var next_us:int=mini(target_us,int(r._next_event_time()))
		state.steps+=1
		check(next_us>r.time_us and state.steps<1000,"bounded forward event progression")
		if next_us<=r.time_us or state.steps>=1000:return
		r.update_us(next_us-int(r.time_us))
		state.events.append_array(r.drain_events())
		check(r.conservation_errors().is_empty(),"conservation at authoritative event boundary")
		track_wait(r,state)
func replay(c:Dictionary,inputs:Array,label:String)->Dictionary:
	var r:=Rules.new();check(r.load_level(c),label+" loads")
	var state:Dictionary={"events":r.drain_events(),"wait_start":-1,"waits":[],"steps":0,"peak":0}
	var paths:Array=[]
	var previous:=-1400000
	for input in inputs:
		var at_us:=Rules.seconds_to_us(float(input.at_sec))
		check(at_us-previous==1400000,"explicit 1.4 second input gaps")
		previous=at_us
		advance(r,at_us,state)
		check(r.status in ["ready","running"] and r.time_us==at_us,"no terminal or delayed input")
		var accepted:Dictionary=r.click_color(input.color)
		check(accepted.ok,label+" accepted explicit input at "+str(input.at_sec))
		if not accepted.ok:break
		var task:Dictionary=r.tasks[accepted.task_id]
		check(task.speed_multiplier==1.0 and task.carrier_type=="worker","ordinary Worker Lv.1 transport")
		check_path(r,task)
		paths.append(task.duplicate(true));state.peak=maxi(state.peak,r.tasks.size())
		state.events.append_array(r.drain_events());track_wait(r,state)
		check(r.conservation_errors().is_empty(),"conservation after dispatch")
	advance(r,60000000,state)
	check(paths.size()==15 and r.status=="victory",label+" wins with exactly fifteen explicit clicks")
	check(r.terminal_reason=="final_segment_hit" and r.alive_segment_ids.is_empty(),"victory requires whole serpent deletion on actual final damage")
	check(r.board.size()==6 and r.tasks.is_empty() and r.inventory.values().all(func(v):return v==0),"six board leftovers and no unpaid hidden task")
	check(r.snapshot().dragon_contact_us==60000000 and r.terminal_time_us<60000000,"finite sixty second initial threat")
	check(state.peak<=4,"four-carrier cap")
	var sixes:=0;var normal_lengths:=0;var distances:Array=[]
	for p in paths:
		distances.append(p.distance_cells)
		if p.distance_cells==6:sixes+=1
		if p.distance_cells>=3 and p.distance_cells<=5:normal_lengths+=1
		check(p.distance_cells<=6,"actual route no longer than six cells")
	check(sixes<=2 and normal_lengths>=12,"most real routes are three to five cells; at most two six-cell routes")
	var first_delivery:=-1;var last_hit:=-1;var hits:=0;var removed:=0
	for event in state.events:
		if event.type=="bead_delivered" and first_delivery<0:first_delivery=event.time_us
		if event.type=="segment_hit":last_hit=event.time_us;hits+=1
		if event.type=="segment_removed":removed+=1
	check(hits==15 and removed==13,"fifteen damage removes thirteen stable-ID segments")
	check(last_hit==r.terminal_time_us,"last hit and victory have identical authoritative time")
	var max_wait:=0
	for window in state.waits:max_wait=maxi(max_wait,window.duration_us)
	return {"label":label,"status":r.status,"loadout":r.ant_loadout,"accepted_inputs":inputs,"transport_paths":paths,"path_cells":distances,"first_delivery_us":first_delivery,"final_hit_us":last_hit,"contact_time_us":r.snapshot().dragon_contact_us,"maximum_carriers":state.peak,"no_dispatch_windows":state.waits,"longest_no_dispatch_opportunity_us":max_wait,"remaining_beads":r.board.size(),"leftover_by_color":r.available_counts(),"leftover_cell_ids":r.board.keys(),"hit_counts":r.hit_counts,"events":state.events,"event_sequence_sha256":JSON.stringify(state.events).sha256_text()}
func opening(c:Dictionary,color:String,cell:int,distance:int,opens:int)->Dictionary:
	var r:=Rules.new();check(r.load_level(c),"opening probe loads")
	check(not r.reachable_cell_ids("purple").has(63) and not r.reachable_cell_ids("purple").has(57),"both purple cores initially enclosed")
	var target:Dictionary=r.best_target(color)
	check(target.cell_id==cell and target.distance==distance,"deterministic initial target and cost for "+color)
	var accepted:Dictionary=r.click_color(color)
	check(accepted.ok and r.tasks.size()==1 and r.reservations.size()==1,"one click creates exactly one ant and bead reservation")
	var task:Dictionary=r.tasks[accepted.task_id].duplicate(true)
	check_path(r,task)
	r.update_us(int(task.pickup_us)-1)
	check(r.board.has(cell) and not r.reachable_cell_ids("purple").has(63) and not r.reachable_cell_ids("purple").has(57),"reservation and pre-pickup movement do not open a core")
	r.update_us(1)
	check(not r.board.has(cell),"actual pickup removes gate or exterior bead")
	if opens>=0:check(r.reachable_cell_ids("purple").has(opens),"actual pickup opens its distinct purple core")
	else:check(not r.reachable_cell_ids("purple").has(63) and not r.reachable_cell_ids("purple").has(57),"outer immediate ammo opens neither core")
	check(r.delivered_counts[color]==0 and r.hit_counts[color]==0,"pickup supplies no ammunition or damage")
	r.update_us(int(task.delivery_us)-1-r.time_us)
	check(r.delivered_counts[color]==0,"unloading must complete before supply")
	r.update_us(1)
	check(r.delivered_counts[color]==1 and r.tasks.is_empty(),"completed unload supplies one bead and releases worker")
	r.update_us(450000)
	var events:Array=r.drain_events();var hits:Array=events.filter(func(e:Dictionary)->bool:return e.type=="segment_hit")
	check(hits.size()==1 and r.conservation_errors().is_empty(),"one delivered bead funds one damage only")
	if color in ["purple","blue"]:check(hits[0].kind=="armored" and hits[0].hp==1,"first matching projectile cracks visible HP2 armor")
	else:check(hits[0].kind=="normal" and hits[0].hp==0,"green gate supplies normal segment removal")
	return {"color":color,"target_cell_id":cell,"path":task.path,"distance_cells":distance,"pickup_us":task.pickup_us,"first_delivery_us":task.delivery_us,"first_hit_us":hits[0].time_us,"first_hit_hp_remaining":hits[0].hp,"opens_purple_core_cell_id":opens,"both_cores_closed_until_pickup":true,"events":events}
func run()->void:
	var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(LEVEL))
	check(Rules.API_VERSION=="3.1.0","current production rules API")
	check(FileAccess.get_sha256("res://scripts/rescue_rules.gd")==SOURCE_HASH,"production rules copied byte for byte; no rule changes")
	check(Rules.validate_level(c).is_empty(),"production schema validation")
	check(c.width==10 and c.height==8 and int(c.transport.entrance_cell[0])==5 and int(c.transport.entrance_cell[1])==8,"existing woodland BoardPlane grid and central entrance")
	check(c.region_id=="forest" and c.scene_layout=="res://data/scenes/forest-traveler.json","requested scene integration reference")
	check(c.defense_target=={"id":"traveler","display_name":"Traveler","fixed":true},"fixed traveler, not mobile escort")
	check(not c.serpent.has("art_profile"),"existing default serpent skin")
	check(c.tools.is_empty(),"no tools or new mechanisms")
	var seed:=Rules.new();seed.load_level(c)
	check(seed.board.size()==21 and seed.initial_counts=={"red":4,"blue":4,"green":4,"yellow":5,"purple":4},"twenty-one beads in five supported colors")
	var initial_targets:Dictionary={}
	for color in c.palette.values():
		initial_targets[color]=seed.best_target(color)
		check(not initial_targets[color].is_empty(),"all five color choices have an initial legal route")
	var required:Dictionary={};var armor:=0
	for s in c.segments:
		required[s.color]=int(required.get(s.color,0))+int(s.hp)
		if s.kind=="armored":armor+=1
	check(required=={"red":3,"blue":3,"green":3,"yellow":2,"purple":4} and armor==2,"fifteen total HP, two armored segments, adequate supply by color")
	var openings:Array=[opening(c,"green",64,3,63),opening(c,"purple",72,4,-1),opening(c,"blue",67,4,57)]
	var main:=replay(c,c.solution.inputs,"near_green_first")
	var alternate:Array=c.solution.inputs.duplicate(true)
	alternate[0].color="purple";alternate[1].color="green"
	var alt:=replay(c,alternate,"outer_purple_first")
	check(main.transport_paths[0].cell_id!=alt.transport_paths[0].cell_id and main.transport_paths[1].cell_id!=alt.transport_paths[1].cell_id,"alternate opening changes actual target order, not just labels")
	for proof in [main,alt]:
		var picked:Array=[]
		for event in proof.events:
			if event.type=="bead_picked_up":picked.append(event.cell_id)
		check(picked.has(63) and picked.has(57),"both mandatory purple cores actually collected in viable solution")
	var cap:=Rules.new();cap.load_level(c)
	for color in ["green","purple","blue","yellow"]:check(cap.click_color(color).ok,"bounded capacity probe accepted")
	var denied:Dictionary=cap.click_color("red")
	check(not denied.ok and denied.reason=="carrier_limit" and denied.queued==false and cap.tasks.size()==4,"fifth click rejects without hidden queue")
	var slow:=Rules.new();slow.load_level(c);slow.click_color("green");slow.update_us(60000000)
	check(slow.status=="defeat" and slow.terminal_reason=="dragon_contact" and slow.time_us==60000000,"incomplete serpent reaches finite goal and defeats, not looping")
	var report:Dictionary={"ok":failures.is_empty(),"checks":checks,"failures":failures,"engine_version":Engine.get_version_info().string,"rules_api":Rules.API_VERSION,"rules_sha256":SOURCE_HASH,"level_sha256":FileAccess.get_sha256(LEVEL),"supply_by_color":seed.initial_counts,"required_damage_by_color":required,"normal_segments":c.segments.size()-armor,"armored_segments":armor,"total_beads":seed.board.size(),"initial_best_targets":initial_targets,"openings":openings,"solutions":[main,alt],"scope":"One current-mode level draft and two authored Worker Lv.1 sequences, isolated production-rules headless only. No old-level batch, scene loading, GL rendering, human strategy approval, visual approval, native input, audio, reward balance or device acceptance."}
	save_json("res://reports/rules/forest-traveler-level08.json",report)
	print("FOREST_TRAVELER_LEVEL08 ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"main_first_delivery_us":main.first_delivery_us,"alternate_first_delivery_us":alt.first_delivery_us,"final_hit_us":main.final_hit_us,"remaining_beads":main.remaining_beads,"max_wait_us":main.longest_no_dispatch_opportunity_us,"alternate_max_wait_us":alt.longest_no_dispatch_opportunity_us,"path_cells":main.path_cells}))
	quit(0 if failures.is_empty() else 1)
