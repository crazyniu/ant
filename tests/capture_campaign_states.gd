extends SceneTree
## Finite real-GL candidate review. All higher-level unlocks use isolated QA saves.
var scene: Control
var evidence := ""
var shots: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func fresh(level: int, label: String, seed_unlocks := true) -> Control:
	var result = load("res://scenes/play.tscn").instantiate()
	result.profile_directory = "/tmp/ant-rescue-campaign-capture-%d-%s" % [Time.get_ticks_usec(), label]
	result.use_command_line_level = false
	result.use_command_line_catalog = false
	result.campaign_drafts = true
	result.level_index = level
	result.qa_fixture_mode = seed_unlocks
	root.add_child(result)
	result.set_process(false)
	return result

func capture(id: String, seeded: bool) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var pixels := root.get_texture().get_image()
	assert(pixels.get_size() == Vector2i(1440, 2560))
	assert(pixels.save_png(evidence.path_join(id + "-engine.png")) == OK)
	shots.append({"id": id, "level_id": scene.level_config.level_id,
		"content_version": scene.level_config.content_version,
		"qa_seeded_prior_unlocks": seeded, "level": scene.level_index,
		"board_node_count": scene.bead_nodes.size(), "status": scene.rules.status,
		"simulation_us": scene.rules.time_us,
		"conservation_errors": scene.rules.conservation_errors()})

func drop() -> void:
	if is_instance_valid(scene): scene.queue_free()
	await process_frame

func run() -> void:
	evidence = OS.get_environment("ANT_RESCUE_EVIDENCE_DIR")
	assert(not evidence.is_empty(), "Provide an external evidence directory")
	DirAccess.make_dir_recursive_absolute(evidence)
	root.size = Vector2i(1440, 2560)
	if "--final-only" in OS.get_cmdline_user_args():
		scene = fresh(30, "final-review")
		await replay_final()
		await capture("campaign-30-final-hit-victory", true)
		await drop()
		print("CAMPAIGN_FINAL_RENDER_PASS")
		quit()
		return
	scene = fresh(1, "fresh", false)
	scene.finish_tutorial()
	await capture("campaign-01-ready", false)
	scene.show_levels(0)
	await capture("campaign-page-one-locked", false)
	scene.show_levels(2)
	await capture("campaign-page-three-locked", false)
	await drop()

	for index in [16, 28, 30]:
		scene = fresh(index, "level-%d" % index)
		await capture("campaign-%02d-ready" % index, true)
		if index != 30: await drop()
	for page in range(3):
		scene.show_levels(page)
		await capture("campaign-page-%d-unlocked" % (page + 1), true)
	await replay_final()
	await capture("campaign-30-final-hit-victory", true)
	assert(scene.profile_state.next_level_id.is_empty())
	await drop()
	var out := FileAccess.open(evidence.path_join("campaign-render-report.json"), FileAccess.WRITE)
	out.store_string(JSON.stringify({"viewport": [1440, 2560], "shots": shots,
		"rendering": RenderingServer.get_current_rendering_method(),
		"human_playtest": "NOT_RUN", "visual_acceptance": "NOT_RUN",
		"scope": "Real GL candidate files and nodes. Seeded prior unlocks are QA-only; last-level victory uses the actual timed no-tool sequence through final hit. No player profile, draft configuration or acceptance metadata changes."}, "\t"))
	out.close()
	print("CAMPAIGN_RENDER_SUITE_PASS ", shots.size())
	quit()

func replay_final() -> void:
	scene.dismiss_modal()
	scene.rules.set_paused(false)
	for input in scene.level_config.validation.no_tool_solution:
		scene.rules.update_us(int(input.time_us) - scene.rules.time_us)
		assert(scene.rules.select_front(input.column_id, input.team_id).ok)
	scene.rules.update_us(180000000)
	scene.sync_view()
	scene.consume_rule_events()
	assert(scene.rules.status == "victory")
	# Rules are terminal and immutable; allow presentation to settle normally.
	scene.set_process(true)
	await create_timer(.75).timeout
