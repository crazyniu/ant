extends SceneTree
## Real GL presentation at 1x. Only prerequisite unlocks are a labelled isolated
## fixture; all level10 transport, shots, shortening and settlement are production.
class ReviewClock extends Node:
	var harness:SceneTree
	var seconds:=0.0
	func _process(delta:float)->void:
		seconds+=delta;harness.observe(seconds)
var out:="/tmp/ant-snowpass-journey"
var play:Node
var clock_node:ReviewClock
var shots:Dictionary={}
var terminal_at:=-1.0
var done:=false
var maximum_carriers:=0
var boot_events:Array=[]
func _initialize()->void:call_deferred("run")
func run()->void:
	if not OS.get_environment("ANT_RESCUE_EVIDENCE_DIR").is_empty():out=OS.get_environment("ANT_RESCUE_EVIDENCE_DIR")
	DirAccess.make_dir_recursive_absolute(out)
	var boot=load("res://scenes/startup.tscn").instantiate()
	boot.profile_directory="/tmp/ant-rescue-snowpass-capture-%d"%Time.get_ticks_usec();boot.use_command_line_catalog=false
	root.add_child(boot);current_scene=boot
	for i in range(600):
		await process_frame
		if boot.home_ready:break
	if not boot.home_ready:push_error("Snow courtyard fixture home did not load");quit(1);return
	for id in ["serpent-01","serpent-02","serpent-03","serpent-04","serpent-05","serpent-06","serpent-07","serpent-08","serpent-09"]:
		var prerequisite:Dictionary=boot.saves.mark_complete(id,"isolated-snowpass-prerequisite-fixture")
		if not prerequisite.ok:push_error("Snow courtyard prerequisite failed: "+id+" "+str(prerequisite));quit(1);return
	var entrance:Dictionary=boot.saves.set_current_entrance("serpent-10")
	if not entrance.ok:push_error("Snow courtyard entrance failed: "+str(entrance));quit(1);return
	boot.saves.set_tutorial_completed(true);boot.profile_state=boot.saves.get_view_state()
	boot.open_adventure("preparation",10)
	await create_timer(.6).timeout
	if boot.adventure.screen!="preparation":push_error("Snow courtyard preparation did not open");quit(1);return
	await shot("preparation")
	await create_timer(1.4).timeout
	boot.adventure.begin_level.emit(10,"worker")
	boot_events=boot.boot_events.duplicate(true)
	for i in range(600):
		await process_frame
		if is_instance_valid(current_scene) and current_scene!=boot and current_scene.get("ready_to_simulate")==true:play=current_scene;break
	if play==null:push_error("Snow courtyard loading failed");quit(1);return
	await shot("initial")
	play.auto_replay=true
	clock_node=ReviewClock.new();clock_node.harness=self;root.add_child(clock_node)
func observe(seconds:float)->void:
	if done or play==null:return
	maximum_carriers=maxi(maximum_carriers,play.rules.tasks.size())
	for entry in [["walking",2.8],["opened-core",6.0],["shortened-snake",19.0]]:
		if seconds>=entry[1] and not shots.has(entry[0]):capture(entry[0])
	if not play.rules.projectile.is_empty() and not shots.has("projectile"):
		if play.rules.time_us-int(play.rules.projectile.fire_us)>180000:capture("projectile")
	if play.rules.status in ["victory","defeat"]:
		if terminal_at<0:terminal_at=seconds;capture("last-hit")
		if seconds-terminal_at>=1.9 and not shots.has("result"):capture("result")
		if seconds-terminal_at>=2.6:finish()
	elif seconds>70:finish()
func capture(id:String)->void:
	shots[id]={"simulation_us":play.rules.time_us,"alive_segments":play.rules.alive_segment_ids.size(),"carriers":play.rules.tasks.size()}
	call_deferred("shot",id)
func shot(id:String)->void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+"/"+id+"-2k.png")
func finish()->void:
	done=true
	var report:Dictionary={"mode":"actual GL production preparation/loading/snowpass gameplay; automatic authored clicks, not human playtest","prerequisite_unlocks":"isolated fixture for first9, no points granted","speed":1,"status":play.rules.status,"terminal_time_us":play.rules.terminal_time_us,"remaining_beads":play.rules.board.size(),"maximum_carriers":maximum_carriers,"conservation_errors":play.rules.conservation_errors(),"output_pixels":[root.get_texture().get_width(),root.get_texture().get_height()],"audio":play.audio_service.get_status(),"victory_saved":play.victory_saved,"guardian":play.scene_layout.defense_target.id,"shots":shots,"boot_events":boot_events,"reward":play.reward_receipt,"source_hashes":{}}
	for path in ["scripts/ui_skin.gd", "scripts/ui_icon.gd", "scripts/level_catalog.gd", "scripts/play.gd", "scripts/scene_layout.gd", "scripts/board_plane.gd", "scripts/carrier_route.gd", "scripts/rescue_rules.gd", "scripts/adventure_view.gd", "scripts/startup.gd", "scripts/serpent_view.gd", "scripts/combat_tint.gdshader", "scripts/contact_shadow.gd", "data/scenes/ice-snowpass.json", "data/serpent-levels/serpent-10.json", "assets/worlds/ice-valley.png", "assets/worlds/winter-camp.png", "assets/serpent/ice-serpent-atlas.png", "assets/serpent/ice-serpent-atlas.json", "assets/serpent/serpent-armor-atlas.png", "scripts/bead.gd", "scripts/directional_carrier.gd", "assets/motion/ant-directions.png", "assets/ui/fusion/beads.png", "assets/ui/fusion/bead-regions.json", "scripts/rescue_fx.gd"]:report.source_hashes[path]=FileAccess.get_sha256("res://"+path)
	var file:=FileAccess.open(out+"/snowpass-journey.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("SNOWPASS_JOURNEY ",JSON.stringify({"status":report.status,"terminal_time_us":report.terminal_time_us,"guardian":report.guardian,"remaining_beads":report.remaining_beads,"maximum_carriers":maximum_carriers,"victory_saved":report.victory_saved}))
	play.set_process(false);play.queue_free();clock_node.queue_free();await process_frame;await process_frame
	quit(0 if report.status=="victory" and report.victory_saved and report.conservation_errors.is_empty() else 1)
