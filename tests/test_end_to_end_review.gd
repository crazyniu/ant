extends SceneTree
## One bounded real-scene journey. QA tool scenario and injected save fault are explicit.
## Automated viewport input/timing checks are NOT human playtesting or listening.
const Saves=preload("res://scripts/save_service.gd")
const Fixture=preload("res://tests/p3_fixture.gd")
const REPORT_DIR="user://review-evidence/flow-review"
var failures:Array[String]=[]
var checks:=0
var directories:Array[String]=[]
var actions:Array=[]
var event_log:Array=[]
var audio_log:Array=[]
var phase:="initial"
var lifecycle:Dictionary={}
var delivered:Dictionary={}
var spent:Dictionary={}
var witness_counts:Dictionary={}
var cue_waits:Dictionary={}
var fire_events:Dictionary={}
var timing_summary:Dictionary={}
func _initialize()->void:call_deferred("run")
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures.append(phase+": "+message);push_error(phase+": "+message)
func directory(label:String)->String:
	var path:String="/tmp/ant-rescue-e2e-%d-%d-%s"%[OS.get_process_id(),Time.get_ticks_usec(),label]
	directories.append(path);return path
func make(path:String,qa:bool=false)->Control:
	var scene=load("res://scenes/play.tscn").instantiate()
	scene.profile_directory=path;scene.use_command_line_level=false;scene.use_command_line_catalog=false;scene.campaign_drafts=not qa
	if qa:
		scene.qa_fixture_mode=true;scene.qa_level_config=Fixture.config()
		# Explicit QA-only split: the existing three red beads still have total quota 3.
		# It exposes two same-color team identities without inventing any resource.
		scene.qa_level_config.columns[0].teams[0].quota=2
		scene.qa_level_config.columns[0].teams.insert(1,{"id":"qa-red-twin","color":"red","quota":1})
	root.add_child(scene);scene.set_process(false);wire_audio(scene);return scene
func wire_audio(scene:Control)->void:
	scene.audio_service.cue_played.connect(func(id):audio_log.append({"phase":phase,"time_us":scene.rules.time_us,"cue":str(id),"result":"played"}))
	scene.audio_service.cue_dropped.connect(func(id,reason):audio_log.append({"phase":phase,"time_us":scene.rules.time_us,"cue":str(id),"result":"dropped","reason":str(reason)}))
func remove_scene(scene:Control)->void:
	if is_instance_valid(scene):scene.queue_free()
	await process_frame
func wait_real(seconds:float=.20)->void:await create_timer(seconds).timeout
func tap_at(scene:Control,point:Vector2)->void:
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;event.global_position=point
		scene.get_viewport().push_input(event,true)
func tap(scene:Control,node:Control)->void:
	actions.append({"phase":phase,"time_us":scene.rules.time_us,"pointer":str(node.get_path())})
	tap_at(scene,node.get_global_rect().get_center())
func key(scene:Control,keycode:Key)->void:
	for down in [true,false]:
		var event:=InputEventKey.new();event.keycode=keycode;event.pressed=down
		scene.get_viewport().push_input(event,true)
func save_bytes(scene:Control)->PackedByteArray:return FileAccess.get_file_as_bytes(scene.profile_directory+"/save.json")
func cues(id:String,result:String="played",in_phase:String="")->int:
	return audio_log.filter(func(entry):return entry.cue==id and entry.result==result and (in_phase.is_empty() or entry.phase==in_phase)).size()
func effects(scene:Control,kind:String)->int:
	return scene.fx.debug_snapshot().effects.filter(func(effect):return effect.kind==kind).size()
func bounded_labels(scene:Control,context:String)->void:
	if not is_instance_valid(scene.pause_overlay):return
	for label in scene.pause_overlay.find_children("*","Label",true,false):
		check(label.get_minimum_size().x<=label.size.x+1,"Label fits "+context+": "+label.text)
func slider_pointer(scene:Control,name:String,fraction:float)->void:
	var slider:Control=scene.pause_overlay.get_node(name)
	var rect:=slider.get_global_rect()
	tap_at(scene,Vector2(rect.position.x+rect.size.x*fraction,rect.get_center().y))
func drag_endpoint_knob(scene:Control,index:int,from_max:bool)->void:
	var knob:Control=scene.pause_overlay.get_node("PearlKnob%d"%index)
	var slider:Control=scene.pause_overlay.get_node("MusicVolume" if index==0 else "SoundVolume")
	var rect:=knob.get_global_rect()
	var start:=Vector2(rect.end.x-3 if from_max else rect.position.x+3,rect.get_center().y)
	var finish:=slider.get_global_rect().get_center()
	actions.append({"phase":phase,"drag_visible_outer_edge":str(knob.get_path()),"from_max":from_max,"start":str(start),"finish":str(finish)})
	var down:=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;down.position=start;down.global_position=start;scene.get_viewport().push_input(down,true)
	var motion:=InputEventMouseMotion.new();motion.position=finish;motion.global_position=finish;motion.relative=finish-start;motion.button_mask=MOUSE_BUTTON_MASK_LEFT;scene.get_viewport().push_input(motion,true)
	var up:=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false;up.position=finish;up.global_position=finish;scene.get_viewport().push_input(up,true)
func check_hud(scene:Control)->void:
	check(scene.get_node("TopHUD/ArmorLink1").visible==(scene.rules.armor_index+1<scene.rules.armors.size()),"First armor link exists only when a next armor exists")
	check(scene.get_node("TopHUD/ArmorLink2").visible==(scene.rules.armor_index+2<scene.rules.armors.size()),"Second armor link exists only when a third armor exists")
	check(scene.get_node("DragonRoute/RouteMarkers").visible==(scene.rules.status!="victory"),"Victory hides route markers instead of leaving a dead threat path")
	check(scene.get_node("TransportScene/AmmoCount").visible==(scene.rules.armor_index<scene.rules.armors.size()),"Ammo label is hidden after the final armor instead of showing stale zero-demand ammo")
func audit_pending(scene:Control)->void:
	var events:Array=scene.rules._events.duplicate(true)
	var needing_gap:=false
	var sound_map:Dictionary={"ant_dispatched":"dispatch","bead_picked_up":"pickup","bead_delivered":"return","cannon_fired":"cannon","armor_broken":"armor_hit"}
	for event in events:
		if sound_map.has(event.type):
			var cue:String=sound_map[event.type]
			if cues(cue,"played",phase)==0 and int(cue_waits.get(cue,0))<10:
				needing_gap=true;cue_waits[cue]=int(cue_waits.get(cue,0))+1
	if needing_gap:await wait_real(.17)
	var attempts_before:=audio_log.size()
	for event in events:
		event_log.append({"phase":phase,"event":event})
		witness_counts[event.type]=int(witness_counts.get(event.type,0))+1
		if event.type=="ant_dispatched":lifecycle[str(event.id)]={"depart_us":event.time_us,"pickup_us":event.pickup_us,"delivery_us":event.delivery_us,"color":event.color,"cell_id":event.cell_id,"picked":false,"delivered":false}
		elif event.type=="bead_picked_up":
			var task:Dictionary=lifecycle.get(str(event.id),{})
			check(not task.is_empty() and event.time_us==event.pickup_us and event.time_us>event.depart_us,"Pickup only at authoritative arrival for task %s"%event.id)
			check(not scene.rules.board.has(event.cell_id) and not scene.rules.reservations.has(event.cell_id),"Pickup removes exact real bead/reservation %s"%event.id)
			if not task.is_empty():task.picked=true
		elif event.type=="bead_delivered":
			var task:Dictionary=lifecycle.get(str(event.id),{})
			check(not task.is_empty() and task.get("picked",false) and event.time_us==event.delivery_us and event.delivery_us>event.pickup_us,"Delivery follows pickup and actual return time for task %s"%event.id)
			if not task.is_empty():task.delivered=true
			delivered[event.color]=int(delivered.get(event.color,0))+1
		elif event.type=="cannon_fired":
			var available:int=int(delivered.get(event.color,0))-int(spent.get(event.color,0))
			check(available>=int(event.amount),"Cannon cannot spend undelivered beads")
			spent[event.color]=int(spent.get(event.color,0))+int(event.amount);fire_events[str(event.id)]=event
			check(event.hit_us-event.fire_us==roundi(float(scene.level_config.parameters.projectile_flight_sec)*1000000),"Projectile uses authored nonzero flight time")
			check(scene.rules.status=="running" and scene.rules.armor_index==0,"Last armor is not broken early at firing")
		elif event.type=="armor_broken":
			check(fire_events.has(str(event.id)) and event.time_us==event.hit_us and event.hit_us>event.fire_us,"Only the scheduled real projectile hit breaks its armor")
		elif event.type=="victory":check(event.reason=="final_armor_hit" and scene.rules.armor_index==scene.rules.armors.size(),"Victory follows final authoritative hit, not animation")
	scene.sync_view();check_hud(scene);scene.consume_rule_events()
	for event in events:
		if sound_map.has(event.type):
			var cue:String=sound_map[event.type]
			check(audio_log.slice(attempts_before).any(func(entry):return entry.cue==cue),"Real event maps to accepted or explicitly dropped cue "+str(event.type))
		if event.type=="cannon_fired":check(scene.fx.debug_snapshot().projectiles.size()==1,"Fire renders a live projectile before hit")
		elif event.type=="armor_broken":check(scene.fx.debug_snapshot().projectiles.is_empty(),"Actual hit retires visual projectile")
		elif event.type=="victory":check(effects(scene,"confetti")>0,"Final-hit victory starts bounded confetti")
	for color in scene.COLORS:check(int(scene.get_node("TransportScene/Stock/Count_"+color).text)==int(scene.rules.inventory.get(color,0)),"Visible stock equals real delivered unspent "+color)
	check(scene.rules.conservation_errors().is_empty(),"Combined journey conserves all real quotas, beads, carriers, stock and spent ammo")
func advance_to(scene:Control,target:int)->void:
	var steps:=0
	while scene.rules.status=="running" and scene.rules.time_us<target and steps<2000:
		var next:int=mini(target,maxi(scene.rules.time_us+1,scene.rules._next_event_time()))
		scene.rules.update_us(next-scene.rules.time_us)
		await audit_pending(scene);steps+=1
	check(steps<2000,"Finite event-boundary stepping bound")
func seed_existing_tasks(scene:Control)->void:
	for task in scene.rules.tasks.values():
		if not lifecycle.has(str(task.id)):lifecycle[str(task.id)]={"depart_us":task.depart_us,"pickup_us":task.pickup_us,"delivery_us":task.delivery_us,"color":task.color,"cell_id":task.cell_id,"picked":false,"delivered":false}
func run()->void:
	root.size=Vector2i(1440,2560)
	await integrated_journey()
	await isolated_tool_journey()
	var report:Dictionary={"pass":failures.is_empty(),"assertions":checks,"failures":failures,"timing_summary":timing_summary,"event_counts":witness_counts,"actions":actions,"audio":audio_log,"engine":Engine.get_version_info().string,"audio_driver":AudioServer.get_driver_name(),"bgm_format":"native Ogg Vorbis","human_playtest":"NOT_RUN","human_listening":"NOT_RUN","scope":"One real authored campaign-01 end-to-end journey with viewport pointer/key input, genuine dragon-contact defeat and Retry, legal solution pointer inputs, exact pickup/return/fire/hit events, explicit injected replace_primary save fault and Retry Save, Next to campaign-02 and fresh-scene reload. One separate, explicit QA fixture tests all four tool icons and two same-color team identities. Not a 30-level sweep, visual acceptance, difficulty acceptance or hardware listening."}
	var file:=FileAccess.open(REPORT_DIR+"/end-to-end-flow-report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	file=FileAccess.open(REPORT_DIR+"/authoritative-event-trace.json",FileAccess.WRITE);file.store_string(JSON.stringify(event_log,"\t")+"\n");file.close()
	print("END_TO_END_REVIEW ",JSON.stringify(report))
	for path in directories:remove_directory(path)
	await wait_real(.8)
	quit(0 if failures.is_empty() else 1)
func remove_directory(path:String)->void:
	for subdirectory in DirAccess.get_directories_at(path):remove_directory(path.path_join(subdirectory))
	for file in DirAccess.get_files_at(path):DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)
func integrated_journey()->void:
	phase="fresh-tutorial-settings"
	var base:=directory("journey");var scene:=make(base);await process_frame;check_hud(scene)
	check(scene.level_config.level_id=="campaign-01" and scene.level_config.production_level_number==null and scene.rules.status=="ready" and scene.rules.time_us==0,"Fresh real authored campaign01, not promoted production content")
	check(scene.modal_title=="YOUR FIRST RESCUE" and scene.rules.paused and not scene.profile_state.tutorial_completed,"Fresh tutorial is deliberate and does not start threat")
	bounded_labels(scene,"tutorial")
	var frozen:Dictionary=scene.rules.snapshot();scene.rules.update_us(5000000)
	check(scene.rules.snapshot()==frozen,"Tutorial freezes actual gameplay")
	tap(scene,scene.pause_overlay.get_node("Button_LET'S GO"));await process_frame
	check(scene.profile_state.tutorial_completed and scene.rules.status=="ready" and not scene.rules.paused,"Tutorial primary pointer saves completion but leaves observation ready")
	tap(scene,scene.get_node("TopHUD/PauseButton"));await process_frame
	tap(scene,scene.pause_overlay.get_node("Button_SETTINGS"));await process_frame
	check(scene.modal_title=="SETTINGS" and scene.pause_overlay.has_node("AudioEmblem0") and scene.pause_overlay.has_node("AudioEmblem1"),"Settings uses actual note/speaker emblem nodes")
	bounded_labels(scene,"settings")
	check(scene.audio_service._music.stream is AudioStreamOggVorbis,"Integrated scene uses native compact OGG music")
	check(scene.rules.paused and scene.audio_service.get_status().music_preview and scene.audio_service.get_status().game_paused and not scene.audio_service.get_status().music_paused,"Settings allows BGM preview while actual gameplay stays paused")
	var settings_snapshot:Dictionary=scene.rules.snapshot();var preview_position:float=scene.audio_service.get_status().music_position
	scene.rules.update_us(4000000);await wait_real(.13)
	check(scene.rules.snapshot()==settings_snapshot and scene.audio_service.get_status().music_position>preview_position+.03,"Settings preview advances real music transport but no rule time")
	scene.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_OUT);await process_frame
	check(scene.audio_service.get_status().music_paused and scene.rules.paused,"Synthetic background lifecycle notification also silences settings preview")
	scene.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_IN);await process_frame
	check(not scene.audio_service.get_status().music_paused and scene.rules.snapshot()==settings_snapshot,"Foreground restores settings preview without unpausing gameplay")
	for index in range(2):
		var slider_name:String="MusicVolume" if index==0 else "SoundVolume"
		slider_pointer(scene,slider_name,0);await process_frame
		check(scene.pause_overlay.get_node(slider_name).value==0,"Pointer reaches actual zero endpoint on "+slider_name)
		drag_endpoint_knob(scene,index,false);await process_frame
		check(scene.pause_overlay.get_node(slider_name).value>20 and scene.pause_overlay.get_node(slider_name).value<80,"Visible zero-end outer knob edge really drags "+slider_name)
		slider_pointer(scene,slider_name,.999);await process_frame
		check(scene.pause_overlay.get_node(slider_name).value==100,"Pointer reaches actual maximum endpoint on "+slider_name)
		drag_endpoint_knob(scene,index,true);await process_frame
		check(scene.pause_overlay.get_node(slider_name).value>20 and scene.pause_overlay.get_node(slider_name).value<80,"Visible max-end outer knob edge really drags "+slider_name)
	slider_pointer(scene,"MusicVolume",0);await process_frame
	check(scene.audio_service.get_status().music_volume==0 and AudioServer.is_bus_mute(AudioServer.get_bus_index(scene.audio_service.MUSIC_BUS)),"Pointer to note slider zero mutes actual music bus")
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index(scene.audio_service.SFX_BUS)),"Music zero does not mute speaker bus")
	slider_pointer(scene,"SoundVolume",0);await process_frame
	check(scene.audio_service.get_status().sfx_volume==0 and AudioServer.is_bus_mute(AudioServer.get_bus_index(scene.audio_service.SFX_BUS)),"Pointer to speaker slider zero mutes actual SFX bus")
	check(scene.profile_state.music_volume==0 and scene.profile_state.sfx_volume==0,"Actual slider releases persist both zero values")
	var zero_record:Dictionary=JSON.parse_string(save_bytes(scene).get_string_from_utf8())
	check(zero_record.music_volume==0 and zero_record.sfx_volume==0,"Both zero gains are present in the actual save bytes, not just UI state")
	slider_pointer(scene,"MusicVolume",.31);await wait_real(.08)
	var previews_before:int=cues("ui_click","played",phase)
	slider_pointer(scene,"SoundVolume",.47);await process_frame
	check(cues("ui_click","played",phase)==previews_before+1,"Nonzero sound-slider release gives one actual accepted preview click")
	var saved_music:int=scene.profile_state.music_volume;var saved_sound:int=scene.profile_state.sfx_volume
	check(saved_music>0 and saved_sound>0 and not scene.audio_service.music_muted and not scene.audio_service.sfx_muted,"Positive pointer sliders restore independent channels and persist")
	tap(scene,scene.pause_overlay.get_node("CloseButton"));await process_frame
	check(scene.modal_title=="PAUSED" and scene.rules.paused and scene.audio_service.get_status().music_ducked and not scene.audio_service.get_status().music_paused,"Settings X returns to parent pause with softer continuing BGM")
	tap(scene,scene.pause_overlay.get_node("Button_SETTINGS"));await process_frame
	check(scene.pause_overlay.get_node("MusicVolume").value==saved_music and scene.pause_overlay.get_node("SoundVolume").value==saved_sound,"Reopened note/speaker sliders show committed values")
	key(scene,KEY_ESCAPE);await process_frame
	check(scene.modal_title=="PAUSED" and scene.rules.paused and scene.audio_service.get_status().music_ducked and not scene.audio_service.get_status().music_paused,"Settings ESC returns to parent pause with softer continuing BGM")
	tap(scene,scene.pause_overlay.get_node("Button_LEVEL SELECT"));await process_frame
	check(scene.modal_title=="LEAVE THIS LEVEL?","Pause level-select asks before discarding live board")
	tap(scene,scene.pause_overlay.get_node("Button_CANCEL"));await process_frame
	check(scene.modal_title=="PAUSED" and scene.rules.time_us==0,"Leave Cancel restores pause without beginning a run")
	key(scene,KEY_ESCAPE);await process_frame
	check(not is_instance_valid(scene.pause_overlay) and not scene.rules.paused and not scene.audio_service.get_status().music_paused,"Pause ESC resumes music and ready board")
	var front:Control=scene.get_node("CandidateQueues/Column1/FrontButton")
	var rear_point:Vector2=front.get_global_rect().get_center()+Vector2(0,57*scene.scale.y)
	var queue_count:int=scene.rules.columns[0].teams.size();tap_at(scene,rear_point)
	check(scene.rules.columns[0].teams.size()==queue_count and scene.rules.status=="ready","Rear visual rows do not dispatch or start dragon")
	for i in range(4):
		var button:Button=scene.get_node("ToolTray/ToolButton%d"%i);tap(scene,button)
		check(button.disabled and int(scene.rules.tool_uses.get(scene.TOOL_IDS[i],0))==0,"Locked real level-one icon cannot consume use")
	phase="genuine-defeat-retry"
	tap(scene,scene.get_node("CandidateQueues/Column1/FrontButton"));await process_frame
	check(scene.rules.status=="running" and scene.rules.slots[0].id=="green-01","Actual front pointer starts correct same-color team in first work slot")
	check(scene.get_node("WorkSlots/Quota0").text==str(scene.rules.slots[0].remaining),"Real displayed work quota reflects dispatch debit")
	var early_board:int=scene.rules.board.size();var early_task:Dictionary=scene.rules.tasks.values()[0].duplicate(true)
	check(scene.rules.board.has(early_task.cell_id) and scene.rules.reservations.has(early_task.cell_id) and int(scene.rules.inventory.green)==0,"Outbound carrier reserves bead but creates no stock")
	scene.rules.update_us(int(early_task.pickup_us)-1);scene.sync_view();check_hud(scene);scene.consume_rule_events()
	check(scene.rules.board.size()==early_board and int(scene.rules.inventory.green)==0,"Before first arrival the board and stock remain uncollected")
	var before_time:int=scene.rules.time_us
	tap(scene,scene.get_node("TopHUD/SpeedButton"));scene.sync_view();check_hud(scene);scene.consume_rule_events()
	check(scene.rules.speed_multiplier==2,"Actual speed control enters x2")
	tap(scene,scene.get_node("TopHUD/PauseButton"));await process_frame
	var paused_rules:Dictionary=scene.rules.snapshot();var paused_fx:Dictionary=scene.fx.debug_snapshot()
	scene.rules.update_us(8000000);scene.fx.advance(8);await wait_real(.16)
	check(scene.rules.snapshot()==paused_rules and scene.fx.debug_snapshot()==paused_fx,"Pause freezes authoritative run and FX together")
	check(scene.rules.speed_multiplier==1 and scene.audio_service.get_status().music_ducked and not scene.audio_service.get_status().music_paused,"Pause resets speed to x1 while OGG music continues at menu gain")
	tap(scene,scene.pause_overlay.get_node("Button_RESTART"));await process_frame
	key(scene,KEY_ESCAPE);await process_frame
	check(scene.modal_title=="PAUSED" and scene.rules.time_us==before_time,"Restart ESC returns to pause without changing real elapsed time")
	tap(scene,scene.pause_overlay.get_node("Button_CONTINUE"));await process_frame
	check(not scene.rules.paused and not scene.audio_service.get_status().music_paused,"Continue pointer resumes both gameplay and OGG transport")
	# One real front cannot satisfy authored 62-bead armor. Let the actual dragon arrive.
	scene.rules.update_us(28000000-scene.rules.time_us);scene.sync_view();check_hud(scene);scene.consume_rule_events()
	check(scene.rules.status=="running" and scene.warning_played and cues("warning","played",phase)==1,"Crossing genuine 80-percent threat threshold emits one warning")
	scene.consume_rule_events();check(cues("warning","played",phase)==1,"Repeated event drain does not repeat warning")
	scene.rules.update_us(10000000);scene.sync_view();check_hud(scene);scene.consume_rule_events()
	check(scene.rules.status=="defeat" and scene.rules.terminal_reason=="dragon_contact" and scene.rules.time_us==34000000,"Defeat is genuine authored dragon contact, not a forced outcome")
	check(scene.profile_state.completed_levels.is_empty() and scene.rules.conservation_errors().is_empty(),"Defeat unlocks nothing and preserves conservation")
	await wait_real(.75)
	check(scene.modal_title=="TRY AGAIN" and scene.pause_overlay.has_node("Button_RETRY") and not scene.pause_overlay.has_node("Button_NEXT LEVEL"),"Actual delayed defeat flow offers Retry without invented Next")
	check(cues("lose","played",phase)==1,"Genuine defeat emits exactly one actual loss cue")
	bounded_labels(scene,"defeat")
	var old_run:int=scene.rules.run_id
	tap(scene,scene.pause_overlay.get_node("Button_RETRY"));scene=await await_loaded_play();scene.set_process(false);wire_audio(scene);await process_frame
	check(scene.level_index==1 and scene.rules.run_id!=old_run and scene.rules.status=="ready" and scene.rules.time_us==0 and scene.rules.board.size()==early_board and scene.rules.tasks.is_empty(),"Actual Retry pointer replaces run with full fresh authored board")
	check(scene.audio_visual_state.music==saved_music and scene.audio_visual_state.sound==saved_sound and not is_instance_valid(scene.pause_overlay),"Retry retains persisted positive sliders and completed tutorial")
	phase="legal-victory-save-fault"
	lifecycle.clear();delivered.clear();spent.clear();cue_waits.clear();fire_events.clear()
	var committed:=save_bytes(scene);scene.saves.test_fail_stage="replace_primary"
	actions.append({"phase":phase,"injected_test_fault":"SaveService.test_fail_stage = replace_primary","scope":"unique /tmp profile only"})
	for entry in scene.level_config.validation.no_tool_solution:
		await advance_to(scene,int(entry.time_us));await wait_real(.20)
		var column_index:=-1
		for i in scene.rules.columns.size():
			if scene.rules.columns[i].id==entry.column_id:column_index=i
		check(column_index>=0 and scene.rules.columns[column_index].teams[0].id==entry.team_id,"Authored timed input targets real currently exposed team "+str(entry.team_id))
		tap(scene,scene.get_node("CandidateQueues/Column%d/FrontButton"%(column_index+1)));seed_existing_tasks(scene)
		check(scene.rules.slots.any(func(team):return team!=null and team.id==entry.team_id) or scene.rules.tasks.values().any(func(task):return task.team_id==entry.team_id),"Pointer selected exact distinct same-color team "+str(entry.team_id))
	await advance_to(scene,60000000)
	check(scene.rules.status=="victory" and scene.rules.board.is_empty() and scene.rules.tasks.is_empty() and int(scene.rules.spent_counts.green)==62,"Legal pointer sequence spends exactly all 62 real beads and wins")
	check(not scene.victory_saved and scene.pending_save_kind=="victory" and save_bytes(scene)==committed and scene.profile_state.available_unlocked==1,"Injected save fault preserves previous bytes and cannot falsely unlock Next")
	check(scene.rules.terminal_reason=="final_armor_hit" and witness_counts.get("victory",0)==1,"Final hit settles victory once immediately, independent of finite dragon outro and save failure")
	var terminal_time:int=scene.rules.time_us
	scene._process(.62)
	check(not scene.get_node("DragonRoute/Dragon").visible and scene.rules.time_us==terminal_time,"Finite terminal presentation disappears by 0.62 seconds without changing outcome time")
	await wait_real(.75)
	check(scene.modal_title=="COULDN'T SAVE" and scene.pause_overlay.has_node("Button_RETRY SAVE") and not scene.pause_overlay.has_node("Button_NEXT LEVEL"),"Delayed outcome truthfully shows pending save and Retry Save")
	check(cues("win","played",phase)==1,"Only one final-hit victory cue is played")
	for cue in ["dispatch","pickup","return","cannon","armor_hit"]:check(cues(cue,"played",phase)>0,"At least one real accepted gameplay cue "+cue)
	bounded_labels(scene,"save fault")
	key(scene,KEY_ESCAPE);await process_frame
	check(scene.modal_title=="COULDN'T SAVE" and scene.pending_save_kind=="victory","ESC cannot discard an unsaved genuine win")
	scene.saves.test_fail_stage="";tap(scene,scene.pause_overlay.get_node("Button_RETRY SAVE"));await process_frame
	check(scene.victory_saved and scene.profile_state.completed_levels.has("campaign-01") and scene.profile_state.available_unlocked==2 and scene.modal_title=="PRINCESS SAVED!","Retry Save pointer commits real completion before revealing Next")
	check(cues("win","played",phase)==1,"Retry Save does not replay the outcome jingle")
	bounded_labels(scene,"saved victory")
	timing_summary={"defeat_us":34000000,"victory_us":scene.rules.time_us,"fire_events":fire_events,"picked_tasks":lifecycle.size(),"all_returned":lifecycle.values().all(func(task):return task.picked and task.delivered),"saved_music":saved_music,"saved_sound":saved_sound}
	check(timing_summary.all_returned and lifecycle.size()==62,"Every genuine victorious carrier completes pickup then return")
	phase="next-and-reload"
	tap(scene,scene.pause_overlay.get_node("Button_NEXT LEVEL"));scene=await await_loaded_play();scene.set_process(false);wire_audio(scene);await process_frame
	check(scene.level_config.level_id=="campaign-02" and scene.profile_state.current_entrance.level_id=="campaign-02" and scene.rules.time_us==0 and scene.rules.status=="ready","Next pointer durably enters fresh authored level two")
	var next_board:Dictionary=scene.rules.board.duplicate(true)
	tap(scene,scene.get_node("CandidateQueues/Column1/FrontButton"));scene.rules.update_us(500000);scene.sync_view();check_hud(scene);scene.consume_rule_events()
	check(scene.rules.status=="running" and scene.rules.time_us>0,"Level two genuinely starts before recreation")
	await remove_scene(scene);scene=make(base);await process_frame
	check(scene.level_index==2 and scene.rules.status=="ready" and scene.rules.time_us==0 and scene.rules.board==next_board and scene.rules.tasks.is_empty() and scene.rules.slots.size()==5,"Scene recreation restores saved entrance but fresh board, clock, carriers and slots")
	check(scene.audio_visual_state.music==saved_music and scene.audio_visual_state.sound==saved_sound and scene.profile_state.completed_levels.has("campaign-01"),"Recreation restores both slider values and genuine completion")
	await remove_scene(scene)
func isolated_tool_journey()->void:
	phase="explicit-isolated-qa-tools"
	var scene:=make(directory("qa-tools"),true);await process_frame
	check(scene.qa_fixture_mode and scene.level_config.content_version=="qa-p3-ui" and scene.level_config.production_level_number==null,"Tool scenario is explicitly isolated QA, never authored production progression")
	check(scene.rules.initial_counts.red==3 and scene.rules.conservation_errors().is_empty(),"Same-color QA split preserves exactly three real red beads")
	tap(scene,scene.get_node("ToolTray/ToolButton2"));await process_frame
	check(not scene.rules.paused and scene.rules.tool_uses.get("recall",0)==0 and scene.get_node("ToolFeedback").text=="NO ACTIVE TEAM · USE KEPT" and cues("tool_recall","played",phase)==0,"Actual empty recall icon fails without pause, use or success sound")
	tap(scene,scene.get_node("ToolTray/ToolButton0"));await process_frame
	check(scene.rules.slots.size()==6 and scene.slots.size()==6 and scene.rules.tool_uses.get("extra_slot",0)==1 and cues("tool_plus","played",phase)==1 and effects(scene,"plus")==1,"Actual extra-slot icon creates sixth real slot with one success sound/FX")
	for i in range(5):check(not scene.slots[i].get_rect().intersects(scene.slots[i+1].get_rect()),"Six real slots do not overlap")
	tap(scene,scene.get_node("ToolTray/ToolButton0"));check(cues("tool_plus","played",phase)==1,"Consumed disabled extra-slot pointer cannot repeat success")
	tap(scene,scene.get_node("CandidateQueues/Column1/FrontButton"));await wait_real(.20)
	tap(scene,scene.get_node("CandidateQueues/Column1/FrontButton"));await process_frame
	check(scene.rules.slots[0].id=="qa-red" and scene.rules.slots[1].id=="qa-red-twin" and scene.rules.slots[0].color==scene.rules.slots[1].color,"Two actual front pointers retain separate same-color team identities")
	var before:Dictionary=scene.rules.snapshot();var outgoing:Dictionary=scene.rules.tasks.duplicate(true);var reserved:Dictionary=scene.rules.reservations.duplicate(true)
	tap(scene,scene.get_node("ToolTray/ToolButton2"));await process_frame
	check(scene.modal_title=="RECALL A TEAM" and scene.rules.paused and scene.pause_overlay.has_node("RecallChoice0") and scene.pause_overlay.has_node("RecallChoice1"),"Recall icon shows both actual same-color slot targets and pauses")
	bounded_labels(scene,"recall")
	tap(scene,scene.pause_overlay.get_node("Button_CANCEL"));await process_frame
	check(not scene.rules.paused and scene.rules.tool_uses.get("recall",0)==0 and scene.rules.tasks==outgoing and scene.rules.reservations==reserved and scene.rules.slots==before.slots,"Recall Cancel leaves quota, team identities, carriers and reservations unchanged")
	tap(scene,scene.get_node("ToolTray/ToolButton2"));await process_frame
	var mismatch:Dictionary=scene.confirm_recall(0,"qa-red-twin")
	check(not mismatch.ok and not mismatch.consumed and scene.rules.paused and scene.rules.slots[0].id=="qa-red" and cues("tool_recall","played",phase)==0,"Wrong same-color identity cannot recall another slot or play success")
	tap(scene,scene.pause_overlay.get_node("RecallChoice1"));await process_frame
	check(not scene.rules.paused and scene.rules.slots[1]==null and scene.rules.slots[0].id=="qa-red" and scene.rules.columns[0].teams[0].id=="qa-red-twin","Actual second target pointer returns only the chosen same-color team")
	check(scene.rules.tasks==outgoing and scene.rules.reservations==reserved and scene.rules.tool_uses.get("recall",0)==1 and cues("tool_recall","played",phase)==1 and effects(scene,"recall")==1,"Successful recall conserves carriers/reservations and emits one success cue/FX")
	tap(scene,scene.get_node("ToolTray/ToolButton3"));await process_frame
	check(not scene.rules.paused and scene.has_node("ScoutHints/FrontTeam") and scene.rules.tool_uses.get("scout",0)==1 and cues("tool_hint","played",phase)==1 and effects(scene,"scout")==1,"Actual scout icon creates live hint without pausing and one success cue/FX")
	var exact_before:Dictionary=scene.rules.replay_state()
	var failed:Dictionary=scene.activate_tool("shuffle",{"search_budget":0})
	check(not failed.ok and not failed.consumed and scene.rules.replay_state()==exact_before and cues("tool_shuffle","played",phase)==0 and scene.get_node("ToolFeedback").text.contains("USE KEPT"),"Explicit bounded zero-budget shuffle failure changes nothing and plays no success cue")
	tap(scene,scene.get_node("ToolTray/ToolButton1"));await process_frame
	check(scene.rules.tool_uses.get("shuffle",0)==1 and cues("tool_shuffle","played",phase)==1 and effects(scene,"swirl")==1,"Actual shuffle icon commits verified success with exactly one sound/FX")
	check(scene.rules.conservation_errors().is_empty() and scene.rules.board.size()==18,"All four real tool paths conserve the isolated QA board and quotas")
	for i in range(4):check(scene.get_node("ToolTray/ToolButton%d"%i).disabled and scene.get_node("ToolTray/Uses%d"%i).text=="0","All four consumed icons show truthful zero-use disabled state")
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
