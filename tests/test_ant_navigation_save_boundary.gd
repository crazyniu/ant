extends SceneTree
var checks:=0
var failures:Array[String]=[]
var profile:="/tmp/ant-rescue-navigation-boundary-%d"%Time.get_ticks_usec()
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
	check(home.phase=="home","Startup reaches Home")
	if home.phase!="home":quit(1);return
	home.open_adventure("preparation",1)
	home.adventure.map_scroll=411
	home.progression.test_fail_stage="write_temp"
	home.open_shop()
	check(home.phase=="preparation" and home.adventure.visible and not is_instance_valid(home.shop),"Failed navigation save cannot open shop over the error")
	check(home.modal_title=="COULDN'T SAVE" and home.meta_navigation_recovery_pending,"Failed navigation has explicit pending-save recovery")
	check(home.adventure.map_scroll==411 and home.economy_state.navigation.scroll_y!=411,"Pending position is kept separately from committed navigation")
	press(home.pause_overlay,"Button_TRY AGAIN")
	check(home.modal_title=="COULDN'T SAVE" and home.phase=="preparation","Retry while storage fails cannot silently leave the preparation")
	home.progression.test_fail_stage=""
	press(home.pause_overlay,"Button_TRY AGAIN")
	check(home.modal_title=="" and home.phase=="preparation","Successful save retry returns to same page without inventing a second action")
	check(home.economy_state.navigation.scroll_y==411 and not home.meta_navigation_recovery_pending,"Retry commits the actual map position")
	home.open_shop();check(home.phase=="shop","Shop works normally after navigation is saved")
	home.close_shop();check(home.phase=="preparation" and home.adventure.map_scroll==411,"Shop return keeps the selected preparation and map position")
	home.adventure.map_scroll=512
	home.progression.test_fail_stage="write_temp"
	home.show_home_again()
	check(home.phase=="preparation" and home.modal_title=="COULDN'T SAVE","Failed Home return leaves the error and original page visible")
	press(home.pause_overlay,"CloseButton")
	press(home.adventure,"AdventurePage/BeginLevel")
	check(home.phase=="preparation" and not home.launch_pending,"Preparation cannot start Loading after navigation write failure")
	check(not home.adventure.get_node("AdventurePage/BeginLevel").disabled,"Failed start releases the Begin lock for a real retry")
	check(home.progression._record.runs.is_empty() and home.economy_state.points==0,"Blocked navigation never creates a battle, reward or spend")
	home.progression.test_fail_stage=""
	press(home.pause_overlay,"Button_TRY AGAIN")
	check(home.economy_state.navigation.scroll_y==512 and home.phase=="preparation","Navigation retry persists the second intended position")
	home.show_home_again();check(home.phase=="home","Home return succeeds after the actual write recovers")
	await process_frame;await process_frame
	home.audio_service.stop_music();home.audio_service.stop_all_sfx();await create_timer(.15).timeout
	home.queue_free();await process_frame;await process_frame
	var report:Dictionary={"pass":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Real headless menu callbacks, navigation write failure, retry, shop/Home/start guards, retained map position and no economy side effects. No production-save writes or visual/audio/native-input acceptance."}
	DirAccess.make_dir_recursive_absolute("res://reports/flow")
	var file:=FileAccess.open("res://reports/flow/navigation-save-boundary.json",FileAccess.WRITE)
	if file==null:push_error("Cannot create test report");quit(1);return
	file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	print("ANT_NAVIGATION_SAVE_BOUNDARY ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
