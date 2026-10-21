extends SceneTree
## Bounded content proof for level 10 only. The production CLI owns event stepping,
## schema, scene and resource-conservation validation; no parallel rule simulator.
const Rules = preload("res://scripts/rescue_rules.gd")
const Validator = preload("res://tools/validate_serpent_level.gd")
const LEVEL = "res://data/serpent-levels/serpent-10.json"
const RULES_HASH = "14a5b20efdf237fbf271ea8749b35580d012485aee8a529a30e53487852c7c23"
const SUPPLY = {"red":4,"blue":5,"green":4,"yellow":5,"purple":4,"white":3}
const DAMAGE = {"red":3,"blue":3,"green":3,"yellow":3,"purple":3,"white":3}
const ALTERNATE = ["green","white","red","blue","purple","white","green","yellow","red","blue","purple","green","yellow","red","purple","white","blue","yellow"]
var checks := 0
var failures: Array = []

func _initialize() -> void: call_deferred("run")
func check(value:bool,label:String) -> void:
 checks += 1
 if not value: failures.append(label); push_error(label)
func save_json(path:String,value:Variant) -> void:
 var file := FileAccess.open(path,FileAccess.WRITE)
 assert(file != null,"Cannot write bounded report")
 file.store_string(JSON.stringify(value,"\t")+"\n");file.close()
func fresh(c:Dictionary):
 var r := Rules.new()
 check(r.load_level(c),"level 10 loads into unchanged rules")
 return r
func geometry(r) -> Dictionary:
 var result := {}
 for id in [44,46,54,57]:
  var reachable:bool=r.reachable_cell_ids("",true).has(id)
  result[str(id)]={"reachable":reachable,"distance":int(r._routes[id].distance) if reachable else -1}
 return result
func opening(c:Dictionary,color:String,cell:int,distance:int,opens:Array) -> Dictionary:
 var r=fresh(c)
 var before:=geometry(r)
 var before_ids:Array=r.reachable_cell_ids("",true)
 check(not before["44"].reachable and not before["46"].reachable,"both inner white beads start blocked")
 check(r.reachable_cell_ids("white")==[73],"only external white starts accessible")
 var target:Dictionary=r.best_target(color)
 check(target.cell_id==cell and target.distance==distance,"actual nearest opening target for "+color)
 var accepted:Dictionary=r.click_color(color)
 check(accepted.ok and r.tasks.size()==1 and r.board.size()==25,"one input creates one carrier without removing a bead")
 var task:Dictionary=r.tasks[accepted.task_id].duplicate(true)
 check(geometry(r)==before,"reservation alone cannot open the courtyard")
 r.update_us(int(task.pickup_us)-1)
 check(geometry(r)==before,"route remains blocked until actual pickup")
 r.update_us(1)
 var after:=geometry(r)
 var newly_reachable:Array=[]
 for id in r.reachable_cell_ids("",true):
  if not before_ids.has(id):newly_reachable.append({"cell_id":id,"color":r.board[id].color,"distance_cells":r._routes[id].distance})
 for id in [44,46,54,57]:check(after[str(id)].reachable==opens.has(id),"exact pickup opening set: "+color+"/"+str(id))
 check(r.board.size()==24 and r.available_counts()[color]==SUPPLY[color]-1,"pickup removes exactly one same-color board bead")
 check(r.delivered_counts[color]==0 and r.hit_counts[color]==0,"pickup is neither inventory nor damage")
 r.update_us(int(task.delivery_us)-1-r.time_us)
 check(r.delivered_counts[color]==0,"unload must finish before delivery")
 r.update_us(1)
 check(r.delivered_counts[color]==1 and r.tasks.is_empty(),"one delivery releases its worker")
 r.update_us(450000)
 var events:Array=r.drain_events()
 var hits:Array=events.filter(func(e):return e.type=="segment_hit")
 check(hits.size()==1 and hits[0].amount==1,"one bead yields one actual ordinary projectile damage")
 check(r.conservation_errors().is_empty(),"opening probe conserves every color")
 if color=="white":check(hits[0].kind=="armored" and hits[0].hp==1,"external-white alternative cracks real white HP2 armor")
 return {"color":color,"target_cell_id":cell,"distance_cells":distance,"path":task.path,"before":before,"after_pickup":after,"all_newly_reachable":newly_reachable,"pickup_us":task.pickup_us,"delivery_us":task.delivery_us,"first_hit_us":hits[0].time_us,"first_hit_kind":hits[0].kind,"first_hit_hp_remaining":hits[0].hp,"events":events}
func first_two(c:Dictionary,first:String) -> Dictionary:
 var r=fresh(c)
 check(r.click_color(first).ok,"first input accepted")
 r.update_us(1400000)
 var before:=geometry(r)
 var accepted:Dictionary=r.click_color("white")
 check(accepted.ok,"white input accepted at 1.4 seconds")
 var task:Dictionary=r.tasks[accepted.task_id].duplicate(true)
 var first_left_us:=-1
 if before["44"].reachable:first_left_us=r.time_us
 while r.time_us<3000000:
  var at:int=mini(3000000,r._next_event_time())
  check(at>r.time_us,"bounded positive event progress in first-two probe")
  r.update_us(at-r.time_us)
  if first_left_us<0 and r.reachable_cell_ids("",true).has(44):first_left_us=r.time_us
 check(r.conservation_errors().is_empty(),"first-two probe conserves resources")
 return {"first_color":first,"white_input_at_us":1400000,"white_selected_cell_id":task.cell_id,"white_distance_cells":task.distance_cells,"first_left_white_reachable_us":first_left_us,"geometry_before_second_input":before,"events":r.drain_events()}
func replay(c:Dictionary,inputs:Array,label:String) -> Dictionary:
 var candidate:=c.duplicate(true)
 candidate.solution.inputs=inputs.duplicate(true)
 var report:Dictionary=Validator.inspect(candidate,true)
 check(report.ok,label+" passes unchanged production CLI inspection")
 if not report.ok:return report
 check(report.status=="victory" and report.terminal_time_us==29400000,"victory on final damage at 29.40 seconds")
 check(report.contact_time_us==64000000,"64-second finite threat")
 check(report.accepted_inputs==18 and report.remaining_beads==7,"18 inputs, seven leftover beads")
 check(report.supply_by_color==SUPPLY and report.required_damage_by_color==DAMAGE and report.hit_counts==DAMAGE,"exact six-color supply and actual damage")
 check(report.maximum_carriers==4 and report.longest_no_dispatch_opportunity_us<=800000,"four-carrier limit and no all-color wait over 0.8 seconds")
 var short_routes:=0;var six_routes:=0
 for d in report.path_cells:
  if d>=3 and d<=5:short_routes+=1
  if d==6:six_routes+=1
 check(short_routes==16 and six_routes==2,"sixteen routes are 3–5 cells and two are six")
 var previous:=-1400000
 for input in inputs:
  var time:=Rules.seconds_to_us(input.at_sec)
  check(time-previous==1400000,"independent exact 1.4-second input spacing");previous=time
 var paths:Array=[];var picked:Array=[];var delivered:Array=[];var removed:Array=[]
 var first_delivery:=-1;var last_hit:=-1;var final_fire:=-1
 var hits:=0;var armor_hits:=0;var white_hits:Array=[];var pickup_times:Dictionary={}
 for event in report.events:
  if event.type=="ant_dispatched":
   paths.append(event)
   check(event.carrier_type=="worker" and event.speed_multiplier==1.0,"unchanged Worker Lv.1 speed snapshot")
   check(event.path.front()==[6,8] and event.path.size()==event.distance_cells+1,"path begins at scene gateway and has declared length")
   check(int(event.path.back()[1])*10+int(event.path.back()[0])==event.cell_id,"path ends at actual reserved bead")
   for i in range(1,event.path.size()):
    var a:Array=event.path[i-1];var b:Array=event.path[i]
    check(absi(int(a[0])-int(b[0]))+absi(int(a[1])-int(b[1]))==1,"all route edges are orthogonal")
  elif event.type=="bead_picked_up":
   check(not picked.has(event.cell_id),"each board bead picked once");picked.append(event.cell_id)
   pickup_times[str(event.cell_id)]=event.time_us
  elif event.type=="bead_delivered":
   check(not delivered.has(event.id),"each transport supplies ammunition once");delivered.append(event.id)
   if first_delivery<0:first_delivery=event.time_us
  elif event.type=="cannon_fired":final_fire=event.time_us
  elif event.type=="segment_hit":
   hits+=1;last_hit=event.time_us
   check(event.source=="projectile" and event.amount==1,"all damage is real projectile damage")
   if event.kind=="armored":armor_hits+=1
   if event.color=="white":white_hits.append(event)
  elif event.type=="segment_removed":
   check(not removed.has(event.segment_id),"each stable segment ID removed once");removed.append(event.segment_id)
 check(hits==18 and armor_hits==4 and removed.size()==16,"14 HP1 plus two HP2 segments consume exactly 18 damage")
 check(white_hits.size()==3 and white_hits[0].hp==1 and white_hits[1].hp==0 and white_hits[2].kind=="normal","white has real armor crack, break and separate normal hit")
 check(last_hit==report.terminal_time_us and final_fire==28950000 and last_hit-final_fire==450000,"last actual damage, not launch, owns victory")
 check(picked.has(44) and picked.has(46) and picked.has(73),"all three real white beads collected")
 report["label"]=label;report["accepted_input_sequence"]=inputs
 report["transport_paths"]=paths;report["first_delivery_us"]=first_delivery
 report["final_hit_us"]=last_hit;report["final_fire_us"]=final_fire
 report["pickup_times_us"]=pickup_times
 var leftover:Dictionary={};var leftover_ids:Array=[]
 for color in c.palette.values():leftover[color]=0
 for y in range(int(c.height)):
  for x in range(int(c.width)):
   var symbol:String=str(c.grid[y]).substr(x,1)
   if symbol!="." and not picked.has(y*int(c.width)+x):
    leftover[c.palette[symbol]]+=1;leftover_ids.append(y*int(c.width)+x)
 check(leftover=={"red":1,"blue":2,"green":1,"yellow":2,"purple":1,"white":0},"actual unpicked board colors match expected surplus")
 report["leftover_by_color"]=leftover;report["leftover_cell_ids"]=leftover_ids
 report["path_histogram"]={"three_to_five":short_routes,"six":six_routes}
 return report
func run() -> void:
 var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(LEVEL))
 check(Rules.API_VERSION=="3.1.0" and FileAccess.get_sha256("res://scripts/rescue_rules.gd")==RULES_HASH,"frozen production rule bytes and API")
 check(c.width==10 and c.height==8 and int(c.transport.entrance_cell[0])==6 and int(c.transport.entrance_cell[1])==8,"unchanged ice board and source")
 check(c.region_id=="ice_valley" and c.scene_layout in ["res://data/scenes/ice-camp.json","res://data/scenes/ice-snowpass.json"],"existing ice presentation or level-local stock-layout successor")
 check(c.defense_target=={"id":"winter_camp","display_name":"Winter Camp","fixed":true},"same stationary winter camp")
 check(c.serpent.art_profile=="ice_crest" and c.tools.is_empty(),"same ice appearance and no tools")
 check(c.transport.outbound_speed_cells_sec==2.5 and c.transport.returning_speed_cells_sec==2.0,"unchanged base worker speeds")
 check(c.transport.pickup_pause_sec==0.3 and c.transport.unload_pause_sec==0.2,"pickup and unloading remain readable")
 var seed=fresh(c)
 check(seed.board.size()==25 and seed.initial_counts==SUPPLY,"25 real beads across six colors")
 var damage:Dictionary={};var armor:=0
 for s in c.segments:
  damage[s.color]=int(damage.get(s.color,0))+int(s.hp)
  if s.kind=="armored":armor+=1;check(s.color in ["white","purple"] and s.hp==2,"only white and purple have one visible HP2 each")
 check(damage==DAMAGE and c.segments.size()==16 and armor==2,"18 damage, 14 normal and two armor")
 var initial_targets:Dictionary={}
 for color in c.palette.values():initial_targets[color]=seed.best_target(color)
 var openings:Array=[opening(c,"red",55,4,[44,46,54]),opening(c,"green",56,3,[46,57]),opening(c,"white",73,4,[])]
 check(openings[0].after_pickup["46"].distance==6 and openings[1].after_pickup["46"].distance==4,"red opens the wider courtyard while green shortens right-white transport by two cells")
 var red_pair:=first_two(c,"red");var green_pair:=first_two(c,"green")
 check(red_pair.white_selected_cell_id==73 and green_pair.white_selected_cell_id==46,"same second white input selects different real nearest targets")
 check(red_pair.first_left_white_reachable_us==1600000 and green_pair.first_left_white_reachable_us==3000000,"red opens left white 1.4 seconds earlier; green+white opens it in two pickups")
 var alternate:Array=[]
 for i in range(ALTERNATE.size()):alternate.append({"at_sec":float(i)*1.4,"color":ALTERNATE[i]})
 var main:=replay(c,c.solution.inputs,"red_courtyard_first")
 var alt:=replay(c,alternate,"green_right_white_first")
 check(main.first_delivery_us==4100000 and alt.first_delivery_us==3200000,"opening choices have distinct first-ammunition latency")
 var cap=fresh(c)
 for color in ["red","blue","green","purple"]:check(cap.click_color(color).ok,"four-carrier probe dispatch accepted")
 var fifth:Dictionary=cap.click_color("white")
 check(not fifth.ok and fifth.reason=="carrier_limit" and not fifth.queued and cap.tasks.size()==4,"fifth click refused without hidden queue")
 cap.set_paused(true);var paused:Dictionary=cap.replay_state();cap.update_us(2000000)
 check(cap.time_us==paused.time_us and cap.tasks==paused.tasks and not cap.click_color("white").ok,"pause freezes workers and rejects new inputs")
 var unfinished=fresh(c);unfinished.click_color("green");unfinished.update_us(64000000)
 check(unfinished.status=="defeat" and unfinished.terminal_reason=="dragon_contact" and unfinished.time_us==64000000,"remaining enemy reaches the finite endpoint at 64 seconds")
 var last=fresh(c)
 for input in c.solution.inputs:
  last.update_us(Rules.seconds_to_us(input.at_sec)-last.time_us);check(last.click_color(input.color).ok,"last-hit timing probe input")
 last.update_us(29399999-last.time_us)
 check(last.status=="running" and not last.projectile.is_empty(),"no victory one microsecond before final projectile hit")
 last.update_us(1)
 check(last.status=="victory" and last.terminal_reason=="final_segment_hit" and last.time_us==29400000,"exact last actual hit wins")
 check(last.tasks.is_empty() and last.inventory.values().all(func(v):return v==0) and last.hit_counts==DAMAGE,"no leftover carried beads, hidden inventory or unpaid damage")
 check(last.available_counts()==main.leftover_by_color and last.conservation_errors().is_empty(),"reported leftovers equal actual terminal board")
 var insufficient:Dictionary=c.duplicate(true)
 insufficient.grid[4]=str(insufficient.grid[4]).substr(0,4)+"."+str(insufficient.grid[4]).substr(5)
 check(Rules.validate_level(insufficient).has("insufficient segment supply: white"),"surplus other colors cannot replace missing mandatory white")
 var report:Dictionary={"ok":failures.is_empty(),"checks":checks,"failures":failures,"engine":Engine.get_version_info().string,"rules_api":Rules.API_VERSION,"rules_sha256":RULES_HASH,"level_sha256":FileAccess.get_sha256(LEVEL),"scene_layout":c.scene_layout,"supply_by_color":SUPPLY,"required_damage_by_color":DAMAGE,"normal_segments":14,"armored_segments":2,"total_beads":25,"initial_best_targets":initial_targets,"openings":openings,"same_second_color_different_targets":[red_pair,green_pair],"solutions":[main,alt],"scope":"Only level 10: two authored base-Worker timed solutions, production CLI inspection, bounded opening/accounting/capacity/pause/finite-goal/last-hit checks. No old-level/full-suite run, new gameplay, GL, human balance, visual, native-input, sound, target-device or economy acceptance."}
 save_json("res://reports/rules/ice-courtyard-level10.json",report)
 save_json("res://reports/rules/serpent-10-alternate-inputs.json",{"level_id":c.level_id,"level_sha256":report.level_sha256,"label":alt.label,"minimum_input_gap_sec":1.4,"inputs":alternate})
 print("ICE_COURTYARD_LEVEL10 ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"main_final_hit_us":main.final_hit_us,"alt_final_hit_us":alt.final_hit_us,"remaining_beads":7,"main_wait_us":main.longest_no_dispatch_opportunity_us,"alt_wait_us":alt.longest_no_dispatch_opportunity_us}))
 quit(0 if failures.is_empty() else 1)
