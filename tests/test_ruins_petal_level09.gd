extends SceneTree
## Finite, rules-only candidate proof. The production RescueRules file is byte-identical.
const Rules=preload("res://scripts/rescue_rules.gd")
const LEVEL="res://data/serpent-levels/serpent-09.json"
const RULES_HASH="14a5b20efdf237fbf271ea8749b35580d012485aee8a529a30e53487852c7c23"
const ALT_COLORS=["blue","yellow","green","red","yellow","blue","yellow","red","green","blue","yellow","red","green","yellow","red","green","blue"]
var checks:=0
var failures:Array=[]
func check(value:bool,label:String)->void:
 checks+=1
 if not value:failures.append(label);push_error(label)
func _initialize()->void:call_deferred("run")
func save_json(path:String,value:Variant)->void:
 var f:=FileAccess.open(path,FileAccess.WRITE)
 assert(f!=null,"Cannot write isolated report")
 f.store_string(JSON.stringify(value,"\t")+"\n");f.close()
func check_path(r,task:Dictionary)->void:
 var path:Array=task.path
 check(path.front()==[5,8] and path.size()==int(task.distance_cells)+1,"real route begins at [5,8]")
 for i in range(1,path.size()):
  var a:Array=path[i-1];var b:Array=path[i]
  check(absi(int(a[0])-int(b[0]))+absi(int(a[1])-int(b[1]))==1,"cardinal route edge")
  if i<path.size()-1 and b[0]>=0 and b[0]<10 and b[1]>=0 and b[1]<8:
   check(not r.board.has(int(b[1])*10+int(b[0])),"no occupied cell inside an outbound route")
 check(int(path.back()[1])*10+int(path.back()[0])==int(task.cell_id),"route endpoint is reserved target")
func track_wait(r,state:Dictionary)->void:
 var blocked:bool=r.status=="running" and (r.tasks.size()>=Rules.CARRIER_LIMIT or r.reachable_cell_ids().is_empty())
 if blocked and int(state.wait_start)<0:state.wait_start=int(r.time_us)
 elif not blocked and int(state.wait_start)>=0:
  var duration:int=int(r.time_us)-int(state.wait_start)
  if duration>0:state.waits.append({"start_us":state.wait_start,"end_us":r.time_us,"duration_us":duration})
  state.wait_start=-1
func observe_reachability(r,state:Dictionary)->void:
 var reachable:Array=r.reachable_cell_ids("",true)
 for id in [44,54,56,63,47]:
  if reachable.has(id) and not state.first_reachable.has(str(id)):state.first_reachable[str(id)]=int(r.time_us)
func advance(r,target_us:int,state:Dictionary)->void:
 while r.status=="running" and int(r.time_us)<target_us:
  track_wait(r,state)
  var next_us:int=mini(target_us,int(r._next_event_time()))
  state.steps+=1
  check(next_us>r.time_us and state.steps<1000,"bounded forward event progression")
  if next_us<=r.time_us or state.steps>=1000:return
  var before_head:float=r.head_s()
  var before_reachable:Array=r.reachable_cell_ids("",true)
  r.update_us(next_us-int(r.time_us))
  var fresh_events:Array=r.drain_events()
  state.events.append_array(fresh_events)
  var picked_here:Array=[]
  for e in fresh_events:
   if e.type=="bead_picked_up":picked_here.append(e.cell_id)
  if not picked_here.is_empty():
   var newly_reachable:Array=[]
   for id in r.reachable_cell_ids("",true):
    if not before_reachable.has(id):newly_reachable.append({"cell_id":id,"color":r.board[id].color})
   state.pickup_openings.append({"time_us":r.time_us,"picked_cell_ids":picked_here,"newly_reachable":newly_reachable})
  check(r.head_s()>=before_head,"serpent head never retreats after damage")
  check(r.conservation_errors().is_empty(),"conservation at authoritative event boundary")
  check(r.tasks.size()<=4,"capacity at event boundary")
  observe_reachability(r,state);track_wait(r,state)
func replay(c:Dictionary,inputs:Array,label:String)->Dictionary:
 var r:=Rules.new();check(r.load_level(c),label+" loads")
 var state:Dictionary={"events":r.drain_events(),"wait_start":-1,"waits":[],"steps":0,"peak":0,"first_reachable":{},"pickup_openings":[]}
 var paths:Array=[];var previous:=-1400000
 observe_reachability(r,state)
 for input in inputs:
  var at_us:=Rules.seconds_to_us(float(input.at_sec))
  check(at_us-previous==1400000,"exact 1.4-second independent input gaps");previous=at_us
  advance(r,at_us,state)
  check(r.status in ["ready","running"] and r.time_us==at_us,"not terminal or delayed at input")
  var nearest:Dictionary=r.best_target(input.color)
  var before_board:int=r.board.size();var before_tasks:int=r.tasks.size()
  var accepted:Dictionary=r.click_color(input.color)
  check(accepted.ok,label+" accepts input at "+str(input.at_sec))
  if not accepted.ok:break
  var task:Dictionary=r.tasks[accepted.task_id]
  check(task.cell_id==nearest.cell_id and task.path==nearest.path,"input selects actual nearest reachable unreserved bead")
  check(task.speed_multiplier==1.0 and task.carrier_type=="worker","base Worker Lv.1, no speed increase")
  check(r.tasks.size()==before_tasks+1 and r.board.size()==before_board,"one click adds one ant; reservation does not pick up")
  check_path(r,task)
  paths.append(task.duplicate(true));state.peak=maxi(state.peak,r.tasks.size())
  state.events.append_array(r.drain_events());track_wait(r,state)
  check(r.conservation_errors().is_empty(),"conservation after dispatch")
 advance(r,62000000,state)
 check(paths.size()==17 and r.status=="victory",label+" wins with seventeen explicit inputs")
 check(r.terminal_reason=="final_segment_hit" and r.alive_segment_ids.is_empty(),"last actual damage removes the whole serpent")
 check(r.board.size()==6 and r.tasks.is_empty() and r.inventory.values().all(func(v):return v==0),"six leftover board beads; no hidden unpaid task")
 check(r.snapshot().dragon_contact_us==62000000 and r.terminal_time_us<62000000,"finite 62-second threat budget")
 check(state.peak<=4,"no fifth carrier")
 var distances:Array=[];var normal_lengths:=0;var sixes:=0;var picked:Array=[]
 for p in paths:
  distances.append(p.distance_cells)
  if p.distance_cells>=3 and p.distance_cells<=5:normal_lengths+=1
  if p.distance_cells==6:sixes+=1
  check(p.distance_cells>=3 and p.distance_cells<=6,"actual route is 3–6 cells")
 check(normal_lengths==16 and sixes==1,"sixteen 3–5-cell routes; only one six-cell route")
 var first_delivery:=-1;var last_hit:=-1;var hits:=0;var removed:=0;var armor_hits:=0
 var pickup_times:Dictionary={};var delivered_ids:Array=[];var picked_ids:Array=[]
 for event in state.events:
  if event.type=="bead_delivered":
   if first_delivery<0:first_delivery=event.time_us
   check(not delivered_ids.has(event.id),"each task delivers once");delivered_ids.append(event.id)
  if event.type=="bead_picked_up":
   check(not picked_ids.has(event.cell_id),"each bead is picked once");picked_ids.append(event.cell_id)
   pickup_times[str(event.cell_id)]=event.time_us
  if event.type=="segment_hit":
   last_hit=event.time_us;hits+=1
   check(event.source=="projectile" and event.amount==1,"each actual hit comes from one ordinary bead projectile")
   if event.kind=="armored":armor_hits+=1
  if event.type=="segment_removed":removed+=1
 check(hits==17 and removed==15 and armor_hits==4,"17 damage removes 13 normal plus 2 HP2 armored segments")
 check(last_hit==r.terminal_time_us,"victory timestamp equals final actual hit")
 check(r.hit_counts=={"red":4,"blue":4,"green":4,"yellow":5},"per-color HP budget paid exactly")
 for id in [44,47,66,73]:check(picked_ids.has(id),"every blue bead including both far beads is really collected")
 check(state.first_reachable["44"]==mini(pickup_times["54"],pickup_times["45"]),"an actual adjacent yellow pickup, not reservation, opens mandatory upper blue")
 var max_wait:=0
 for window in state.waits:max_wait=maxi(max_wait,window.duration_us)
 check(max_wait<=800000,"no uninterrupted all-color no-dispatch window above 0.8 seconds")
 return {"label":label,"status":r.status,"loadout":r.ant_loadout,"accepted_inputs":inputs,"transport_paths":paths,"path_cells":distances,"first_delivery_us":first_delivery,"final_hit_us":last_hit,"contact_time_us":r.snapshot().dragon_contact_us,"maximum_carriers":state.peak,"no_dispatch_windows":state.waits,"longest_no_dispatch_opportunity_us":max_wait,"first_reachable_us":state.first_reachable,"pickup_times_us":pickup_times,"pickup_openings":state.pickup_openings,"remaining_beads":r.board.size(),"leftover_by_color":r.available_counts(),"leftover_cell_ids":r.board.keys(),"hit_counts":r.hit_counts,"events":state.events,"event_sequence_sha256":JSON.stringify(state.events).sha256_text()}
func opening(c:Dictionary,color:String,cell:int,opens:Array)->Dictionary:
 var r:=Rules.new();check(r.load_level(c),"opening probe loads")
 for id in [44,54,56,63]:check(not r.reachable_cell_ids().has(id),"all inner targets initially enclosed")
 var target:Dictionary=r.best_target(color)
 check(target.cell_id==cell and target.distance==3,"deterministic near gate for "+color)
 var accepted:Dictionary=r.click_color(color)
 check(accepted.ok and r.tasks.size()==1 and r.reservations.size()==1,"one ant/one reservation opening")
 var task:Dictionary=r.tasks[accepted.task_id].duplicate(true)
 check_path(r,task)
 r.update_us(int(task.pickup_us)-1)
 for id in [44,54,56,63]:check(not r.reachable_cell_ids().has(id),"no reservation-only opening")
 r.update_us(1)
 var after:Array=r.reachable_cell_ids()
 for id in opens:check(after.has(id),"real first pickup opens intended petal")
 check(not after.has(44),"one near pickup cannot skip second gate to the blue core")
 check(r.delivered_counts[color]==0 and r.hit_counts[color]==0,"pickup does not supply ammo or damage")
 r.update_us(int(task.delivery_us)-1-r.time_us);check(r.delivered_counts[color]==0,"no ammo before unload completes")
 r.update_us(1);check(r.delivered_counts[color]==1 and r.tasks.is_empty(),"one unload frees one worker and supplies one bead")
 r.update_us(450000)
 var events:Array=r.drain_events();var hits:Array=events.filter(func(e:Dictionary)->bool:return e.type=="segment_hit")
 check(hits.size()==1 and r.conservation_errors().is_empty(),"one delivered bead funds exactly one hit")
 if color=="blue":check(hits[0].kind=="armored" and hits[0].hp==1,"blue-first immediately cracks visible armor")
 else:check(hits[0].kind=="normal" and hits[0].hp==0,"red-first immediately removes a normal segment")
 return {"color":color,"target_cell_id":cell,"path":task.path,"distance_cells":3,"pickup_us":task.pickup_us,"delivery_us":task.delivery_us,"first_hit_us":hits[0].time_us,"first_hit_kind":hits[0].kind,"first_hit_hp_remaining":hits[0].hp,"opens_cell_ids":opens,"core_blue_still_blocked_after_first_pickup":true,"events":events}
func run()->void:
 var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(LEVEL))
 check(Rules.API_VERSION=="3.1.0","production rules API")
 check(FileAccess.get_sha256("res://scripts/rescue_rules.gd")==RULES_HASH,"byte-identical frozen production rules")
 check(Rules.validate_level(c).is_empty(),"production schema validation")
 check(c.width==10 and c.height==8 and int(c.transport.entrance_cell[0])==5 and int(c.transport.entrance_cell[1])==8,"existing ruins grid and central entrance")
 check(c.region_id=="ruins" and c.scene_layout=="res://data/scenes/ruins-fork.json","reuse existing ruins scene without new art")
 check(c.defense_target=={"id":"supply_cart","display_name":"Supply Cart","fixed":true},"fixed supply cart; no moving escort")
 check(c.serpent.get("art_profile","default") in ["default","ruins_carapace"] and c.tools.is_empty(),"approved presentation profile only; no tools or new mechanisms")
 check(c.transport.outbound_speed_cells_sec==2.5 and c.transport.returning_speed_cells_sec==2.0,"unchanged ordinary worker speeds")
 var seed:=Rules.new();seed.load_level(c)
 check(seed.board.size()==23 and seed.initial_counts=={"red":6,"blue":4,"green":7,"yellow":6},"23 beads, exact four-color supply")
 var initial_targets:Dictionary={}
 for color in c.palette.values():
  initial_targets[color]=seed.best_target(color);check(not initial_targets[color].is_empty(),"all four colors initially have legal choices")
 var required:Dictionary={};var armor:=0
 for s in c.segments:
  required[s.color]=int(required.get(s.color,0))+int(s.hp)
  if s.kind=="armored":armor+=1
 check(required=={"red":4,"blue":4,"green":4,"yellow":5} and armor==2,"17 HP, two armored segments, base supply by color")
 check(seed.reachable_cell_ids("blue").size()==3 and seed.initial_counts.blue==4,"three exterior blue beads cannot pay four blue HP without opening the core")
 var openings:Array=[opening(c,"red",64,[54,63]),opening(c,"blue",66,[56])]
 var main:=replay(c,c.solution.inputs,"central_red_then_yellow")
 var alternate:Array=[]
 for i in range(ALT_COLORS.size()):alternate.append({"at_sec":float(i)*1.4,"color":ALT_COLORS[i]})
 var alt:=replay(c,alternate,"right_blue_then_yellow")
 check(main.transport_paths[1].cell_id==54 and alt.transport_paths[1].cell_id==56,"second yellow actually selects different nearest targets in the two openings")
 check(main.first_reachable_us["44"]==3000000 and alt.first_reachable_us["44"]==7200000,"central-first opens mandatory blue 4.2 seconds earlier than the alternate upper-yellow approach")
 check(main.pickup_times_us["56"]==10000000 and alt.pickup_times_us["56"]==3000000,"right-first collects right yellow 7 seconds earlier")
 var cap:=Rules.new();cap.load_level(c)
 for color in ["red","blue","green","yellow"]:check(cap.click_color(color).ok,"four-cap probe accepted")
 var denied:Dictionary=cap.click_color("red")
 check(not denied.ok and denied.reason=="carrier_limit" and denied.queued==false and cap.tasks.size()==4,"fifth click rejected with no queue")
 cap.set_paused(true);var before:Dictionary=cap.replay_state();cap.update_us(2000000)
 check(cap.time_us==before.time_us and cap.tasks==before.tasks,"pause freezes existing transport")
 check(not cap.click_color("blue").ok,"pause rejects input")
 var slow:=Rules.new();slow.load_level(c);slow.click_color("red");slow.update_us(62000000)
 check(slow.status=="defeat" and slow.terminal_reason=="dragon_contact" and slow.time_us==62000000,"unfinished serpent defeats at finite endpoint")
 var insufficient:Dictionary=c.duplicate(true);insufficient.grid[4]=str(insufficient.grid[4]).substr(0,4)+"."+str(insufficient.grid[4]).substr(5)
 check(Rules.validate_level(insufficient).has("insufficient segment supply: blue"),"removing mandatory blue cannot pass validation via total count")
 var report:Dictionary={"ok":failures.is_empty(),"checks":checks,"failures":failures,"engine_version":Engine.get_version_info().string,"rules_api":Rules.API_VERSION,"art_profile":c.serpent.get("art_profile","default"),"rules_sha256":RULES_HASH,"level_sha256":FileAccess.get_sha256(LEVEL),"supply_by_color":seed.initial_counts,"required_damage_by_color":required,"normal_segments":c.segments.size()-armor,"armored_segments":armor,"total_beads":seed.board.size(),"initial_best_targets":initial_targets,"openings":openings,"solutions":[main,alt],"scope":"One new current-mode level candidate, two explicit Worker Lv.1 sequences, and bounded rules probes. No modifications to production/old levels, no scene rendering or desktop use, no human balance, visual, native-input, audio, reward-economy or device acceptance."}
 save_json("res://reports/rules/ruins-petal-level09.json",report)
 save_json("res://reports/rules/serpent-09-alternate-inputs.json",{"level_id":c.level_id,"level_sha256":report.level_sha256,"label":alt.label,"minimum_input_gap_sec":1.4,"inputs":alternate})
 print("RUINS_PETAL_LEVEL09 ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"final_hit_us":main.final_hit_us,"alternate_final_hit_us":alt.final_hit_us,"remaining_beads":main.remaining_beads,"max_wait_us":main.longest_no_dispatch_opportunity_us,"alternate_max_wait_us":alt.longest_no_dispatch_opportunity_us,"path_cells":main.path_cells,"alternate_path_cells":alt.path_cells}))
 quit(0 if failures.is_empty() else 1)
