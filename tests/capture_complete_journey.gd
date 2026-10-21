extends SceneTree
## Automated viewport-input demonstration, NOT human playtesting or listening.
## The real play scene alone advances rules/FX and settles victory. No QA unlocks.
## Run with --fixed-fps 24; screenshots are disabled for --logic-only/headless.

class JourneyClock extends Node:
	signal tick
	var harness: SceneTree
	var seconds := 0.0
	var frames := 0
	func _process(delta: float) -> void:
		seconds += delta
		frames += 1
		harness.observe_frame()
		tick.emit()
		if seconds > 45.0:
			harness.abort("45-second engine-time watchdog expired")

var scene: Control
var clock_node: JourneyClock
var evidence := ""
var isolated_root := ""
var resolved_profile := ""
var logic_only := false
var finished := false
var journey_completed := false
var phase := "initialization"
var failures: Array[String] = []
var checks := 0
var actions: Array = []
var cues: Array = []
var checkpoints: Array = []
var observations: Array = []
var lifecycles: Dictionary = {}
var previous_tasks: Dictionary = {}
var seen_projectiles: Dictionary = {}
var previous_status := ""
var initial_state: Dictionary = {}
var terminal_state: Dictionary = {}
var selected: Array = []
var screenshot_ids: Array[String] = []
var collapse_seen := false
var collapse_finished := false
var last_level := ""
var source_hashes: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures.append(phase + ": " + message)
		push_error(phase + ": " + message)
	return ok

func stamp() -> Dictionary:
	return {"phase": phase, "movie_seconds": clock_node.seconds if is_instance_valid(clock_node) else 0.0,
		"frame": clock_node.frames if is_instance_valid(clock_node) else 0,
		"level_id": scene.level_config.get("level_id", "") if is_instance_valid(scene) else "",
		"simulation_us": scene.rules.time_us if is_instance_valid(scene) else -1}

func note(kind: String, data: Dictionary = {}) -> void:
	var entry := stamp()
	entry["observation"] = kind
	entry.merge(data)
	observations.append(entry)

func observe_frame() -> void:
	if finished or not is_instance_valid(scene) or not scene.ready_to_simulate:
		return
	var id: String = scene.level_config.level_id
	if id != last_level:
		last_level = id
		previous_tasks.clear()
		previous_status = ""
	var errors: Array = scene.rules.conservation_errors()
	if not errors.is_empty():
		abort("Conservation failed: " + str(errors))
		return
	if scene.rules.status != previous_status:
		note("status_transition", {"from": previous_status, "to": scene.rules.status,
			"terminal_time_us": scene.rules.terminal_time_us, "terminal_reason": scene.rules.terminal_reason})
		previous_status = scene.rules.status
	for key in scene.rules.tasks:
		var task: Dictionary = scene.rules.tasks[key]
		var identity := "%s:%s" % [id, key]
		if not lifecycles.has(identity):
			lifecycles[identity] = task.duplicate(true)
			note("carrier_first_observed", {"task": task.duplicate(true)})
		if previous_tasks.has(key) and previous_tasks[key].get("stage", "") != task.get("stage", ""):
			note("carrier_state_transition", {"task": task.duplicate(true)})
	for key in previous_tasks:
		if not scene.rules.tasks.has(key):
			note("carrier_return_observed", {"task_id": key, "scheduled_delivery_us": previous_tasks[key].delivery_us,
				"delivered_counts": scene.rules.delivered_counts.duplicate()})
	previous_tasks = scene.rules.tasks.duplicate(true)
	if not scene.rules.projectile.is_empty():
		var shot: Dictionary = scene.rules.projectile
		var identity := "%s:%s" % [id, shot.id]
		if not seen_projectiles.has(identity):
			seen_projectiles[identity] = shot.duplicate(true)
			note("real_projectile_first_observed", {"projectile": shot.duplicate(true),
				"status": scene.rules.status, "armor_index": scene.rules.armor_index})
	if scene.rules.status == "victory" and terminal_state.is_empty():
		terminal_state = scene.rules.snapshot()
		note("natural_final_hit", {"terminal_time_us": scene.rules.terminal_time_us,
			"terminal_reason": scene.rules.terminal_reason, "saved": scene.victory_saved})
	if scene.rules.status == "victory":
		var pose: Dictionary = scene.fx.dragon_pose()
		if scene.fx._dragon_defeat_age > 0.0 and not pose.defeat_complete:
			collapse_seen = true
		if pose.defeat_complete and not collapse_finished:
			collapse_finished = true
			note("dragon_collapse_complete", {"authored_duration_seconds": scene.fx.DRAGON_DEFEAT_DURATION,
				"actual_fx_age": scene.fx._dragon_defeat_age, "dragon_visible": pose.visible})

func wire_audio(target: Control) -> void:
	target.audio_service.cue_played.connect(func(id):
		var entry := stamp(); entry.merge({"cue": str(id), "result": "played"}); cues.append(entry))
	target.audio_service.cue_dropped.connect(func(id, reason):
		var entry := stamp(); entry.merge({"cue": str(id), "result": "dropped", "reason": str(reason)}); cues.append(entry))

func hold(seconds: float) -> void:
	var until := clock_node.seconds + seconds
	while not finished and clock_node.seconds + 0.000001 < until:
		await clock_node.tick

func wait_for(predicate: Callable, seconds: float, description: String) -> bool:
	var until := clock_node.seconds + seconds
	while not finished and not predicate.call() and clock_node.seconds < until:
		await clock_node.tick
	return not finished and check(bool(predicate.call()), description)

func mouse(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = point
	event.global_position = point
	scene.get_viewport().push_input(event, true)

func tap(path: String) -> bool:
	var control := scene.get_node_or_null(path) as Control
	if not check(is_instance_valid(control), "Pointer target exists: " + path): return false
	var entry := stamp()
	var point := control.get_global_rect().get_center()
	entry.merge({"input": "mouse_button_click", "target": path, "position": [point.x, point.y]})
	actions.append(entry)
	mouse(point, true)
	mouse(point, false)
	return true

func modal_tap(name: String) -> bool:
	if not check(is_instance_valid(scene.pause_overlay), "Modal exists for " + name): return false
	return tap(str(scene.get_path_to(scene.pause_overlay)) + "/" + name)

func drag_slider(name: String, percent: int) -> bool:
	var slider := scene.pause_overlay.get_node(name) as HSlider
	var rect := slider.get_global_rect()
	var grabber_width := float(slider.get_theme_icon("grabber").get_width()) * slider.get_global_transform().get_scale().x
	var start := Vector2(rect.position.x + grabber_width * .5 + (rect.size.x - grabber_width) * slider.value / 100.0, rect.get_center().y)
	var end := Vector2(rect.position.x + grabber_width * .5 + (rect.size.x - grabber_width) * percent / 100.0, rect.get_center().y)
	var entry := stamp()
	entry.merge({"input": "mouse_drag", "target": name, "from_value": slider.value, "requested_value": percent,
		"start": [start.x, start.y], "end": [end.x, end.y]})
	actions.append(entry)
	mouse(start, true)
	var previous := start
	for step in range(1, 13):
		var point := start.lerp(end, float(step) / 12.0)
		var motion := InputEventMouseMotion.new()
		motion.position = point; motion.global_position = point
		motion.relative = point - previous; motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		scene.get_viewport().push_input(motion, true)
		previous = point
		await clock_node.tick
	mouse(end, false)
	entry["actual_value"] = slider.value
	return check(slider.value == percent, "Actual pointer drag reaches " + name + "=" + str(percent))

func checkpoint(id: String) -> void:
	if not logic_only:
		await RenderingServer.frame_post_draw
	var entry := stamp()
	entry.merge({"id": id, "status": scene.rules.status, "modal": scene.modal_title,
		"board_cells_remaining": scene.rules.board.size(), "board_node_count": scene.bead_nodes.size(),
		"live_node_count": scene.find_children("*", "", true, false).size() + 1,
		"conservation_errors": scene.rules.conservation_errors(),
		"dragon_fx_age": scene.fx._dragon_defeat_age, "qa_fixture_mode": scene.qa_fixture_mode,
		"automatic_replay": scene.auto_replay, "profile": scene.profile_directory})
	if not logic_only:
		var pixels := root.get_texture().get_image()
		check(pixels.get_size() == Vector2i(1440, 2560), "Actual framebuffer is 1440x2560")
		var path := evidence.path_join(id + ".png")
		if check(pixels.save_png(path) == OK, "Screenshot saved: " + id):
			entry["png"] = path
			entry["sha256"] = FileAccess.get_sha256(path)
			screenshot_ids.append(id)
	else:
		entry["graphics"] = "NOT_RUN_HEADLESS_LOGIC_ONLY"
	checkpoints.append(entry)

func run() -> void:
	evidence = OS.get_environment("ANT_RESCUE_EVIDENCE_DIR")
	if evidence.is_empty() or not evidence.is_absolute_path() or evidence.begins_with(ProjectSettings.globalize_path("res://")):
		push_error("ANT_RESCUE_EVIDENCE_DIR must be an absolute external output directory")
		quit(2); return
	if DirAccess.make_dir_recursive_absolute(evidence) != OK:
		push_error("Cannot create evidence directory: " + evidence); quit(2); return
	logic_only = "--logic-only" in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless"
	for forbidden in ["--auto-replay", "--capture-play"]:
		if forbidden in OS.get_cmdline_user_args():
			failures.append("Forbidden argument: " + forbidden); finish(); return
	root.size = Vector2i(1440, 2560)
	clock_node = JourneyClock.new()
	clock_node.harness = self
	clock_node.process_priority = 1000
	root.add_child(clock_node)
	isolated_root = "/tmp/ant-rescue-complete-journey-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	if not check(not DirAccess.dir_exists_absolute(isolated_root), "Profile root is genuinely fresh"):
		finish(); return
	scene = load("res://scenes/play.tscn").instantiate()
	scene.profile_directory = isolated_root
	scene.use_command_line_level = false
	scene.use_command_line_catalog = false
	scene.campaign_drafts = true
	root.add_child(scene)
	current_scene = scene
	resolved_profile = scene.profile_directory
	wire_audio(scene)
	await journey()
	finish()

func journey() -> void:
	phase = "tutorial"
	await hold(.25)
	initial_state = scene.rules.snapshot()
	if not check(scene.level_config.level_id == "campaign-01" and scene.level_ids.size() == 30 and scene.rules.time_us == 0 and scene.rules.status == "ready", "Real fresh first entry of the 30-level candidate"): return
	if not check(not scene.qa_fixture_mode and not scene.auto_replay and scene.profile_state.levels.filter(func(e): return e.unlocked).size() == 1, "No seeded unlocks or replay bypass"): return
	if not check(scene.modal_title == "YOUR FIRST RESCUE" and scene.rules.paused and not scene.profile_state.tutorial_completed, "Fresh tutorial pauses gameplay"): return
	await checkpoint("01-tutorial")
	await hold(1.75)
	if not modal_tap("Button_LET'S GO"): return
	await hold(.5)
	if not check(scene.profile_state.tutorial_completed and scene.rules.time_us == 0, "Tutorial UI saves completion without starting gameplay"): return
	phase = "pause-settings"
	if not tap("TopHUD/PauseButton"): return
	await hold(.45)
	if not modal_tap("Button_SETTINGS"): return
	await hold(.45)
	if not check(scene.modal_title == "SETTINGS" and scene.rules.paused and scene.audio_service.get_status().music_preview, "Settings previews music while gameplay is frozen"): return
	if not await drag_slider("MusicVolume", 0): return
	if not check(AudioServer.is_bus_mute(AudioServer.get_bus_index(scene.audio_service.MUSIC_BUS)), "Music zero really mutes bus"): return
	await hold(.25)
	if not await drag_slider("MusicVolume", 65): return
	if not await drag_slider("SoundVolume", 60): return
	if not check(scene.profile_state.music_volume == 65 and scene.profile_state.sfx_volume == 60 and scene.rules.time_us == 0, "Slider releases save 65/60 with gameplay unchanged"): return
	await checkpoint("02-settings-65-60")
	await hold(.8)
	if not modal_tap("CloseButton"): return
	await hold(.45)
	if not check(scene.modal_title == "PAUSED" and scene.rules.paused, "Settings X returns to pause"): return
	if not modal_tap("Button_CONTINUE"): return
	await hold(.7)
	if not check(not scene.rules.paused and scene.rules.status == "ready", "Continue leaves first board ready"): return
	await checkpoint("03-campaign-01-ready")
	phase = "legal-seven-front-inputs"
	var solution: Array = scene.level_config.validation.no_tool_solution
	if not check(solution.size() == 7, "Authored first-level proof has seven inputs"): return
	for proof in solution:
		if not await wait_for(func(): return scene.rules.time_us >= int(proof.time_us), 8.0, "Reach proof time " + str(proof.time_us)): return
		var index := -1
		for column_index in range(scene.rules.columns.size()):
			if scene.rules.columns[column_index].id == proof.column_id: index = column_index
		if not check(index >= 0, "Proof column is real"): return
		if not await wait_for(func(): return scene.rules.slots.find(null) >= 0 and not scene.queue_transition_busy, 3.0, "Wait for real free slot and finished queue transition"): return
		var teams: Array = scene.rules.columns[index].teams
		if not check(not teams.is_empty() and teams[0].id == proof.team_id, "Expected real front identity: " + str(proof.team_id)): return
		var before_count := teams.size()
		var entry := stamp()
		entry.merge({"proof_time_us": proof.time_us, "column_id": proof.column_id, "team_id": proof.team_id,
			"delay_from_proof_us": scene.rules.time_us - int(proof.time_us), "free_slots": scene.rules.slots.count(null)})
		if not tap("CandidateQueues/Column%d/FrontButton" % (index + 1)): return
		entry["accepted"] = scene.rules.columns[index].teams.size() == before_count - 1 and scene.rules.slots.any(func(slot): return slot != null and slot.id == proof.team_id)
		selected.append(entry)
		if not check(entry.accepted, "Legal viewport input accepted: " + str(proof.team_id)): return
	phase = "natural-delivery-fire-hit"
	if not await wait_for(func(): return not scene.rules.projectile.is_empty() or scene.rules.status != "running", 28.0, "Natural transport creates actual cannon projectile"): return
	if not check(scene.rules.status == "running" and not scene.rules.projectile.is_empty() and scene.rules.armor_index == 0, "Firing is not victory"): return
	await hold(.125)
	await checkpoint("04-real-cannon-shot")
	if not await wait_for(func(): return scene.rules.status != "running", 3.0, "Real final projectile reaches hit"): return
	if not check(scene.rules.status == "victory" and scene.rules.terminal_reason == "final_armor_hit" and scene.rules.time_us < 34000000 and scene.victory_saved, "Natural final hit alone wins and saves within authored 34-second limit"): return
	if not check(seen_projectiles.size() == 1 and scene.rules.terminal_time_us == seen_projectiles.values()[0].hit_us, "Terminal event matches actual scheduled projectile hit"): return
	phase = "natural-dragon-collapse"
	if not await wait_for(func(): return scene.fx._dragon_defeat_age >= .25, 1.0, "Natural collapse reaches middle frame"): return
	if not check(scene.fx._dragon_defeat_age < .56 and scene.modal_title != "PRINCESS SAVED!", "Mid-collapse precedes results"): return
	await checkpoint("05-dragon-collapse-midframe")
	if not await wait_for(func(): return scene.modal_title == "PRINCESS SAVED!", 2.0, "Real delayed result opens"): return
	if not check(collapse_seen and collapse_finished and is_equal_approx(scene.fx.DRAGON_DEFEAT_DURATION, .56), "Full authored 0.56-second collapse completed"): return
	phase = "result"
	await checkpoint("06-natural-victory-result")
	await hold(1.5)
	if not modal_tap("Button_NEXT LEVEL"): return
	if not await wait_for(func(): return current_scene != scene, 2.0, "Next Level creates actual replacement scene"): return
	scene = current_scene
	wire_audio(scene)
	phase = "real-next-level"
	await hold(.25)
	if not check(scene.level_config.level_id == "campaign-02" and scene.level_index == 2 and scene.rules.status == "ready" and scene.rules.time_us == 0, "Next Level loads real campaign-02 at fresh time zero"): return
	if not check(scene.profile_directory == resolved_profile and not scene.qa_fixture_mode and not scene.auto_replay and scene.profile_state.music_volume == 65 and scene.profile_state.sfx_volume == 60, "Replacement retains isolated genuine save and volumes"): return
	await checkpoint("07-real-campaign-02")
	await hold(1.0)
	if not tap("TopHUD/PauseButton"): return
	await hold(.4)
	if not modal_tap("Button_LEVEL SELECT"): return
	await hold(.4)
	if not check(scene.modal_title == "LEAVE THIS LEVEL?", "Pause selector has real leave confirmation"): return
	if not modal_tap("Button_LEVEL SELECT"): return
	await hold(.25)
	phase = "genuine-unlocked-selector"
	var unlocked: Array = scene.profile_state.levels.filter(func(entry): return entry.unlocked)
	if not check(scene.modal_title == "CHOOSE A LEVEL" and unlocked.size() == 2 and unlocked[0].level_id == "campaign-01" and unlocked[1].level_id == "campaign-02", "Exactly first two levels naturally unlocked"): return
	for number in range(1, 11):
		if not check(scene.pause_overlay.get_node("LevelButton%d" % number).disabled == (number > 2), "Visible level tile lock state " + str(number)): return
	await checkpoint("08-only-first-two-unlocked")
	await hold(2.0)
	check(clock_node.seconds >= 25.0 and clock_node.seconds <= 35.0, "Uncut journey lasts 25–35 engine seconds")
	check(logic_only or screenshot_ids.size() == 8, "All eight requested real screenshots captured, unless explicitly logic-only")
	journey_completed = true

func hash_tree(path: String) -> void:
	for filename in DirAccess.get_files_at(path):
		if filename.ends_with(".import") or filename.ends_with(".uid"): continue
		var file_path := path.path_join(filename)
		source_hashes[file_path] = FileAccess.get_sha256(file_path)
	for directory in DirAccess.get_directories_at(path):
		hash_tree(path.path_join(directory))

func abort(reason: String) -> void:
	if finished: return
	check(false, reason)
	finish()

func write_json(filename: String, data: Variant) -> void:
	var file := FileAccess.open(evidence.path_join(filename), FileAccess.WRITE)
	if file == null:
		failures.append("Cannot write " + filename); return
	file.store_string(JSON.stringify(data, "\t") + "\n")
	file.close()

func finish() -> void:
	if finished: return
	finished = true
	check(journey_completed, "Journey reached every required final step without premature exit")
	for directory in ["res://scripts", "res://assets", "res://data/campaign-drafts"]:
		hash_tree(directory)
	for path in ["res://project.godot", "res://scenes/play.tscn", "res://tests/capture_complete_journey.gd"]:
		source_hashes[path] = FileAccess.get_sha256(path)
	write_json("complete-journey-state-observations.json", observations)
	write_json("complete-journey-source-sha256.json", source_hashes)
	var report := {"pass": failures.is_empty(), "checks": checks, "failures": failures,
		"engine": Engine.get_version_info().string, "display_driver": DisplayServer.get_name(),
		"audio_driver": AudioServer.get_driver_name(), "logic_only": logic_only,
		"graphical_capture": "NOT_RUN" if logic_only else "REAL_ENGINE_FRAMEBUFFER",
		"human_playtest": "NOT_RUN", "human_listening": "NOT_RUN", "visual_acceptance": "NOT_RUN",
		"scope": "One uncut automated viewport-input journey. Native scene _process advances all gameplay; read-only state observation, no rules stepping, no QA unlocks, no forced victory, no auto-replay, no configuration mutation.",
		"time_basis": "Engine process delta, requested --fixed-fps 24; never wall-clock intervals. Source audio cooldowns are unmodified and remain wall-clock based; played/dropped cues are reported, not treated as listening acceptance.",
		"profile": resolved_profile, "fresh_isolated_root": isolated_root, "player_profile_touched": false,
		"movie_seconds": clock_node.seconds if is_instance_valid(clock_node) else 0.0,
		"frames": clock_node.frames if is_instance_valid(clock_node) else 0,
		"viewport": [1440, 2560], "initial_state": initial_state, "terminal_state": terminal_state,
		"final_event_time_us": terminal_state.get("terminal_time_us", -1), "selected_front_inputs": selected,
		"inputs": actions, "checkpoints": checkpoints, "audio_cues": cues,
		"real_projectiles": seen_projectiles, "unique_carriers_observed": lifecycles.size(),
		"observation_limit": "Snapshots observe state after native processing. Scheduled carrier/projectile times are copied from real tasks; this is not an intercepted raw rule-event stream.",
		"collapse_observed": collapse_seen, "collapse_completed": collapse_finished,
		"source_sha256_manifest": "complete-journey-source-sha256.json",
		"observation_trace": "complete-journey-state-observations.json",
		"save_sha256": FileAccess.get_sha256(resolved_profile.path_join("save.json")) if not resolved_profile.is_empty() else ""}
	write_json("complete-journey-report.json", report)
	print("COMPLETE_JOURNEY ", JSON.stringify({"pass": failures.is_empty(), "checks": checks, "failures": failures,
		"movie_seconds": report.movie_seconds, "final_event_time_us": report.final_event_time_us,
		"selected_inputs": selected.size(), "logic_only": logic_only, "report": evidence.path_join("complete-journey-report.json")}))
	call_deferred("shutdown")

func shutdown() -> void:
	# Exit outside the clock signal stack, after scene/audio resources are released.
	if is_instance_valid(scene): scene.queue_free()
	if is_instance_valid(clock_node): clock_node.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
