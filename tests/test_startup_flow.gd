extends SceneTree
## Bounded startup/navigation integration, not a campaign replay or visual review.
## Every save and fault fixture is isolated; normal routes use the actual entry scene.
const Saves = preload("res://scripts/save_service.gd")
const Catalog = preload("res://scripts/level_catalog.gd")
const STARTUP := "res://scenes/startup.tscn"
const PLAY_SCRIPT := "res://scripts/play.gd"
const TIMEOUT_MS := 10000

# A real missing resource extends only this test's home manifest. Production assets
# are never moved, corrupted or replaced; repair exercises the real Retry button.
class RecoverableStartup:
	extends "res://scripts/startup.gd"
	var fixture_resource := ""
	func begin_home_load() -> void:
		phase = "loading"
		batch = "home"
		record_event("resource_batch_requested")
		var paths: Array[String] = HOME_RESOURCES.duplicate()
		paths.append(AudioService.BGM_PATH)
		for path in AudioService.SFX_PATHS.values():
			paths.append(str(path))
		paths.append(fixture_resource)
		loader.start(paths)

var checks := 0
var failures: Array[String] = []
var directories: Array[String] = []
var fixtures: Array[String] = []
var observed_boots: Array[Array] = []
var play_entries := 0
var cases: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func directory(label: String) -> String:
	var path := "/tmp/ant-rescue-startup-flow-%d-%d-%s" % [OS.get_process_id(), Time.get_ticks_usec(), label]
	directories.append(path)
	return path


func saved_bytes(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path.path_join("save.json"))


func observe_node(node: Node) -> void:
	if node.has_method("handover_game"):
		node.ready.connect(func(): observed_boots.append(node.boot_events))
	elif node.get_script() != null and node.get_script().resource_path == PLAY_SCRIPT:
		node.ready.connect(func():
			# Navigation does not need to run the simulation or auto-replay in idle.
			# The existing gameplay suites own correctness of the rule simulation.
			node.set_process(false)
			play_entries += 1)


func make_home(path: String, campaign := false, fault_resource := "") -> Control:
	var scene = load(STARTUP).instantiate()
	if not fault_resource.is_empty():
		scene.set_script(RecoverableStartup)
		scene.fixture_resource = fault_resource
	scene.profile_directory = path
	scene.campaign_drafts = campaign
	scene.use_command_line_catalog = false
	root.add_child(scene)
	current_scene = scene
	return scene


func until(predicate: Callable, message: String) -> bool:
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	var reached: bool = predicate.call()
	check(reached, message)
	return reached


func wait_home(scene: Control) -> bool:
	return await until(func() -> bool:
		return is_instance_valid(scene) and scene.phase == "home" and scene.home_ready,
		"The real home batch reaches Home within the bounded deadline")


func wait_play() -> Control:
	var reached := await until(func() -> bool:
		return is_instance_valid(current_scene) and current_scene.get_script() != null \
			and current_scene.get_script().resource_path == PLAY_SCRIPT and current_scene.is_node_ready(),
		"The loader hands over to one ready actual play scene within the deadline")
	return current_scene as Control if reached else null


func press(owner: Node, path: String) -> bool:
	var button := owner.get_node_or_null(path) as Button
	check(button != null, "Action exists: " + path)
	if button == null:
		return false
	check(not button.disabled, "Action is available: " + path)
	if button.disabled:
		return false
	button.pressed.emit()
	return true


func event_count(events: Array, event: String) -> int:
	return events.filter(func(row: Dictionary) -> bool: return row.event == event).size()


func check_handover(events: Array, context: String) -> void:
	var names: Array = events.map(func(row: Dictionary) -> String: return row.event)
	check(names.find("home_ready") >= 0 and names.find("home_ready") < names.find("play_requested"), context + ": Home resources precede the Play request")
	check(event_count(events, "game_handover") == 1, context + ": exactly one game handover")
	var game_loaded := -1
	for index in range(events.size()):
		if events[index].event == "resource_batch_loaded" and events[index].batch == "game":
			game_loaded = index
	check(game_loaded >= 0 and game_loaded < names.find("game_handover"), context + ": actual game-resource completion precedes handover")


func check_fresh(scene: Control, context: String) -> void:
	check(scene.ready_to_simulate and scene.rules.status == "ready" and scene.rules.time_us == 0, context + ": round begins ready at time zero")
	check(scene.rules.tasks.is_empty() and scene.rules.reservations.is_empty() and scene.rules.projectile.is_empty(), context + ": no in-progress carriers, reservations or projectile are restored")
	check(scene.rules.inventory.values().all(func(value): return value == 0), context + ": no ammunition is invented")
	check(scene.rules.conservation_errors().is_empty(), context + ": initial resources are conserved")


func drop_current() -> void:
	if is_instance_valid(current_scene):
		current_scene.queue_free()
	await process_frame
	await process_frame


func remove_directory(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for child in DirAccess.get_directories_at(path):
		remove_directory(path.path_join(child))
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)


func run() -> void:
	root.size = Vector2i(1440, 2560)
	node_added.connect(observe_node)
	check(ProjectSettings.get_setting("application/run/main_scene") == STARTUP, "The configured production entry is the startup scene")
	var replay_probe := "--probe=startup-replay" in OS.get_cmdline_user_args()
	if replay_probe:
		await test_replay_cli_profile()
	else:
		await test_first_play_and_duplicate_launch()
		await test_home_level_picker_close()
		await test_saved_entrance_and_home_cancel()
		await test_catalog_isolation()
		await test_retry_and_next(false)
		await test_retry_and_next(true)
		await test_home_resource_recovery()
		await test_game_resource_recovery()
	await drop_current()
	for path in fixtures:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in directories:
		remove_directory(path)
	# This shared presentation cache intentionally survives scene changes. Release
	# only its retained atlases at test shutdown, not between the tested handovers.
	load("res://scripts/bead.gd").textures.clear()
	var report := {
		"pass": failures.is_empty(), "assertions": checks, "failures": failures,
		"cases": cases, "boot_instances": observed_boots.size(), "play_entries": play_entries,
		"probe": "replay_cli" if replay_probe else "normal",
		"human_playtest": "NOT_RUN", "visual_acceptance": "NOT_RUN", "audio_acceptance": "NOT_RUN",
		"scope": "Actual CLI replay startup and Retry preserve one temporary profile, chosen catalog/level and QA identity without changing either normal catalog's save bytes. Simulation is disabled; no actual replay is claimed." if replay_probe else "Bounded real startup/Home/Play/tutorial/level-picker navigation, fresh saved entrances, validation/campaign profile isolation, Retry/Next through the loader, duplicate guards and missing-resource repair. Outcome navigation uses seeded save records and explicit terminal-state fixtures, not gameplay victory claims. One game-load failure is injected at the loader boundary; Home failure uses a real missing local resource. No 30-level scan or campaign replay.",
	}
	print("STARTUP_FLOW_REPORT ", JSON.stringify(report))
	# Let the headless native audio thread observe disposals before process exit.
	await create_timer(.25).timeout
	quit(0 if failures.is_empty() else 1)


func test_first_play_and_duplicate_launch() -> void:
	cases.append("first_play_duplicate_guard")
	var path := directory("first")
	var home := make_home(path)
	check(home.phase == "splash" and not home.home_ready and not home.launch_pending, "Cold entry exposes the splash before resource polling")
	home.launch_game()
	check(not home.launch_pending, "Play cannot launch before Home resources are ready")
	if not await wait_home(home):
		await drop_current()
		return
	check(not home.has_node("Mosaic") and not home.has_node("CandidateQueues"), "Home does not construct the game board before Play")
	check(home.loader.state == home.loader.State.COMPLETED and home.progress_bar.value == 1.0, "Home readiness reflects the actual completed resource batch")
	check(not home.loading_layer.visible and home.home_art.visible, "Home replaces the loading surface")
	check(not home.profile_state.tutorial_completed, "Home does not pre-complete the first tutorial")
	var original := saved_bytes(path)
	var events: Array = home.boot_events
	var before_entries := play_entries
	press(home, "HomeArtwork/PlayButton")
	var request_id: int = home.loader.request_id
	check(home.phase == "loading" and home.launch_pending and home.loading_layer.visible, "Play immediately activates the loading surface and pending guard")
	press(home, "HomeArtwork/PlayButton")
	press(home, "HomeArtwork/LevelsButton")
	check(home.loader.request_id == request_id and home.entry_screen.is_empty(), "Repeated Play/Levels cannot replace or duplicate the active launch")
	check(event_count(events, "play_requested") == 1, "Duplicate presses produce one Play request")
	var play := await wait_play()
	if play != null:
		check(play_entries == before_entries + 1, "Duplicate presses create exactly one game instance")
		check(play.modal_title == "YOUR FIRST RESCUE" and play.rules.paused, "Normal Home Play enters the existing first tutorial paused")
		check(play.from_startup and not play.qa_fixture_mode and not play.auto_replay, "Normal Play stays outside QA/replay shortcuts")
		check(play.profile_directory == path and play.level_config.level_id == "validation-01", "Normal Play preserves the validation profile and first entrance")
		check(saved_bytes(path) == original and not play.profile_state.tutorial_completed, "Opening the first tutorial does not mutate saved progress")
		check_fresh(play, "First Play")
		check_handover(events, "First Play")
		press(play.pause_overlay, "Button_LET'S GO")
		check(play.profile_state.tutorial_completed and not play.rules.paused, "Only the explicit tutorial action persists completion and resumes observation")
		check(play.rules.time_us == 0 and play.rules.status == "ready", "Accepting the tutorial does not start threat time")
	await drop_current()


func test_home_level_picker_close() -> void:
	cases.append("home_levels_close_preserves_tutorial")
	var path := directory("levels")
	var home := make_home(path)
	if not await wait_home(home):
		await drop_current()
		return
	var original := saved_bytes(path)
	press(home, "HomeArtwork/LevelsButton")
	var play := await wait_play()
	if play == null:
		await drop_current()
		return
	check(play.chooser_from_home and play.modal_title == "CHOOSE A LEVEL" and play.rules.paused, "Home Levels opens the existing paused level picker")
	check(not play.pause_overlay.get_node("LevelButton1").disabled and play.pause_overlay.get_node("LevelButton2").disabled, "Home picker preserves genuine saved unlocks")
	check(not play.profile_state.tutorial_completed and saved_bytes(path) == original, "Replacing the tutorial with Home's picker never marks the tutorial complete")
	play.close_current_modal()
	check(is_instance_valid(current_scene) and current_scene.has_method("handover_game") and current_scene.start_mode == "home", "Picker Close returns through the real startup shell, not to an un-taught round")
	home = current_scene as Control
	if await wait_home(home):
		check(home.profile_directory == path and not home.profile_state.tutorial_completed and saved_bytes(path) == original, "Picker Close restores Home without changing tutorial or entrance bytes")
		check(not home.launch_pending and home.entry_screen.is_empty(), "Returning Home clears the old picker/launch intent")
		press(home, "HomeArtwork/PlayButton")
		play = await wait_play()
		if play != null:
			check(play.modal_title == "YOUR FIRST RESCUE" and not play.chooser_from_home, "A later normal Play still shows the first tutorial rather than the picker")
	await drop_current()


func test_saved_entrance_and_home_cancel() -> void:
	cases.append("saved_fresh_round_and_home_cancel")
	var path := directory("saved")
	var seed := Saves.new(path)
	check(seed.load_save().ok and seed.set_tutorial_completed(true).ok, "Saved-profile fixture initializes")
	check(seed.mark_complete("validation-01", "startup-flow-fixture").ok and seed.set_current_entrance("validation-02").ok, "Saved-profile fixture selects an unlocked existing entrance")
	check(seed.set_volumes(21, 43).ok, "Saved-profile fixture has distinct persisted audio settings")
	var original := saved_bytes(path)
	var home := make_home(path)
	if not await wait_home(home):
		await drop_current()
		return
	check(home.get_node("HomeArtwork/SavedEntrance").text == "LEVEL 2", "Home identifies the actual saved entrance")
	check(home.get_node("HomeArtwork/ResumeMeaning").text.contains("FRESH ROUND"), "Home does not promise mid-round restoration")
	press(home, "HomeArtwork/PlayButton")
	var play := await wait_play()
	if play == null:
		await drop_current()
		return
	check(play.level_index == 2 and play.level_config.level_id == "validation-02", "Saved entrance selects level two without unlocking anything else")
	check(play.audio_visual_state.music == 21 and play.audio_visual_state.sound == 43, "Saved audio settings survive both Home and Play")
	check(play.has_node("RoundRestartNotice") and not is_instance_valid(play.pause_overlay), "Saved entrance presents the nonmodal fresh-round notice, not the tutorial")
	check_fresh(play, "Saved Play")
	check(saved_bytes(path) == original, "Loading an existing entrance leaves committed save bytes unchanged")
	var first_id := str(play.rules.columns[0].teams[0].id)
	check(play.preview_select_front(0, first_id), "One actual team selection starts a round for the Home-cancel probe")
	play.rules.update_us(100000)
	var before: Dictionary = play.rules.snapshot()
	play.request_home()
	check(current_scene == play and play.modal_title == "LEAVE THIS LEVEL?" and play.rules.paused, "Leaving a running round asks through the existing confirmation modal")
	press(play.pause_overlay, "Button_CANCEL")
	check(current_scene == play and play.modal_title == "PAUSED" and not play.replacement_pending, "Cancel keeps the current round and does not schedule a replacement")
	check(play.rules.time_us == before.time_us and play.rules.board == before.board and play.rules.tasks == before.tasks, "Cancel keeps elapsed time, board and active carrier tasks")
	play.request_home()
	press(play.pause_overlay, "Button_HOME")
	home = current_scene as Control
	if await wait_home(home):
		press(home, "HomeArtwork/PlayButton")
		play = await wait_play()
		if play != null:
			check_fresh(play, "Return Home then Play")
			check(play.level_index == 2 and saved_bytes(path) == original, "Confirmed Home discards only the running round, retaining entrance and completion bytes")
	await drop_current()


func test_catalog_isolation() -> void:
	cases.append("validation_campaign_save_isolation")
	var base := directory("isolation")
	var seed := Saves.new(base)
	check(seed.load_save().ok and seed.set_tutorial_completed(true).ok, "Validation isolation fixture initializes")
	check(seed.mark_complete("validation-01", "startup-flow-fixture").ok and seed.set_current_entrance("validation-02").ok, "Validation isolation fixture retains its own second entrance")
	var validation_bytes := saved_bytes(base)
	var home := make_home(base, true)
	if not await wait_home(home):
		await drop_current()
		return
	var campaign_path := base.path_join("campaign-drafts")
	check(home.campaign_drafts and home.profile_directory == campaign_path, "Campaign Home resolves the distinct child profile exactly once")
	check(home.has_node("HomeArtwork/CatalogIdentity") and home.profile_state.resume_level_id == "campaign-01", "Campaign Home truthfully identifies the preview and its independent entrance")
	press(home, "HomeArtwork/PlayButton")
	var play := await wait_play()
	if play != null:
		check(play.campaign_drafts and play.profile_directory == campaign_path and play.level_ids.size() == 30, "Campaign mode and resolved profile survive Home handover without double nesting")
		check(play.level_config.level_id == "campaign-01" and play.level_config.production_level_number == null, "Campaign handover does not promote draft source identity")
		check(play.modal_title == "YOUR FIRST RESCUE" and not play.profile_state.tutorial_completed, "Campaign tutorial is independent of the completed validation tutorial")
		press(play.pause_overlay, "Button_LET'S GO")
		check(saved_bytes(base) == validation_bytes, "Campaign initialization and tutorial cannot modify validation save bytes")
	await drop_current()
	var campaign_bytes := saved_bytes(campaign_path)
	home = make_home(base)
	if await wait_home(home):
		press(home, "HomeArtwork/PlayButton")
		play = await wait_play()
		if play != null:
			check(not play.campaign_drafts and play.profile_directory == base and play.level_index == 2 and play.level_ids.size() == 3, "Default Home still restores the separate three-level validation catalog")
			check(saved_bytes(campaign_path) == campaign_bytes and saved_bytes(base) == validation_bytes, "Returning to validation changes neither catalog's committed bytes")
	await drop_current()


func test_retry_and_next(campaign: bool) -> void:
	var label := "campaign" if campaign else "validation"
	cases.append(label + "_retry_next_loader")
	var base := directory(label + "-navigation")
	var path := Catalog.profile_path(base, campaign)
	var ids := Catalog.level_ids(campaign)
	var seed := Saves.new(path, ids, 30)
	check(seed.load_save().ok and seed.set_tutorial_completed(true).ok and seed.mark_complete(ids[0], "startup-navigation-fixture").ok, label + ": seed only the prerequisite completion, not a claimed gameplay replay")
	check(seed.set_volumes(32, 54).ok, label + ": navigation fixture stores independent settings")
	var home := make_home(base, campaign)
	if not await wait_home(home):
		await drop_current()
		return
	press(home, "HomeArtwork/PlayButton")
	var play := await wait_play()
	if play == null:
		await drop_current()
		return
	# Explicit terminal-state fixtures exercise actual outcome buttons, not combat.
	play.rules.status = "defeat"
	play.show_outcome(false)
	var before_run: int = play.rules.run_id
	var before_entries := play_entries
	press(play.pause_overlay, "Button_RETRY")
	home = current_scene as Control
	check(home.has_method("handover_game") and home.start_mode == "play", label + ": Retry enters the startup loader, never directly swaps a play scene")
	check(home.profile_directory_resolved and home.profile_directory == path and home.campaign_drafts == campaign, label + ": Retry carries the exact resolved profile and catalog")
	var events: Array = home.boot_events
	play.replace_level(1)
	check(current_scene == home, label + ": repeated old-scene replacement cannot create another loader")
	play = await wait_play()
	if play == null:
		await drop_current()
		return
	check(play_entries == before_entries + 1 and play.rules.run_id != before_run, label + ": Retry creates exactly one new run")
	check(play.profile_directory == path and play.campaign_drafts == campaign and play.level_index == 1, label + ": Retry keeps mode and level")
	check_fresh(play, label + " Retry")
	check_handover(events, label + " Retry")
	play.rules.status = "victory"
	play.victory_saved = true
	play.show_outcome(true)
	press(play.pause_overlay, "Button_NEXT LEVEL")
	home = current_scene as Control
	check(home.has_method("handover_game") and home.start_mode == "play", label + ": Next enters the startup loader")
	check(home.profile_directory == path and home.campaign_drafts == campaign, label + ": Next preserves exact profile and mode")
	events = home.boot_events
	play = await wait_play()
	if play != null:
		check(play.level_index == 2 and play.level_config.level_id == ids[1] and play.profile_state.resume_level_id == ids[1], label + ": Next uses the genuinely unlocked second entrance")
		check(play.profile_directory == path and play.campaign_drafts == campaign and play.audio_visual_state.music == 32 and play.audio_visual_state.sound == 54, label + ": Next preserves catalog, resolved profile and settings")
		check(play.profile_state.tutorial_completed and play.profile_state.available_unlocked == 2 and play.profile_state.completed_levels.size() == 1, label + ": navigation does not invent further completions or unlocks")
		check_fresh(play, label + " Next")
		check_handover(events, label + " Next")
	await drop_current()


func test_home_resource_recovery() -> void:
	cases.append("real_missing_home_resource_repair")
	var path := directory("resource-recovery")
	var missing := "user://startup_flow_missing_%d_%d.tres" % [OS.get_process_id(), Time.get_ticks_usec()]
	fixtures.append(missing)
	var home := make_home(path, false, missing)
	if not await until(func() -> bool: return home.phase == "error", "A real missing local resource reaches the startup error surface"):
		await drop_current()
		return
	check(not home.home_ready and not home.has_node("HomeArtwork") and not home.launch_pending, "Failed Home resource loading never constructs a fake Home or play scene")
	check(home.loader.state == home.loader.State.FAILED and home.loader.last_error.path == missing, "Error surface retains the actual missing resource diagnostic")
	check(home.loading_layer.visible and not home.progress_bar.visible and home.loading_layer.has_node("RetryButton"), "Missing resources leave a visible retryable error, not an infinite progress bar")
	var original := saved_bytes(path)
	var request: int = home.loader.request_id
	press(home, "LoadingLayer/RetryButton")
	await process_frame
	check(home.phase == "error" and home.loader.request_id == request + 1 and home.loading_layer.find_children("RetryButton", "Button", false, false).size() == 1, "Retry while the resource is still absent fails once and keeps one retry control")
	check(saved_bytes(path) == original, "Repeated resource failure cannot reset saved progress")
	var file := FileAccess.open(missing, FileAccess.WRITE)
	check(file != null, "The isolated missing-resource fixture can be repaired")
	if file == null:
		await drop_current()
		return
	file.store_string("[gd_resource type=\"Resource\" format=3]\n\n[resource]\nresource_name = \"Startup flow repaired fixture\"\n")
	file.close()
	press(home, "LoadingLayer/RetryButton")
	if await wait_home(home):
		check(home.loader.last_error.is_empty() and home.loader.get_resource(missing) != null, "Retry actually loads the repaired file and clears its diagnostic")
		check(home.progress_bar.visible and not home.loading_layer.visible and saved_bytes(path) == original, "Successful retry restores Home without a reset or misleading loading surface")
		var events: Array = home.boot_events
		press(home, "HomeArtwork/PlayButton")
		var play := await wait_play()
		if play != null:
			check(play.modal_title == "YOUR FIRST RESCUE" and play.profile_directory == path, "A repaired Home can enter the genuine first tutorial")
			check_handover(events, "Repaired Home")
	await drop_current()


func test_game_resource_recovery() -> void:
	cases.append("injected_game_load_failure_retry")
	var path := directory("game-recovery")
	var home := make_home(path)
	if not await wait_home(home):
		await drop_current()
		return
	var original := saved_bytes(path)
	var before_entries := play_entries
	var events: Array = home.boot_events
	press(home, "HomeArtwork/LevelsButton")
	# Inject before a native request is issued, so there is no abandoned native job.
	check(home.loader._active_path.is_empty(), "Game-load failure probe is injected before any native token is outstanding")
	home.loader._fail(home.loader.request_id, "res://scenes/play.tscn", "request", ERR_CANT_OPEN, "Explicit integration-test boundary fault")
	check(home.phase == "error" and home.launch_pending and current_scene == home and play_entries == before_entries, "Failed game-resource loading never hands over a partial scene")
	var request: int = home.loader.request_id
	home.launch_game("")
	check(home.loader.request_id == request and home.entry_screen == "levels", "A fresh launch cannot bypass the failed request or overwrite its Levels intent")
	press(home, "LoadingLayer/RetryButton")
	check(home.phase == "loading" and home.progress_bar.visible, "Game retry uses the same real loading surface")
	var play := await wait_play()
	if play != null:
		check(play_entries == before_entries + 1 and play.modal_title == "CHOOSE A LEVEL" and play.chooser_from_home, "Successful game retry creates one scene and retains the original Levels destination")
		check(play.profile_directory == path and not play.profile_state.tutorial_completed and saved_bytes(path) == original, "Game retry retains the profile without falsely completing the tutorial")
		check_handover(events, "Game resource retry")
	await drop_current()


func test_replay_cli_profile() -> void:
	cases.append("cli_replay_profile_survives_loader")
	var args := OS.get_cmdline_user_args()
	check("--auto-replay" in args, "The CLI replay probe requires the actual --auto-replay option")
	if not "--auto-replay" in args:
		return
	var campaign := "--campaign-drafts" in args
	var ids := Catalog.level_ids(campaign)
	var requested := 1
	for arg in args:
		if arg.begins_with("--level="):
			requested = clampi(int(arg.trim_prefix("--level=")), 1, ids.size())
	var base := directory("replay-cli-normal")
	var validation_seed := Saves.new(base)
	var campaign_path := Catalog.profile_path(base, true)
	var campaign_seed := Saves.new(campaign_path, Catalog.level_ids(true), 30)
	check(validation_seed.load_save().ok and campaign_seed.load_save().ok, "Both normal catalog fixtures exist before CLI replay")
	var validation_bytes := saved_bytes(base)
	var campaign_bytes := saved_bytes(campaign_path)
	var home = load(STARTUP).instantiate()
	home.profile_directory = base
	# Unlike the normal in-process cases, leave actual CLI parsing enabled.
	root.add_child(home)
	current_scene = home
	var replay_path: String = home.profile_directory
	check(replay_path.begins_with("/tmp/ant-rescue-replay-") and replay_path != base and replay_path != campaign_path, "CLI startup selects a distinct temporary replay profile")
	if replay_path.begins_with("/tmp/ant-rescue-replay-"):
		directories.append(replay_path)
	var events: Array = home.boot_events
	var play := await wait_play()
	if play == null:
		await drop_current()
		return
	check(play.profile_directory == replay_path and play.auto_replay and play.qa_fixture_mode, "CLI handover retains the temporary replay profile and explicit QA mode")
	check(play.campaign_drafts == campaign and play.level_index == requested and play.level_config.level_id == ids[requested - 1], "CLI handover retains the selected catalog and requested level")
	check_handover(events, "CLI replay")
	check(saved_bytes(base) == validation_bytes and saved_bytes(campaign_path) == campaign_bytes, "Initial CLI replay cannot write either normal catalog profile")
	var replay_bytes := saved_bytes(replay_path)
	play.rules.status = "defeat"
	play.show_outcome(false)
	press(play.pause_overlay, "Button_RETRY")
	home = current_scene
	check(home.has_method("handover_game") and not home.use_command_line_catalog and home.start_mode == "play", "Replay Retry uses the loader without reparsing cold-entry CLI flags")
	check(home.profile_directory == replay_path and home.auto_replay and home.qa_fixture_mode and home.campaign_drafts == campaign, "Replay Retry does not create a second temporary profile or change mode")
	events = home.boot_events
	play = await wait_play()
	if play != null:
		check(play.profile_directory == replay_path and play.level_index == requested and play.campaign_drafts == campaign, "Retried replay returns to the same selected entrance and profile")
		# QA entrance initialization can reserialize JSON numbers as 1.0 instead
		# of 1. Compare saved meaning here; untouched normal profiles stay exact.
		var before_record: Dictionary = JSON.parse_string(replay_bytes.get_string_from_utf8())
		var after_record: Dictionary = JSON.parse_string(saved_bytes(replay_path).get_string_from_utf8())
		check(play.auto_replay and play.qa_fixture_mode and after_record == before_record, "Replay Retry preserves its existing QA save identity and content")
		check(saved_bytes(base) == validation_bytes and saved_bytes(campaign_path) == campaign_bytes, "Replay Retry leaves both normal catalog profiles byte-identical")
		check_fresh(play, "CLI replay Retry")
		check_handover(events, "CLI replay Retry")
	await drop_current()
