extends SceneTree
## Current-motion integration: actual three play scenes, deterministic 1x input.
## Node replay is not human playtesting; graphical recording is separate.
var checks:=0
var failures:Array[String]=[]
var results:Array=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures.append(message);push_error(message)
func run()->void:
	var directory:="/tmp/ant-rescue-motion-binding-%d"%Time.get_ticks_usec()
	for index in range(1,4):
		var scene=load("res://scenes/play.tscn").instantiate()
		scene.profile_directory=directory;scene.profile_directory_resolved=true
		scene.use_command_line_level=false;scene.use_command_line_catalog=false
		scene.qa_fixture_mode=true;scene.auto_replay=true;scene.level_index=index
		root.add_child(scene);scene.set_process(false)
		var held:=false;var outbound:=false;var loaded:=false
		var first_hold_position:=Vector2.ZERO;var held_task:=-1
		var frames:=0
		while scene.rules.status in ["ready","running"] and frames<2400:
			scene._process(1.0/24.0);frames+=1
			for id in scene.rules.tasks:
				var task:Dictionary=scene.rules.tasks[id]
				var actor:Control=scene.carriers[id]
				if task.stage=="outbound" and not outbound:
					check(actor.get_node("Ant").material is ShaderMaterial,"Outbound ant owns articulated material")
					check(not actor.get_node("CarriedBead").visible,"Outbound does not fabricate carried bead")
					outbound=true
				if task.stage=="returning" and scene.rules.time_us<task.return_depart_us:
					if not held:
						check(actor.position.distance_to(scene.map_path_point(task.path[-1]))<.01,"Pickup hold is at exact board target")
						check(actor.get_node("CarriedBead").visible and not scene.rules.board.has(task.cell_id),"Pickup opens cell while load remains visible")
						held=true;held_task=id;first_hold_position=actor.position
					elif id==held_task:check(actor.position.distance_to(first_hold_position)<.01,"Pickup hold never slides home early")
				elif task.stage=="returning" and not loaded:
					check(actor.get_node("CarriedBead").visible,"Return load remains readable")
					loaded=true
			if frames%120==0:await process_frame
		check(outbound and held and loaded,"All transport presentation phases actually observed")
		check(scene.rules.status=="victory" and scene.victory_saved,"Final hit settles victory and saves before cosmetic completion")
		check(scene.rules.conservation_errors().is_empty(),"Current three-level transport conserves each color")
		check(scene.rules.board.is_empty() and scene.rules.tasks.is_empty(),"All real loads arrived before final victory")
		check(scene.pending_victory_presentation_run==scene.rules.run_id and scene.modal_title!="PRINCESS SAVED!","Result does not cover pending collapse")
		var final_time:int=scene.rules.time_us
		var save_path:String=scene.profile_directory+"/save.json"
		var saved_bytes:=FileAccess.get_file_as_bytes(save_path)
		check(not saved_bytes.is_empty(),"Victory save byte comparison uses the real nonempty primary")
		scene.show_pause();check(not is_instance_valid(scene.pause_overlay),"Pause cannot obscure a settled final-hit collapse")
		var before:float=scene.fx.dragon_pose().defeat_age
		scene.fx.set_backgrounded(true);scene._process(.3)
		check(is_equal_approx(before,scene.fx.dragon_pose().defeat_age),"Background freezes cosmetic collapse")
		scene.fx.set_backgrounded(false)
		while not scene.fx.dragon_pose().defeat_complete:scene._process(1.0/24.0)
		check(scene.modal_title=="PRINCESS SAVED!" and not scene.get_node("DragonRoute/Dragon").visible,"Result appears only after readable collapse")
		check(scene.rules.time_us==final_time and scene.rules.status=="victory","Death presentation cannot create late defeat")
		scene._process(.2);scene.consume_rule_events();scene.present_pending_outcome()
		check(saved_bytes==FileAccess.get_file_as_bytes(save_path),"Presentation never repeats or changes saved progress")
		results.append({"level":index,"final_hit_us":final_time,"frames_1x_24fps":frames,"held":held,"gait":outbound,"loaded":loaded})
		scene.queue_free();await process_frame;await process_frame;await create_timer(.05).timeout
	var report:={"pass":failures.is_empty(),"checks":checks,"failures":failures,"results":results,"scope":"Current three actual Godot play scenes with 1x simulation input; headless node replay, not GL or human playtesting"}
	var f:=FileAccess.open("res://reports/ui/motion-binding-report.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	print("MOTION_BINDING ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
