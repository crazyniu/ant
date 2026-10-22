extends SceneTree
const Catalog=preload("res://scripts/level_catalog.gd")
const Saves=preload("res://scripts/save_service.gd")
const Progression=preload("res://scripts/ant_progression.gd")
const Motion=preload("res://scripts/first_level_carrier.gd")
var checks:=0
var failures:Array[String]=[]
var profile:="/tmp/ant-rescue-first-batch-%d"%Time.get_ticks_usec()
func _initialize()->void:call_deferred("run")
func check(value:bool,note:String)->void:
	checks+=1
	if not value:failures.append(note);push_error(note)
func bytes(path:String)->PackedByteArray:return FileAccess.get_file_as_bytes(path)
func dispose(node:Node)->void:
	if is_instance_valid(node):
		if is_instance_valid(node.get("audio_service")):node.audio_service.stop_music();node.audio_service.stop_all_sfx()
		await create_timer(.3).timeout # Allow asynchronous audio playback references to release.
		node.queue_free()
	await process_frame;await process_frame
func run()->void:
	check(Catalog.level_ids(false).size()==13,"Keep complete catalog for historical save compatibility")
	for number in [0,2,13,99]:check(not Catalog.runtime_level_allowed(number),"Reject non-first number %d"%number)
	check(not Catalog.runtime_level_allowed(1,true),"Campaign draft one is not approved serpent-01")
	var store:=Saves.new(profile,Catalog.level_ids(false),30);check(store.load_save().ok,"Temporary historical fixture initializes")
	# Historical metadata only: no later level config, scene or Rules is loaded.
	var record:Dictionary=store._record.duplicate(true);record.highest_unlocked=13;record.current_entrance={"level_id":"serpent-13","level_number":13};record.tutorial_completed=true;record.music_volume=0;record.sfx_volume=23
	for number in range(1,13):record.completed_levels[Catalog.level_ids(false)[number-1]]={"level_number":number,"content_versions":["historical-metadata-fixture"]}
	check(store._save_candidate(record).ok,"Seed historical progress without playing other levels")
	# Give the backup the same valid historical entrance for recovery coverage.
	check(DirAccess.copy_absolute(profile.path_join("save.json"),profile.path_join("save.backup.json"))==OK,"Seed an exact historical backup fixture")
	var economy:=Progression.new(profile);check(economy.load_save().ok,"Temporary economy initialized")
	check(economy.create_run("first-history","serpent-01",110,130).ok,"Historical first-level reward fixture")
	check(economy.settle_run("first-history","won",110).ok,"Historical points seeded through normal ledger")
	var save_before:=bytes(profile.path_join("save.json"));var money_before:=bytes(economy.base_path.path_join("progression.json"))
	var home=load("res://scenes/startup.tscn").instantiate();home.profile_directory=profile;home.profile_directory_resolved=true;home.use_command_line_catalog=false;home.level_index=13;home.campaign_drafts=true
	root.add_child(home);current_scene=home
	var deadline:=Time.get_ticks_msec()+8000
	while home.phase!="home" and Time.get_ticks_msec()<deadline:await process_frame
	check(home.phase=="home" and home.level_index==1 and not home.campaign_drafts,"Historical Home projects only approved first level")
	check(home.profile_state.resume_level_id=="serpent-13" and home.profile_state.completed_levels.size()==12,"Gate does not delete historical progress")
	check(bytes(profile.path_join("save.json"))==save_before and bytes(economy.base_path.path_join("progression.json"))==money_before,"Startup gate does not rewrite progress or points")
	home.open_adventure("map")
	check(home.adventure.level_definitions.size()==1 and home.adventure.level_definitions[0].level_id=="serpent-01","Map contains only approved first level despite thirteen historical unlocks")
	for number in [0,2,13,99]:
		check(not home.adventure.show_preparation(number),"View refuses preparation %d"%number)
		home.begin_prepared_level(number,"swift");home.adventure.begin_level.emit(number,"swift");home.adventure.choose_level.emit(number)
	check(not home.launch_pending and home.phase=="map","Rejected direct and emitted requests do not launch or switch page")
	check(bytes(profile.path_join("save.json"))==save_before and bytes(economy.base_path.path_join("progression.json"))==money_before,"Rejected requests do not equip, spend, write entrance or create runs")
	home.adventure.restore_navigation_state({"selected_level":13,"screen":"preparation","region_id":"ruins","scroll_y":999})
	check(home.adventure.selected_level==1 and home.adventure.screen=="map","Saved navigation cannot reopen later preparation")
	await process_frame;await process_frame
	var map_view:Control=home.adventure.get_node("AdventurePage/MapScroll")
	var first_node:Control=map_view.get_node("MapCanvas/LevelNode1")
	check(map_view.get_global_rect().encloses(first_node.get_global_rect()),"Recovered first-level map node is fully inside the scrolled viewport")
	home.finish_profile_recovery();check(home.level_index==1,"Recovery projects historical entrance to first level")
	var bad:=FileAccess.open(profile.path_join("save.json"),FileAccess.WRITE);bad.store_string("broken");bad.close()
	home.retry_profile_load();check(home.modal_title=="COULDN'T LOAD","Corrupt historical save uses real recovery screen")
	home.restore_profile_backups();check(home.phase=="home" and home.level_index==1 and home.profile_state.resume_level_id=="serpent-13","Backup recovery retains history but enters only first level")
	check(home.economy_state.points==150 and home.profile_state.music_volume==0 and home.profile_state.sfx_volume==23,"Recovery gate preserves points and both volume settings")
	home.open_adventure("preparation",1);home.open_shop();home.economy_state.navigation.selected_level=13;home.shop_return_screen="preparation";home.close_shop()
	check(home.phase=="preparation" and home.adventure.selected_level==1,"Shop return cannot restore later level")
	home.level_index=13;home.launch_game();check(not home.launch_pending,"Direct forbidden launch is rejected before loading")
	# Deferred boundary checks use forbidden request IDs only, never later configs.
	home.level_index=13;home.launch_pending=true;home.phase="loading";home.batch="game";home.load_generation+=1
	home.prepare_game_resources(home.load_generation);check(home.phase=="error","Deferred resource preparation rechecks scope before reading a level")
	home.phase="loading";home.handover_game(home.load_generation);check(home.phase=="error" and current_scene==home,"Deferred handover rechecks scope before instantiation")
	await dispose(home)
	var scene=load("res://scenes/play.tscn").instantiate();scene.profile_directory=profile;scene.profile_directory_resolved=true;scene.use_command_line_catalog=false;scene.use_command_line_level=false;scene.level_index=13;scene.campaign_drafts=true
	root.add_child(scene);current_scene=scene;scene.set_process(false)
	check(scene.ready_to_simulate and scene.level_index==1 and scene.level_config.level_id=="serpent-01","Direct play scene uses first level, not saved/requested later level")
	var direct_before:=bytes(profile.path_join("save.json"));var run_count:int=scene.progression._record.runs.size()
	for number in [0,2,13,99]:scene.replace_level(number)
	check(not scene.replacement_pending and bytes(profile.path_join("save.json"))==direct_before and scene.progression._record.runs.size()==run_count,"Direct replace handlers have no forbidden-transition side effects")
	check(scene.select_color("blue"),"First-level carrier starts through actual color handler")
	scene.rules.update_us(1000000);scene.sync_carriers()
	var moving_ant:Control=scene.carriers.values()[0]
	var first_position:Vector2=moving_ant.position;var first_phase:float=moving_ant.get_meta(Motion.CACHE_KEY).last_pose.phase
	scene.rules.update_us(500000);scene.sync_carriers()
	var travelled:float=moving_ant.position.distance_to(first_position)
	var phase_delta:float=moving_ant.get_meta(Motion.CACHE_KEY).last_pose.phase-first_phase
	check(absf(phase_delta-TAU*travelled/Motion.OUTBOUND_STRIDE_PIXELS)<.001,"Production carrier foot phase follows actual straight-approach travel distance")
	# A controlled presentation fixture: red is first in UI palette, but blue is
	# the frontmost legal authoritative target. No fixture reward is settled.
	scene.rules.inventory.red=1;scene.rules.inventory.blue=1;scene.rules.status="running"
	var target:Dictionary=scene.rules.next_fire_target();check(target.color=="blue","Fixture distinguishes palette order from true next-shot order")
	scene.sync_hopper_ammo();var hopper:Control=scene.get_node("TransportScene/Cannon/HopperAmmo")
	check(hopper.visible and hopper.color_id==target.color,"Hopper uses authoritative next-fire color")
	scene.rules._check_fire();check(scene.rules.projectile.color==target.color,"Actual subsequent fire matches hopper color")
	scene.sync_hopper_ammo();check(not hopper.visible,"Fired ball is not duplicated in hopper during flight")
	scene.show_click_feedback("THESE BALLS ARE ALREADY CLAIMED")
	var feedback:Control=scene.get_node("ClickFeedback");var speed:Control=scene.get_node("TopHUD/SpeedButton")
	check(not feedback.get_global_rect().intersects(speed.get_global_rect()),"Feedback bounds cannot cover speed control at actual canvas scale")
	check(feedback.mouse_filter==Control.MOUSE_FILTER_IGNORE and feedback.autowrap_mode==TextServer.AUTOWRAP_WORD_SMART,"Feedback wraps and cannot consume speed input")
	var a:Dictionary=Motion.sample({"time":1.0,"outbound_distance":50.0,"loaded_distance":0.0,"phase_offset":.7,"stage":"outbound","moving":true})
	var b:Dictionary=Motion.sample({"time":100.0,"outbound_distance":50.0,"loaded_distance":0.0,"phase_offset":.7,"stage":"outbound","moving":true})
	check(is_equal_approx(a.phase,b.phase) and a.gait==b.gait,"Same physical travel yields identical foot phase regardless of elapsed time")
	check(Motion.phase_at_distance(60,0,.7)>a.phase,"More physical travel advances gait")
	check(is_equal_approx(Motion.phase_at_distance(50,0,.7),Motion.sample({"time":12.0,"outbound_distance":50.0,"stage":"pickup","phase_offset":.7}).phase),"Pickup hold keeps continuous distance phase")
	check(Motion.phase_at_distance(50,10,.7)>Motion.phase_at_distance(50,0,.7),"Loaded travel continues rather than resetting gait")
	check(Motion.sample({"time":100.0,"outbound_distance":50.0,"moving":false}).gait==Vector4.ZERO,"Stationary carrier has no stepping displacement")
	await create_timer(1.8).timeout # Let the real feedback timer release its callback.
	await dispose(scene)
	var foreign:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-01.json"));foreign.level_id="serpent-13"
	var blocked=load("res://scenes/play.tscn").instantiate();blocked.profile_directory=profile;blocked.profile_directory_resolved=true;blocked.use_command_line_catalog=false;blocked.use_command_line_level=false;blocked.qa_fixture_mode=true;blocked.qa_level_config=foreign
	root.add_child(blocked);current_scene=blocked;blocked.set_process(false)
	check(not blocked.ready_to_simulate and blocked.level_load_reason=="first_level_review_only","QA override cannot impersonate another level")
	await dispose(blocked)
	var report:Dictionary={"checks":checks,"failures":failures,"scope":"First-level-only headless controller/entry, historical metadata recovery, hopper selector, distance gait and non-overlapping feedback. Later level numbers are rejected inputs only; no later config or scene was exercised. No GL/native input/sound/visual acceptance."}
	var report_path:=OS.get_environment("ANT_MINIMAL_REPORT")
	if report_path.is_empty():report_path="res://reports/first-level/batch-1/minimal-fixes.json"
	var f:=FileAccess.open(report_path,FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close();print("FIRST_LEVEL_MINIMAL_BATCH ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
