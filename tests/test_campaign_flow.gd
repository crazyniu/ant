extends SceneTree
## Finite actual-scene campaign integration. All writable profiles are unique /tmp.
const Catalog=preload("res://scripts/level_catalog.gd")
const Saves=preload("res://scripts/save_service.gd")
var failures:Array[String]=[]
var checks:=0
var directories:Array[String]=[]
var entries:Array=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures.append(message);push_error(message)
func directory(label:String)->String:
	var path:String="/tmp/ant-rescue-campaign-flow-%d-%d-%s"%[OS.get_process_id(),Time.get_ticks_usec(),label]
	directories.append(path);return path
func make(path:String,campaign:bool=true)->Control:
	var scene=load("res://scenes/play.tscn").instantiate()
	scene.profile_directory=path;scene.campaign_drafts=campaign;scene.use_command_line_catalog=false;scene.use_command_line_level=false
	root.add_child(scene);scene.set_process(false);return scene
func remove_scene(scene:Control)->void:
	if is_instance_valid(scene):scene.queue_free()
	await process_frame
func check_labels(scene:Control,context:String)->void:
	for label in scene.pause_overlay.find_children("*","Label",true,false):
		check(label.get_minimum_size().x<=label.size.x+1,"No label overflow in "+context+": "+label.text)
func tap(scene:Control,node:Control)->void:
	var point:Vector2=node.get_global_rect().get_center()
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;event.global_position=point
		scene.get_viewport().push_input(event,true)
func run()->void:
	root.size=Vector2i(1440,2560)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--probe="):
			await run_cli_probe(arg.trim_prefix("--probe="));return
	await test_registry_and_isolation()
	await test_selector()
	await test_all_entries_and_navigation()
	await test_recovery_and_source_failure()
	await test_replay_isolation()
	var report:Dictionary={"pass":failures.is_empty(),"assertions":checks,"failures":failures,"entries":entries,"catalog":"campaign_drafts","human_playtest":"NOT_RUN","visual_acceptance":"NOT_RUN","production_eligible":false,"scope":"30 actual formal-art scenes, conserved full timed no-tool replays and durable sequential Next; 3x10 selector pointer routes/bounds/locks/completion; default catalog separation; tool unlocks; retry/leave/recovery and automatic replay profile isolation. Automated, not human difficulty or visual acceptance."}
	var file:=FileAccess.open("res://reports/ui/campaign-flow-report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("CAMPAIGN_FLOW_REPORT ",JSON.stringify(report))
	for path in directories:remove_directory(path)
	await create_timer(.8).timeout
	quit(0 if failures.is_empty() else 1)
func remove_directory(path:String)->void:
	for subdirectory in DirAccess.get_directories_at(path):remove_directory(path.path_join(subdirectory))
	for file in DirAccess.get_files_at(path):DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)
func test_registry_and_isolation()->void:
	var base:=directory("isolation")
	var validation:=Saves.new(base);check(validation.load_save().ok,"Validation fixture initializes")
	validation.set_tutorial_completed(true);validation.mark_complete("validation-01","validation-fixture");validation.set_current_entrance("validation-02");validation.set_volumes(21,43)
	var original:=FileAccess.get_file_as_bytes(base+"/save.json")
	var scene:=make(base)
	check(scene.campaign_drafts and scene.level_ids.size()==30,"Opt-in catalog contains exactly 30 IDs")
	check(scene.profile_directory==base+"/campaign-drafts" and scene.level_index==1,"Candidate uses separate profile and fresh level one")
	check(scene.level_config.level_id=="campaign-01" and scene.level_config.production_level_number==null,"Candidate source identity is not promoted")
	check(scene.modal_title=="YOUR FIRST RESCUE" and not scene.profile_state.tutorial_completed,"Candidate tutorial is separate from validation")
	scene.finish_tutorial()
	check(FileAccess.get_file_as_bytes(base+"/save.json")==original,"Candidate initialization/tutorial cannot touch validation bytes")
	check(not Catalog.check_identity(scene.level_config,2,true).ok,"Wrong campaign ID is rejected rather than silently reused")
	var changed:Dictionary=scene.level_config.duplicate(true);changed.level_number=30
	check(not Catalog.check_identity(changed,1,true).ok,"Wrong tool context is rejected")
	check(Catalog.level_path(31,true).is_empty() and Catalog.level_path(4,false).is_empty(),"Catalog bounds never map absent levels")
	await remove_scene(scene)
	scene=make(base,false)
	check(not scene.campaign_drafts and scene.level_ids.size()==3 and scene.level_index==2,"Default launch still resumes validation catalog")
	check(scene.level_config.level_id=="validation-02" and scene.audio_visual_state.music==21 and scene.audio_visual_state.sound==43,"Default source/settings are preserved")
	scene.show_levels();check(scene.pause_overlay.has_node("LevelButton3") and not scene.pause_overlay.has_node("LevelButton4"),"Default selector still contains only three levels")
	await remove_scene(scene)
func test_selector()->void:
	var base:=directory("selector")
	var scene:=make(base);scene.finish_tutorial();scene.show_levels()
	var before:=FileAccess.get_file_as_bytes(scene.profile_directory+"/save.json")
	for page in range(3):
		check(scene.level_selector_page==page and scene.pause_overlay.get_node("PageNumber").text=="%d / 3"%(page+1),"Selector page %d has truthful page count"%(page+1))
		var buttons:Array=scene.pause_overlay.find_children("LevelButton*","Button",false,false)
		check(buttons.size()==10,"Page %d renders exactly ten real entries"%(page+1))
		for index in range(10):
			var number:=page*10+index+1
			var button:Button=scene.pause_overlay.get_node("LevelButton%d"%number)
			check(button.disabled==(number!=1),"Sequential lock matches save for level %d"%number)
			check(Rect2(185,625,570,290).encloses(Rect2(button.position,button.size)),"Selector tile %d is inside grid"%number)
			check(scene.pause_overlay.has_node("LevelLock%d"%number)==(number!=1),"Lock marker is truthful for %d"%number)
			for other in buttons:
				if other!=button:check(not button.get_rect().intersects(other.get_rect()),"Selector buttons do not overlap")
		check(scene.pause_overlay.get_node("PageButton_PREVIOUS").disabled==(page==0),"Previous page bound")
		check(scene.pause_overlay.get_node("PageButton_NEXT").disabled==(page==2),"Next page bound")
		check_labels(scene,"campaign page %d"%page)
		if page<2:
			await process_frame;tap(scene,scene.pause_overlay.get_node("PageButton_NEXT"))
	check(scene.pause_overlay.has_node("LevelButton30") and not scene.pause_overlay.has_node("LevelButton31"),"Last page ends at actual draft30")
	check(FileAccess.get_file_as_bytes(scene.profile_directory+"/save.json")==before,"Pagination does not write progress or unlock entries")
	scene.close_current_modal();check(scene.modal_title=="PAUSED","Campaign picker X returns to pause")
	scene.show_levels();check(scene.level_selector_page==2,"Reopening picker preserves browsed page")
	scene.show_levels(99);check(scene.level_selector_page==2,"Out-of-range page is clamped safely")
	await process_frame;tap(scene,scene.pause_overlay.get_node("PageButton_PREVIOUS"));check(scene.level_selector_page==1,"Previous page actual pointer route")
	scene.show_levels(0)
	await process_frame;tap(scene,scene.pause_overlay.get_node("LevelButton1"));await process_frame
	var selected:Control=await await_loaded_play();selected.set_process(false)
	check(selected!=scene and selected.campaign_drafts and selected.level_config.level_id=="campaign-01","Actual tile pointer starts its real campaign scene")
	check(selected.profile_directory==base+"/campaign-drafts","Replacement keeps one isolated suffix")
	await remove_scene(selected)
func inspect_entry(scene:Control,number:int)->void:
	var id:String="campaign-%02d"%number
	check(scene.campaign_drafts and scene.level_config.level_id==id and scene.profile_state.current_entrance.level_id==id,"Source/save identity matches "+id)
	check(scene.level_config.level_number==number and scene.level_config.production_level_number==null,"Preserved draft tool context "+id)
	check(scene.level_config.validation.production_eligible==false and scene.level_config.validation.human_playtest=="NOT_RUN","No false human acceptance "+id)
	check(scene.ready_to_simulate and scene.rules.status=="ready" and scene.rules.time_us==0,"Real fresh scene loads "+id)
	check(scene.rules.board.size()>0 and scene.bead_nodes.size()==scene.rules.board.size() and scene.cells.size()==scene.rules.board.size(),"Every real bead is rendered "+id)
	var rendered:Dictionary={}
	for bead in scene.bead_nodes:rendered[bead.color_id]=int(rendered.get(bead.color_id,0))+1
	for color in scene.COLORS:
		check(int(rendered.get(color,0))==int(scene.level_config.initial_color_counts[color]) and int(scene.counts[color])==int(scene.level_config.initial_color_counts[color]),"No missing or invented color "+id+" "+color)
	check(scene.board_plane.columns==scene.level_config.width and scene.board_plane.rows==scene.level_config.height,"Shared BoardPlane uses actual dimensions "+id)
	for color in scene.COLORS:
		check(scene.get_node("TransportScene/Stock/Count_"+color).text=="0","Initial stock is truthful for "+id+" "+color)
	check(scene.get_node("TransportScene/AmmoCount").text=="0 / %d"%scene.rules.armors[0].demand,"Armor demand display matches real first armor "+id)
	check(scene.current_armor_color==scene.rules.armors[0].color,"Armor display uses actual color "+id)
	check(scene.candidate_columns.size()==5 and scene.rules.columns.size()==5,"Exactly five queue columns "+id)
	for column in range(5):
		var node:Control=scene.get_node("CandidateQueues/Column%d"%(column+1))
		var teams:Array=scene.rules.columns[column].teams
		check(node.find_children("FrontButton","Button",false,false).size()==(0 if teams.is_empty() else 1),"Front-only target including empty queues "+id)
		check(node.find_children("Quota*","Label",false,false).size()==mini(3,teams.size()),"Long rear queues stay limited to three visible rows "+id)
		check(not node.has_node("Ant3") and not node.has_node("Quota3"),"No fourth rear row overlaps tools "+id)
		if not teams.is_empty():check(node.get_node("FrontButton").tooltip_text=="%s · %d"%[teams[0].color.to_upper(),teams[0].remaining],"Actual front identity displayed "+id)
	for index in range(4):
		var unlocked:bool=number>=[3,6,9,16][index]
		check(scene.get_node("ToolTray/ToolButton%d"%index).disabled==not unlocked,"Production unlock context for tool %d on %s"%[index,id])
	check(scene.rules.conservation_errors().is_empty(),"Initial conservation "+id)
func win(scene:Control)->void:
	for entry in scene.level_config.validation.no_tool_solution:
		scene.rules.update_us(int(entry.time_us)-scene.rules.time_us)
		check(scene.rules.select_front(entry.column_id,entry.team_id).ok,"Actual timed replay input accepted "+scene.level_config.level_id)
	scene.rules.update_us(120000000);scene.sync_view();scene.consume_rule_events()
func test_all_entries_and_navigation()->void:
	var base:=directory("sequential")
	var scene:=make(base);scene.finish_tutorial()
	for number in range(1,31):
		inspect_entry(scene,number)
		if number==16:
			var front:Dictionary=scene.rules.columns[0].teams[0]
			check(scene.preview_select_front(0,front.id),"Campaign16 can start actual front before retry")
			scene.rules.update_us(500000);var time:int=scene.rules.time_us;var board:Dictionary=scene.rules.board.duplicate(true)
			scene.show_restart();scene.pause_overlay.get_node("Button_CANCEL").pressed.emit();scene.dismiss_modal()
			check(scene.rules.time_us==time and scene.rules.board==board,"Campaign retry Cancel preserves live run")
			scene.show_restart();scene.pause_overlay.get_node("Button_RESTART").pressed.emit();await process_frame
			scene=await await_loaded_play();scene.set_process(false)
			check(scene.campaign_drafts and scene.level_index==16 and scene.rules.status=="ready" and scene.rules.time_us==0,"Retry preserves campaign16 identity with a fresh board")
			check(scene.profile_directory==base+"/campaign-drafts","Retry preserves exact isolated profile")
		if number==20:
			scene.show_leave();scene.pause_overlay.get_node("Button_CANCEL").pressed.emit();scene.dismiss_modal()
			check(scene.rules.status=="ready" and scene.rules.time_us==0,"Leave Cancel does not start or replace campaign20")
			scene.show_leave();scene.pause_overlay.get_node("Button_LEVEL SELECT").pressed.emit()
			check(scene.level_selector_page==1 and scene.pause_overlay.has_node("LevelButton20"),"Leave uses current campaign page, not validation")
			check(scene.pause_overlay.has_node("LevelComplete19") and scene.pause_overlay.get_node("LevelButton20").disabled==false,"Completed and current entries show correct state")
			scene.close_current_modal();scene.dismiss_modal()
		if number==1:scene.saves.test_fail_stage="replace_primary"
		win(scene)
		check(scene.rules.status=="victory" and scene.rules.conservation_errors().is_empty(),"Conserved final-hit replay wins campaign%02d"%number)
		check(scene.fx.dragon_pose().visible and not scene.fx.dragon_pose().defeat_complete,"Final hit starts finite collapse campaign%02d"%number)
		scene.fx.advance(.62);scene.apply_actor_poses()
		check(not scene.get_node("DragonRoute/Dragon").visible,"Finite terminal collapse retires dragon campaign%02d"%number)
		check(scene.rules.tool_uses.values().all(func(value):return value==0),"Full replay uses no tools campaign%02d"%number)
		scene.show_outcome(true)
		if number==1:
			check(not scene.victory_saved and scene.modal_title=="COULDN'T SAVE" and scene.profile_state.available_unlocked==1,"Candidate victory save failure cannot unlock Next")
			scene.saves.test_fail_stage="";scene.retry_save()
		check(scene.victory_saved and scene.profile_state.completed_levels.has("campaign-%02d"%number),"Real candidate completion is durably saved %d"%number)
		check(scene.pause_overlay.has_node("Button_NEXT LEVEL")== (number<30),"Next availability matches actual catalog at %d"%number)
		entries.append({"level_id":scene.level_config.level_id,"beads":scene.bead_nodes.size(),"final_hit_us":scene.rules.time_us,"pass":scene.rules.status=="victory"})
		if number<30:
			if number==10:scene.saves.test_fail_stage="replace_primary"
			scene.pause_overlay.get_node("Button_NEXT LEVEL").pressed.emit()
			if number==10:
				check(scene.pending_save_kind=="entrance" and scene.modal_title=="COULDN'T SAVE" and not scene.replacement_pending,"Failed page-crossing Next preserves old scene")
				scene.saves.test_fail_stage="";scene.retry_save()
			await process_frame;scene=await await_loaded_play();scene.set_process(false)
			check(scene.profile_directory==base+"/campaign-drafts","Next keeps campaign save path at %d"%(number+1))
		else:
			check(scene.profile_state.highest_unlocked==30 and scene.profile_state.next_level_id.is_empty(),"Final30 completion never offers level31")
			scene.show_levels();check(scene.level_selector_page==2 and scene.pause_overlay.has_node("LevelComplete30"),"Final completed level appears on correct page")
	await remove_scene(scene)
	scene=make(base)
	check(scene.level_index==30 and scene.rules.status=="ready" and scene.rules.time_us==0,"Relaunch resumes campaign30, never default validation")
	check(scene.profile_state.completed_levels.size()==30 and scene.profile_state.next_level_id.is_empty(),"All thirty candidate completions persist without invented Next")
	await remove_scene(scene)
func test_recovery_and_source_failure()->void:
	var base:=directory("recovery")
	var store:=Saves.new(Catalog.profile_path(base,true),Catalog.level_ids(true),30)
	store.load_save();store.set_tutorial_completed(true);store.mark_complete("campaign-01","fixture");store.set_current_entrance("campaign-02");store.set_volumes(31,47)
	var broken:=FileAccess.open(Catalog.profile_path(base,true)+"/save.json",FileAccess.WRITE);broken.store_string("{broken");broken.close()
	var scene:=make(base)
	check(not scene.profile_state.ready and scene.modal_title=="COULDN'T LOAD","Corrupt candidate profile blocks play")
	scene.restore_backup();await process_frame;scene=await await_loaded_play();scene.set_process(false)
	check(scene.campaign_drafts and scene.level_config.level_id=="campaign-02" and scene.profile_state.ready,"Backup recovery stays in campaign catalog")
	await remove_scene(scene)
	base=directory("invalid-source")
	scene=load("res://scenes/play.tscn").instantiate();scene.profile_directory=base;scene.campaign_drafts=true;scene.use_command_line_catalog=false;scene.use_command_line_level=false;scene.qa_fixture_mode=true;scene.qa_level_config={"schema_version":1}
	root.add_child(scene);scene.set_process(false)
	check(scene.rules.status=="load_error" and not scene.has_node("Mosaic"),"Invalid candidate source has no fallback validation board")
	scene.show_levels();check(scene.pause_overlay.has_node("PageButton_NEXT") and scene.pause_overlay.has_node("LevelButton10"),"Source-error picker retains actual campaign catalog")
	scene.close_current_modal();scene.qa_level_config.clear();scene.pause_overlay.get_node("Button_TRY AGAIN").pressed.emit();await process_frame
	scene=await await_loaded_play();scene.set_process(false)
	check(scene.campaign_drafts and scene.level_config.level_id=="campaign-01" and scene.rules.status=="ready","Source-error retry reloads real campaign, not validation")
	await remove_scene(scene)
func test_replay_isolation()->void:
	var base:=directory("replay")
	var store:=Saves.new(base);store.load_save();var original:=FileAccess.get_file_as_bytes(base+"/save.json")
	var scene=load("res://scenes/play.tscn").instantiate();scene.campaign_drafts=true;scene.use_command_line_catalog=false;scene.use_command_line_level=false;scene.auto_replay=true;scene.level_index=30;scene.profile_directory=base
	root.add_child(scene);scene.set_process(false);directories.append(scene.profile_directory)
	check(scene.profile_directory!=base and scene.profile_directory.begins_with("/tmp/ant-rescue-replay-"),"Automatic candidate replay overrides normal profile with unique /tmp")
	check(scene.level_index==30 and scene.level_config.level_id=="campaign-30" and scene.auto_replay,"Automatic replay targets actual30")
	check(FileAccess.get_file_as_bytes(base+"/save.json")==original and not DirAccess.dir_exists_absolute(base+"/campaign-drafts"),"Automatic replay writes neither real validation nor candidate profile")
	var replay_path:String=scene.profile_directory
	scene.replace_level(30);await process_frame;scene=await await_loaded_play();scene.set_process(false)
	check(scene.auto_replay and scene.campaign_drafts and scene.level_index==30 and scene.profile_directory==replay_path,"Replay retry keeps same candidate catalog and isolated session")
	await remove_scene(scene)

func run_cli_probe(mode:String)->void:
	var base:=OS.get_environment("ANT_RESCUE_PROFILE_DIR")
	if not base.begins_with("/tmp/ant-rescue-"):
		push_error("CLI probes require an explicit isolated /tmp/ant-rescue-* root");quit(2);return
	var validation:=Saves.new(base);validation.load_save();validation.set_tutorial_completed(true)
	var original:=FileAccess.get_file_as_bytes(base+"/save.json")
	var scene=load("res://scenes/play.tscn").instantiate();root.add_child(scene);scene.set_process(false)
	if mode=="campaign-locked":
		check(scene.campaign_drafts and scene.level_index==1 and scene.level_config.level_id=="campaign-01","CLI opt-in uses campaign without --level unlock bypass")
		check(scene.profile_directory==base+"/campaign-drafts" and scene.profile_state.available_unlocked==1,"CLI candidate save path is separate")
	elif mode=="campaign-auto":
		check(scene.campaign_drafts and scene.auto_replay and scene.level_index==30 and scene.level_config.level_id=="campaign-30","CLI automatic replay really selects campaign30")
		check(scene.profile_directory.begins_with("/tmp/ant-rescue-replay-") and scene.profile_directory!=base,"CLI automatic replay owns unique isolated profile")
		check(not DirAccess.dir_exists_absolute(base+"/campaign-drafts"),"CLI automatic replay does not create normal candidate profile")
		directories.append(scene.profile_directory)
	elif mode=="validation-default":
		check(not scene.campaign_drafts and scene.level_ids.size()==3 and scene.level_index==1,"CLI launch without opt-in stays three validation levels")
	else:check(false,"Unknown CLI probe")
	check(FileAccess.get_file_as_bytes(base+"/save.json")==original,"CLI probe preserves original validation save bytes")
	await remove_scene(scene)
	for path in directories:remove_directory(path)
	print("CAMPAIGN_CLI_REPORT ",JSON.stringify({"mode":mode,"pass":failures.is_empty(),"assertions":checks,"failures":failures}))
	await create_timer(.8).timeout
	quit(0 if failures.is_empty() else 1)

# Replacements now traverse real threaded Loading; a single process frame is not
# a completion contract. This waits only for the actual destination, never a timer.
func await_loaded_play()->Control:
	var deadline:=Time.get_ticks_msec()+10000
	while Time.get_ticks_msec()<deadline:
		if is_instance_valid(current_scene) and current_scene.get_script()!=null and current_scene.get_script().resource_path=="res://scripts/play.gd" and current_scene.is_node_ready():
			current_scene.set_process(false)
			return current_scene as Control
		await process_frame
	push_error("Actual play scene did not finish Loading")
	quit(1)
	return null
