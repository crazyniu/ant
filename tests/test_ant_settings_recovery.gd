extends SceneTree
## Regression for metadata settings persistence failures, using real UI callbacks.
var checks:=0
var failures:Array[String]=[]
var profile:="/tmp/ant-rescue-settings-recovery-%d"%Time.get_ticks_usec()
func _initialize()->void:call_deferred("run")
func check(value:bool,note:String)->void:
	checks+=1
	if not value:failures.append(note);push_error(note)
func press(parent:Node,path:String)->void:
	var button=parent.get_node_or_null(path)
	check(button is Button,"Button exists: "+path)
	if button is Button:button.pressed.emit()
func run()->void:
	var home=load("res://scenes/startup.tscn").instantiate()
	home.profile_directory=profile;home.use_command_line_catalog=false
	root.add_child(home);current_scene=home
	var end:=Time.get_ticks_msec()+8000
	while home.phase!="home" and Time.get_ticks_msec()<end:await process_frame
	check(home.phase=="home","Production startup reaches Home")
	if home.phase!="home":quit(1);return
	home.open_adventure("preparation",1)
	var origin:String=home.phase
	home.show_settings()
	var before_music:int=home.profile_state.music_volume
	var before_sound:int=home.profile_state.sfx_volume
	home.pause_overlay.get_node("MusicVolume").value=0
	home.pause_overlay.get_node("SoundVolume").value=23
	home.saves.test_fail_stage="write_temp"
	press(home.pause_overlay,"CloseButton")
	check(home.modal_title=="COULDN'T SAVE" and home.meta_settings_recovery_pending,"Failed close clearly reports unsaved settings")
	check(home.meta_settings_dirty and home.phase==origin,"Failure retains unsaved values and the original preparation")
	check(home.profile_state.music_volume==before_music and home.profile_state.sfx_volume==before_sound,"Failed write preserves the prior committed settings")
	press(home.pause_overlay,"Button_TRY AGAIN")
	check(home.modal_title=="COULDN'T SAVE" and home.meta_settings_dirty,"Retry while storage still fails cannot claim success by reading the old file")
	check(home.phase==origin,"Failed settings retry does not jump to Adventure Map")
	press(home.pause_overlay,"CloseButton")
	check(home.modal_title=="SETTINGS","Closing recovery returns to settings, not silently discarding edits")
	check(home.pause_overlay.get_node("MusicVolume").value==0 and home.pause_overlay.get_node("SoundVolume").value==23,"Retry/back retain the exact chosen slider values")
	press(home.pause_overlay,"CloseButton")
	check(home.modal_title=="COULDN'T SAVE","Unsaved settings remain explicit when a second close cannot persist")
	home.saves.test_fail_stage=""
	press(home.pause_overlay,"Button_TRY AGAIN")
	check(home.modal_title=="SETTINGS" and not home.meta_settings_dirty and not home.meta_settings_recovery_pending,"Successful retry actually commits and returns to settings")
	check(home.profile_state.music_volume==0 and home.profile_state.sfx_volume==23,"Committed state equals the player's intended values")
	var disk=load("res://scripts/save_service.gd").new(home.profile_directory,home.Catalog.level_ids(false),30)
	var reloaded:Dictionary=disk.load_save()
	check(reloaded.ok and reloaded.state.music_volume==0 and reloaded.state.sfx_volume==23,"Independent reload confirms both volumes persisted")
	press(home.pause_overlay,"CloseButton")
	check(home.modal_title=="" and home.phase==origin and home.adventure.selected_level==1,"Successful settings close returns to the same selected preparation")
	check(home.economy_state.points==0 and home.progression._record.runs.is_empty(),"Settings recovery never changes points or starts a battle")
	home.audio_service.stop_music();home.audio_service.stop_all_sfx()
	await create_timer(.15).timeout
	home.queue_free();await process_frame;await process_frame
	var report:Dictionary={"pass":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Real headless startup/preparation/settings button callbacks with write failure, repeat failure, close/back, retry and independent disk reload. No visual/audio/native-input acceptance."}
	DirAccess.make_dir_recursive_absolute("res://reports/flow")
	var file:=FileAccess.open("res://reports/flow/settings-recovery.json",FileAccess.WRITE)
	if file==null:push_error("Cannot create test report");quit(1);return
	file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	print("ANT_SETTINGS_RECOVERY ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
