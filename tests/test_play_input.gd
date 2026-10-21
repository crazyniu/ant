extends SceneTree
var failures:Array[String]=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,reason:String)->void:
	if not ok:failures.append(reason)
func mouse(scene:Control,p:Vector2,down:bool)->void:
	var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=p;e.global_position=p
	scene.get_viewport().push_input(e,true)
func tap(scene:Control,p:Vector2)->void:mouse(scene,p,true);mouse(scene,p,false)
func run()->void:
	root.size=Vector2i(1440,2560)
	var directory:String="/tmp/ant-rescue-input-%d-%d"%[OS.get_process_id(),Time.get_ticks_usec()]
	var saves=load("res://scripts/save_service.gd").new(directory)
	check(saves.load_save().ok,"Isolated profile initialized")
	check(saves.set_tutorial_completed(true).ok,"Isolated input fixture skips completed tutorial")
	var scene=load("res://scenes/play.tscn").instantiate();scene.profile_directory=directory;scene.use_command_line_level=false;root.add_child(scene);await process_frame
	scene.set_process(false)
	var front:Control=scene.get_node("CandidateQueues/Column1/FrontButton")
	var p:Vector2=front.get_global_rect().get_center()
	var count:int=scene.rules.columns[0].teams.size()
	var first_id:String=scene.rules.columns[0].teams[0].id
	tap(scene,p+Vector2(0,57*scene.scale.y))
	check(scene.rules.columns[0].teams.size()==count,"Rear pointer dispatched")
	check(scene.rules.status=="ready","Rear pointer started dragon")
	mouse(scene,p,true);scene.show_settings();await process_frame;mouse(scene,p,false)
	check(scene.rules.columns[0].teams.size()==count,"Opening modal did not cancel press")
	tap(scene,p);check(scene.rules.columns[0].teams.size()==count,"Modal input leaked")
	tap(scene,scene.pause_overlay.get_node("CloseButton").get_global_rect().get_center());await process_frame
	check(scene.modal_title=="PAUSED","Settings X skipped parent pause")
	var esc:=InputEventKey.new();esc.keycode=KEY_ESCAPE;esc.pressed=true;scene.get_viewport().push_input(esc,true);await process_frame
	check(not scene.rules.paused,"Pause ESC failed to resume")
	tap(scene,p);tap(scene,p)
	check(scene.rules.columns[0].teams.size()==count-1,"Rapid input did not select exactly one team")
	check(scene.rules.slots[0]!=null and scene.rules.slots[0].id==first_id,"Wrong front team selected")
	check(scene.rules.status=="running","Successful team did not start dragon")
	scene.rules.update_us(500000);scene.sync_view();scene.consume_rule_events()
	var before:int=scene.rules.time_us;var remaining:int=scene.rules.board.size()
	scene.show_pause();scene.rules.update_us(10000000)
	check(scene.rules.time_us==before and scene.rules.board.size()==remaining,"Pause advanced gameplay")
	scene.show_restart();scene.pause_overlay.get_node("Button_CANCEL").pressed.emit();await process_frame
	check(scene.modal_title=="PAUSED" and scene.rules.run_id>0,"Restart cancel returned incorrectly")
	check(scene.rules.time_us==before and scene.rules.columns[0].teams.size()==count-1,"Restart cancel altered run")
	check(scene.rules.conservation_errors().is_empty(),"Input broke conservation")
	for i in range(4):check(scene.get_node("ToolTray/ToolButton%d"%i).disabled,"Level-one locked tool was enabled")
	var report:Dictionary={"pass":failures.is_empty(),"failures":failures,"viewport":root.size,"scope":"Actual Godot input dispatch at 2K with an isolated local profile: rear rejection, modal press cancellation, X/ESC parent navigation, rapid click identity, first dispatch start, pause and restart-cancel conservation. Automated, not manual playtest."}
	var f:=FileAccess.open("res://reports/ui/play-input-report.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close();print(JSON.stringify(report))
	scene.queue_free();await process_frame;await create_timer(.12).timeout
	quit(0 if failures.is_empty() else 1)
