extends SceneTree
var scene:Control
var checks:=0
var failures:Array[String]=[]
func _initialize()->void:call_deferred("run")
func check(value:bool,note:String)->void:
	checks+=1
	if not value:failures.append(note);push_error(note)
func run()->void:
	scene=load("res://scenes/play.tscn").instantiate()
	scene.auto_replay=true;scene.use_command_line_catalog=false;scene.use_command_line_level=false
	root.add_child(scene);current_scene=scene;scene.set_process(false)
	check(scene.ready_to_simulate,"scene ready")
	check(scene.color_buttons.size()==3,"three real color entries")
	check(scene.rules.status=="ready","no automatic dispatch before click")
	for i in range(750):
		scene.advance_replay(.05);scene.sync_view();scene.consume_rule_events();scene.fx.advance(.05);scene.serpent.advance(.05);scene.apply_actor_poses();scene.present_pending_outcome()
		if scene.rules.status=="victory":break
	check(scene.rules.status=="victory","single-click timed solution reaches actual victory")
	check(scene.rules.conservation_errors().is_empty(),"resource conservation")
	check(scene.rules.tasks.size()<=4,"carrier cap")
	check(scene.rules.board.size()==6,"surplus beads remain at victory")
	check(scene.victory_saved,"victory progress saved with authored content version")
	check(scene.pending_save_kind.is_empty(),"no pending completion save error")
	var report:Dictionary={"checks":checks,"failures":failures,"status":scene.rules.status,"time_us":scene.rules.time_us,"remaining_board":scene.rules.board.size(),"mode":"headless actual scene adapter, not visual acceptance"}
	print("SERPENT_SCENE_CHECK ",JSON.stringify(report))
	var f:=FileAccess.open("res://reports/ui/serpent-scene-check.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	scene.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
