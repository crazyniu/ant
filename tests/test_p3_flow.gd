extends SceneTree
const Saves=preload("res://scripts/save_service.gd")
const Fixture=preload("res://tests/p3_fixture.gd")
var failures:Array[String]=[]
var checks:=0
var directories:Array[String]=[]
var tool_cues:Array[String]=[]
var proofs:Array=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures.append(message);push_error(message)
func directory(label:String)->String:
	var path:String="/tmp/ant-rescue-p3-%d-%d-%s"%[OS.get_process_id(),Time.get_ticks_usec(),label]
	directories.append(path);return path
func make(path:String,qa:bool=false)->Control:
	var scene=load("res://scenes/play.tscn").instantiate()
	scene.profile_directory=path;scene.use_command_line_level=false;scene.qa_fixture_mode=qa
	if qa:scene.qa_level_config=Fixture.config()
	root.add_child(scene);scene.set_process(false)
	return scene
func remove_scene(scene:Control)->void:
	if is_instance_valid(scene):scene.queue_free()
	await process_frame
func bytes(path:String)->PackedByteArray:return FileAccess.get_file_as_bytes(path+"/save.json")
func count_effect(scene:Control,kind:String)->int:
	return scene.fx.debug_snapshot().effects.filter(func(effect:Dictionary)->bool:return effect.kind==kind).size()
func check_labels(scene:Control,context:String)->void:
	for label in scene.pause_overlay.find_children("*","Label",true,false):check(label.get_minimum_size().x<=label.size.x+1,"No label overflow in "+context+": "+label.text)
func run()->void:
	root.size=Vector2i(1440,2560)
	await test_first_load_and_settings()
	await test_tools()
	await test_tool_pointer_routes()
	await test_victory_and_navigation()
	await test_recovery()
	await test_invalid_level_shell()
	await test_real_level_three_slot()
	var report:Dictionary={"pass":failures.is_empty(),"assertions":checks,"failures":failures,"tool_cues":tool_cues,"shuffle_proofs":proofs,"scope":"P3 actual scene integration with isolated local profiles: four tool successes and one-use audio/FX, six slots, bounded shuffle failure, live scout, paused recall/cancel/stale guards, tutorial/settings/save retry, sequential three-level entry, recovery, restart and fresh process entry. Automated only; not human playtest or thirty authored levels."}
	var out:=FileAccess.open("res://reports/ui/p3-flow-report.json",FileAccess.WRITE);out.store_string(JSON.stringify(report,"\t"));out.close()
	print("P3_FLOW_REPORT ",JSON.stringify(report))
	for path in directories:
		for file in DirAccess.get_files_at(path):DirAccess.remove_absolute(path+"/"+file)
		DirAccess.remove_absolute(path)
	await create_timer(3.0).timeout
	quit(0 if failures.is_empty() else 1)
func test_first_load_and_settings()->void:
	var path:=directory("fresh")
	var scene:=make(path)
	check(scene.level_index==1 and scene.rules.time_us==0 and scene.rules.status=="ready","Genuine fresh first entry is level one at time zero")
	check(scene.modal_title=="YOUR FIRST RESCUE" and scene.rules.paused,"First-run tutorial pauses observation")
	check(not scene.profile_state.tutorial_completed,"Opening tutorial does not complete it")
	check(scene.pause_overlay.has_node("Button_LET'S GO") and not scene.pause_overlay.has_node("Button_SKIP"),"Tutorial has one primary action; X/ESC supplies skip without a duplicate button")
	check_labels(scene,"tutorial")
	var fresh:=bytes(path)
	scene.show_tutorial();check(bytes(path)==fresh,"Reopening tutorial performs no save")
	scene.close_current_modal()
	check(scene.profile_state.tutorial_completed and not scene.rules.paused and not is_instance_valid(scene.pause_overlay),"Tutorial X follows explicit skip and resumes")
	check(scene.rules.status=="ready" and scene.rules.time_us==0,"Skipping tutorial never starts threat")
	scene.show_levels()
	check(not scene.pause_overlay.get_node("LevelButton1").disabled and scene.pause_overlay.get_node("LevelButton2").disabled and scene.pause_overlay.get_node("LevelButton3").disabled,"Only the saved first level is playable")
	check(not scene.pause_overlay.has_node("LevelButton4"),"No unproduced fourth level is offered")
	check_labels(scene,"levels")
	scene.close_current_modal();check(scene.modal_title=="PAUSED","Level picker X returns to pause")
	scene.show_settings();check_labels(scene,"settings")
	var old:=bytes(path)
	scene.pause_overlay.get_node("MusicVolume").value=0
	scene.pause_overlay.get_node("SoundVolume").value=37
	check(bytes(path)==old,"Slider preview does not write on every movement")
	check(scene.audio_service.get_status().music_muted and is_equal_approx(scene.audio_service.get_status().sfx_volume,.37),"Zero mutes music independently of SFX")
	scene.pause_overlay.get_node("MusicVolume").drag_ended.emit(true)
	check(scene.profile_state.music_volume==0 and scene.profile_state.sfx_volume==37 and bytes(path)!=old,"Drag end atomically saves both volumes")
	old=bytes(path)
	scene.pause_overlay.get_node("MusicVolume").value=22
	scene.saves.test_fail_stage="replace_primary"
	scene.close_current_modal()
	check(scene.modal_title=="COULDN'T SAVE" and scene.pending_save_kind=="settings" and bytes(path)==old,"Failed settings close keeps committed bytes and offers retry")
	check_labels(scene,"settings error")
	scene.saves.test_fail_stage="";scene.retry_save()
	check(scene.modal_title=="SETTINGS" and scene.profile_state.music_volume==22 and not scene.settings_dirty,"Settings Retry Save commits then returns to settings")
	scene.close_current_modal();check(scene.modal_title=="PAUSED","Settings X returns to pause")
	scene.dismiss_modal();check(not scene.rules.paused,"Pause closes cleanly")
	var initial:Dictionary=scene.rules.snapshot()
	scene.show_restart();scene.pause_overlay.get_node("Button_CANCEL").pressed.emit();scene.dismiss_modal()
	check(scene.rules.time_us==initial.time_us and scene.rules.board==initial.board and scene.rules.columns==initial.columns,"Restart cancel has no gameplay side effect")
	scene.show_leave();scene.pause_overlay.get_node("Button_CANCEL").pressed.emit();scene.dismiss_modal()
	check(scene.rules.time_us==initial.time_us and scene.rules.columns==initial.columns,"Leave cancel has no gameplay side effect")
	await remove_scene(scene)
	scene=make(path)
	check(scene.level_index==1 and not is_instance_valid(scene.pause_overlay) and scene.rules.status=="ready","Process recreation keeps tutorial flag but starts a fresh level")
	check(scene.audio_visual_state.music==22 and scene.audio_visual_state.sound==37,"Process recreation restores saved slider values")
	await remove_scene(scene)
func test_tools()->void:
	var scene:=make(directory("tools"),true)
	check(scene.level_config.production_level_number==null,"QA uses explicit tool config without changing null production identity")
	for i in range(4):check(not scene.get_node("ToolTray/ToolButton%d"%i).disabled,"QA tool icon %d is genuinely active"%i)
	check(not scene.get_node("ToolTray").has_node("Tray"),"Tools have no enclosing tray")
	scene.activate_tool("recall")
	check(not scene.rules.paused and not is_instance_valid(scene.pause_overlay) and scene.rules.tool_uses.get("recall",0)==0 and scene.get_node("ToolFeedback").text=="NO ACTIVE TEAM · USE KEPT","Empty recall reports unavailable without pausing or spending")
	scene.audio_service.cue_played.connect(func(id):
		if str(id).begins_with("tool_"):tool_cues.append(str(id)))
	var before:Dictionary=scene.rules.snapshot()
	var result:Dictionary=scene.activate_tool("extra_slot")
	check(result.ok and result.consumed and scene.slots.size()==6 and scene.rules.slots.size()==6,"Extra-slot tool creates an actual sixth UI/rule slot")
	check(scene.slots[5].get_rect().end.x<=940 and scene.slots[0].position.x>=0,"All six slots fit baseline canvas")
	for i in range(5):check(not scene.slots[i].get_rect().intersects(scene.slots[i+1].get_rect()),"Six-slot layout has no overlap %d"%i)
	check(scene.rules.time_us==before.time_us and scene.rules.columns==before.columns,"Extra slot never starts or changes waiting teams")
	check(scene.get_node("ToolTray/ToolButton0").disabled and scene.get_node("ToolTray/Uses0").text=="0","Consumed icon is disabled with zero remaining")
	check(count_effect(scene,"plus")==1 and tool_cues.count("tool_plus")==1,"One accepted extra-slot event gives one sound and plus effect")
	check(scene.fx._can_draw(scene.slot_effect_point(5),18) and scene.fx.get_index()>scene.get_node("WorkSlots").get_index(),"Sixth-slot plus is outside number protection and above rebuilt slot artwork")
	for i in range(6):check(not scene.fx._can_draw(scene.slot_bounds(i).position+Vector2(60,99),1),"Each of six current quota labels stays protected from FX")
	scene.consume_rule_events();scene.activate_tool("extra_slot")
	check(count_effect(scene,"plus")==1 and tool_cues.count("tool_plus")==1,"Draining again and repeated click cannot replay success cue")
	check(scene.preview_select_front(0,"qa-red"),"Real front selection starts QA run")
	var tasks:Dictionary=scene.rules.tasks.duplicate(true);var reserved:Dictionary=scene.rules.reservations.duplicate(true)
	scene.rules.set_speed(2);scene.show_recall_selection()
	check(scene.rules.paused and scene.rules.speed_multiplier==1 and scene.modal_title=="RECALL A TEAM","Recall opens deliberate paused selection and resets speed")
	check_labels(scene,"recall")
	check(scene.pause_overlay.find_children("RecallChoice*","Button",false,false).size()==1 and is_equal_approx(scene.pause_overlay.get_node("RecallChoice0").get_rect().get_center().x,470),"Recall shows only the one real team, centered with its original slot identity")
	var token:String=scene.recall_selection.token
	before=scene.rules.snapshot();scene.rules.update_us(10000000)
	check(scene.rules.time_us==before.time_us,"Recall choice waits without elapsed threat time")
	scene.dismiss_modal()
	check(not scene.rules.paused and scene.rules.tool_uses.get("recall",0)==0 and scene.rules.tasks==tasks and scene.rules.reservations==reserved,"Recall cancel consumes no use, quota, reservation or transport")
	check(not scene.rules.cancel_tool_selection(token),"Canceled recall token cannot be reused")
	scene.show_recall_selection();result=scene.confirm_recall(0,"stale-team")
	check(not result.ok and not result.consumed and scene.rules.paused and not scene.recall_selection.is_empty(),"Stale recall identity stays paused without consumption")
	result=scene.confirm_recall(0,"qa-red")
	check(result.ok and result.remaining_quota==2 and not scene.rules.paused and not is_instance_valid(scene.pause_overlay),"Confirmed recall returns only remaining quota then resumes")
	check(scene.rules.tasks==tasks and scene.rules.reservations==reserved and scene.rules.columns[0].teams[0].remaining==2,"Existing carrier and reservation survive recall exactly")
	check(tool_cues.count("tool_recall")==1 and count_effect(scene,"recall")==1,"Recall release sound and FX fire once after resume")
	before=scene.rules.snapshot();result=scene.activate_tool("scout")
	check(result.ok and not scene.rules.paused and not is_instance_valid(scene.pause_overlay),"Scout succeeds atomically without opening a paused modal")
	check(scene.rules.columns==before.columns and scene.rules.board==before.board and scene.rules.reservations==before.reservations and scene.rules.time_us==before.time_us,"Scout neither selects nor reserves nor advances time")
	check(scene.has_node("ScoutHints/FrontTeam"),"Scout visually outlines the suggested front")
	scene.previous_queue_signature="force-redraw";scene.sync_view()
	check(scene.get_node("ScoutHints").get_index()>scene.get_node("CandidateQueues").get_index(),"Scout front highlight remains above a rebuilt candidate queue")
	for id in result.exposed_cell_ids:check(scene.has_node("ScoutHints/Cell%d"%id) and not scene.rules.reservations.has(id),"Scout highlights only a legal unreserved cell")
	check(tool_cues.count("tool_hint")==1 and count_effect(scene,"scout")==1,"Scout maps to the actual hint audio and one FX event")
	before=scene.rules.replay_state();result=scene.activate_tool("shuffle",{"search_budget":0})
	check(not result.ok and not result.consumed and scene.rules.replay_state()==before,"Bounded shuffle timeout leaves exact state and use unchanged")
	check(scene.has_node("ToolFeedback") and scene.get_node("ToolFeedback").text.contains("USE KEPT"),"Unproved shuffle explains that no use was spent")
	check(tool_cues.count("tool_shuffle")==0,"Failed shuffle does not play successful release audio")
	before=scene.rules.snapshot();result=scene.activate_tool("shuffle")
	check(result.ok and result.consumed and result.proof.kind=="complete_timed_victory_replay","Shuffle button commits only a verified timed winner")
	if result.ok:
		proofs.append(result.proof)
		check(scene.rules.board==before.board and scene.rules.inventory==before.inventory and scene.rules.tasks==before.tasks and scene.rules.time_us==before.time_us,"Verified shuffle changes candidates only")
		var copy=scene.rules.duplicate_for_replay()
		for input in result.proof.inputs:copy.update_us(int(input.time_us)-copy.time_us);check(copy.select_front(input.column_id,input.team_id).ok,"UI shuffle proof contains legal timed input")
		copy.update_us(1000000000);check(copy.status=="victory" and copy.time_us==int(result.proof.terminal_time_us),"UI shuffle proof independently reaches final-hit victory")
	check(tool_cues.count("tool_shuffle")==1 and count_effect(scene,"swirl")==1,"Verified shuffle success drives one sound and one swirl")
	check(scene.rules.conservation_errors().is_empty(),"All four actual UI tool paths conserve quotas and beads")
	var path:Array=[[9,1],[9,0],[8,0],[7,0]]
	var start:Dictionary=scene.sample_carrier_path(path,0);var end:Dictionary=scene.sample_carrier_path(path,1)
	check(start.position==scene.map_path_point(path[0]) and end.position==scene.map_path_point(path[-1]),"Visual arc-length interpolation preserves exact path endpoints")
	await remove_scene(scene)
func tap(scene:Control,node:Control)->void:
	var point:Vector2=node.get_global_rect().get_center()
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;event.global_position=point
		scene.get_viewport().push_input(event,true)
func test_tool_pointer_routes()->void:
	var scene:=make(directory("tool-pointer"),true)
	await process_frame
	tap(scene,scene.get_node("ToolTray/ToolButton0"))
	check(scene.rules.slots.size()==6,"Actual pointer on extra-slot icon reaches rule use")
	tap(scene,scene.get_node("CandidateQueues/Column1/FrontButton"))
	check(scene.rules.status=="running","Actual pointer starts a front team before recall")
	tap(scene,scene.get_node("ToolTray/ToolButton2"))
	check(scene.modal_title=="RECALL A TEAM" and scene.rules.paused,"Actual recall icon pointer opens paused target selector")
	await process_frame
	tap(scene,scene.pause_overlay.get_node("Button_CANCEL"));await process_frame
	check(not scene.rules.paused and scene.rules.tool_uses.get("recall",0)==0,"Actual Cancel pointer resumes without spending recall")
	tap(scene,scene.get_node("ToolTray/ToolButton2"));await process_frame
	tap(scene,scene.pause_overlay.get_node("RecallChoice0"));await process_frame
	check(scene.rules.tool_uses.get("recall",0)==1 and not scene.rules.paused,"Actual target pointer confirms one conserving recall")
	tap(scene,scene.get_node("ToolTray/ToolButton3"))
	check(scene.rules.tool_uses.get("scout",0)==1 and not scene.rules.paused and scene.has_node("ScoutHints/FrontTeam"),"Actual scout icon pointer gives a live nonmodal highlight")
	tap(scene,scene.get_node("ToolTray/ToolButton1"))
	check(scene.rules.tool_uses.get("shuffle",0)==1 and not scene.rules.paused,"Actual shuffle icon pointer reaches verified success")
	check(scene.rules.conservation_errors().is_empty(),"All four pointer routes preserve conservation")
	await remove_scene(scene)

func win(scene:Control)->void:
	for entry in scene.level_config.validation.no_tool_solution:
		scene.rules.update_us(int(entry.time_us)-scene.rules.time_us)
		check(scene.rules.select_front(entry.column_id,entry.team_id).ok,"Real level final-hit replay input accepted")
	scene.rules.update_us(120000000);scene.sync_view();scene.consume_rule_events()
func test_victory_and_navigation()->void:
	var path:=directory("victory");var seed:=Saves.new(path);seed.load_save();seed.set_tutorial_completed(true)
	var scene:=make(path);var old:=bytes(path)
	scene.saves.test_fail_stage="replace_primary";win(scene)
	check(scene.rules.status=="victory" and not scene.victory_saved and scene.pending_save_kind=="victory","Victory save failure is not reported as saved")
	check(bytes(path)==old and scene.profile_state.available_unlocked==1,"Failed victory cannot unlock level two")
	check(scene.fx.dragon_pose().visible and not scene.fx.dragon_pose().defeat_complete,"Final-hit victory starts a finite collapse even when save fails")
	scene.fx.advance(scene.fx.DRAGON_DEFEAT_DURATION);scene.apply_actor_poses();scene.present_pending_outcome()
	check(not scene.get_node("DragonRoute/Dragon").visible and scene.rules.status=="victory","Collapse ends without delaying or changing the already-settled victory")
	scene.show_outcome(true)
	check(scene.modal_title=="COULDN'T SAVE" and not scene.pause_overlay.has_node("Button_NEXT LEVEL"),"Save failure offers Retry Save, not Next")
	check_labels(scene,"victory save error")
	scene.close_current_modal();check(scene.modal_title=="COULDN'T SAVE","Victory-save X cannot discard pending result")
	scene.saves.test_fail_stage="";scene.retry_save()
	check(scene.victory_saved and scene.profile_state.available_unlocked==2 and scene.pause_overlay.has_node("Button_NEXT LEVEL"),"Retry Save commits unlock before exposing Next")
	check_labels(scene,"saved victory")
	var completed:=bytes(path);scene.persist_victory();check(bytes(path)==completed,"Duplicate victory save is idempotent")
	scene.close_current_modal();check(scene.modal_title=="CHOOSE A LEVEL","Saved victory X opens actual catalog")
	check(not scene.pause_overlay.get_node("LevelButton2").disabled and scene.pause_overlay.get_node("LevelButton3").disabled,"Only the sequential next entry becomes available")
	scene.close_current_modal();check(scene.modal_title=="PRINCESS SAVED!","Terminal picker X returns to result")
	scene.replace_level(2);await process_frame
	var next:Control=await await_loaded_play()
	check(next!=scene and next.level_index==2 and next.rules.time_us==0 and next.rules.status=="ready","Next persists selected entrance and constructs fresh level two")
	check(next.profile_state.current_entrance.level_id=="validation-02","Next entrance is durable")
	next.preview_select_front(0,str(next.rules.columns[0].teams[0].id));next.rules.update_us(250000)
	check(next.rules.status=="running","Restart fixture has genuinely started")
	await remove_scene(next)
	next=make(path)
	check(next.level_index==2 and next.rules.status=="ready" and next.rules.time_us==0 and next.rules.tasks.is_empty() and next.rules.slots.size()==5,"Process recreation resumes saved entrance, not ants/clock/extra slots")
	await remove_scene(next)
func test_recovery()->void:
	var path:=directory("corrupt");var seed:=Saves.new(path);seed.load_save();seed.set_tutorial_completed(true);seed.set_volumes(31,42)
	var broken:=FileAccess.open(path+"/save.json",FileAccess.WRITE);broken.store_string("{damaged");broken.close()
	var scene:=make(path)
	check(not scene.profile_state.ready and scene.rules.paused and scene.modal_title=="COULDN'T LOAD","Corrupt primary blocks play and presents recovery")
	check(FileAccess.get_file_as_string(path+"/save.json")=="{damaged","Corrupt primary is not silently overwritten")
	check(FileAccess.file_exists(scene.profile_state.corrupt_backup_path),"Damaged bytes have preserved recovery evidence")
	check_labels(scene,"recovery")
	scene.close_current_modal();check(scene.modal_title=="COULDN'T LOAD" and scene.rules.paused,"Recovery X cannot bypass failed load")
	scene.reset_saved_progress();check(FileAccess.get_file_as_string(path+"/save.json")=="{damaged","Reset method cannot proceed without explicit confirmation")
	scene.confirm_progress_reset();check_labels(scene,"reset confirmation")
	scene.pause_overlay.get_node("Button_CANCEL").pressed.emit();check(FileAccess.get_file_as_string(path+"/save.json")=="{damaged","Cancel reset preserves primary")
	scene.restore_backup();await process_frame
	var recovered:Control=await await_loaded_play()
	check(recovered.profile_state.ready and recovered.level_index==1,"Explicit backup action recovers a playable saved entrance")
	await remove_scene(recovered)
	path=directory("future");seed=Saves.new(path);seed.load_save()
	var record:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path+"/save.json"));record.schema_version=999
	broken=FileAccess.open(path+"/save.json",FileAccess.WRITE);broken.store_string(JSON.stringify(record));broken.close()
	scene=make(path)
	check(not scene.profile_state.ready and not scene.pause_overlay.has_node("Button_RESET PROGRESS") and not scene.pause_overlay.has_node("Button_RESTORE BACKUP"),"Future schema is blocked without downgrade/reset controls")
	await remove_scene(scene)
func test_invalid_level_shell()->void:
	var path:=directory("level-error")
	var scene=load("res://scenes/play.tscn").instantiate()
	scene.profile_directory=path;scene.qa_fixture_mode=true;scene.use_command_line_level=false
	scene.qa_level_config={"schema_version":1}
	root.add_child(scene);scene.set_process(false)
	check(scene.rules.status=="load_error" and not scene.ready_to_simulate,"Invalid configuration never starts simulation")
	check(scene.modal_title=="COULDN'T LOAD" and scene.pause_overlay.has_node("Button_TRY AGAIN") and scene.pause_overlay.has_node("Button_LEVEL SELECT"),"Invalid config has a navigable retry/level error shell")
	check(not scene.has_node("Mosaic"),"Load failure does not fabricate a board")
	check_labels(scene,"technical load error")
	var parsed:Dictionary=scene.read_level_configuration(path+"/missing.json")
	check(not parsed.ok and parsed.reason=="level_file_missing","Missing level source is classified safely")
	var broken:=FileAccess.open(path+"/invalid-level.json",FileAccess.WRITE);broken.store_string("[invalid json");broken.close()
	parsed=scene.read_level_configuration(path+"/invalid-level.json")
	check(not parsed.ok and parsed.reason=="invalid_level_json","Malformed level JSON is classified safely")
	scene.close_current_modal();check(scene.modal_title=="CHOOSE A LEVEL","Technical error X reaches real catalog")
	scene.close_current_modal();check(scene.modal_title=="COULDN'T LOAD","Technical-error catalog X returns to error, not an empty play screen")
	# Remove the deliberate QA fault, then retry the actual unchanged resource.
	scene.qa_level_config.clear();scene.pause_overlay.get_node("Button_TRY AGAIN").pressed.emit();await process_frame
	var next:Control=await await_loaded_play()
	check(next.rules.status=="ready" and next.ready_to_simulate and next.has_node("Mosaic"),"Retry reloads repaired content into a real fresh scene")
	await remove_scene(next)

func test_real_level_three_slot()->void:
	var path:=directory("level-three");var seed:=Saves.new(path);seed.load_save();seed.set_tutorial_completed(true)
	seed.mark_complete("validation-01","fixture");seed.mark_complete("validation-02","fixture");seed.set_current_entrance("validation-03")
	var scene:=make(path)
	check(scene.level_index==3 and not scene.get_node("ToolTray/ToolButton0").disabled,"Real level-three context legitimately unlocks the extra-slot tool")
	for i in range(1,4):check(scene.get_node("ToolTray/ToolButton%d"%i).disabled,"Later tool %d remains locked outside QA"%i)
	var result:Dictionary=scene.activate_tool("extra_slot");check(result.ok and scene.slots.size()==6,"Six-slot layout is usable on actual level three")
	win(scene);scene.show_outcome(true)
	check(scene.victory_saved and scene.profile_state.highest_unlocked==4 and scene.profile_state.available_unlocked==3,"Third completion saves future unlock but exposes only actual content")
	check(not scene.pause_overlay.has_node("Button_NEXT LEVEL"),"Third level never offers missing level four")
	await remove_scene(scene)

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
