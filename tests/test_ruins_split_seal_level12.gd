extends SceneTree
## Level 12 only: bounded authored inputs and actual production events, never a solver.
const Rules=preload("res://scripts/rescue_rules.gd")
const Validator=preload("res://tools/validate_serpent_level.gd")
const LEVEL="res://data/serpent-levels/serpent-12.json"
const ALT="res://reports/rules/serpent-12-alternate-inputs.json"
const RULES_SHA="14a5b20efdf237fbf271ea8749b35580d012485aee8a529a30e53487852c7c23"
const SUPPLY={"red":4,"blue":4,"green":5,"yellow":6,"purple":4}
const DAMAGE={"red":3,"blue":4,"green":3,"yellow":3,"purple":4}
var checks:=0
var failures:Array=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func write(path:String,value:Dictionary):
 var file=FileAccess.open(path,FileAccess.WRITE)
 assert(file!=null,"Cannot write the level 12 report")
 file.store_string(JSON.stringify(value,"\t")+"\n");file.close()
func fresh(c:Dictionary):
 var r=Rules.new();assert(r.load_level(c),"Current candidate must load");return r
func geometry(r)->Dictionary:
 var result={};var reachable:Array=r.reachable_cell_ids("",true)
 for id in [41,42,43,51,52,55,65,66]:
  result[str(id)]={"reachable":reachable.has(id),"distance_cells":r._routes[id].distance if reachable.has(id) else -1,"path":r._routes[id].path if reachable.has(id) else []}
 return result
func opening(c:Dictionary,label:String,prefix:Array,cell:int,new_ids:Array)->Dictionary:
 var r=fresh(c);var task:Dictionary={};var accepted_ok:=true
 for input in prefix:
  r.update_us(Rules.seconds_to_us(input.at_sec)-r.time_us)
  var accepted:Dictionary=r.click_color(input.color)
  accepted_ok=accepted_ok and accepted.ok
  if not accepted.ok:break
  task=r.tasks[accepted.task_id].duplicate(true)
 check(accepted_ok and task.cell_id==cell,label+": production clicks select the claimed nearest target")
 var reserved=geometry(r);var reachable:Array=r.reachable_cell_ids("",true);var count=r.board.size()
 r.update_us(int(task.pickup_us)-1-r.time_us);var before=geometry(r)
 check(before==reserved and r.board.size()==count,label+": reservation and one microsecond before pickup do not open the gate")
 r.update_us(1);var after=geometry(r);var newly:Array=[]
 for id in r.reachable_cell_ids("",true):
  if not reachable.has(id):newly.append(id)
 check(newly==new_ids and r.board.size()==count-1,label+": exactly the actual pickup opens the recorded branch")
 check(r.delivered_counts.values().reduce(func(a,b):return a+b,0)==0 and r.hit_counts.values().reduce(func(a,b):return a+b,0)==0 and r.conservation_errors().is_empty(),label+": pickup is not supply or damage")
 return {"label":label,"inputs":prefix,"gate_task":task,"after_reservation":reserved,"one_microsecond_before_pickup":before,"after_actual_pickup":after,"newly_reachable_cell_ids":newly,"raw_events":r.drain_events()}
func replay(c:Dictionary,inputs:Array,label:String)->Dictionary:
 var candidate=c.duplicate(true);candidate.solution.inputs=inputs.duplicate(true)
 var out:Dictionary=Validator.inspect(candidate,true)
 check(out.ok,label+": all explicit inputs pass the unchanged single-level inspector without retries")
 if not out.ok:return out
 check(out.status=="victory" and out.terminal_time_us==31050000 and out.contact_time_us==64000000,label+": final damage wins at 31.05s before the 64s finite threat")
 check(out.accepted_inputs==17 and out.remaining_beads==6 and out.supply_by_color==SUPPLY and out.required_damage_by_color==DAMAGE and out.hit_counts==DAMAGE,label+": exact five-color supply, HP and leftover accounting")
 check(out.maximum_carriers==4 and out.longest_no_dispatch_opportunity_us==200000,label+": four-carrier peak and 0.20s longest all-color unavailable window")
 var histogram={};var short:=0
 for distance in out.path_cells:
  histogram[str(distance)]=int(histogram.get(str(distance),0))+1
  if distance>=3 and distance<=5:short+=1
 check(short==14 and histogram.get("6",0)==2 and histogram.get("2",0)==1,label+": fourteen 3–5-cell trips, two six-cell trips and one two-cell trip")
 var previous:=-1600000;var regular:=true
 for input in inputs:
  var at=Rules.seconds_to_us(input.at_sec);regular=regular and at-previous==1600000;previous=at
 check(regular,label+": one authored input every 1.6s")
 var paths:Array=[];var picks:Array=[];var deliveries:Array=[];var removed:Array=[];var hits:Array=[];var projectile_count:=0;var valid_events:=true;var armor_hits:=0;var first_delivery:=-1;var final_fire:=-1;var final_hit:=-1
 for e in out.events:
  if e.type=="ant_dispatched":
   paths.append(e);valid_events=valid_events and e.carrier_type=="worker" and e.speed_multiplier==1.0
  elif e.type=="bead_picked_up":valid_events=valid_events and not picks.has(e.cell_id);picks.append(e.cell_id)
  elif e.type=="bead_delivered":
   valid_events=valid_events and not deliveries.has(e.id);deliveries.append(e.id)
   if first_delivery<0:first_delivery=e.time_us
  elif e.type=="cannon_fired":projectile_count+=1;valid_events=valid_events and projectile_count==1;final_fire=e.time_us
  elif e.type=="segment_hit":
   projectile_count-=1;final_hit=e.time_us;hits.append(e)
   valid_events=valid_events and e.source=="projectile" and e.amount==1
   if e.kind=="armored":armor_hits+=1
  elif e.type=="segment_removed":valid_events=valid_events and not removed.has(e.segment_id);removed.append(e.segment_id)
 check(valid_events and paths.size()==17 and picks.size()==17 and deliveries.size()==17 and hits.size()==17 and removed.size()==15 and armor_hits==4 and projectile_count==0,label+": one click/ant/bead, one ordinary projectile, stable HP1/HP2 events")
 check([41,42,51,52].all(func(id):return picks.has(id)) and final_hit==out.terminal_time_us and final_hit-final_fire==450000,label+": all mandatory sealed purple collected and last flight ends on actual damage")
 out.merge({"label":label,"inputs":inputs,"transport_paths":paths,"pickup_cell_ids":picks,"damage_events":hits,"first_delivery_us":first_delivery,"final_fire_us":final_fire,"final_hit_us":final_hit,"path_histogram":histogram,"leftover_by_color":{"red":1,"blue":0,"green":2,"yellow":3,"purple":0}},true)
 return out
func run():
 var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(LEVEL));var alt:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ALT))
 check(FileAccess.get_sha256("res://scripts/rescue_rules.gd")==RULES_SHA and Rules.API_VERSION=="3.1.0","authoritative production rules are byte-identical")
 check(c.palette.size()==5 and c.tools.is_empty() and c.scene_layout=="res://data/scenes/ruins-cart.json" and c.serpent.art_profile=="ruins_carapace" and c.defense_target=={"id":"supply_cart","display_name":"Supply Cart","fixed":true},"five colors and existing parked-cart/carapace scene, no new tools or mechanism")
 check(c.transport.carrier_type=="worker" and c.transport.outbound_speed_cells_sec==2.5 and c.transport.returning_speed_cells_sec==2.0 and c.transport.pickup_pause_sec==0.3 and c.transport.unload_pause_sec==0.2 and int(c.transport.entrance_cell[0])==3 and int(c.transport.entrance_cell[1])==8 and int(c.parameters.max_inflight_ants)==4 and c.parameters.projectile_flight_sec==0.45 and c.parameters.cannon_cooldown_sec==0.65,"unchanged left-entry Worker Lv.1 movement, pauses and cannon timing")
 var r=fresh(c)
 check(r.board.size()==23 and r.initial_counts==SUPPLY and r.reachable_cell_ids("purple").is_empty() and r.best_target("purple").is_empty(),"all four necessary purple beads initially blocked")
 var components:Array=[];var unvisited:Array=r.board.keys()
 while not unvisited.is_empty():
  var component:Array=[unvisited.pop_front()];var cursor:=0
  while cursor<component.size():
   var id:int=component[cursor];cursor+=1
   for other in unvisited.duplicate():
    if absi(int(r.board[id].x)-int(r.board[other].x))+absi(int(r.board[id].y)-int(r.board[other].y))==1:component.append(other);unvisited.erase(other)
  component.sort();components.append(component)
 var sizes:Array=components.map(func(component):return component.size());sizes.sort()
 check(sizes==[11,12],"separate 12-bead sealed vault and 11-bead supply terrace, not level 11's connected crossing")
 var blocked=r.click_color("purple")
 check(not blocked.ok and blocked.reason=="color_blocked" and not blocked.queued and r.tasks.is_empty(),"purple-before-opening fails visibly without dispatch or hidden queue")
 var gates=[opening(c,"blue_lower_seal",[{"at_sec":0.0,"color":"blue"}],62,[52]),opening(c,"red_outer_seal",[{"at_sec":0.0,"color":"red"}],61,[51]),opening(c,"yellow_upper_passage",[{"at_sec":0.0,"color":"yellow"}],53,[52]),opening(c,"blue_right_terrace",[{"at_sec":0.0,"color":"blue"},{"at_sec":1.6,"color":"blue"}],64,[65])]
 check(gates[2].one_microsecond_before_pickup["55"].distance_cells==17 and gates[2].after_actual_pickup["55"].distance_cells==5 and gates[2].one_microsecond_before_pickup["43"].distance_cells==16 and gates[2].after_actual_pickup["43"].distance_cells==4,"yellow pickup makes real 17→5 red and 16→4 green shortcuts")
 check(gates[3].one_microsecond_before_pickup["55"].distance_cells==17 and gates[3].after_actual_pickup["55"].distance_cells==5 and gates[3].after_actual_pickup["43"].distance_cells==6,"second real blue click opens the terrace, with a different six-cell upper-green approach")
 var main=replay(c,c.solution.inputs,"blue_lower_seal_first");var alternative=replay(c,alt.inputs,"red_outer_seal_first")
 check(main.transport_paths[1].cell_id==52 and alternative.transport_paths[1].cell_id==51,"two strategies take different actual first-purple targets")
 var cap=fresh(c);var accepted:=true
 for color in ["blue","red","yellow","green"]:accepted=accepted and cap.click_color(color).ok
 var fifth:Dictionary=cap.click_color("blue")
 check(accepted and cap.tasks.size()==4 and not fifth.ok and fifth.reason=="carrier_limit" and not fifth.queued,"four clicks create four carriers and fifth is rejected without queue")
 cap.update_us(7000000)
 check(cap.tasks.is_empty() and cap.dispatched_counts.values().reduce(func(a,b):return a+b,0)==4,"rejected fifth click never appears after the slots clear")
 var last=fresh(c)
 for input in c.solution.inputs:
  last.update_us(Rules.seconds_to_us(input.at_sec)-last.time_us);assert(last.click_color(input.color).ok)
 last.update_us(31049999-last.time_us)
 check(last.status=="running" and not last.projectile.is_empty(),"launch and one microsecond before final damage are not victory")
 last.update_us(1)
 check(last.status=="victory" and last.terminal_reason=="final_segment_hit" and last.conservation_errors().is_empty() and last.available_counts()==main.leftover_by_color and last.tasks.is_empty() and last.inventory.values().all(func(x):return x==0),"final actual hit wins with exact leftover board, no phantom stock or tasks")
 var shortfall=c.duplicate(true);shortfall.grid[4]="Y.PG.Y...."
 check(Rules.validate_level(shortfall).has("insufficient segment supply: purple"),"surplus colors cannot fund a missing mandatory purple bead")
 var idle=fresh(c);idle.click_color("blue");idle.update_us(64000000)
 check(idle.status=="defeat" and idle.terminal_reason=="dragon_contact" and idle.time_us==64000000,"unfinished serpent reaches its fixed finite endpoint at 64s")
 var hash=FileAccess.get_sha256(LEVEL);alt["level_sha256"]=hash;write(ALT,alt)
 var report={"ok":failures.is_empty(),"checks":checks,"failures":failures,"engine":Engine.get_version_info().string,"level_sha256":hash,"rules_api":Rules.API_VERSION,"rules_sha256":FileAccess.get_sha256("res://scripts/rescue_rules.gd"),"validator_sha256":FileAccess.get_sha256("res://tools/validate_serpent_level.gd"),"scene_sha256":FileAccess.get_sha256(c.scene_layout),"supply_by_color":SUPPLY,"required_damage_by_color":DAMAGE,"total_beads":23,"normal_segments":13,"armored_segments":2,"occupied_components":components,"gate_checks":gates,"solutions":[main,alternative],"reward_thresholds":{"fast_seconds":33,"normal_seconds":46,"status":"Candidate configuration only. Based on the measured 31.05s authored base-worker replay; not human difficulty or economy balancing."},"scope":"Level 12 only. Two authored 1.6-second Worker Lv.1 sequences, actual nearest-target click_color paths, supply/HP, opening/shortcut deadlines, four-carrier rejection, conservation and final-hit/finite-goal checks. No solver, old-level reruns, new mechanics, GL, human pacing/economy, native-input, audio or target-device acceptance."}
 report["test_sha256"]=FileAccess.get_sha256("res://tests/test_ruins_split_seal_level12.gd")
 write("res://reports/rules/ruins-split-seal-level12.json",report)
 print("RUINS_SPLIT_SEAL_LEVEL12 ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"level_sha256":hash,"main_final_hit_us":main.terminal_time_us,"alternate_final_hit_us":alternative.terminal_time_us,"main_longest_wait_us":main.longest_no_dispatch_opportunity_us,"alternate_longest_wait_us":alternative.longest_no_dispatch_opportunity_us}))
 quit(0 if report.ok else 1)
