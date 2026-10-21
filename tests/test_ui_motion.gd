extends SceneTree
## Focused cosmetic interruption/input contract. Not a campaign or visual review.
var checks:=0
var failures:Array[String]=[]
var activations:=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures.append(message);push_error(message)
func mouse(scene:Control,point:Vector2,down:bool)->void:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT
	event.position=point;event.global_position=point;event.pressed=down
	scene.get_viewport().push_input(event,true)
func tap(scene:Control,point:Vector2)->void:
	mouse(scene,point,true);mouse(scene,point,false)
func run()->void:
	root.size=Vector2i(1440,2560)
	var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene)
	await process_frame
	var button:Button=scene.get_node("ToolTray/ToolButton0")
	var painted:Control=scene.get_node("ToolTray/PaintedTool0")
	var original_rect:Rect2=button.get_global_rect()
	var original_position:=painted.position
	button.pressed.connect(func():activations+=1)
	scene.bind_new_button(button);scene.bind_new_button(button)
	check(button.button_down.get_connections().size()==1,"Repeated binding does not stack down callbacks")
	button.button_down.emit();await create_timer(.09).timeout;await process_frame
	check(painted.scale.x<.97,"Button artwork has a short physical press")
	check(button.get_global_rect()==original_rect,"Tactile press never changes input geometry")
	for i in range(5):button.button_up.emit();button.button_down.emit()
	button.mouse_exited.emit();await create_timer(.21).timeout
	check(painted.scale==Vector2.ONE and painted.position==original_position,"Interrupted presses return exactly without layout drift")
	check(activations==0,"Motion never synthesizes a pressed signal")
	button.disabled=true;painted.modulate=Color(.62,.62,.62,.8)
	button.button_down.emit();button.button_up.emit();await create_timer(.18).timeout
	check(painted.modulate.is_equal_approx(Color(.62,.62,.62,.8)),"Used/disabled tool tint is not reset by motion")
	button.disabled=false;painted.modulate=Color.WHITE
	var front:Control=scene.get_node("CandidateQueues/Column1/FrontButton")
	var front_point:=front.get_global_rect().get_center()
	var queue_count:int=scene.fixture.queues[0].size()
	scene.show_settings()
	var settings:Control=scene.pause_overlay
	check(settings.has_node("MusicVolume") and settings.has_node("SoundVolume"),"Logical settings children exist synchronously")
	check(scene.audio_service.get_status().game_paused,"Modal pauses immediately before its reveal")
	check(settings.mouse_filter==Control.MOUSE_FILTER_STOP and settings.size==Vector2(940,1672),"Modal blocks the full logical canvas from frame zero")
	tap(scene,front_point)
	check(scene.fixture.queues[0].size()==queue_count,"Revealing modal cannot leak a front-team click")
	var close:Button=settings.get_node("CloseButton")
	var close_rect:=close.get_rect()
	check(close_rect==Rect2(749,564,63,63),"Close button keeps its final stable hit rectangle during reveal")
	close.pressed.emit()
	check(scene.modal_title=="PAUSED" and scene.pause_overlay!=settings,"Settings X keeps original pause/back destination")
	close.pressed.emit()
	check(scene.modal_title=="PAUSED","Retired page callback cannot reopen an earlier page")
	var old:Control=scene.pause_overlay
	var old_action:Button=old.get_node("Button_CONTINUE")
	scene.dismiss_modal()
	check(scene.pause_overlay==null and scene.modal_title.is_empty(),"Dismissal clears logical ownership synchronously")
	check(not scene.audio_service.get_status().game_paused,"Cosmetic closing never delays logical audio resume")
	check(old.mouse_filter==Control.MOUSE_FILTER_IGNORE and old_action.disabled,"Closing art is inert, not a second active modal")
	scene.show_settings()
	var newest:Control=scene.pause_overlay
	old_action.pressed.emit()
	check(scene.pause_overlay==newest and scene.modal_title=="SETTINGS","A stale close callback cannot dismiss the newly opened modal")
	await create_timer(.32).timeout
	check(scene.pause_overlay==newest and scene.modal_title=="SETTINGS","Interrupted old tweens never restore or remove the new modal")
	check(scene.find_children("ClosingModal*","Control",false,false).is_empty(),"Reopening removes any superseded close artwork")
	var panel:Control=newest.get_node("ModalPanel")
	check(panel.position==Vector2(143,585) and panel.scale==Vector2.ONE and panel.modulate.a==1.0,"Reveal resolves to exact original panel layout and opacity")
	check(newest.get_node("MusicVolume").get_rect()==Rect2(346,714,355,57),"Animated settings never move slider interaction bounds")
	newest.get_node("MusicVolume").value=0
	check(scene.audio_service.get_status().music_muted,"Independent zero-to-mute slider remains functional")
	scene.dismiss_modal();scene.dismiss_modal()
	tap(scene,front_point);tap(scene,front_point)
	check(scene.fixture.queues[0].size()==queue_count-1,"Repeated close and double tap dispatch only one front team")
	await create_timer(.27).timeout
	check(scene.ui_motion.retired_modals.is_empty(),"Completed close releases its transient overlay")
	scene.show_tool_detail("HINT","hint")
	check(scene.pause_overlay.has_node("ToolEmblem"),"Tool emblem still constructs synchronously")
	var emblem:Control=scene.pause_overlay.get_node("ToolEmblem")
	check(emblem.modulate.a==0.0,"Tool emblem enters with restrained fade rather than a hard pop")
	# Scene destruction during a reveal must cancel bound tracks with no late work.
	scene.queue_free();await process_frame;await create_timer(.28).timeout
	var report:={"pass":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Shared UI motion: stable hit rectangles, same-frame modal construction/input shield, back callbacks, interrupted reveal/close, repeated binding/presses, inert retired pages and scene disposal. Headless, not visual acceptance or full campaign."}
	print("UI_MOTION_REPORT ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
