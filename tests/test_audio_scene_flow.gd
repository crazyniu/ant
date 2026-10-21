extends SceneTree
## Bounded real-scene audio lifecycle checks, not a full level replay.
const AudioService = preload("res://scripts/audio_service.gd")
var checks := 0
var failures: Array[String] = []
var states: Array[Dictionary] = []
var profile := ""

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func wait_for_scene(script_path: String, home := false) -> Node:
	var deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		var node := current_scene
		if is_instance_valid(node) and node.get_script().resource_path == script_path:
			if not home or node.home_ready:
				return node
		await process_frame
	check(false, "Scene/audio lifecycle reaches " + script_path)
	return null

func note(scene: Node, label: String, ducked: bool, muted := false) -> void:
	var status: Dictionary = scene.audio_service.get_status()
	var count := root.find_children("AudioService", "Node", true, false).size()
	check(count == 1, "One music service after " + label)
	check(status.load_errors.is_empty(), "All audio resources exist at " + label)
	check(not status.music_paused, "Foreground music transport is not suspended at " + label)
	check(status.music_ducked == ducked, "Correct modal gain policy at " + label)
	check(status.music_muted == muted, "Saved mute policy is respected at " + label)
	states.append({"state": label, "services": count, "audio": status})

func music_advances(scene: Node, label: String) -> void:
	var before: float = scene.audio_service.get_status().music_position
	await create_timer(.2).timeout
	check(scene.audio_service.get_status().music_position > before + .03, "Real BGM transport advances during " + label)

func run() -> void:
	root.size = Vector2i(1440, 2560)
	profile = "/tmp/ant-rescue-audio-flow-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var startup = load("res://scenes/startup.tscn").instantiate()
	startup.use_command_line_catalog = false
	startup.profile_directory = profile
	startup.profile_directory_resolved = true
	root.add_child(startup); current_scene = startup
	check(not is_instance_valid(startup.audio_service), "Boot shell does not reference audio before threaded load finishes")
	startup = await wait_for_scene("res://scripts/startup.gd", true)
	if startup == null: quit(1); return
	note(startup, "home", false)
	await music_advances(startup, "home")
	startup.launch_game("")
	note(startup, "game-loading", false)
	var scene = await wait_for_scene("res://scripts/play.gd")
	if scene == null: quit(1); return
	await process_frame
	check(scene.modal_title == "YOUR FIRST RESCUE" and scene.rules.paused, "First-load tutorial still freezes gameplay")
	note(scene, "tutorial", true)
	await music_advances(scene, "tutorial")
	scene.finish_tutorial()
	note(scene, "play", false)
	scene.show_pause()
	note(scene, "pause", true)
	var paused_rule_time: int = scene.rules.time_us
	await music_advances(scene, "pause")
	check(scene.rules.time_us == paused_rule_time and scene.rules.paused, "Ducked music never resumes paused gameplay")
	scene.show_settings()
	note(scene, "settings", false)
	check(scene.audio_service.get_status().music_preview, "Settings explicitly uses normal audition level")
	scene.pause_overlay.get_node("MusicVolume").value = 0
	scene.pause_overlay.get_node("MusicVolume").drag_ended.emit(true)
	check(scene.profile_state.music_volume == 0, "Zero music is actually saved")
	scene.close_current_modal()
	note(scene, "settings-close-zero", true, true)
	scene.return_home()
	startup = await wait_for_scene("res://scripts/startup.gd", true)
	if startup == null: quit(1); return
	await process_frame
	note(startup, "home-saved-zero", false, true)
	check(startup.audio_service.music_volume == 0, "Home does not restore a saved-zero setting to default")
	startup.launch_game("")
	scene = await wait_for_scene("res://scripts/play.gd")
	if scene == null: quit(1); return
	await process_frame
	note(scene, "play-saved-zero", false, true)
	scene.show_settings()
	scene.pause_overlay.get_node("MusicVolume").value = 70
	scene.pause_overlay.get_node("MusicVolume").drag_ended.emit(true)
	scene.close_current_modal(); scene.dismiss_modal()
	note(scene, "play-restored-by-user-slider", false)
	# Presentation-only outcome probe. No final hit, completion or unlock is
	# manufactured: this tests the modal's audio policy, not a won level.
	scene.show_outcome(false)
	note(scene, "retry-modal-presentation-only", true)
	await music_advances(scene, "retry-modal-presentation-only")
	scene.pause_overlay.get_node("Button_RETRY").pressed.emit()
	scene = await wait_for_scene("res://scripts/play.gd")
	if scene == null: quit(1); return
	await process_frame
	note(scene, "retry-new-scene", false)
	check(scene.audio_service.music_volume == .7, "Retry preserves the player's new positive setting")
	scene.show_outcome(true)
	note(scene, "victory-modal-presentation-only", true)
	await music_advances(scene, "victory-modal-presentation-only")
	var report := {"pass": failures.is_empty(), "assertions": checks, "failures": failures,
		"states": states, "audio_driver": AudioServer.get_driver_name(),
		"scope": "Real startup/home/threaded play load/tutorial/pause/settings/saved-zero/home/retry audio state and transport. Outcome modals are explicit presentation-only probes, not a gameplay replay or claimed victory.",
		"hardware_output": "NOT_RUN", "human_listening": "NOT_RUN"}
	var out := OS.get_environment("ANT_RESCUE_AUDIO_EVIDENCE_DIR")
	if out.is_empty(): out = "user://audio-mix-evidence"
	DirAccess.make_dir_recursive_absolute(out)
	var file := FileAccess.open(out.path_join("scene-audio-flow.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n"); file.close()
	print("AUDIO_SCENE_FLOW ", JSON.stringify(report))
	scene.queue_free(); current_scene = null
	await process_frame
	await process_frame
	scene = null; startup = null
	await create_timer(.4).timeout
	quit(0 if failures.is_empty() else 1)
