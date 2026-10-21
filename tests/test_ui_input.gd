extends SceneTree
var failures:Array[String]=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,reason:String)->void:
	if not ok:failures.append(reason)
func mouse(scene:Control,p:Vector2,down:bool)->void:
	var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=p;e.global_position=p
	scene.get_viewport().push_input(e,true)
func tap(scene:Control,p:Vector2)->void:
	mouse(scene,p,true);mouse(scene,p,false)
func run()->void:
	root.size=Vector2i(1440,2560)
	var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene)
	await process_frame
	await create_timer(.15).timeout
	var front:Control=scene.get_node("CandidateQueues/Column1/FrontButton")
	var front_pos:Vector2=front.get_global_rect().get_center()
	var rear_pos:Vector2=front_pos+Vector2(0,57*scene.scale.y)
	var count:int=scene.fixture.queues[0].size()
	tap(scene,rear_pos)
	check(scene.fixture.queues[0].size()==count,"Rear-row pointer consumed a team")
	mouse(scene,front_pos,true)
	var move:=InputEventMouseMotion.new();move.position=front_pos+Vector2(300,0);move.global_position=move.position;move.button_mask=MOUSE_BUTTON_MASK_LEFT;scene.get_viewport().push_input(move,true)
	mouse(scene,move.position,false)
	check(scene.fixture.queues[0].size()==count,"Drag outside dispatched")
	scene.show_settings();await process_frame
	tap(scene,front_pos)
	check(scene.fixture.queues[0].size()==count,"Modal pointer leaked to front team")
	var close:Control=scene.pause_overlay.get_node("CloseButton")
	tap(scene,close.get_global_rect().get_center());await process_frame
	check(scene.modal_title=="PAUSED","X pointer did not return settings to pause")
	var esc:=InputEventKey.new();esc.keycode=KEY_ESCAPE;esc.pressed=true;scene.get_viewport().push_input(esc,true);await process_frame
	check(scene.modal_title.is_empty(),"ESC did not dismiss pause")
	tap(scene,front_pos);tap(scene,front_pos)
	check(scene.fixture.queues[0].size()==count-1,"Rapid double tap did not dispatch exactly once")
	check(scene.slot_teams[3].quota==20,"Pointer input dispatched wrong same-color quota")
	await create_timer(.22).timeout
	front=scene.get_node("CandidateQueues/Column1/FrontButton")
	tap(scene,front.get_global_rect().get_center())
	check(scene.slot_teams[4].quota==30,"Second same-color team quota not independently selected")
	check(scene.fixture.queues[0].size()==count-2,"Queue did not advance exactly twice")
	await create_timer(.22).timeout
	var report:Dictionary={"pass":failures.is_empty(),"failures":failures,"viewport":root.size,"front_target":front_pos,"scope":"Actual Godot input dispatch at 2K coordinates, modal isolation, drag cancel, same-color20/30, rear rejection, rapid click guard; UI fixture only"}
	var f:=FileAccess.open("res://reports/ui/input-report.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close();print(JSON.stringify(report,"\t"))
	scene.queue_free();await process_frame;await create_timer(.12).timeout
	quit(0 if failures.is_empty() else 1)
