extends SceneTree
## Level 11 only. Reuses the unchanged production single-level inspector; no solver.
const Rules=preload("res://scripts/rescue_rules.gd")
const Validator=preload("res://tools/validate_serpent_level.gd")
const LEVEL="res://data/serpent-levels/serpent-11.json"
const ALT="res://reports/rules/serpent-11-alternate-inputs.json"
const RULES_HASH="14a5b20efdf237fbf271ea8749b35580d012485aee8a529a30e53487852c7c23"
const SUPPLY={"red":4,"blue":4,"green":8,"yellow":6}
const DAMAGE={"red":4,"blue":4,"green":4,"yellow":4}
var checks:=0
var failures:Array=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func write(path:String,data:Dictionary):
 var f=FileAccess.open(path,FileAccess.WRITE)
 assert(f!=null,"Cannot write level 11 report")
 f.store_string(JSON.stringify(data,"\t")+"\n");f.close()
func fresh(c:Dictionary):
 var r=Rules.new();check(r.load_level(c),"current level loads");return r
func geometry(r)->Dictionary:
 var result={}
 var ids:Array=r.reachable_cell_ids("",true)
 for id in [44,45,54,56,57,63,67]:
  result[str(id)]={"reachable":ids.has(id),"distance_cells":r._routes[id].distance if ids.has(id) else -1}
 return result
func opening(c:Dictionary,color:String,cell:int,new_ids:Array)->Dictionary:
 var r=fresh(c);var before=geometry(r);var reachable:Array=r.reachable_cell_ids("",true)
 var target:Dictionary=r.best_target(color)
 check(target.cell_id==cell and target.distance==3,"real nearest first gate for "+color)
 var click:Dictionary=r.click_color(color);var task:Dictionary=r.tasks[click.task_id].duplicate(true)
 check(r.tasks.size()==1 and r.board.size()==22 and geometry(r)==before,"reservation neither picks up nor opens a gate")
 r.update_us(int(task.pickup_us)-1)
 check(geometry(r)==before and r.board.size()==22,"gate stays closed one microsecond before pickup")
 r.update_us(1);var after=geometry(r);var newly:Array=[]
 for id in r.reachable_cell_ids("",true):
  if not reachable.has(id):newly.append(id)
 check(newly==new_ids,"exact newly reachable beads on "+color+" pickup")
 check(r.board.size()==21 and r.delivered_counts[color]==0 and r.hit_counts[color]==0,"pickup removes one bead but supplies no ammunition or damage")
 r.update_us(int(task.delivery_us)-1-r.time_us)
 check(r.delivered_counts[color]==0 and r.tasks.size()==1,"return and unloading retain capacity until completed")
 r.update_us(1)
 check(r.delivered_counts[color]==1 and r.tasks.is_empty(),"exactly one delivery supplies one bead")
 r.update_us(450000);var events:Array=r.drain_events();var hits:Array=events.filter(func(e):return e.type=="segment_hit")
 check(hits.size()==1 and hits[0].amount==1,"one first delivery produces one actual damage")
 if color=="blue":check(hits[0].kind=="armored" and hits[0].hp==1,"side-route opening also cracks the blue HP2")
 check(r.conservation_errors().is_empty(),"opening conserves resources")
 return {"color":color,"target_cell_id":cell,"task":task,"before":before,"after_actual_pickup":after,"newly_reachable_cell_ids":newly,"raw_events":events}
func replay(c:Dictionary,inputs:Array,label:String)->Dictionary:
 var candidate=c.duplicate(true);candidate.solution.inputs=inputs.duplicate(true)
 var out:Dictionary=Validator.inspect(candidate,true)
 check(out.ok,label+" passes the unchanged production inspector")
 if not out.ok:return out
 check(out.status=="victory" and out.terminal_time_us==26600000 and out.contact_time_us==62000000,"final-hit victory at 26.60s before 62s finite threat")
 check(out.accepted_inputs==16 and out.remaining_beads==6 and out.hit_counts==DAMAGE,"16 real inputs, 16 damage, six untouched beads")
 check(out.supply_by_color==SUPPLY and out.required_damage_by_color==DAMAGE,"exact four-color supply and HP budget")
 check(out.maximum_carriers==4 and out.longest_no_dispatch_opportunity_us<=800000,"four carriers, no all-color inactivity longer than 0.8s")
 var short:=0;var six:=0
 for distance in out.path_cells:
  if distance>=3 and distance<=5:short+=1
  if distance==6:six+=1
 check(short==15 and six==1,"fifteen 3–5-cell trips and one six-cell trip")
 var previous:=-1400000
 for input in inputs:
  var t=Rules.seconds_to_us(input.at_sec);check(t-previous==1400000,"one explicit click every 1.4 seconds");previous=t
 var picked:Array=[];var delivered:Array=[];var removed:Array=[];var paths:Array=[];var armor_hits:=0;var live_projectiles:=0;var first_delivery:=-1;var final_fire:=-1;var final_hit:=-1;var blue_hits:Array=[]
 for e in out.events:
  if e.type=="ant_dispatched":
   check(e.carrier_type=="worker" and e.speed_multiplier==1.0,"base Worker Lv.1 transport");paths.append(e)
  elif e.type=="bead_picked_up":check(not picked.has(e.cell_id),"one pickup per actual bead");picked.append(e.cell_id)
  elif e.type=="bead_delivered":
   check(not delivered.has(e.id),"one supply per task");delivered.append(e.id)
   if first_delivery<0:first_delivery=e.time_us
  elif e.type=="cannon_fired":live_projectiles+=1;final_fire=e.time_us;check(live_projectiles==1,"at most one ordinary projectile in flight")
  elif e.type=="segment_hit":
   live_projectiles-=1;final_hit=e.time_us;check(e.source=="projectile" and e.amount==1,"only actual one-damage projectile hits")
   if e.kind=="armored":armor_hits+=1
   if e.color=="blue":blue_hits.append(e)
  elif e.type=="segment_removed":check(not removed.has(e.segment_id),"stable segment ID removed only once");removed.append(e.segment_id)
 check(paths.size()==16 and picked.size()==16 and delivered.size()==16 and removed.size()==14 and armor_hits==4,"one-click/one-ant/one-bead and HP1/HP2 accounting")
 check(picked.has(44) and picked.has(63) and blue_hits.size()==4,"both originally enclosed mandatory blue beads collected")
 check(first_delivery==3200000 and final_hit==out.terminal_time_us and final_hit-final_fire==450000,"delivery and final actual damage own their deadlines")
 out.merge({"label":label,"inputs":inputs,"transport_paths":paths,"pickup_cell_ids":picked,"blue_hits":blue_hits,"first_delivery_us":first_delivery,"final_fire_us":final_fire,"final_hit_us":final_hit,"leftover_by_color":{"red":0,"blue":0,"green":4,"yellow":2},"path_histogram":{"three_to_five":short,"six":six}},true)
 return out
func right_branch_shortcut(c:Dictionary)->Dictionary:
 var r=fresh(c);var task:Dictionary={}
 for i in range(9):
  var input:Dictionary=c.solution.inputs[i]
  r.update_us(Rules.seconds_to_us(input.at_sec)-r.time_us)
  var accepted:Dictionary=r.click_color(input.color);check(accepted.ok,"real authored prefix opens right branch")
  task=r.tasks[accepted.task_id].duplicate(true)
 check(task.cell_id==56,"prefix selects actual nearest right yellow, not a hand-picked cell")
 var reserved_geometry=geometry(r)
 check(reserved_geometry["57"].distance_cells==11,"reservation retains the long exterior route")
 r.update_us(int(task.pickup_us)-1-r.time_us);var before=geometry(r)
 check(before["57"].distance_cells==11,"right blue route remains eleven cells before actual pickup")
 r.update_us(1);var after=geometry(r)
 check(after["57"].distance_cells==5,"actual right-yellow pickup shortens blue route by six cells")
 return {"prefix_input_count":9,"opening_task":task,"one_microsecond_before_pickup":before,"after_actual_pickup":after,"raw_events":r.drain_events()}
func run():
 var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(LEVEL));var alt:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ALT))
 check(Rules.API_VERSION=="3.1.0" and FileAccess.get_sha256("res://scripts/rescue_rules.gd")==RULES_HASH,"production rules byte identity")
 check(c.region_id=="forest" and c.scene_layout=="res://data/scenes/forest-traveler.json" and c.defense_target=={"id":"traveler","display_name":"Traveler","fixed":true},"unchanged woodland and fixed traveler")
 check(c.palette.size()==4 and c.tools.is_empty() and c.serpent.get("art_profile","default")=="default","four colors, no tools or new appearance/mechanic")
 check(c.transport.carrier_type=="worker" and c.transport.outbound_speed_cells_sec==2.5 and c.transport.returning_speed_cells_sec==2.0 and c.transport.pickup_pause_sec==0.3 and c.transport.unload_pause_sec==0.2 and int(c.transport.entrance_cell[0])==5 and int(c.transport.entrance_cell[1])==8,"unchanged Worker Lv.1 transport")
 var r=fresh(c);check(r.board.size()==22 and r.initial_counts==SUPPLY,"22 actual beads")
 check(r.reachable_cell_ids("blue")==[57,73] and r.reachable_cell_ids("yellow")==[52,62],"initial exterior supply of blue and yellow is insufficient for four hits each")
 var connected:Array=[r.board.keys()[0]];var cursor:=0
 while cursor<connected.size():
  var id:int=connected[cursor];cursor+=1
  for delta in [-10,-1,1,10]:
   var other=id+delta
   if r.board.has(other) and not connected.has(other) and absi(int(r.board[id].x)-int(r.board[other].x))+absi(int(r.board[id].y)-int(r.board[other].y))==1:connected.append(other)
 check(connected.size()==22,"one connected branching bead formation, not twin islands")
 var initial_targets={}
 for color in c.palette.values():initial_targets[color]=r.best_target(color)
 var gates=[opening(c,"red",55,[45,54,56]),opening(c,"blue",73,[63]),opening(c,"green",64,[54,63])]
 var shortcut=right_branch_shortcut(c)
 var main=replay(c,c.solution.inputs,"red_three_branch_first");var alternative=replay(c,alt.inputs,"blue_side_supply_first")
 check(main.transport_paths[1].cell_id==45 and alternative.transport_paths[1].cell_id==63,"different second real targets: upper yellow core versus lower blue core")
 check(main.blue_hits[0].time_us==7850000 and alternative.blue_hits[0].time_us==3650000,"side opening cracks blue armor 4.20s earlier")
 var cap=fresh(c)
 for color in ["red","blue","green","yellow"]:check(cap.click_color(color).ok,"capacity probe accepts four ordinary clicks")
 var fifth:Dictionary=cap.click_color("blue")
 check(not fifth.ok and fifth.reason=="carrier_limit" and not fifth.queued and cap.tasks.size()==4,"fifth click rejected, not hidden-queued")
 cap.update_us(6000000)
 check(cap.dispatched_counts.values().reduce(func(a,b):return a+b,0)==4 and cap.tasks.is_empty(),"rejected fifth click never dispatches later")
 var last=fresh(c)
 for input in c.solution.inputs:
  last.update_us(Rules.seconds_to_us(input.at_sec)-last.time_us);check(last.click_color(input.color).ok,"last-hit probe accepts actual inputs")
 last.update_us(26599999-last.time_us);check(last.status=="running" and not last.projectile.is_empty(),"launch and one microsecond before final hit are not victory")
 last.update_us(1);check(last.status=="victory" and last.terminal_reason=="final_segment_hit" and last.conservation_errors().is_empty(),"final actual damage wins with conserved resources")
 check(last.tasks.is_empty() and last.inventory.values().all(func(x):return x==0) and last.available_counts()==main.leftover_by_color,"real leftover board and empty inventory, no phantom supply")
 var shortfall=c.duplicate(true);shortfall.grid[4]="..GR.YG..."
 check(Rules.validate_level(shortfall).has("insufficient segment supply: blue"),"other-color surplus cannot replace mandatory blue core")
 var idle=fresh(c);idle.click_color("red");idle.update_us(62000000)
 check(idle.status=="defeat" and idle.terminal_reason=="dragon_contact" and idle.time_us==62000000,"unfinished serpent contacts finite goal")
 var hash=FileAccess.get_sha256(LEVEL);alt["level_sha256"]=hash;write(ALT,alt)
 var report={"ok":failures.is_empty(),"checks":checks,"failures":failures,"engine":Engine.get_version_info().string,"level_sha256":hash,"rules_api":Rules.API_VERSION,"rules_sha256":FileAccess.get_sha256("res://scripts/rescue_rules.gd"),"validator_sha256":FileAccess.get_sha256("res://tools/validate_serpent_level.gd"),"scene_sha256":FileAccess.get_sha256(c.scene_layout),"supply_by_color":SUPPLY,"required_damage_by_color":DAMAGE,"total_beads":22,"normal_segments":12,"armored_segments":2,"occupied_components":1,"initial_best_targets":initial_targets,"openings":gates,"solutions":[main,alternative],"scope":"Level 11 only; two authored 1.4-second Worker Lv.1 solutions through unchanged production inspector, raw opening events, supply/capacity/final-hit/finite-goal checks. No old-level rerun, solver, new mechanics, GL, human difficulty/economy, visual, native input, audio or device acceptance."}
 report["right_branch_shortcut"]=shortcut
 write("res://reports/rules/forest-crossing-level11.json",report)
 print("FOREST_CROSSING_LEVEL11 ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"level_sha256":hash,"main_final_hit_us":main.terminal_time_us,"alternate_final_hit_us":alternative.terminal_time_us,"main_wait_us":main.longest_no_dispatch_opportunity_us,"alternate_wait_us":alternative.longest_no_dispatch_opportunity_us}))
 quit(0 if report.ok else 1)
