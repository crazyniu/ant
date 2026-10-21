extends SceneTree
## Real GL presentation at 1x. Only prerequisite unlocks are a labelled isolated
## fixture; all level4 transport, shots, shortening and settlement are production.
class ReviewClock extends Node:
	var harness:SceneTree
	var seconds:=0.0
	func _process(delta:float)->void:
		seconds+=delta;harness.observe(seconds)
var out:="/tmp/ant-ruins-journey"
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
	boot.profile_directory="/tmp/ant-rescue-ruins-capture-%d"%Time.get_ticks_usec();boot.use_command_line_catalog=false
	root.add_child(boot);current_scene=boot
	for i in range(6000):
		await process_frame
		if boot.home_ready:break
	for id in ["serpent-01","serpent-02","serpent-03"]:boot.saves.mark_complete(id,"isolated-ruins-prerequisite-fixture")
	boot.saves.set_current_entrance("serpent-04");boot.saves.set_tutorial_completed(true);boot.profile_state=boot.saves.get_view_state()
	boot.open_adventure("preparation",4)
	await create_timer(.6).timeout;await shot("preparation")
	await create_timer(1.4).timeout
	boot.adventure.begin_level.emit(4,"worker")
	boot_events=boot.boot_events.duplicate(true)
	for i in range(6000):
		await process_frame
		if is_instance_valid(current_scene) and current_scene!=boot and current_scene.get("ready_to_simulate")==true:play=current_scene;break
	if play==null:push_error("Ruins loading failed");quit(1);return
	await shot("initial")
	play.auto_replay=true
	clock_node=ReviewClock.new();clock_node.harness=self;root.add_child(clock_node)
func observe(seconds:float)->void:
	if done or play==null:return
	maximum_carriers=maxi(maximum_carriers,play.rules.tasks.size())
	for entry in [["walking",2.8],["opened-core",8.0],["shortened-snake",18.0]]:
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
	var report:Dictionary={"mode":"actual GL production preparation/loading/ruins gameplay; automatic authored clicks, not human playtest","prerequisite_unlocks":"isolated fixture for first3, no points granted","speed":1,"status":play.rules.status,"terminal_time_us":play.rules.terminal_time_us,"remaining_beads":play.rules.board.size(),"maximum_carriers":maximum_carriers,"conservation_errors":play.rules.conservation_errors(),"output_pixels":[root.get_texture().get_width(),root.get_texture().get_height()],"audio":play.audio_service.get_status(),"victory_saved":play.victory_saved,"guardian":play.scene_layout.defense_target.id,"shots":shots,"boot_events":boot_events,"reward":play.reward_receipt,"source_hashes":{}}
	for path in ["scripts/ui_skin.gd","scripts/play.gd","scripts/scene_layout.gd","scripts/board_plane.gd","scripts/carrier_route.gd","scripts/rescue_rules.gd","scripts/adventure_view.gd","scripts/startup.gd","data/scenes/ruins-cart.json","data/serpent-levels/serpent-04.json","assets/worlds/ruins-courtyard.png","assets/worlds/supply-cart.png"]:report.source_hashes[path]=FileAccess.get_sha256("res://"+path)
	var file:=FileAccess.open(out+"/ruins-journey.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("RUINS_JOURNEY ",JSON.stringify({"status":report.status,"terminal_time_us":report.terminal_time_us,"guardian":report.guardian,"remaining_beads":report.remaining_beads,"maximum_carriers":maximum_carriers,"victory_saved":report.victory_saved}))
	play.set_process(false);play.queue_free();clock_node.queue_free();await process_frame;await process_frame
	quit(0 if report.status=="victory" and report.victory_saved and report.conservation_errors.is_empty() else 1)
