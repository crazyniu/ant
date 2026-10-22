extends SceneTree
func _initialize()->void:call_deferred("run")
func finish(live:Node,ok:bool)->void:
	live.set_process(false)
	if is_instance_valid(live.get("audio_service")):live.audio_service.stop_music();live.audio_service.stop_all_sfx()
	await create_timer(.4).timeout
	live.queue_free();await process_frame;await create_timer(.15).timeout
	quit(0 if ok else 1)
func run()->void:
	var home=load("res://scenes/startup.tscn").instantiate();home.profile_directory="/tmp/ant-rescue-cli-scope-%d"%Time.get_ticks_usec()
	root.add_child(home);current_scene=home
	var end:=Time.get_ticks_msec()+10000
	while Time.get_ticks_msec()<end:
		await process_frame
		var live=current_scene
		if not is_instance_valid(live):continue
		if live.get_script().resource_path=="res://scripts/play.gd":
			live.set_process(false)
			var ok:bool=live.ready_to_simulate and live.level_index==1 and not live.campaign_drafts and live.level_config.level_id=="serpent-01"
			print("FIRST_LEVEL_CLI ",JSON.stringify({"ok":ok,"args":OS.get_cmdline_user_args(),"entered":"serpent-01" if ok else "blocked-or-invalid"}))
			await finish(live,ok);return
		if live.phase=="home" and "--auto-replay" not in OS.get_cmdline_user_args():
			var ok:bool=live.level_index==1 and not live.campaign_drafts and live.meta_levels().size()==1
			print("FIRST_LEVEL_CLI ",JSON.stringify({"ok":ok,"args":OS.get_cmdline_user_args(),"entered":"home-first-level-only"}))
			await finish(live,ok);return
	push_error("First-level CLI probe timed out");quit(1)
