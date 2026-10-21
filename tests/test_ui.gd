extends SceneTree
var failures: Array[String]=[]
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(.12).timeout
	check(scene.audio_service.get_status().music_playing,"Actual BGM transport not started")
	check(scene.bead_nodes.size()>500,"High-density mosaic missing")
	check(scene.slots.size()==5,"Must have five work slots")
	check(scene.candidate_columns.size()==5,"Must have five candidate columns")
	for name in ["Environment","Mosaic","DragonRoute/Dragon","DragonRoute/PrincessTower","TransportScene/Cannon","TransportScene/Nest","TransportScene/Stock","TopHUD/CurrentArmorShield","TopHUD/NextArmorBlue","TopHUD/NextArmorYellow","ToolTray"]:
		check(scene.has_node(name),"Missing independent UI node: "+name)
	var f:Dictionary=scene.fixture
	for color in scene.COLORS:
		check(f.initial[color]==f.board[color]+f.stock[color]+f.carrying[color],"Board/inventory conservation: "+color)
		check(f.armor_total[color]==f.initial[color],"Armor conservation: "+color)
		var queue_total:=0
		for column in f.queues:
			for squad in column:
				if squad.color==color:queue_total+=squad.quota
		check(queue_total+f.active[color]==f.board[color],"Queue/active conservation: "+color)
	check(scene.get_node("DragonRoute/Dragon").size==Vector2(394,203),"Dragon atlas minimum size overrode display bounds")
	check(scene.ant_atlas!=null,"Production ant atlas missing")
	check(f.visual_only,"Must not imply completed gameplay")
	for col in scene.candidate_columns:
		check(col.has_node("FrontButton"),"Missing front-row input")
		check(not col.has_node("BackButton"),"Back rows must not be interactive")
	scene.show_settings()
	check(scene.audio_service.get_status().game_paused,"Modal must pause audio transport")
	check(scene.has_node("Modal/MusicVolume"),"Missing separate music control")
	check(scene.has_node("Modal/SoundVolume"),"Missing separate SFX control")
	scene.pause_overlay.queue_free()
	await process_frame
	scene.show_levels()
	check(scene.has_node("Modal/LevelTile30"),"Thirty-level selector missing")
	scene.pause_overlay.queue_free()
	await process_frame
	scene.show_tool_detail("RECALL","recall")
	check(scene.has_node("Modal/ToolDescription"),"Missing tool modal")
	scene.dismiss_modal()
	await process_frame
	scene.show_outcome(true)
	check(not scene.get_node("Mosaic").visible,"Victory must not show uncleared board")
	check(not scene.get_node("DragonRoute/Dragon").visible,"Victory must not show a live dragon")
	check(not scene.pause_overlay.has_node("Button_NEXT LEVEL"),"Unproduced next level must not be offered")
	scene.dismiss_modal()
	await process_frame
	check(scene.get_node("Mosaic").visible,"Modal dismissal must restore presentation")
	scene.show_settings()
	scene.pause_overlay.get_node("MusicVolume").value=35
	check(scene.audio_visual_state.music==35,"Music slider visual state missing")
	check(is_equal_approx(scene.audio_service.get_status().music_volume,.35),"Music slider not wired to audio bus")
	scene.pause_overlay.get_node("MusicVolume").value=0
	check(scene.audio_visual_state.music_muted,"Zero-volume music must be muted")
	check(scene.audio_service.get_status().music_muted,"Zero slider not wired to bus mute")
	check(is_equal_approx(scene.audio_service.get_status().sfx_volume,.7),"Music slider modified SFX bus")
	check(not scene.pause_overlay.has_node("Mute_music"),"Redundant mute switch must not exist")
	check(not scene.pause_overlay.has_node("BackButton"),"Settings must have only one close action")
	check(not scene.audio_visual_state.sound_muted,"Music mute must not toggle SFX")
	scene.dismiss_modal()
	await process_frame
	for screen in ["pause","settings","levels","victory","defeat","restart","leave","recall","blocked","error","save-error","tutorial"]:
		scene.show_screen(screen)
		await process_frame
		for label in scene.pause_overlay.find_children("*","Label",true,false):
			check(label.get_minimum_size().x<=label.size.x+1,"Label overflow in "+screen+": "+label.text)
		scene.dismiss_modal()
		await process_frame
	check(scene.fixture.queues[0][0].quota==20 and scene.fixture.queues[0][1].quota==30,"Distinct same-color preview teams missing")
	var rear_id:String=scene.fixture.queues[0][1].id
	var front_id:String=scene.fixture.queues[0][0].id
	check(not scene.preview_select_front(0,rear_id),"Rear team must not be selectable")
	check(scene.preview_select_front(0,front_id),"Front team selection failed")
	check(scene.slot_teams[3].quota==20,"Selected quota did not enter its own work slot")
	check(scene.fixture.queues[0][0].quota==30,"Rear team did not advance separately")
	check(not scene.preview_select_front(0,front_id),"Rapid repeated old-team click must not duplicate")
	check(not scene.preview_select_front(0,rear_id),"Transition must reject a second rapid dispatch")
	check(not scene.get_node("ToolTray").has_node("Tray"),"Skill outer tray must not return")
	check(not scene.get_node("ToolTray").has_node("ToolName0"),"Skill text must not return")
	var audio_before:int=scene.audio_service.get_status().accepted
	scene.show_settings()
	scene.pause_overlay.get_node("CloseButton").pressed.emit()
	check(scene.modal_title=="PAUSED","Settings X must return to pause")
	check(scene.audio_service.get_status().accepted>audio_before,"Real button click not bound to SFX")
	scene.dismiss_modal()
	await process_frame
	check(not scene.audio_service.get_status().game_paused,"Dismissal must restore audio transport")
	check(not scene.get_node("TopHUD").has_node("CurrentArmorTitle"),"Redundant armor label returned")
	check(not scene.get_node("TransportScene").has_node("AutoFireBanner"),"Redundant delivery banner returned")
	print(JSON.stringify({"pass":failures.is_empty(),"failures":failures,"beads":scene.bead_nodes.size(),"colors":f.board,"scope":"UI structure, independent audio buses and coherent visual fixture; gameplay simulation remains separate"},"\t"))
	await create_timer(.22).timeout
	scene.queue_free()
	await process_frame
	await create_timer(.12).timeout
	quit(0 if failures.is_empty() else 1)
