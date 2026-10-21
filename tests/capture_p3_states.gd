extends SceneTree
## Finite real-GL render review. Tool screens use an isolated unlock-only copy;
## production configs, progress and gameplay data are never overwritten.
const Saves = preload("res://scripts/save_service.gd")
var scene: Control
var profiles: Array[String] = []
var shots: Array[Dictionary] = []
var evidence := ""

func _initialize() -> void:
	call_deferred("run")

func fresh(label: String, tools_unlocked := false) -> Control:
	var directory := "/tmp/ant-rescue-p3-capture-%d-%s" % [Time.get_ticks_usec(), label]
	profiles.append(directory)
	var result = load("res://scenes/play.tscn").instantiate()
	result.profile_directory = directory
	result.use_command_line_level = false
	if tools_unlocked:
		result.qa_fixture_mode = true
		result.qa_level_config = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/validation-01.json"))
		for tool in result.qa_level_config.tools:
			tool.unlock_level = 1
	root.add_child(result)
	result.set_process(false)
	return result

func capture(id: String, fixture := false) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var pixels := root.get_texture().get_image()
	assert(pixels.get_size() == Vector2i(1440,2560))
	assert(pixels.save_png(evidence.path_join(id + "-engine.png")) == OK)
	shots.append({"id": id, "qa_unlock_override": fixture, "level": scene.level_index,
		"beads": scene.bead_nodes.size(), "status": scene.rules.status,
		"simulation_us": scene.rules.time_us, "conservation_errors": scene.rules.conservation_errors()})

func drop() -> void:
	if is_instance_valid(scene): scene.queue_free()
	await process_frame

func replay_to_win() -> void:
	for input in scene.level_config.validation.no_tool_solution:
		scene.rules.update_us(int(input.time_us) - scene.rules.time_us)
		assert(scene.rules.select_front(input.column_id, input.team_id).ok)
	scene.rules.update_us(120000000)
	scene.sync_view()
	scene.consume_rule_events()
	assert(scene.rules.status == "victory")
	await create_timer(.72).timeout

func run() -> void:
	evidence = OS.get_environment("ANT_RESCUE_EVIDENCE_DIR")
	assert(not evidence.is_empty(), "Provide an external evidence directory")
	DirAccess.make_dir_recursive_absolute(evidence)
	root.size = Vector2i(1440,2560)
	scene = fresh("first")
	await capture("p3-first-tutorial")
	scene.finish_tutorial()
	await capture("p3-level-one-ready")
	scene.show_pause()
	scene.show_settings()
	await capture("p3-settings")
	scene.close_current_modal()
	scene.show_levels()
	await capture("p3-real-level-picker")
	await drop()

	scene = fresh("tools", true)
	assert(scene.activate_tool("extra_slot").ok)
	await capture("p3-six-slots", true)
	assert(scene.preview_select_front(0, str(scene.rules.columns[0].teams[0].id)))
	scene.rules.update_us(250000)
	scene.sync_view()
	scene.consume_rule_events()
	scene.show_recall_selection()
	await capture("p3-recall-selection", true)
	scene.close_current_modal()
	assert(scene.activate_tool("scout").ok)
	await capture("p3-live-scout", true)
	var shuffled: Dictionary = scene.activate_tool("shuffle")
	assert(shuffled.ok)
	await capture("p3-shuffle-used", true)
	await drop()

	scene = fresh("save-error")
	scene.finish_tutorial()
	scene.saves.test_fail_stage = "replace_primary"
	await replay_to_win()
	await capture("p3-victory-save-error")
	scene.saves.test_fail_stage = ""
	scene.retry_save()
	await capture("p3-saved-victory-next")
	scene.close_current_modal()
	await capture("p3-unlocked-level-picker")
	await drop()
	var out := FileAccess.open(evidence.path_join("p3-render-report.json"), FileAccess.WRITE)
	out.store_string(JSON.stringify({"rendering": RenderingServer.get_current_rendering_method(),
		"viewport": [1440,2560], "shots": shots, "human_playtest": false,
		"scope": "Real Godot GL snapshots. Tool views use original first-level data with unlock-only QA overrides; no official unlock/config or player save is changed."}, "\t"))
	out.close()
	print("P3_RENDER_SUITE_PASS ", shots.size())
	for directory in profiles:
		for file in DirAccess.get_files_at(directory): DirAccess.remove_absolute(directory.path_join(file))
		DirAccess.remove_absolute(directory)
	await create_timer(.2).timeout
	quit()
