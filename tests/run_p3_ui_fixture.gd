extends SceneTree
## Manual/graphical QA launcher. Never a normal campaign entrypoint.
func _initialize()->void:call_deferred("run")
func run()->void:
	var scene=load("res://scenes/play.tscn").instantiate()
	scene.profile_directory="/tmp/ant-rescue-manual-qa-%d-%d"%[OS.get_process_id(),Time.get_ticks_usec()]
	scene.qa_fixture_mode=true;scene.use_command_line_level=false
	var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/validation-01.json"))
	config.content_version=str(config.content_version)+"-qa-tool-unlocks"
	config.tools=[]
	for id in ["extra_slot","shuffle","recall","scout"]:config.tools.append({"id":id,"unlock_level":1,"uses_per_level":1})
	# Optional tiny fixture has a fast, deterministic verified shuffle winner.
	if "--tiny-tools" in OS.get_cmdline_user_args():config=load("res://tests/p3_fixture.gd").config()
	scene.qa_level_config=config;root.add_child(scene);current_scene=scene
	print("P3_QA_ONLY profile=",scene.profile_directory," production_level_number=",str(config.production_level_number))
