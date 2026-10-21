extends SceneTree
## Observation-only harness. It never selects teams, advances time, solves a
## level, mutates Rules or changes production data. Use native window input.
class InputLog extends Node:
	var game: Control
	var owner_tree: SceneTree
	var inputs: Array = []
	var samples: Array[float] = []
	var finishing := false
	func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			inputs.append({"position": [event.position.x,event.position.y],
				"simulation_us": game.rules.time_us,"modal": game.modal_title,
				"wall_ms": Time.get_ticks_msec()})
	func _process(delta: float) -> void:
		if game.rules.status == "running": samples.append(delta * 1000.0)
		if game.rules.status in ["victory","defeat"] and not finishing:
			finishing = true
			owner_tree.finish()

var game: Control
var observer: InputLog
var evidence := ""

func _initialize() -> void: call_deferred("run")
func run() -> void:
	evidence = OS.get_environment("ANT_RESCUE_EVIDENCE_DIR")
	assert(not evidence.is_empty())
	DirAccess.make_dir_recursive_absolute(evidence)
	game = load("res://scenes/play.tscn").instantiate()
	game.profile_directory = "/tmp/ant-rescue-native-%d" % Time.get_ticks_usec()
	game.use_command_line_level = false
	root.add_child(game)
	current_scene = game
	observer = InputLog.new()
	observer.game = game
	observer.owner_tree = self
	root.add_child(observer)
	print("NATIVE_ONLY_INPUT_READY profile=",game.profile_directory)

func finish() -> void:
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join("native-final-engine.png"))
	observer.samples.sort()
	var metrics := {}
	if not observer.samples.is_empty():
		metrics = {"samples": observer.samples.size(),
			"median_ms": observer.samples[observer.samples.size()/2],
			"p95_ms": observer.samples[mini(observer.samples.size()-1,int(observer.samples.size()*.95))]}
	var report := {"level": game.level_index, "status": game.rules.status,
		"simulation_us": game.rules.time_us, "conservation_errors": game.rules.conservation_errors(),
		"native_pointer_inputs": observer.inputs, "timed_replay": false,
		"automated_solver": false, "operator": "assistant via native cloud window input",
		"human_playtest": false, "frame_time": metrics,
		"profile": game.profile_directory, "saved": game.victory_saved,
		"audio_driver": AudioServer.get_driver_name(), "audio": game.audio_service.get_status()}
	var file := FileAccess.open(evidence.path_join("native-play-report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")); file.close()
	print("NATIVE_ROUND_COMPLETE ", game.rules.status," clicks=",observer.inputs.size())
	await create_timer(1.0).timeout
	quit()
