extends SceneTree
## First-level-only modal geometry and real controller/synthetic input regression.
## Headless data is not GL, native touch, animation or visual acceptance.
const Saves=preload("res://scripts/save_service.gd")
const Catalog=preload("res://scripts/level_catalog.gd")
var checks:=0
var failures:Array[String]=[]
var layouts:Array[Dictionary]=[]
var profile:="/tmp/ant-rescue-mobile-modal-%d"%Time.get_ticks_usec()
func _initialize()->void:call_deferred("run")
func check(value:bool,note:String)->void:
	checks+=1
	if not value:failures.append(note);push_error(note)
func press(parent:Node,path:String)->void:
	var button=parent.get_node_or_null(path)
	check(button is Button,"Button exists: "+path)
	if button is Button:button.pressed.emit()
func rest_rect(control:Control)->Rect2:
	return Rect2(control.get_meta(&"ui_motion_rest",{"position":control.position}).position,control.size)
func inspect_layout(scene:Control,context:String)->void:
	await create_timer(.28).timeout
	var m:Control=scene.pause_overlay
	var panel:=rest_rect(m.get_node("ModalPanel"))
	var buttons:Array[Control]=[]
	var labels:Array[Label]=[]
	var snapshot:Dictionary={"state":context,"panel":str(panel),"buttons":[],"labels":[]}
	check(Rect2(0,0,940,1672).encloses(panel),context+": panel stays inside logical canvas")
	for child in m.get_children():
		if child is Button:
			buttons.append(child)
			if str(child.name).begins_with("Button_"):
				check(child.size==Vector2(560,118),context+": painted action has 560×118 hit area")
				check(panel.encloses(rest_rect(child)),context+": action lies inside panel")
				var title:String=str(child.name).trim_prefix("Button_")
				var art:Control=m.get_node("Action_"+title)
				check(rest_rect(art).is_equal_approx(rest_rect(child)),context+": art and action hit bounds match")
				var texture:AtlasTexture=art.get_node("PaintedNineSlice").texture
				check(texture.region in [scene.skin.texture("game/primary").region,scene.skin.texture("game/secondary").region],context+": official primary/secondary skin, never row skin")
				var text:Label=m.get_node("Text_"+title)
				check(text.get_theme_font_size("font_size")==38,context+": action type is 38 logical px")
				var primary:bool=texture.region==scene.skin.texture("game/primary").region
				check(text.get_theme_color("font_color")== (Color.WHITE if primary else scene.INK),context+": primary/secondary text uses the shared readable color")
				check(text.get_theme_font("font").get_string_size(text.text,HORIZONTAL_ALIGNMENT_LEFT,-1,38).x<=text.size.x,context+": complete action label fits horizontally")
				check(rest_rect(child).encloses(rest_rect(text)),context+": action label stays inside button")
			if str(child.name)=="CloseButton":check(child.size==Vector2(120,120),context+": Close hit area is 120×120")
			snapshot.buttons.append({"name":str(child.name),"rect":str(rest_rect(child))})
		if child is Label:
			labels.append(child)
			var font_size:int=child.get_theme_font_size("font_size")
			check(font_size>=32,context+": modal information is not shrunk below 32")
			check(panel.encloses(rest_rect(child)),context+": body/label stays inside panel")
			var height:float=child.get_theme_font("font").get_height(font_size)*child.get_line_count()+child.get_theme_constant("line_spacing")*maxi(0,child.get_line_count()-1)
			check(height<=child.size.y+.1,context+": all wrapped lines fit "+str(child.name))
			check(child.position.is_equal_approx(rest_rect(child).position),context+": motion restores final position "+str(child.name))
			snapshot.labels.append({"name":str(child.name),"rect":str(rest_rect(child)),"font_size":font_size,"lines":child.get_line_count(),"text":child.text})
	for i in buttons.size():
		for j in range(i+1,buttons.size()):check(not rest_rect(buttons[i]).intersects(rest_rect(buttons[j])),context+": button targets never overlap")
		for label in labels:
			if str(buttons[i].name).trim_prefix("Button_")==str(label.name).trim_prefix("Text_"):continue
			check(not rest_rect(buttons[i]).intersects(rest_rect(label)),context+": unrelated text never intersects button")
	for i in labels.size():
		for j in range(i+1,labels.size()):check(not rest_rect(labels[i]).intersects(rest_rect(labels[j])),context+": label groups never overlap")
	layouts.append(snapshot)
func check_settings(scene:Control,context:String)->void:
	await create_timer(.28).timeout
	var m:Control=scene.pause_overlay
	var sliders:Array[Control]=[]
	for i in 2:
		var slider:HSlider=m.get_node("MusicVolume" if i==0 else "SoundVolume")
		var y:=714+i*133
		check(slider.position==Vector2(346,y-30.5) and slider.size==Vector2(355,118),context+": enlarged vertical input bounds are centered on original track")
		check(rest_rect(m.get_node("SliderTrack%d"%i))==Rect2(349,y,349,57),context+": painted track position/size unchanged")
		check(slider.get_theme_icon("grabber").get_size()==Vector2(49,49),context+": unchanged 49px grabber preserves horizontal range mapping")
		check(rest_rect(m.get_node("ModalPanel")).encloses(slider.get_rect()),context+": slider hit area stays inside panel")
		sliders.append(slider)
	check(not sliders[0].get_rect().intersects(sliders[1].get_rect()),context+": volume touch targets do not overlap")
func click_slider(scene:Control,id:String,value:float,local_y:float)->void:
	var slider:HSlider=scene.pause_overlay.get_node(id)
	var point:Vector2=slider.get_global_transform_with_canvas()*Vector2(24.5+value*3.06,local_y)
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;event.global_position=point
		root.push_input(event,true)
		await process_frame
	check(absf(slider.value-value)<=1.0,"Synthetic viewport input reaches enlarged slider band: "+id)
	var index:=0 if id=="MusicVolume" else 1
	check(is_equal_approx(scene.pause_overlay.get_node("PearlKnob%d"%index).position.x,346+slider.value*3.06),"Knob keeps original value-to-x mapping")
func back(scene:Control)->void:
	var event:=InputEventKey.new();event.keycode=KEY_ESCAPE;event.pressed=true
	scene._unhandled_key_input(event)
func dispose(scene:Control)->void:
	scene.audio_service.stop_music();scene.audio_service.stop_all_sfx()
	await create_timer(.3).timeout
	scene.queue_free();await process_frame;await process_frame
func settings_flow(scene:Control,from_pause:bool,failed:bool,use_back:bool)->void:
	var context:="pause" if from_pause else "gear"
	if is_instance_valid(scene.pause_overlay):scene.dismiss_modal()
	if from_pause:
		press(scene,"TopHUD/PauseButton");press(scene.pause_overlay,"Button_SETTINGS")
	else:press(scene,"TopHUD/SettingsButton")
	check(scene.modal_title=="SETTINGS" and scene.rules.paused,context+": entering settings freezes the running first level")
	check(scene.settings_return_to_pause==from_pause,context+": settings records its actual caller")
	var time_before:int=scene.rules.time_us
	scene.rules.update_us(1000000)
	check(scene.rules.time_us==time_before,context+": settings cannot advance gameplay time")
	var old_music:int=scene.profile_state.music_volume
	var old_sound:int=scene.profile_state.sfx_volume
	var chosen_sound:=23 if old_sound!=23 else 37
	scene.pause_overlay.get_node("MusicVolume").value=0
	scene.pause_overlay.get_node("SoundVolume").value=chosen_sound
	if failed:scene.saves.test_fail_stage="write_temp"
	if use_back:back(scene)
	else:press(scene.pause_overlay,"CloseButton")
	if failed:
		check(scene.modal_title=="COULDN'T SAVE" and scene.rules.paused,context+": failed close stays frozen and exposes failure")
		check(scene.profile_state.music_volume==old_music and scene.profile_state.sfx_volume==old_sound,context+": failed write retains committed values")
		await inspect_layout(scene,context+" settings-save failure")
		press(scene.pause_overlay,"Button_RETRY SAVE")
		check(scene.modal_title=="COULDN'T SAVE" and scene.settings_dirty,context+": repeated failed retry never leaves recovery")
		press(scene.pause_overlay,"Button_BACK")
		check(scene.modal_title=="SETTINGS" and scene.settings_return_to_pause==from_pause,context+": recovery Back keeps the original caller")
		check(scene.pause_overlay.get_node("SoundVolume").value==chosen_sound,context+": recovery Back keeps intended volume")
		back(scene)
		check(scene.modal_title=="COULDN'T SAVE",context+": repeated close still requires a successful write")
		press(scene.pause_overlay,"CloseButton")
		check(scene.modal_title=="SETTINGS" and scene.settings_return_to_pause==from_pause,context+": recovery X keeps the original caller")
		back(scene);scene.saves.test_fail_stage=""
		press(scene.pause_overlay,"Button_RETRY SAVE")
		check(scene.modal_title=="SETTINGS" and not scene.settings_dirty,context+": successful retry returns to Settings only after commit")
		check(scene.settings_return_to_pause==from_pause,context+": successful retry does not overwrite caller")
		if use_back:back(scene)
		else:press(scene.pause_overlay,"CloseButton")
	check(scene.modal_title==("PAUSED" if from_pause else ""),context+": X/Back returns to actual origin")
	check(scene.rules.paused==from_pause,context+": close preserves origin pause semantics")
	var disk:=Saves.new(scene.profile_directory,Catalog.level_ids(false),30)
	var read:Dictionary=disk.load_save()
	check(read.ok and read.state.music_volume==0 and read.state.sfx_volume==chosen_sound,context+": disk reload confirms intended volume and zero/mute")
func run()->void:
	var game=load("res://scenes/play.tscn").instantiate()
	game.profile_directory=profile.path_join("play");game.profile_directory_resolved=true;game.use_command_line_catalog=false;game.use_command_line_level=false;game.qa_fixture_mode=true
	root.add_child(game);current_scene=game;game.set_process(false)
	check(game.level_index==1 and game.level_config.level_id=="serpent-01","Only the approved first level is instantiated")
	check(game.select_color("blue") and game.rules.status=="running","Normal first-level color callback starts the round")
	var runs_before:int=game.progression._record.runs.size()
	for from_pause in [false,true]:
		for failed in [false,true]:
			for use_back in [false,true]:await settings_flow(game,from_pause,failed,use_back)
	check(game.progression._record.runs.size()==runs_before and game.economy_state.points==0,"Settings callbacks neither create runs nor award/spend points")
	game.dismiss_modal();press(game,"TopHUD/SettingsButton")
	# Change during the still-running entrance, before its original rest is restored.
	game.pause_overlay.get_node("MusicVolume").value=25
	game.pause_overlay.get_node("SoundVolume").value=75
	await check_settings(game,"play")
	for index in 2:
		var expected:float=25 if index==0 else 75
		var knob:Control=game.pause_overlay.get_node("PearlKnob%d"%index)
		check(knob.position.is_equal_approx(Vector2(346+expected*3.06,717+index*133)),"Early slider edit cannot snap back after modal entrance")
		check(rest_rect(knob).position.is_equal_approx(knob.position),"Dynamic knob rest position follows chosen volume")
	for value in [0,50,100]:
		await click_slider(game,"MusicVolume",value,4)
		await click_slider(game,"SoundVolume",value,114)
	press(game.pause_overlay,"CloseButton")
	game.level_load_reason="first_level_review_only"
	for name in ["show_pause","show_restart","show_leave","show_levels","request_home","show_error"]:
		game.call(name);await inspect_layout(game,"play/"+name)
		if name=="show_pause":
			check(game.pause_overlay.get_node("HomeButton").size==Vector2(120,120),"Pause keeps one Home with a mobile-size hit target")
			var button_count:=0
			for child in game.pause_overlay.get_children():
				if child is Button:button_count+=1
			check(button_count==6,"Pause keeps four actions, one Home and one Close only")
			press(game.pause_overlay,"Button_CONTINUE")
			check(not is_instance_valid(game.pause_overlay) and not game.rules.paused,"Continue returns to same running game")
		elif name in ["show_restart","show_leave","show_levels","request_home"]:
			press(game.pause_overlay,"Button_CANCEL")
			check(game.modal_title=="PAUSED" and game.rules.paused,"Confirmation Cancel returns to Pause without navigation")
	game.last_save_reason="storage_changed_retry_load"
	for kind in ["victory","settings","tutorial","entrance",""]:
		game.pending_save_kind=kind;game.show_save_error();await inspect_layout(game,"play/save-error/"+kind)
		if kind=="victory":check(not game.pause_overlay.has_node("Button_BACK"),"Victory save failure never offers a discard Back button")
	game.pending_save_kind=""
	game.profile_state.reason="backup_unsupported_schema";game.profile_state.recovery_allowed=true
	game.show_load_recovery();await inspect_layout(game,"play/load-recovery")
	game.confirm_progress_reset();await inspect_layout(game,"play/reset-confirmation")
	press(game.pause_overlay,"Button_CANCEL")
	check(not game.recovery_reset_confirm and game.modal_title=="COULDN'T LOAD","Cancel reset returns to recovery without resetting progress")
	await dispose(game)
	var home=load("res://scenes/startup.tscn").instantiate()
	home.profile_directory=profile.path_join("startup");home.use_command_line_catalog=false
	root.add_child(home);current_scene=home
	var deadline:=Time.get_ticks_msec()+8000
	while home.phase!="home" and Time.get_ticks_msec()<deadline:await process_frame
	check(home.phase=="home","Normal production startup reaches Home")
	if home.phase!="home":quit(1);return
	for phase in ["preparation","map"]:
		home.open_adventure(phase,1);home.show_settings()
		await check_settings(home,"startup/"+phase)
		press(home.pause_overlay,"CloseButton")
		check(home.modal_title=="" and home.phase==phase,"Startup Settings returns directly to same "+phase)
	for kind in ["settings","navigation","other"]:
		home.show_meta_failure("storage_changed_retry_load",kind=="settings",kind=="navigation")
		await inspect_layout(home,"startup/save-error/"+kind)
	# Longest real failure combinations are presentation fixtures, not later levels.
	home.profile_state.ready=false;home.profile_state.reason="backup_unsupported_schema";home.profile_state.recovery_allowed=true
	home.economy_state.ready=false;home.economy_state.reason="storage_changed_retry_load"
	home.show_profile_recovery("backup_unsupported_schema")
	await inspect_layout(home,"startup/load-recovery")
	await dispose(home)
	var report:Dictionary={"pass":failures.is_empty(),"checks":checks,"failures":failures,"layouts":layouts,"scope":"First-level-only headless controller and measured-node checks. Real X/Back/button callbacks, write-failure retry and disk reload. Synthetic viewport clicks cover expanded slider bands; this is NOT native input, GL rendering, touch-device, sound, visual or animation acceptance."}
	var path:="res://reports/first-level/mobile-modal-controls/layout-and-behavior.json"
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	print("FIRST_LEVEL_MOBILE_MODALS ",JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"report":path}));quit(0 if failures.is_empty() else 1)
