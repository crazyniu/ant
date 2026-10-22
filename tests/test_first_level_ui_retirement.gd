extends SceneTree
## Finite engine-touch input regression. Not GL, physical touch, or a played win.
var checks:=0
var failures:Array[String]=[]
var profile:="/tmp/ant-ui-retirement-%d"%Time.get_ticks_usec()
var observer:Probe
var purchase_count:=0
var baseline:=false
class Probe:
	extends Node
	var mouse:=0
	var touch:=0
	var non_emulated_mouse:=0
	func _input(event:InputEvent)->void:
		if event is InputEventMouseButton:
			mouse+=1
			if event.device!=-1:non_emulated_mouse+=1
		elif event is InputEventScreenTouch:touch+=1
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func settle()->void:
	Input.flush_buffered_events()
	for frame in 4:await process_frame
func touch_at(point:Vector2,down:bool)->void:
	var event:=InputEventScreenTouch.new()
	event.device=-7304;event.index=0;event.pressed=down;event.window_id=root.get_window_id()
	event.position=root.get_final_transform()*point
	Input.parse_input_event(event);Input.flush_buffered_events()
func click(button:Button,label:String,retired:Control=null,wait_before:float=.3)->void:
	if not is_instance_valid(button):
		check(false,"Missing test target: "+label);quit(1);return
	if wait_before>0.0:await create_timer(wait_before).timeout
	print("BEGIN_INPUT ",label)
	var mouse_before:int=observer.mouse;var touch_before:int=observer.touch
	var point:Vector2=button.get_global_transform_with_canvas()*(button.size*.5)
	touch_at(point,true);await create_timer(.02).timeout;touch_at(point,false)
	check(observer.mouse-mouse_before==2 and observer.touch-touch_before==2,label+": one engine-generated mouse pair and one touch pair")
	if retired!=null and not baseline:
		check(is_instance_valid(retired) and retired.is_inside_tree(),label+": retiring tree stays valid through paired release")
		if is_instance_valid(retired):
			check(not retired.visible and retired.process_mode==Node.PROCESS_MODE_DISABLED and retired.is_queued_for_deletion(),label+": old tree is hidden, inactive, queued")
			check(retired.name.begins_with("RetiredUI") and button.disabled and button.pressed.get_connections().is_empty(),label+": old name/input/callbacks cannot compete")
	await settle()
	if retired!=null:check(not is_instance_valid(retired),label+": old tree freed after event boundary")
	print("END_INPUT ",label)
func dispose(node:Node)->void:
	if not is_instance_valid(node):return
	node.audio_service.stop_music();node.audio_service.stop_all_sfx();node.queue_free();await settle()
func run()->void:
	if DisplayServer.get_name()!="headless":quit(2);return
	baseline="--baseline-detach" in OS.get_cmdline_user_args()
	root.size=Vector2i(1180,812);root.content_scale_size=Vector2i(1440,2560)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	check(Input.is_emulating_mouse_from_touch() and not Input.is_emulating_touch_from_mouse(),"Production engine emulation defaults unchanged")
	observer=Probe.new();root.add_child(observer)
	var home=load("res://scenes/startup.tscn").instantiate()
	home.profile_directory=profile;home.profile_directory_resolved=true;home.use_command_line_catalog=false
	root.add_child(home);current_scene=home
	var deadline:=Time.get_ticks_msec()+12000
	while home.phase!="home" and Time.get_ticks_msec()<deadline:await process_frame
	check(home.phase=="home","Production startup reaches Home with isolated profile")
	if home.phase!="home":quit(1);return
	await click(home.home_art.get_node("LevelsButton"),"Home to Map")
	check(home.phase=="map","Real Home button opens first-level Map")
	await click(home.adventure.get_node("AdventurePage/MapScroll/MapCanvas/SceneSign1/ChooseLevelPreview1"),"Map preview to Prep",home.adventure._page)
	check(home.phase=="preparation" and home.adventure.selected_level==1,"Preview selects only first level")
	await click(home.adventure.get_node("AdventurePage/BackButton"),"Prep back to Map",home.adventure._page)
	await click(home.adventure.get_node("AdventurePage/MapScroll/MapCanvas/LevelNode1/ChooseLevel1"),"Map node to Prep",home.adventure._page)
	check(home.phase=="preparation" and home.adventure.level_definitions.size()==1,"Second real Map entry still exposes one first level")
	# Isolated service receipt fixture funds one purchase. This is not a played win.
	var cfg:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-01.json"))
	check(home.progression.create_run("ui-retirement-fixture",cfg.level_id,cfg.rewards.fast_seconds,cfg.rewards.normal_seconds).ok,"Create isolated first-level receipt fixture")
	check(home.progression.settle_run("ui-retirement-fixture","won",100.0).ok,"Fund isolated purchase fixture through existing service")
	home.economy_state=home.progression.get_view_state()
	await click(home.adventure.get_node("AdventurePage/BackButton"),"Prep back before Shop",home.adventure._page)
	await click(home.adventure.get_node("AdventurePage/ShopButton"),"Map to Shop")
	check(home.phase=="shop","Actual Shop button opens Shop")
	home.shop.purchase_requested.connect(func(_product):purchase_count+=1)
	var points_before:int=home.economy_state.points
	await click(home.shop.content.get_node("TrainingButton"),"One actual Training refresh",home.shop.content)
	check(purchase_count==1 and home.economy_state.carry_level==2 and home.economy_state.points==points_before-100,"Exactly one training purchase commits and rebuilds Shop")
	check(home.shop.content.name=="ShopContent" and not home.shop.content.is_queued_for_deletion(),"New Shop content owns the canonical name")
	await dispose(home)
	var game=load("res://scenes/play.tscn").instantiate()
	game.profile_directory=profile.path_join("battle");game.profile_directory_resolved=true;game.use_command_line_catalog=false
	root.add_child(game);current_scene=game;await settle()
	if game.modal_title=="YOUR FIRST RESCUE":await click(game.pause_overlay.get_node("TutorialContinue"),"Tutorial Continue")
	await click(game.get_node("CandidateQueues/ColorButton_blue"),"One blue carrier")
	check(game.rules.status=="running" and game.rules.tasks.size()==1,"Actual color Button dispatches one carrier")
	await click(game.get_node("TopHUD/SettingsButton"),"Battle Gear to Settings")
	check(game.modal_title=="SETTINGS" and game.rules.paused,"Settings freezes current battle")
	await click(game.pause_overlay.get_node("CloseButton"),"Settings X to Pause",game.pause_overlay)
	check(game.modal_title=="PAUSED" and game.rules.paused,"Settings X stays Paused")
	await click(game.pause_overlay.get_node("Button_LEVEL SELECT"),"Pause Level Select to Leave",game.pause_overlay)
	check(game.modal_title=="LEAVE THIS LEVEL?" and game.rules.paused,"Level Select opens the real Leave confirmation while paused")
	await click(game.pause_overlay.get_node("Button_CANCEL"),"Leave Cancel to Pause",game.pause_overlay)
	check(game.modal_title=="PAUSED" and game.rules.paused,"Cancel returns to Pause without resuming")
	var closing:Control=game.pause_overlay
	await click(game.pause_overlay.get_node("Button_CONTINUE"),"Explicit Continue")
	check(not game.rules.paused and game.modal_title=="","Only explicit Continue resumes")
	check(is_instance_valid(closing) and not closing.get_meta(&"ui_modal_active",true),"Continue is still in its original closing animation")
	await click(game.get_node("TopHUD/SettingsButton"),"Immediate Gear while old Pause closes",null,0.0)
	check(game.modal_title=="SETTINGS" and game.rules.paused and not is_instance_valid(closing),"New Settings replaces closing modal safely and pauses again")
	check(observer.non_emulated_mouse==0,"Test injects no mouse or business callbacks")
	await dispose(game);observer.queue_free();await settle()
	print("UI_RETIREMENT_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"scope":"headless engine-touch input, first-level UI only; no GL or physical device acceptance"}))
	quit(0 if failures.is_empty() else 1)
