extends SceneTree
## Finite separate-process checks. Caller supplies a unique ANT_RESCUE_PROFILE_DIR.
const Saves=preload("res://scripts/save_service.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var path:=OS.get_environment("ANT_RESCUE_PROFILE_DIR")
	assert(path.begins_with("/tmp/ant-rescue-"))
	var mode:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--probe="):mode=arg.trim_prefix("--probe=")
	var store:=Saves.new(path)
	if mode=="seed":
		assert(store.load_save().ok);assert(store.set_tutorial_completed(true).ok)
		assert(store.mark_complete("validation-01","cli-test").ok)
		assert(store.set_current_entrance("validation-02").ok)
		assert(store.set_volumes(0,36).ok)
	else:
		if mode=="auto-isolation":assert(store.load_save().ok)
		var before:=FileAccess.get_file_as_bytes(path+"/save.json") if FileAccess.file_exists(path+"/save.json") else PackedByteArray()
		var scene=load("res://scenes/play.tscn").instantiate();root.add_child(scene);scene.set_process(false)
		if mode=="restart":
			assert(scene.level_index==2 and scene.rules.status=="ready" and scene.rules.time_us==0)
			assert(scene.rules.tasks.is_empty() and scene.rules.projectile.is_empty() and scene.rules.inventory.values().all(func(value):return value==0))
			assert(scene.audio_visual_state.music==0 and scene.audio_visual_state.sound==36 and not is_instance_valid(scene.pause_overlay))
			assert(FileAccess.get_file_as_bytes(path+"/save.json")==before)
		elif mode=="locked-level":
			assert(scene.level_index==1 and scene.profile_state.available_unlocked==1)
			assert(scene.modal_title=="YOUR FIRST RESCUE")
		elif mode=="auto-isolation":
			assert(scene.profile_directory!=path and scene.profile_directory.begins_with("/tmp/ant-rescue-replay-"))
			assert(scene.level_index==3 and scene.auto_replay and not is_instance_valid(scene.pause_overlay))
			assert(FileAccess.get_file_as_bytes(path+"/save.json")==before)
		else:assert(false,"Unknown probe")
		await create_timer(.2).timeout
		scene.queue_free();await process_frame
	print("PLAY_PROFILE_CLI_PASS ",mode)
	await create_timer(.25).timeout
	quit()
