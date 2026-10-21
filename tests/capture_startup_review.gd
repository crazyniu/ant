extends SceneTree
var evidence := ""
var captures:Dictionary={}
var flow:Array[Dictionary]=[]
var current_boot:Node
var startup_events:Array=[]
var audio_states:Dictionary={}
var final_hit_us:=0
var natural_result_geometry:Dictionary={}
var source_hashes:Dictionary={}

func _initialize()->void:
	for path in ["project.godot","scripts/startup.gd","scripts/startup_loader.gd","scripts/main.gd","scripts/play.gd","scripts/audio_service.gd","scripts/ui_icon.gd","scripts/ui_skin.gd","scripts/ui_motion.gd","scripts/rescue_rules.gd","scripts/rescue_fx.gd","data/levels/validation-01.json"]:source_hashes[path]=FileAccess.get_sha256("res://"+path)
	evidence=OS.get_environment("ANT_RESCUE_EVIDENCE_DIR")
	if evidence.is_empty():evidence="/tmp/ant-rescue-startup-capture"
	DirAccess.make_dir_recursive_absolute(evidence)
	RenderingServer.frame_post_draw.connect(observe_loading)
	call_deferred("run")

func observe_loading()->void:
	if not is_instance_valid(current_boot):return
	if current_boot.phase=="loading" and not captures.has("cold-loading"):
		captures["cold-loading"]=root.get_texture().get_image()
		flow.append({"screen":"cold-loading","loader_state":current_boot.loader.state,"actual_progress":current_boot.loader.progress,"ticks_us":Time.get_ticks_usec()})

func wait_scene(kind:String)->Node:
	var start:=Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<15000:
		var node:=current_scene
		if is_instance_valid(node):
			if kind=="home" and node.get("phase")=="home":return node
			if kind=="game" and node.get("ready_to_simulate")==true:return node
		await process_frame
	push_error("Startup capture timeout: "+kind);quit(1);return null

func photo(id:String)->void:
	if is_instance_valid(current_scene) and is_instance_valid(current_scene.get("audio_service")):audio_states[id]=current_scene.audio_service.get_status()
	await process_frame;await RenderingServer.frame_post_draw
	captures[id]=root.get_texture().get_image()
	flow.append({"screen":id,"ticks_us":Time.get_ticks_usec(),"movie_frame":Engine.get_process_frames()})

func tap(button:Control)->void:
	var point:=button.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new();motion.position=point;root.push_input(motion,true)
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;root.push_input(event,true)
	await process_frame

func run()->void:
	current_boot=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(current_boot);current_scene=current_boot
	var home:=await wait_scene("home")
	startup_events.append_array(home.boot_events)
	await photo("home")
	await tap(home.home_art.get_node("LevelsButton"))
	var game:=await wait_scene("game")
	await create_timer(.3).timeout;await photo("home-level-select")
	await tap(game.pause_overlay.get_node("CloseButton"))
	home=await wait_scene("home")
	await tap(home.home_art.get_node("PlayButton"))
	game=await wait_scene("game")
	await create_timer(.3).timeout;await photo("first-tutorial")
	await tap(game.pause_overlay.get_node("Button_LET'S GO"))
	await create_timer(.2).timeout;await photo("first-round")
	game.show_pause();await create_timer(.3).timeout;await photo("pause-home-entry")
	await tap(game.pause_overlay.get_node("HomeButton"))
	home=await wait_scene("home");await photo("home-return")
	# One actual first-level replay, at normal simulation speed. No forced result.
	await create_timer(2.5).timeout
	await tap(home.home_art.get_node("PlayButton"))
	game=await wait_scene("game")
	game.show_pause();await create_timer(.4).timeout
	await tap(game.pause_overlay.get_node("Button_SETTINGS"));await create_timer(1.2).timeout;await photo("settings-bgm")
	await tap(game.pause_overlay.get_node("CloseButton"));await create_timer(.35).timeout
	await tap(game.pause_overlay.get_node("Button_CONTINUE"))
	game.auto_replay=true
	var deadline:=Time.get_ticks_msec()+240000
	while game.rules.status not in ["victory","defeat"] and Time.get_ticks_msec()<deadline:await process_frame
	if game.rules.status!="victory":push_error("Natural result was not victory");quit(1);return
	final_hit_us=game.rules.time_us
	audio_states["final-hit"]=game.audio_service.get_status()
	while game.pending_victory_presentation_run>=0:await process_frame
	await create_timer(.4).timeout
	await photo("natural-victory")
	natural_result_geometry={"panel":rect_data(game.pause_overlay.get_node("ModalPanel")),"next":rect_data(game.pause_overlay.get_node("Button_NEXT LEVEL")),"again":rect_data(game.pause_overlay.get_node("Button_PLAY AGAIN")),"levels":rect_data(game.pause_overlay.get_node("Button_LEVEL SELECT")),"saved":game.victory_saved,"conservation":game.rules.conservation_errors()}
	await create_timer(1.6).timeout
	game.auto_replay=false
	await tap(game.pause_overlay.get_node("Button_NEXT LEVEL"))
	game=await wait_scene("game")
	await create_timer(.8).timeout;await photo("next-level")
	for id in captures:captures[id].save_png(evidence+"/"+id+"-2k.png")
	var report:Dictionary={"source_hashes":source_hashes,"main_scene":ProjectSettings.get_setting("application/run/main_scene"),"viewport":[root.get_texture().get_width(),root.get_texture().get_height()],"window":[root.size.x,root.size.y],"new_process":true,"empty_isolated_profile":OS.get_environment("ANT_RESCUE_PROFILE_DIR"),"capture_instrumented_not_load_benchmark":true,"forced_loading_wait":false,"input":"Viewport mouse events on actual controls","events":flow,"initial_startup_events":startup_events,"captures":captures.keys(),"audio_states":audio_states,"final_hit_us":final_hit_us,"natural_result_geometry":natural_result_geometry,"speed":1,"automatic_replay":true,"human_listening":false}
	var out:=FileAccess.open(evidence+"/cold-start-flow.json",FileAccess.WRITE);out.store_string(JSON.stringify(report,"\t"));out.close()
	print("COLD_START_FLOW_OK ",JSON.stringify(report))
	game.queue_free();current_boot=null;captures.clear();await process_frame;await process_frame;quit()

func rect_data(node:Control)->Dictionary:
	return {"position":[node.position.x,node.position.y],"size":[node.size.x,node.size.y],"scale":[node.scale.x,node.scale.y],"alpha":node.modulate.a}

