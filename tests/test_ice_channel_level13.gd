extends SceneTree
## Level 13 only: two authored input lists, actual production nearest-target events.
## This test neither searches for solutions nor retries rejected inputs.
const Rules=preload("res://scripts/rescue_rules.gd")
const Validator=preload("res://tools/validate_serpent_level.gd")
const LEVEL="res://data/serpent-levels/serpent-13.json"
const ALT="res://reports/rules/serpent-13-alternate-inputs.json"
const LEVEL_SHA="b5952c81d4030f236ad3d3dd14633f153cfa2602bcf97632429219b4f801778a"
const RULES_SHA="14a5b20efdf237fbf271ea8749b35580d012485aee8a529a30e53487852c7c23"
const VALIDATOR_SHA="cedd70807758db55d38f0a836c3260e8da167d3268923797a2545fd1fa519a91"
const SCENE_SHA="1b5ee43ae6dd2d712d4a8e8e4a01cebd6d6511dc1b87cceda46622116a0056c6"
const SUPPLY={"red":5,"blue":5,"green":7,"yellow":5,"white":3}
const DAMAGE={"red":3,"blue":4,"green":4,"yellow":3,"white":3}
const LEFTOVER={"red":2,"blue":1,"green":3,"yellow":2,"white":0}
var checks:=0
var failures:Array=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func write(path:String,value:Dictionary):
 var file=FileAccess.open(path,FileAccess.WRITE)
 assert(file!=null,"Cannot write the bounded level 13 report")
 file.store_string(JSON.stringify(value,"\t")+"\n");file.close()
func fresh(c:Dictionary):
 var r=Rules.new();assert(r.load_level(c),"Current candidate must load");return r
func geometry(r)->Dictionary:
 var result={};var reachable:Array=r.reachable_cell_ids("",true)
 for id in [25,34,35,36,43,44,45,46,52,53,54,55,56,57,64,67,74,77]:
  result[str(id)]={"reachable":reachable.has(id),"distance_cells":r._routes[id].distance if reachable.has(id) else -1,"path":r._routes[id].path if reachable.has(id) else []}
 return result
func gate(c:Dictionary,label:String,prefix:Array,cell:int,new_ids:Array)->Dictionary:
 var r=fresh(c);var task:Dictionary={};var accepted_ok:=true
 for input in prefix:
  r.update_us(Rules.seconds_to_us(input.at_sec)-r.time_us)
  var accepted:Dictionary=r.click_color(input.color)
  accepted_ok=accepted_ok and accepted.ok
  if not accepted.ok:break
  task=r.tasks[accepted.task_id].duplicate(true)
 check(accepted_ok and task.cell_id==cell,label+": only real color clicks choose the stated nearest cell")
 var reserved=geometry(r);var reachable:Array=r.reachable_cell_ids("",true);var count=r.board.size()
 r.update_us(int(task.pickup_us)-1-r.time_us);var before=geometry(r)
 check(before==reserved and r.board.size()==count and r.reservations.has(cell),label+": reservation and one microsecond before pickup leave the gate closed")
 r.update_us(1);var after=geometry(r);var newly:Array=[]
 for id in r.reachable_cell_ids("",true):
  if not reachable.has(id):newly.append(id)
 check(newly==new_ids and r.board.size()==count-1 and not r.reservations.has(cell),label+": the actual pickup alone opens the expected cells")
 var events:Array=r.drain_events();var own_deliveries:=0
 for e in events:
  if e.type=="bead_delivered" and e.id==task.id:own_deliveries+=1
 check(own_deliveries==0 and r.tasks[task.id].stage=="returning" and r.conservation_errors().is_empty(),label+": this pickup has not supplied ammo or freed its carrier")
 r.update_us(int(task.unload_us)-1-r.time_us)
 check(r.tasks.has(task.id) and r.tasks[task.id].stage=="returning",label+": return remains a live task before unloading")
 r.update_us(1)
 check(r.tasks.has(task.id) and r.tasks[task.id].stage=="unloading",label+": arrival starts the actual 0.2-second unload")
 r.update_us(int(task.delivery_us)-1-r.time_us)
 check(r.tasks.has(task.id),label+": no carrier or delivery release one microsecond early")
 r.update_us(1);events.append_array(r.drain_events());var delivered_at:=-1
 for e in events:
  if e.type=="bead_delivered" and e.id==task.id:own_deliveries+=1;delivered_at=e.time_us
 check(own_deliveries==1 and delivered_at==task.delivery_us and not r.tasks.has(task.id) and r.conservation_errors().is_empty(),label+": one bead is delivered exactly after unload, with conserved resources")
 return {"label":label,"inputs":prefix,"gate_task":task,"after_reservation":reserved,"one_microsecond_before_pickup":before,"after_actual_pickup":after,"newly_reachable_cell_ids":newly,"raw_events":events}
func replay(c:Dictionary,inputs:Array,label:String)->Dictionary:
 var candidate=c.duplicate(true);candidate.solution.inputs=inputs.duplicate(true)
 var out:Dictionary=Validator.inspect(candidate,true)
 check(out.ok,label+": every explicit input passes the unchanged single-level validator without retries")
 if not out.ok:return out
 check(out.status=="victory" and out.terminal_time_us==31950000 and out.contact_time_us==66000000,label+": final damage at 31.95s wins inside the fixed 66-second budget")
 check(out.accepted_inputs==17 and out.remaining_beads==8 and out.supply_by_color==SUPPLY and out.required_damage_by_color==DAMAGE and out.hit_counts==DAMAGE,label+": 25 beads, exactly 17 matching HP and eight leftovers")
 check(out.maximum_carriers==4 and out.longest_no_dispatch_opportunity_us==200000,label+": four-carrier peak and 0.20-second maximum unavailable window")
 var histogram={}
 for distance in out.path_cells:histogram[str(distance)]=int(histogram.get(str(distance),0))+1
 check(histogram=={"2":1,"3":4,"4":4,"5":6,"6":2},label+": fourteen 3–5-cell routes, two six-cell routes and one two-cell route")
 var previous:=-1600000;var regular:=true
 for input in inputs:
  var at=Rules.seconds_to_us(input.at_sec);regular=regular and at-previous==1600000;previous=at
 check(regular,label+": the authored click interval is exactly 1.6 seconds")
 var paths:Array=[];var picked:Array=[];var delivered:Array=[];var removed:Array=[];var hits:Array=[]
 var projectile_count:=0;var valid_events:=true;var armor_hits:=0;var first_delivery:=-1;var final_fire:=-1;var final_hit:=-1
 var hp_by_id={};var armor_removal={};var first_hit_by_color={};var task_by_id={}
 for segment in c.segments:hp_by_id[segment.id]=int(segment.hp)
 for e in out.events:
  if e.type=="ant_dispatched":
   paths.append(e);task_by_id[e.id]=e
   valid_events=valid_events and e.carrier_type=="worker" and e.speed_multiplier==1.0 and e.distance_cells>=2 and e.distance_cells<=6
  elif e.type=="bead_picked_up":
   valid_events=valid_events and not picked.has(e.cell_id) and e.time_us==task_by_id[e.id].pickup_us;picked.append(e.cell_id)
  elif e.type=="bead_delivered":
   valid_events=valid_events and not delivered.has(e.id) and e.time_us==task_by_id[e.id].delivery_us;delivered.append(e.id)
   if first_delivery<0:first_delivery=e.time_us
  elif e.type=="cannon_fired":projectile_count+=1;valid_events=valid_events and projectile_count==1;final_fire=e.time_us
  elif e.type=="segment_hit":
   projectile_count-=1;final_hit=e.time_us;hits.append(e)
   hp_by_id[e.segment_id]-=1
   valid_events=valid_events and e.source=="projectile" and e.amount==1 and e.target_segment_id==e.segment_id and e.hp==hp_by_id[e.segment_id] and e.hp>=0
   if not first_hit_by_color.has(e.color):first_hit_by_color[e.color]=e.time_us
   if e.kind=="armored":armor_hits+=1
  elif e.type=="segment_removed":
   valid_events=valid_events and not removed.has(e.segment_id) and hp_by_id[e.segment_id]==0;removed.append(e.segment_id)
   if e.kind=="armored":armor_removal[e.color]=e.time_us
 check(valid_events and paths.size()==17 and picked.size()==17 and delivered.size()==17 and hits.size()==17 and removed.size()==15 and armor_hits==4 and projectile_count==0 and hp_by_id.values().all(func(x):return x==0),label+": one-click/ant/bead, unload supply, stable-ID HP1/HP2 and one in-flight ordinary projectile")
 check([35,44,46].all(func(id):return picked.has(id)) and final_hit==out.terminal_time_us and final_hit-final_fire==450000,label+": all mandatory white beads and the final 0.45-second projectile complete")
 out.merge({"label":label,"inputs":inputs,"transport_paths":paths,"pickup_cell_ids":picked,"damage_events":hits,"first_delivery_us":first_delivery,"first_hit_by_color_us":first_hit_by_color,"armor_removed_us":armor_removal,"final_fire_us":final_fire,"final_hit_us":final_hit,"path_histogram":histogram,"leftover_by_color":LEFTOVER,"remaining_budget_us":int(out.contact_time_us)-int(out.terminal_time_us)},true)
 return out
func run():
 var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(LEVEL));var alt:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ALT))
 check(FileAccess.get_sha256(LEVEL)==LEVEL_SHA,"the handed-off level JSON remains frozen byte-for-byte")
 check(FileAccess.get_sha256("res://scripts/rescue_rules.gd")==RULES_SHA and Rules.API_VERSION=="3.1.0" and FileAccess.get_sha256("res://tools/validate_serpent_level.gd")==VALIDATOR_SHA,"production rules and single-level validator are unchanged fixtures")
 check(FileAccess.get_sha256(c.scene_layout)==SCENE_SHA and c.palette.size()==5 and c.palette.W=="white" and c.tools.is_empty() and c.scene_layout=="res://data/scenes/ice-snowpass.json" and c.serpent.art_profile=="ice_crest" and c.defense_target=={"id":"winter_camp","display_name":"Winter Camp","fixed":true},"existing five-color snowpass scene and ice crest protect the fixed winter camp without new mechanisms")
 check(c.transport.carrier_type=="worker" and c.transport.outbound_speed_cells_sec==2.5 and c.transport.returning_speed_cells_sec==2.0 and c.transport.pickup_pause_sec==0.3 and c.transport.unload_pause_sec==0.2 and int(c.transport.entrance_cell[0])==5 and int(c.transport.entrance_cell[1])==8 and int(c.parameters.max_inflight_ants)==4 and c.parameters.projectile_flight_sec==0.45 and c.parameters.cannon_cooldown_sec==0.65,"Worker Lv.1 movement, four carriers, pauses and cannon timing are unchanged")
 var r=fresh(c)
 check(r.board.size()==25 and r.initial_counts==SUPPLY and r.reachable_cell_ids("white").is_empty() and r.best_target("white").is_empty(),"all three demand-matched white beads are genuinely initially blocked")
 check(r.segment_positions().values().all(func(s):return s>=0.0) and c.serpent.head_start_s==62 and c.serpent.goal_s==144 and c.segments.size()==15,"the complete initial body fits on the finite route before its fixed endpoint")
 var component:Array=[r.board.keys()[0]];var cursor:=0
 while cursor<component.size():
  var id:int=component[cursor];cursor+=1
  for other in r.board:
   if not component.has(other) and absi(int(r.board[id].x)-int(r.board[other].x))+absi(int(r.board[id].y)-int(r.board[other].y))==1:component.append(other)
 component.sort()
 check(component.size()==25,"one connected offset channel mosaic, not the prior separate vaults")
 var blocked=r.click_color("white")
 check(not blocked.ok and blocked.reason=="color_blocked" and not blocked.queued and r.tasks.is_empty(),"white-before-opening visibly fails without task or hidden queue")
 var gates=[gate(c,"central_yellow_first_stage",c.solution.inputs.slice(0,2),55,[45,56]),gate(c,"central_blue_second_stage",c.solution.inputs.slice(0,3),45,[35,44,46]),gate(c,"outer_red_first_stage",alt.inputs.slice(0,1),53,[43,54]),gate(c,"blue_shortcut_to_inner_red",alt.inputs.slice(0,3),64,[]),gate(c,"inner_red_second_stage",alt.inputs.slice(0,4),54,[44])]
 check(gates[0].after_actual_pickup["45"].distance_cells==4 and ["35","44","46"].all(func(id):return not gates[0].after_actual_pickup[id].reachable),"the first central gate exposes blue but does not prematurely expose white")
 check(["35","44","46"].all(func(id):return gates[1].after_actual_pickup[id].distance_cells==5),"the second central gate creates three real five-cell white routes")
 check(gates[2].after_actual_pickup["54"].distance_cells==6 and gates[2].after_actual_pickup["52"].distance_cells==6 and gates[2].one_microsecond_before_pickup["52"].distance_cells==8,"the outer red pickup creates the six-cell inner-red approach and cuts side blue from eight to six")
 check(gates[3].one_microsecond_before_pickup["54"].distance_cells==6 and gates[3].after_actual_pickup["54"].distance_cells==4,"the real lower blue pickup shortens the alternative inner-red route from six to four")
 check(gates[4].after_actual_pickup["44"].distance_cells==5 and not gates[4].after_actual_pickup["35"].reachable and not gates[4].after_actual_pickup["46"].reachable,"the alternative second gate opens only the left white, not the central trio")
 var main=replay(c,c.solution.inputs,"central_yellow_blue_channel");var alternative=replay(c,alt.inputs,"outer_red_channel_first")
 check(main.transport_paths[3].cell_id==35 and alternative.transport_paths[4].cell_id==44,"two authored branches produce different actual first-white targets")
 check(main.first_delivery_us==3200000 and alternative.first_delivery_us==3900000 and main.armor_removed_us.blue==7750000 and alternative.armor_removed_us.blue==14150000 and main.armor_removed_us.white==15500000 and alternative.armor_removed_us.white==17100000,"the branches differ in first supply and real blue/white armor removal timing")
 var cap=fresh(c);var accepted:=true
 for color in ["blue","red","yellow","green"]:accepted=accepted and cap.click_color(color).ok
 var fifth:Dictionary=cap.click_color("blue")
 check(accepted and cap.tasks.size()==4 and not fifth.ok and fifth.reason=="carrier_limit" and not fifth.queued,"four actual tasks occupy all places and the fifth click is rejected")
 cap.update_us(7000000)
 check(cap.tasks.is_empty() and cap.dispatched_counts.values().reduce(func(a,b):return a+b,0)==4,"the rejected fifth click never reappears when places become free")
 var last=fresh(c)
 for input in c.solution.inputs:
  last.update_us(Rules.seconds_to_us(input.at_sec)-last.time_us);assert(last.click_color(input.color).ok)
 last.update_us(31949999-last.time_us)
 check(last.status=="running" and not last.projectile.is_empty(),"launch and one microsecond before last damage are not victory")
 last.update_us(1)
 check(last.status=="victory" and last.terminal_reason=="final_segment_hit" and last.conservation_errors().is_empty() and last.available_counts()==LEFTOVER and last.tasks.is_empty() and last.inventory.values().all(func(x):return x==0),"actual final damage wins with exact leftovers and no phantom ammo or tasks")
 var shortfall=c.duplicate(true);shortfall.grid[3]="...RY.BG.."
 check(Rules.validate_level(shortfall).has("insufficient segment supply: white"),"other surplus colors cannot substitute for a missing necessary white bead")
 var idle=fresh(c);idle.click_color("blue");idle.update_us(65999999)
 check(idle.status=="running" and idle.head_s()<c.serpent.goal_s,"unfinished serpent is still running one microsecond before actual contact")
 idle.update_us(1)
 check(idle.status=="defeat" and idle.terminal_reason=="dragon_contact" and idle.time_us==66000000 and idle.head_s()==c.serpent.goal_s,"the finite enemy reaches its fixed endpoint and fails exactly at 66 seconds")
 alt["level_sha256"]=LEVEL_SHA;write(ALT,alt)
 var report={"ok":failures.is_empty(),"checks":checks,"failures":failures,"engine":Engine.get_version_info().string,"level_sha256":LEVEL_SHA,"rules_api":Rules.API_VERSION,"rules_sha256":RULES_SHA,"validator_sha256":VALIDATOR_SHA,"scene_sha256":SCENE_SHA,"test_sha256":FileAccess.get_sha256("res://tests/test_ice_channel_level13.gd"),"supply_by_color":SUPPLY,"required_damage_by_color":DAMAGE,"total_beads":25,"normal_segments":13,"armored_segments":2,"occupied_component":component,"gate_checks":gates,"solutions":[main,alternative],"reward_thresholds":{"fast_seconds":33,"normal_seconds":47,"status":"Candidate configuration only, informed by the measured 31.95-second authored Worker Lv.1 replay; not human difficulty or economy balancing."},"scope":"Level 13 only: two explicit 1.6-second Worker Lv.1 input lists, real nearest-target paths, two-stage opening and shortcut, reservation/pickup/unload/delivery, stable-ID HP1/HP2, four-carrier rejection, conservation, final actual damage and finite fixed-target contact. No solver, input retry, old-level reruns, mechanism, asset, GL, human pacing/economy, native-input, audio or target-device acceptance."}
 write("res://reports/rules/ice-channel-level13.json",report)
 print("ICE_CHANNEL_LEVEL13 ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"level_sha256":LEVEL_SHA,"main_final_hit_us":main.terminal_time_us,"alternate_final_hit_us":alternative.terminal_time_us,"main_longest_wait_us":main.longest_no_dispatch_opportunity_us,"alternate_longest_wait_us":alternative.longest_no_dispatch_opportunity_us}))
 quit(0 if report.ok else 1)
