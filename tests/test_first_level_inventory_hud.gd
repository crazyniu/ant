extends "res://tests/export_first_level_batch2.gd"
## First-ball presentation regression only; not native input or GL acceptance.
const Saves=preload("res://scripts/save_service.gd")
const Catalog=preload("res://scripts/level_catalog.gd")
var checks:=0
var failures:Array[String]=[]
var observed_events:Array=[]
var checkpoints:Array=[]
var evidence_directory:=""
func check(ok:bool,note:String)->void:
	checks+=1
	if not ok:failures.append(note);push_error(note)
func _verify_displays(label:String)->void:
	check(not scene.has_node("TransportScene/Stock"),label+": rejected side inventory HUD is absent")
	check(scene.has_node("TransportScene/Cannon") and scene.has_node("TransportScene/Cannon/HopperAmmo") and scene.has_node("TransportScene/LiveCarriers"),label+": actual cannon, hopper and carriers remain")
	check(scene.color_buttons.size()==5,label+": five actual color entrances remain")
	for color in scene.color_buttons:
		check(scene.get_node("CandidateQueues/Remaining_"+color).text==str(scene.rules.snapshot().available_counts[color]),label+": "+str(color)+" card retains actual board count")
	check(not scene.has_node("WorkSlots/CarrierCount"),label+": rejected numeric transport HUD is absent")
	check(scene.rules.snapshot().carrier_limit==4 and scene.rules.snapshot().carrier_count==scene.rules.tasks.size(),label+": internal capacity remains four with authoritative occupancy")
	check(scene.rules.conservation_errors().is_empty(),label+": authoritative ammunition conservation holds")
	check(scene.stock_arrivals.is_empty(),label+": no removed-label animation is queued")
	for effect in scene.fx.debug_snapshot().effects:
		check(effect.kind!="transfer",label+": no star flies toward removed inventory HUD")
	checkpoints.append({"name":label,"time_us":scene.rules.time_us,"board":scene.rules.board.size(),"carriers":scene.rules.tasks.size(),"inventory_blue":scene.rules.inventory.get("blue",0),"delivered_blue":scene.rules.delivered_counts.get("blue",0),"spent_blue":scene.rules.spent_counts.get("blue",0),"shots_blue":scene.rules.shot_counts.get("blue",0),"hits_blue":scene.rules.hit_counts.get("blue",0)})
func _advance_to(time_us:int,label:String)->void:
	var delta_us:int=time_us-scene.rules.time_us
	scene.rules.update_us(delta_us)
	for event in scene.rules._events:observed_events.append(event.duplicate(true))
	scene.sync_view();scene.consume_rule_events()
	scene.fx.advance(float(delta_us)/1000000.0);scene.serpent.advance(float(delta_us)/1000000.0);scene.apply_actor_poses()
	_verify_displays(label)
func run()->void:
	evidence_directory=OS.get_environment("ANT_HUD_EVIDENCE_DIR")
	if evidence_directory.is_empty():evidence_directory="user://first-level-hud-evidence"
	check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence_directory))==OK,"Local evidence directory is writable")
	var profile:=ProjectSettings.globalize_path("user://ant-inventory-hud-%d"%Time.get_ticks_usec())
	var saves:=Saves.new(profile,Catalog.level_ids(false),30)
	check(saves.load_save().ok and saves.set_tutorial_completed().ok,"Isolated first-level profile is ready")
	scene=load("res://scenes/play.tscn").instantiate()
	scene.profile_directory=profile;scene.profile_directory_resolved=true
	scene.use_command_line_catalog=false;scene.use_command_line_level=false
	root.add_child(scene);current_scene=scene;scene.set_process(false)
	await process_frame
	check(scene.ready_to_simulate and scene.level_index==1,"Only approved first level starts")
	if not scene.ready_to_simulate:quit(1);return
	_verify_displays("initial")
	for index in 4:check(scene.has_node("WorkSlots/TransportPedestal%d"%index),"Transport pedestal %d remains"%index)
	for name in ["SpeedButton","PauseButton","SettingsButton"]:check(scene.has_node("TopHUD/"+name),name+" remains")
	check(not scene.get_node("TransportScene/Cannon/HopperAmmo").visible,"No fictional loaded ball at zero initial inventory")
	records=[];walk(scene)
	var nodes:=FileAccess.open(evidence_directory.path_join("nodes-initial.json"),FileAccess.WRITE)
	nodes.store_string(JSON.stringify({"label":"OFFLINE NODE DATA · NOT GODOT RENDER","canvas":[940,1672],"nodes":records},"\t"));nodes.close()
	scene.color_buttons.blue.pressed.emit();scene.sync_view()
	check(scene.rules.tasks.size()==1,"One actual connected color press still dispatches one ant")
	_advance_to(3700000,"pickup")
	check(scene.rules.board.size()==239 and int(scene.get_node("CandidateQueues/Remaining_blue").text)==79,"Actual blue pickup removes exactly one board ball")
	_advance_to(8625000,"unloading")
	check(scene.rules.tasks.size()==1 and scene.rules.inventory.blue==0,"Unloading retains capacity and does not credit early ammo")
	_advance_to(9425000,"delivery-and-fire")
	check(scene.rules.tasks.is_empty() and scene.rules.inventory.blue==0,"Delivery releases capacity; actual fire consumes credited ammo once")
	check(scene.rules.delivered_counts.blue==1 and scene.rules.spent_counts.blue==1 and scene.rules.shot_counts.blue==1,"One delivery, one debit, one shot remain authoritative")
	check(not scene.rules.projectile.is_empty() and scene.rules.projectile.color=="blue","The same actual blue shot remains in flight")
	check(not scene.get_node("TransportScene/Cannon/HopperAmmo").visible,"Already-fired ammo is not duplicated in the hopper")
	check(scene.fx.debug_snapshot().projectiles.size()==1,"Actual fired-ball presentation remains")
	for effect in scene.fx.debug_snapshot().effects:
		if effect.kind=="ring":
			for old_anchor in scene.fx._layout.stock_points.values():check(effect.pos.distance_to(old_anchor)>.01,"Delivery creates no ring at a removed stock position; real muzzle feedback remains")
	var frozen:int=scene.rules.time_us
	scene.rules.set_paused(true);scene.sync_view();scene.consume_rule_events();scene.rules.update_us(1000000)
	check(scene.rules.time_us==frozen and scene.rules.projectile.color=="blue","Pause freezes the authoritative shot without changing ammo")
	scene.rules.set_paused(false);scene.sync_view();scene.consume_rule_events()
	_advance_to(9875000,"hit")
	check(scene.rules.projectile.is_empty() and scene.rules.hit_counts.blue==1,"Existing blue shot resolves exactly one hit at unchanged deadline")
	check(scene.fx.debug_snapshot().projectiles.is_empty(),"Hit removes actual projectile presentation")
	var event_times:Dictionary={}
	for event in observed_events:
		if event.type in ["bead_picked_up","bead_unloading","bead_delivered","cannon_fired","segment_hit"]:event_times[event.type]=event.time_us
	check(event_times=={"bead_picked_up":3700000,"bead_unloading":8625000,"bead_delivered":9425000,"cannon_fired":9425000,"segment_hit":9875000},"Removing HUD does not change the first legal supply/fire/hit timeline")
	var report:Dictionary={"checks":checks,"failures":failures,"checkpoints":checkpoints,"event_times_us":event_times,"scope":"First-level rejected side inventory HUD removal and actual first-blue-ball pickup, unload, ammo debit, flight, pause and hit. No new loading animation, native pointer/GL test, full replay, later level or user acceptance."}
	var f:=FileAccess.open(evidence_directory.path_join("inventory-hud-test.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"));f.close()
	scene.audio_service.stop_music();scene.audio_service.stop_all_sfx()
	await create_timer(1.8).timeout
	scene.queue_free();await process_frame;await create_timer(.15).timeout
	print("FIRST_LEVEL_INVENTORY_HUD ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
