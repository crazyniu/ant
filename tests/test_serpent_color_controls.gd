extends SceneTree
var scene:Control
var failures:Array[String]=[]
var checks:=0
func _initialize()->void:call_deferred("run")
func check(value:bool,note:String)->void:
	checks+=1
	if not value:failures.append(note);push_error(note)
func run()->void:
	scene=load("res://scenes/play.tscn").instantiate();scene.auto_replay=true;scene.use_command_line_catalog=false;scene.use_command_line_level=false
	root.add_child(scene);current_scene=scene;scene.set_process(false);scene.auto_replay=false
	for color in ["red","blue","green","red"]:scene.color_buttons[color].emit_signal("pressed")
	check(scene.rules.tasks.size()==4,"exactly one carrier per actual button handler")
	check(scene.rules.reservations.size()==4,"four unique target reservations")
	check(scene.get_node("WorkSlots/CarrierCount").text=="4 / 4","four of four displayed")
	check(scene.get_node("WorkSlots/CapacityState").text=="BUSY","busy is explicit")
	check(scene.get_node("CandidateQueues/Remaining_red").text=="6","reservation does not decrement remaining bead count")
	scene.color_buttons.red.emit_signal("pressed")
	check(scene.rules.tasks.size()==4,"fifth click rejected with no queue")
	check(scene.get_node("ClickFeedback").text=="ALL FOUR ANTS ARE BUSY","rejection explains capacity")
	scene.rules.update_us(3200000);scene.sync_view();scene.consume_rule_events()
	check(scene.rules.tasks.size()==1,"returned ants release capacity, no fifth queued dispatch")
	scene.color_buttons.red.emit_signal("pressed")
	check(scene.rules.tasks.size()==2,"fresh click after return accepted")
	scene.show_pause();var before:int=scene.rules.time_us;var count:int=scene.rules.tasks.size()
	scene.color_buttons.blue.emit_signal("pressed");scene.rules.update_us(1000000)
	check(scene.rules.time_us==before and scene.rules.tasks.size()==count,"modal freezes time and color handler")
	for button in scene.color_buttons.values():check(button.size.y*375.0/940.0>=44.0,"minimum 44-point equivalent touch height")
	var report:Dictionary={"checks":checks,"failures":failures,"scope":"Production Button pressed handlers and modal guard, not native mouse or human playtest."}
	print("SERPENT_COLOR_CONTROLS ",JSON.stringify(report))
	var file:=FileAccess.open("res://reports/ui/serpent-color-controls.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	scene.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
