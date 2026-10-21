extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var scene=load("res://scenes/play.tscn").instantiate();scene.auto_replay=true;scene.use_command_line_catalog=false;scene.use_command_line_level=false
	root.add_child(scene);scene.set_process(false)
	for entry in scene.level_config.validation.no_tool_solution:
		scene.rules.update_us(int(entry.time_us)-scene.rules.time_us);scene.rules.select_front(entry.column_id,entry.team_id)
	scene.rules.update_us(100000000);scene.sync_view();scene.consume_rule_events();scene.fx.advance(.96);scene.apply_actor_poses()
	await process_frame;await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://review-evidence/motion-current")
	root.get_texture().get_image().save_png("user://review-evidence/motion-current/grounded-landing-preview.png")
	print("GROUNDED_PREVIEW ",scene.rules.status," ",scene.fx.dragon_pose());quit()
