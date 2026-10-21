extends SceneTree
var results:Array=[]
func _initialize()->void:call_deferred("run")
func run()->void:
	var directory:String="/tmp/ant-rescue-binding-%d-%d"%[OS.get_process_id(),Time.get_ticks_usec()]
	var saves=load("res://scripts/save_service.gd").new(directory)
	assert(saves.load_save().ok);assert(saves.set_tutorial_completed(true).ok)
	for index in range(1,4):
		assert(saves.set_current_entrance("validation-%02d"%index).ok)
		var scene=load("res://scenes/play.tscn").instantiate();scene.profile_directory=directory;scene.use_command_line_level=false;root.add_child(scene);await process_frame
		assert(scene.level_index==index)
		scene.set_process(false)
		assert(scene.rules.status=="ready")
		assert(scene.bead_nodes.size()==scene.rules.board.size())
		var solution:Array=scene.level_config.validation.no_tool_solution
		for entry in solution:
			scene.rules.update_us(int(entry.time_us)-scene.rules.time_us)
			var result:Dictionary=scene.rules.select_front(entry.column_id,entry.team_id)
			assert(result.ok)
			scene.sync_view();scene.consume_rule_events();scene.apply_actor_poses()
			await process_frame
		scene.rules.update_us(120000000);scene.sync_view();scene.consume_rule_events()
		assert(scene.rules.status=="victory")
		assert(scene.last_outcome=="victory")
		assert(scene.rules.conservation_errors().is_empty())
		assert(scene.rules.board.is_empty())
		assert(scene.rules.tasks.is_empty())
		assert(scene.rules.inventory.values().all(func(n):return n==0))
		scene.fx.advance(scene.fx.DRAGON_DEFEAT_DURATION);scene.apply_actor_poses();scene.present_pending_outcome()
		assert(scene.modal_title=="PRINCESS SAVED!")
		assert(not scene.get_node("DragonRoute/Dragon").visible)
		scene.close_current_modal();assert(scene.modal_title=="CHOOSE A LEVEL")
		scene.close_current_modal();assert(scene.modal_title=="PRINCESS SAVED!")
		assert(scene.rules.status=="victory")
		results.append({"level":index,"beads":scene.bead_nodes.size(),"final_hit_us":scene.rules.time_us,"audio_cues":scene.audio_service.get_status().accepted,"fx_accepted":scene.fx.debug_snapshot().accepted,"pass":true})
		scene.queue_free();await process_frame;await create_timer(.12).timeout
	var f:=FileAccess.open("res://reports/ui/play-binding-report.json",FileAccess.WRITE);f.store_string(JSON.stringify({"pass":true,"results":results,"scope":"Three real levels: authoritative replay, actual node/audio/FX binding and sequential local-save progression. Isolated profile; not manual playtesting or 30-level completion"},"\t"));f.close()
	print("THREE_PLAY_BINDINGS_PASS ",JSON.stringify(results));quit()
