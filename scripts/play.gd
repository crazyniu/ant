extends "res://scripts/main.gd"
## P3 adapter: rules own gameplay; verified local saves own progression.
## Presentation consumes events and never settles gameplay from animation.
const Rules = preload("res://scripts/rescue_rules.gd")
const FX = preload("res://scripts/rescue_fx.gd")
const CarrierMotion = preload("res://scripts/carrier_motion.gd")
const Saves = preload("res://scripts/save_service.gd")
const Catalog = preload("res://scripts/level_catalog.gd")
# Retained as the default catalog contract; opt-in entries use level_ids below.
const LEVEL_IDS = ["validation-01", "validation-02", "validation-03"]
var level_ids: Array[String] = Catalog.level_ids(false)
var campaign_drafts := false
var use_command_line_catalog := true
var profile_directory_resolved := false
var level_selector_page := -1
var entry_screen := ""
var from_startup := false
var chooser_from_home := false
const TOOL_IDS = ["extra_slot", "shuffle", "recall", "scout"]
const TOOL_KINDS = ["plus", "shuffle", "recall", "hint"]
var profile_directory := ""
# Explicit isolated test fixtures only. Normal entry never uses this override.
var qa_fixture_mode := false
var qa_level_config: Dictionary = {}
var saves: RefCounted
var profile_state: Dictionary = {}
var victory_saved := false
var pending_save_kind := ""
var pending_entrance := 0
var last_save_reason := ""
var recall_selection: Dictionary = {}
var settings_dirty := false
var recovery_reset_confirm := false
var scout_result: Dictionary = {}
var scout_seconds := 0.0
var feedback_serial := 0
var replacement_pending := false
var level_load_reason := ""
static var next_run_serial:=0
var level_index:=1
var use_command_line_level:=true
var rules:RefCounted
var fx:Control
var level_config:Dictionary
var cells:Dictionary={}
var carriers:Dictionary={}
var board_plane:RefCounted
var grid_origin:=Vector2.ZERO
var cell_edge:=35.0
var previous_queue_signature:=""
var previous_slot_signature:=""
var ready_to_simulate:=false
var last_outcome:=""
var pending_victory_presentation_run := -1
var warning_played:=false
var auto_replay:=false
var replay_index:=0
var capture_play:=false
var current_armor_color:=""
var captured_first_fire:=false
var captured_first_hit:=false
var shield_shader:Shader
var color_materials:Array[ShaderMaterial]=[]
# Presentation tracks use the same simulation clock, never delay selection,
# reservation, delivery or saving. Buttons keep their authoritative rectangles.
var queue_refills:Array[Dictionary]=[]
var team_arrivals:Array[Dictionary]=[]
var stock_arrivals:Dictionary={}
const COLOR_VALUES={"red":Color("ed4137"),"blue":Color("329cfa"),"yellow":Color("fbc52c"),"green":Color("68d849"),"purple":Color("a25fe6"),"white":Color("f7efdb")}

func _ready()->void:
	var cold_entry:=not profile_directory_resolved
	var arguments := OS.get_cmdline_user_args()
	if use_command_line_catalog and "--campaign-drafts" in arguments:campaign_drafts=true
	level_ids=Catalog.level_ids(campaign_drafts)
	var requested_level := 0
	for arg in arguments:
		if use_command_line_level and arg.begins_with("--level="):
			requested_level=clampi(int(arg.trim_prefix("--level=")),1,level_ids.size())
	auto_replay=auto_replay or "--auto-replay" in arguments
	capture_play="--capture-play" in arguments
	# Every replay session starts in /tmp regardless of the normal profile override.
	# Scene replacements keep that same isolated profile and the selected catalog.
	if auto_replay:
		qa_fixture_mode=true
		if not profile_directory_resolved:
			profile_directory="/tmp/ant-rescue-replay-%d-%d"%[OS.get_process_id(),Time.get_ticks_usec()]
		if requested_level>0:level_index=requested_level
	elif not profile_directory_resolved:
		var profile_root := profile_directory
		if profile_root.is_empty():profile_root=OS.get_environment("ANT_RESCUE_PROFILE_DIR")
		profile_directory=Catalog.profile_path(profile_root,campaign_drafts)
	profile_directory_resolved=true
	# Programmatic QA overrides are admitted only in a deliberately isolated path.
	qa_fixture_mode=qa_fixture_mode and profile_directory.begins_with("/tmp/ant-rescue-")
	saves=Saves.new(profile_directory,level_ids,30)
	var loaded:Dictionary=saves.load_save()
	profile_state=loaded.state
	if qa_fixture_mode and loaded.ok:
		var fixture_level := clampi(level_index,1,level_ids.size())
		for i in range(fixture_level-1):saves.mark_complete(level_ids[i],"qa-fixture")
		saves.set_current_entrance(level_ids[fixture_level-1])
		saves.set_tutorial_completed(true)
		profile_state=saves.get_view_state()
	elif loaded.ok and requested_level>0:
		# --level is a request, not an unlock bypass, in either catalog.
		var entrance:Dictionary=saves.set_current_entrance(level_ids[requested_level-1])
		profile_state=entrance.state
	if profile_state.ready:
		level_index=level_ids.find(profile_state.resume_level_id)+1
	else:level_index=1
	audio_visual_state={"music":float(profile_state.music_volume),"sound":float(profile_state.sfx_volume),"music_muted":int(profile_state.music_volume)==0,"sound_muted":int(profile_state.sfx_volume)==0}
	var config_result:=read_level_configuration(Catalog.level_path(level_index,campaign_drafts))
	if qa_fixture_mode and not qa_level_config.is_empty():
		config_result={"ok":true,"config":qa_level_config.duplicate(true)}
	elif config_result.ok:
		config_result=Catalog.check_identity(config_result.config,level_index,campaign_drafts)
	level_config=config_result.get("config",{})
	# Draft source identity remains unchanged, including its null production number.
	# Rules use level_number 1..30 for the normal 3/6/9/16 unlock context.
	if not campaign_drafts:level_config.level_number=level_index
	rules=Rules.new();next_run_serial+=1;rules.run_id=next_run_serial*100
	if not rules.load_level(level_config):
		level_load_reason=str(config_result.get("reason","invalid_level_configuration"))
		build_load_failure_ui();return
	if campaign_drafts:
		print("CAMPAIGN_PREVIEW ",JSON.stringify({"level_id":level_config.level_id,"human_playtest":level_config.get("validation",{}).get("human_playtest","NOT_RUN"),"production_eligible":false,"profile":profile_directory,"automatic_replay":auto_replay}))
	shield_shader=preload("res://scripts/combat_tint.gdshader")
	super._ready()
	fx=FX.new();fx.name="RescueFX";add_child(fx)
	fx.set_layout({"board_origin":grid_origin+Vector2.ONE*cell_edge*.5,"cell_size":Vector2.ONE*cell_edge,"route_units_to_pixels":287.0/float(level_config.dragon.route_length),"cannon_muzzle":Vector2(487,918),"cannon_center":Vector2(471,970)})
	var stock_points:Dictionary={}
	for i in range(6):stock_points[COLORS[i]]=Vector2(575.5+i*57,965.5)
	var cell_points:Dictionary={}
	for cell in rules.board.values():cell_points["%d,%d"%[cell.x,cell.y]]=board_plane.center(cell.x,cell.y)
	fx.set_layout({"stock_points":stock_points,"cell_points":cell_points})
	fx.auto_advance=false
	ready_to_simulate=true
	sync_view();consume_rule_events()
	if not profile_state.ready:show_load_recovery()
	elif not profile_state.tutorial_completed and not is_instance_valid(pause_overlay):show_tutorial()
	elif (cold_entry or from_startup) and loaded.reason=="loaded" and not qa_fixture_mode:
		# Existing progress restores an entrance, never a partly played round.
		# This is nonmodal and clears on the first successful team, not a new step.
		text_label("FRESH ROUND · SAVED PROGRESS KEPT",Rect2(149,1471,642,32),18,"RoundRestartNotice",self,INK,true)
	if entry_screen=="levels" and profile_state.ready:
		chooser_from_home=true;show_levels()
	if capture_play:call_deferred("capture_play_start")

func read_level_configuration(path:String)->Dictionary:
	if not FileAccess.file_exists(path):return {"ok":false,"reason":"level_file_missing"}
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null:return {"ok":false,"reason":"level_file_unreadable"}
	var source:=file.get_as_text();file.close()
	var parser:=JSON.new()
	if parser.parse(source)!=OK or not parser.data is Dictionary:return {"ok":false,"reason":"invalid_level_json"}
	return {"ok":true,"config":parser.data}

func build_load_failure_ui()->void:
	# Build only a navigable error shell. Invalid content must never become a fake
	# board, an empty frozen window or a fabricated completion.
	var canvas_scale:=minf(1440.0/940.0,2560.0/1672.0)
	size=Vector2(940,1672);scale=Vector2.ONE*canvas_scale;position=(Vector2(1440,2560)-size*scale)*.5
	audio_service=AudioService.new();audio_service.name="AudioService";audio_service.apply_settings_state(audio_visual_state);add_child(audio_service)
	get_tree().node_added.connect(bind_new_button)
	font=load("res://assets/fonts/Title.ttf");skin=UiSkin.new()
	theme=Theme.new()
	for state in ["normal","hover","pressed","disabled","focus"]:theme.set_stylebox(state,"Button",StyleBoxEmpty.new())
	atlas=load("res://assets/characters-atlas.png")
	build_environment()
	if profile_state.get("ready",false):show_error()
	else:show_load_recovery()

func build_mosaic()->void:
	var board:=group("Mosaic")
	board_plane=BoardPlane.new(int(level_config.width),int(level_config.height))
	cell_edge=minf(660.0/float(level_config.width),570.0/float(level_config.height))
	grid_origin=Vector2((940.0-cell_edge*float(level_config.width))*.5,315)
	for cell in rules.board.values():
		var b:=place_board_bead(cell.color,cell.x,cell.y,board_plane,board)
		b.name="Bead%d"%cell.id;cells[cell.id]=b;bead_nodes.append(b);counts[cell.color]+=1

func create_fixture()->void:
	fixture={"visual_only":false,"stock":rules.inventory.duplicate(),"queues":[],"active":{},"board":counts,"initial":rules.initial_counts,"armor_total":rules.initial_counts}
	pull_team_view()

func pull_team_view()->void:
	fixture.queues=[];fixture.active={}
	for color in COLORS:fixture.active[color]=0
	for col in rules.columns:
		var q:Array=[]
		for team in col.teams:q.append({"color":team.color,"quota":team.remaining,"id":team.id})
		fixture.queues.append(q)
	slot_teams=[]
	for team in rules.slots:
		if team==null:slot_teams.append(null)
		else:
			slot_teams.append({"color":team.color,"quota":team.remaining,"id":team.id,"work_state":team.work_state})
			fixture.active[team.color]+=team.remaining
	fixture.stock=rules.inventory.duplicate()

func tint_red(target:CanvasItem,color:String)->void:
	var material:ShaderMaterial
	if target.material is ShaderMaterial:material=target.material
	else:material=ShaderMaterial.new();material.shader=shield_shader;target.material=material
	material.set_shader_parameter("tint",COLOR_VALUES[color])
	if target.name=="Dragon":
		material.set_shader_parameter("tint_region",Vector4(370.0/1536.0,330.0/1024.0,562.0/1536.0,533.0/1024.0))
		material.set_shader_parameter("is_dragon",true)
		ensure_dragon_mesh(target as TextureRect,material)
	elif target.name=="Cannon":material.set_shader_parameter("tint_region",Vector4(180.0/1536.0,654.0/1024.0,395.0/1536.0,851.0/1024.0))

func ensure_dragon_mesh(target:TextureRect,material:ShaderMaterial)->void:
	if target.has_node("ArticulatedDragon"):return
	# A bounded flat 2D lattice reuses the exact atlas. It keeps painted parts
	# connected under forward local deformation, with no 3D model or new bitmap.
	var mesh:=ArrayMesh.new();var vertices:=PackedVector3Array();var uvs:=PackedVector2Array();var indices:=PackedInt32Array()
	var cols:=32;var rows:=24;var source:=Rect2(22,145,714,480)
	for y in range(rows+1):
		for x in range(cols+1):
			var uv:=Vector2(float(x)/cols,float(y)/rows)
			vertices.append(Vector3(uv.x*target.size.x,uv.y*target.size.y,0))
			uvs.append((source.position+uv*source.size)/atlas.get_size())
	for y in range(rows):
		for x in range(cols):
			var a:=y*(cols+1)+x;var b:=a+1;var c:=a+cols+1;var d:=c+1
			indices.append_array(PackedInt32Array([a,b,c,b,d,c]))
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_INDEX]=indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var visual:=MeshInstance2D.new();visual.name="ArticulatedDragon";visual.mesh=mesh;visual.texture=atlas;visual.material=material
	target.add_child(visual);target.self_modulate=Color(1,1,1,0)

func build_transport()->void:
	var layer:=group("TransportScene")
	art(Rect2(481,678,480,307),Rect2(350,1000,231,149),"Nest",layer)
	var cannon:=art(Rect2(48,654,412,337),Rect2(385,876,173,148),"Cannon",layer);cannon.pivot_offset=Vector2(86.5,112)
	frame(Rect2(405,985,130,48),"CurrentAmmo",layer,12)
	text_label("0 / 0",Rect2(409,988,122,40),26,"AmmoCount",layer,Color("a52b1c"))
	var stock:=group("Stock",layer)
	for j in range(6):
		var x:=550+j*57
		bead(COLORS[j],Vector2(x+12,952),27,stock)
		var count:=text_label("0",Rect2(x,985,52,34),23,"Count_"+COLORS[j],stock,Color("fff7d9"));count.add_theme_color_override("font_outline_color",Color("573719"));count.add_theme_constant_override("outline_size",5)
	var live:=group("LiveCarriers",layer);layer.move_child(live,0)

func build_hud()->void:
	super.build_hud()
	get_node("TopHUD/LevelNumber").text="%02d"%level_index
	# Use the same red shield source with material recoloring for all six actual colors.
	for name in ["CurrentArmorShield","NextArmorBlue","NextArmorYellow"]:
		var target:TextureRect=get_node("TopHUD/"+name)
		var tex:=AtlasTexture.new();tex.atlas=atlas;tex.region=Rect2(973,741,179,202);tex.filter_clip=true;target.texture=tex
	var speed:=Button.new();speed.name="SpeedButton";speed.position=Vector2(255,21);speed.size=Vector2(64,47);speed.flat=true;speed.tooltip_text="Simulation speed";get_node("TopHUD").add_child(speed)
	text_label("×1",Rect2(255,21,64,47),26,"SpeedLabel",get_node("TopHUD"),INK,true)
	speed.pressed.connect(func():rules.set_speed(2 if rules.speed_multiplier==1 else 1))

func slot_bounds(index:int)->Rect2:
	var six:bool=slot_teams.size()==6
	return Rect2((60 if six else 67)+index*(137 if six else 162),1173,133 if six else 154,126)

func slot_effect_point(index:int)->Vector2:
	return Vector2(slot_bounds(index).get_center().x,1210)

func build_slots()->void:
	var work:=group("WorkSlots")
	var centers:Array=[]
	var protected:Array=[Rect2(16,10,800,89),Rect2(417,987,115,46),Rect2(548,984,365,36)]
	for i in slot_teams.size():
		var bounds:=slot_bounds(i);var x:float=bounds.position.x;var w:float=bounds.size.x
		var p:=frame(bounds,"Slot%d"%(i+1),work,16,"fffaf1","f1e1c9","caa777");slots.append(p)
		centers.append(slot_effect_point(i));protected.append(Rect2(x+8,1250,w-16,43))
		if slot_teams[i]!=null:
			var team:Dictionary=slot_teams[i]
			ant(team.color,Rect2(x+(w-100)*.5,1179,100,73),"Worker%d"%i,work)
			text_label(str(team.quota),Rect2(x+8,1250,w-16,43),34,"Quota%d"%i,work,Color("b9251f") if team.color=="red" else Color("174184") if team.color=="blue" else INK,true)
			if team.get("work_state","")=="waiting_target":icon("pause",Rect2(x+w-31,1180,25,25),work,Color("b28a50"))
	for i in range(4):protected.append(Rect2(233+i*179,1603,33,33))
	if is_instance_valid(fx):fx.set_layout({"slot_points":centers,"protected_rects":protected})

func build_tools()->void:
	var tools:=group("ToolTray")
	for i in TOOL_IDS.size():
		var x:=139+i*179
		var painted:=skin.sprite("game/"+TOOL_KINDS[i],Rect2(x,1507,125,125),tools,"PaintedTool%d"%i)
		painted.pivot_offset=painted.size*.5
		frame(Rect2(x+94,1604,33,31),"UseBadge%d"%i,tools,9)
		text_label("1",Rect2(x+94,1603,33,28),19,"Uses%d"%i,tools)
		var lock:=icon("lock",Rect2(x+96,1606,28,27),tools,INK);lock.name="ToolLock%d"%i
		var button:=Button.new();button.name="ToolButton%d"%i;button.flat=true;button.position=Vector2(x,1507);button.size=Vector2(132,132);button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;tools.add_child(button)
		button.pressed.connect(func():activate_tool(TOOL_IDS[i]))
	sync_tool_controls()

func sync_tool_controls()->void:
	if not has_node("ToolTray"):return
	var states:Dictionary={}
	for state in rules.tool_states():states[state.id]=state
	for i in TOOL_IDS.size():
		var state:Dictionary=states.get(TOOL_IDS[i],{})
		var unlocked:bool=state.get("unlocked",false)
		var remaining:int=int(state.get("remaining",0))
		var button:Button=get_node("ToolTray/ToolButton%d"%i)
		button.disabled=not unlocked or remaining==0 or not profile_state.get("ready",false) or rules.paused or rules.status not in ["ready","running"]
		button.tooltip_text=(TOOL_IDS[i].replace("_"," ").to_upper()+" · "+("LEVEL %d"%int(state.get("unlock_level",1)) if not unlocked else "%d LEFT"%remaining))
		get_node("ToolTray/PaintedTool%d"%i).modulate=Color(.62,.62,.62,.8) if not unlocked or remaining==0 else Color.WHITE
		get_node("ToolTray/Uses%d"%i).text=str(remaining)
		get_node("ToolTray/Uses%d"%i).visible=unlocked
		get_node("ToolTray/ToolLock%d"%i).visible=not unlocked

func activate_tool(tool_id:String,payload:Dictionary={})->Dictionary:
	if is_instance_valid(pause_overlay) or not profile_state.get("ready",false):return {"ok":false,"consumed":false,"reason":"simulation_frozen"}
	if tool_id=="recall":
		show_recall_selection()
		return {"ok":not recall_selection.is_empty(),"consumed":false}
	var result:Dictionary=rules.request_tool(tool_id,payload)
	if not result.ok:tool_feedback(str(result.get("reason","unavailable")))
	sync_view();consume_rule_events()
	return result

func tool_feedback(reason:String)->void:
	var messages:Dictionary={"search_budget_exhausted":"NO VERIFIED SHUFFLE · USE KEPT","no_verified_winning_replay":"NO VERIFIED SHUFFLE · USE KEPT","no_changed_arrangement":"NO NEW SHUFFLE · USE KEPT","slots_full":"ALL SLOTS FULL · USE KEPT","no_exposed_front_target":"NO REACHABLE FRONT · USE KEPT","no_active_team":"NO ACTIVE TEAM · USE KEPT","invalid_slot":"CHOOSE AN ACTIVE TEAM","stale_team_selection":"TEAM CHANGED · USE KEPT","tool_locked":"THIS TOOL IS STILL LOCKED","tool_already_used":"ALREADY USED THIS ROUND"}
	var existing:=get_node_or_null("ToolFeedback")
	if existing:remove_child(existing);existing.queue_free()
	var label:=text_label(messages.get(reason,"NOT AVAILABLE · USE KEPT"),Rect2(149,1471,642,32),18,"ToolFeedback",self,INK,true)
	ensure_ui_motion();ui_motion.reveal_hint(label)
	feedback_serial+=1;var serial:=feedback_serial
	get_tree().create_timer(2.8).timeout.connect(func():
		if is_inside_tree() and serial==feedback_serial and is_instance_valid(label):label.queue_free())
	audio_service.play_event("error")

func show_recall_selection()->void:
	var available:=false
	for state in rules.tool_states():
		if state.id=="recall":available=state.unlocked and int(state.remaining)>0
	if not available or rules.status not in ["ready","running"]:tool_feedback("tool_locked");return
	if rules.slots.all(func(team:Variant)->bool:return team==null or int(team.get("remaining",0))<=0):
		tool_feedback("no_active_team");return
	var m:=modal("RECALL A TEAM",Rect2(149,520,642,650))
	recall_selection=rules.begin_tool_selection("recall")
	if not recall_selection.ok:
		recall_selection.clear();dismiss_modal();tool_feedback("simulation_frozen");return
	text_label("ONLY UNSENT QUOTA RETURNS",Rect2(202,631,536,44),23,"RecallContract",m)
	var active_slots:Array[int]=[]
	for i in rules.slots.size():
		if rules.slots[i]!=null and int(rules.slots[i].remaining)>0:active_slots.append(i)
	for card_index in active_slots.size():
		var i:int=active_slots[card_index]
		var row:int=card_index/3;var column:int=card_index%3
		var row_count:int=mini(3,active_slots.size()-row*3)
		var x:float=(940.0-(row_count*143+(row_count-1)*28))*.5+column*171
		var y:int=704+row*153
		frame(Rect2(x,y,143,137),"RecallTeam%d"%i,m,22)
		var team:Dictionary=rules.slots[i]
		ant(team.color,Rect2(x+22,y+5,100,72),"RecallAnt%d"%i,m)
		text_label(str(team.remaining),Rect2(x+8,y+78,127,44),30,"RecallQuota%d"%i,m)
		var button:=Button.new();button.name="RecallChoice%d"%i;button.flat=true;button.position=Vector2(x,y);button.size=Vector2(143,137);m.add_child(button)
		var team_id:String=team.id
		button.pressed.connect(func():confirm_recall(i,team_id))
	text_label("CARRIERS ALREADY OUT KEEP GOING",Rect2(190,1011,560,42),20,"CarrierNotice",m)
	action(m,"CANCEL",1071,dismiss_modal)

func confirm_recall(index:int,team_id:String)->Dictionary:
	if recall_selection.is_empty():return {"ok":false,"consumed":false,"reason":"selection_expired"}
	var result:Dictionary=rules.request_tool("recall",{"slot":index,"expected_team_id":team_id,"selection_token":recall_selection.token})
	if result.ok:
		recall_selection.clear()
		# Resume before consuming the committed release cue, never on opening.
		dismiss_modal();sync_view();consume_rule_events()
	else:tool_feedback(str(result.get("reason","invalid_slot")))
	return result

func clear_scout()->void:
	scout_result.clear();scout_seconds=0
	var hints:=get_node_or_null("ScoutHints")
	if hints:remove_child(hints);hints.queue_free()

func sync_scout()->void:
	if scout_result.is_empty():return
	var column_index:=-1
	for i in rules.columns.size():
		if rules.columns[i].id==scout_result.column_id and not rules.columns[i].teams.is_empty() and rules.columns[i].teams[0].id==scout_result.team_id:column_index=i
	if column_index<0 or rules.run_id!=int(scout_result.run_id) or rules.status not in ["ready","running"]:
		clear_scout();return
	var layer:=get_node_or_null("ScoutHints") as Control
	if not layer:
		layer=group("ScoutHints");ensure_ui_motion();ui_motion.reveal_hint(layer)
	for id in scout_result.exposed_cell_ids:
		var name:String="Cell%d"%id
		var outline:=layer.get_node_or_null(name)
		if not rules.board.has(id) or rules.reservations.has(id):
			if outline:outline.hide()
			continue
		if not outline:
			var cell:Dictionary=rules.board[id];var span:Vector2=board_plane.footprint(cell.x,cell.y)
			add_scout_outline(Rect2(board_plane.center(cell.x,cell.y)-span*.53,span*1.06),layer,name)
	var front:=get_node_or_null("CandidateQueues/Column%d/FrontButton"%(column_index+1)) as Control
	if front and not layer.has_node("FrontTeam"):add_scout_outline(Rect2(front.position,front.size),layer,"FrontTeam")
	if not layer.has_node("CurrentArmor"):add_scout_outline(Rect2(438,7,93,93),layer,"CurrentArmor")
	var context:=layer.get_node_or_null("AmmoContext") as Label
	if not context:context=text_label("",Rect2(149,1460,642,34),18,"AmmoContext",layer,INK,true)
	context.text=scout_ammo_context()
	context.visible=not has_node("ToolFeedback")
	# Purely advisory highlight. It neither clicks a front nor freezes simulation.

func scout_ammo_context()->String:
	# Live data, not the snapshot captured at tool use: delivery, firing and armor
	# changes may happen during the short highlight. A shot has already spent ammo.
	if rules.armor_index>=rules.armors.size():return ""
	if not rules.projectile.is_empty():return "SHOT ON THE WAY · AMMO ALREADY SPENT"
	var armor:Dictionary=rules.armors[rules.armor_index]
	var missing:=maxi(0,int(armor.demand)-int(rules.inventory.get(armor.color,0)))
	if missing>0:
		return "%d MORE %s AMMO · OTHER COLORS STAY STORED"%[missing,str(armor.color).to_upper()]
	if rules.cooldown_until_us>rules.time_us:return "AMMO READY · CANNON COOLING"
	return "AMMO READY FOR THIS ARMOR"

func add_scout_outline(bounds:Rect2,parent:Control,id:String)->void:
	var outline:=Panel.new();outline.name=id;outline.position=bounds.position;outline.size=bounds.size;outline.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style:=StyleBoxFlat.new();style.bg_color=Color(1,.83,.27,.12);style.border_color=Color(1,.95,.53,.95);style.set_border_width_all(3);style.set_corner_radius_all(8);outline.add_theme_stylebox_override("panel",style);parent.add_child(outline)

func preview_select_front(column:int,expected_id:String)->bool:
	if queue_transition_busy or is_instance_valid(pause_overlay) or not profile_state.get("ready",false):return false
	var result:Dictionary=rules.select_front(column,expected_id)
	if not result.ok:audio_service.play_event("error");return false
	var notice:=get_node_or_null("RoundRestartNotice")
	if notice:remove_child(notice);notice.queue_free()
	queue_transition_busy=true
	get_tree().create_timer(.18).timeout.connect(func():queue_transition_busy=false)
	sync_view();consume_rule_events();return true

func _process(delta:float)->void:
	if not ready_to_simulate:return
	if not rules.paused and scout_seconds>0:
		scout_seconds-=delta
		if scout_seconds<=0:clear_scout()
	if auto_replay and not rules.paused:advance_replay(delta)
	else:rules.update(delta)
	sync_view();consume_rule_events();fx.advance(delta)
	apply_gameplay_interaction_motion()
	apply_actor_poses()
	present_pending_outcome()

func advance_replay(delta:float)->void:
	var left:=roundi(delta*1000000)
	var solution:Array=level_config.validation.no_tool_solution
	while left>0 and rules.status in ["ready","running"]:
		while replay_index<solution.size() and int(solution[replay_index].time_us)<=rules.time_us:
			var entry:Dictionary=solution[replay_index];rules.select_front(entry.column_id,entry.team_id);replay_index+=1
		var step:=left
		if replay_index<solution.size():step=mini(step,maxi(1,int(solution[replay_index].time_us)-rules.time_us))
		rules.update_us(step);left-=step

func sync_view()->void:
	if not ready_to_simulate:return
	for id in cells:
		if is_instance_valid(cells[id]):cells[id].visible=rules.board.has(id)
	var old_queues:Array=fixture.get("queues",[]).duplicate(true)
	pull_team_view()
	var qsig:=JSON.stringify(fixture.queues);var ssig:=JSON.stringify(slot_teams)
	if qsig!=previous_queue_signature:
		var old:=get_node("CandidateQueues");remove_child(old);old.queue_free();candidate_columns.clear();build_candidates();previous_queue_signature=qsig
		begin_queue_refill(old_queues)
	if ssig!=previous_slot_signature:
		var old:=get_node("WorkSlots");remove_child(old);old.queue_free();slots.clear();build_slots();previous_slot_signature=ssig
	sync_tool_controls();sync_scout()
	var restart_notice:=get_node_or_null("RoundRestartNotice")
	if restart_notice:restart_notice.visible=rules.status=="ready" and scout_result.is_empty() and not has_node("ToolFeedback")
	# Noninteractive effects must remain above rebuilt artwork, with current quota
	# labels protected, while the modal always stays above effects and input.
	if is_instance_valid(fx):move_child(fx,-1)
	var hints:=get_node_or_null("ScoutHints")
	if hints:move_child(hints,-1)
	if is_instance_valid(pause_overlay):move_child(pause_overlay,-1)
	for color in COLORS:get_node("TransportScene/Stock/Count_"+color).text=str(rules.inventory.get(color,0))
	var index:int=rules.armor_index
	for j in range(3):
		var node:TextureRect=get_node("TopHUD/"+["CurrentArmorShield","NextArmorBlue","NextArmorYellow"][j]);node.visible=index+j<rules.armors.size()
		if node.visible:tint_red(node,rules.armors[index+j].color)
	# Only connect armor icons that actually exist. No floating end-of-chain arrows.
	get_node("TopHUD/ArmorLink1").visible=index+1<rules.armors.size()
	get_node("TopHUD/ArmorLink2").visible=index+2<rules.armors.size()
	get_node("DragonRoute/RouteMarkers").visible=rules.status!="victory"
	get_node("TransportScene/CurrentAmmo").visible=index<rules.armors.size()
	get_node("TransportScene/AmmoCount").visible=index<rules.armors.size()
	if index<rules.armors.size():
		var armor:Dictionary=rules.armors[index];current_armor_color=armor.color
		get_node("TransportScene/AmmoCount").text="%d / %d"%[rules.inventory[armor.color],armor.demand]
		tint_red(get_node("TransportScene/Cannon"),armor.color);tint_red(get_node("DragonRoute/Dragon"),armor.color)
	else:get_node("TransportScene/AmmoCount").text="0 / 0"
	get_node("TopHUD/SpeedLabel").text="×%d"%rules.speed_multiplier
	sync_carriers()
	fx.set_layout({"dragon_hit":Vector2(363+287.0*rules.dragon_position()/float(level_config.dragon.route_length),210),"dragon_foot":Vector2(323+287.0*rules.dragon_position()/float(level_config.dragon.route_length),272)})
	fx.sync_snapshot(rules.snapshot())
	apply_gameplay_interaction_motion()

func begin_queue_refill(previous:Array)->void:
	queue_refills.clear()
	for column in mini(previous.size(),fixture.queues.size()):
		var old_ids:Array=[]
		for team in previous[column]:old_ids.append(team.id)
		for row in mini(3,fixture.queues[column].size()):
			var old_row:int=old_ids.find(fixture.queues[column][row].id)
			if old_row<=row:continue
			for prefix in ["Ant","Quota"]:
				var target:=get_node_or_null("CandidateQueues/Column%d/%s%d"%[column+1,prefix,row]) as Control
				if target:
					# Cache button-art rest before applying cosmetic displacement.
					ensure_ui_motion();ui_motion._rest(target)
					queue_refills.append({"target":target,"rest":target.position,"start_us":rules.time_us,"offset":minf(114.0,(old_row-row)*57.0)})

func begin_team_arrival(event:Dictionary)->void:
	var column:=-1
	for i in rules.columns.size():
		if rules.columns[i].id==event.column_id:column=i
	if column<0:return
	var layer:=get_node_or_null("TeamArrivalVisuals") as Control
	if not layer:layer=group("TeamArrivalVisuals")
	var start:=Rect2(84+column*164,1327,66,47)
	var bounds:=slot_bounds(int(event.slot))
	var finish:=Rect2(bounds.position.x+(bounds.size.x-100)*.5,1179,100,73)
	var visual:=ant(event.color,start,"Arrival_%s"%event.team_id,layer)
	team_arrivals.append({"node":visual,"team_id":event.team_id,"slot":event.slot,"start":start,"finish":finish,"start_us":event.time_us})

func apply_gameplay_interaction_motion()->void:
	if not ready_to_simulate:return
	for i in range(queue_refills.size()-1,-1,-1):
		var entry:Dictionary=queue_refills[i];var target:Control=entry.target
		if not is_instance_valid(target):queue_refills.remove_at(i);continue
		var t:=clampf(float(rules.time_us-entry.start_us)/160000.0,0,1)
		target.position=entry.rest+Vector2(0,float(entry.offset)*pow(1.0-t,3))
		if t>=1:queue_refills.remove_at(i)
	# Quota is always the live rules value. Only the ant artwork travels.
	for i in range(team_arrivals.size()-1,-1,-1):
		var entry:Dictionary=team_arrivals[i];var visual:Control=entry.node
		if not is_instance_valid(visual):team_arrivals.remove_at(i);continue
		var t:=clampf(float(rules.time_us-entry.start_us)/240000.0,0,1)
		var ease:=1.0-pow(1.0-t,3)
		var from:Rect2=entry.start;var to:Rect2=entry.finish
		visual.position=from.position.lerp(to.position,ease)+Vector2(0,-sin(t*PI)*10)
		visual.size=from.size.lerp(to.size,ease)
		var slot:int=entry.slot
		var worker:=get_node_or_null("WorkSlots/Worker%d"%slot) as Control
		var same_team:bool=slot<rules.slots.size() and rules.slots[slot]!=null and rules.slots[slot].id==entry.team_id
		if same_team and worker:worker.visible=t>=1
		if t>=1 or not same_team:visual.queue_free();team_arrivals.remove_at(i)
	for color in stock_arrivals.keys():
		var label:=get_node_or_null("TransportScene/Stock/Count_"+color) as Control
		var t:=clampf(float(rules.time_us-int(stock_arrivals[color]))/260000.0,0,1)
		if label:
			label.pivot_offset=label.size*.5
			label.scale=Vector2.ONE*(1.0+sin(t*PI)*.13*(1.0-t))
		if t>=1:stock_arrivals.erase(color)

func map_path_point(point:Variant)->Vector2:
	if int(point[0])==int(level_config.width)/2 and int(point[1])==int(level_config.height):return Vector2(467,1074)
	return board_plane.center(float(point[0]),float(point[1]))

func sync_carriers()->void:
	var container:=get_node("TransportScene/LiveCarriers")
	for id in carriers.keys():
		if not rules.tasks.has(id):carriers[id].queue_free();carriers.erase(id)
	for id in rules.tasks:
		var task:Dictionary=rules.tasks[id]
		if not carriers.has(id):
			var actor:=ground_ant(task.color,Vector2.ZERO,"Carrier%d"%id,container,48)
			var carried:=bead(task.color,Vector2(-12,-48),24,actor);carried.name="CarriedBead"
			carriers[id]=actor
		var return_depart:int=task.get("return_depart_us",task.pickup_us)
		var holding:bool=task.stage=="returning" and rules.time_us<return_depart
		var hold_fraction:=clampf(float(rules.time_us-task.pickup_us)/maxf(1,float(return_depart-task.pickup_us)),0,1)
		var t:float
		if task.stage=="outbound":t=clampf(float(rules.time_us-task.depart_us)/maxf(1,float(task.pickup_us-task.depart_us)),0,1)
		elif holding:t=1.0
		else:t=1.0-clampf(float(rules.time_us-return_depart)/maxf(1,float(task.delivery_us-return_depart)),0,1)
		var pose:Dictionary=sample_carrier_path(task.path,t)
		var actor:Control=carriers[id]
		actor.position=pose.position
		actor.scale=Vector2.ONE*board_plane.depth_scale(pose.depth_y)
		actor.get_node("CarriedBead").visible=task.stage=="returning"
		var direction:Vector2=pose.tangent
		if task.stage=="returning" and not holding:direction=-direction
		var elapsed:=float(rules.time_us-task.depart_us)/1000000.0
		var leg_sec:=float(task.pickup_us-task.depart_us)/1000000.0
		# Continue the stride rather than snapping phase when the load is acquired.
		var stride_time:=minf(elapsed,leg_sec)*CarrierMotion.OUTBOUND_CADENCE
		if task.stage=="returning":stride_time+=maxf(0.0,float(rules.time_us-return_depart)/1000000.0)*CarrierMotion.LOADED_CADENCE
		CarrierMotion.apply(actor,{"time":float(rules.time_us)/1000000.0,
			"distance":pose.travelled if task.stage=="outbound" else pose.total_length*2.0-pose.travelled,
			"moving":not holding,"direction":direction,"stage":"pickup" if holding else task.stage,
			"pickup":hold_fraction if holding else 0.0,"diameter":48.0,"phase":stride_time*TAU+float(id)*1.7})
		var carried:=actor.get_node("CarriedBead") as Control
		carried.scale=Vector2.ONE*lerpf(.65,1.0,smoothstep(0,1,hold_fraction)) if holding else Vector2.ONE
		if holding:carried.position.y+=(1.0-smoothstep(0,1,hold_fraction))*6.0

func sample_carrier_path(path:Array,t:float)->Dictionary:
	# Arc length is visual only. Pickup and delivery happen at authoritative
	# Rules times; the finite hold never credits inventory or completes a trip.
	var points:Array[Vector2]=[];var lengths:Array[float]=[];var total:=0.0
	for point in path:points.append(map_path_point(point))
	for i in range(points.size()-1):
		var length:=points[i].distance_to(points[i+1]);lengths.append(length);total+=length
	var travelled:=clampf(t,0,1)*total
	var distance:=travelled
	for i in lengths.size():
		if distance<=lengths[i] or i==lengths.size()-1:
			var weight:=clampf(distance/maxf(.001,lengths[i]),0,1)
			return {"position":points[i].lerp(points[i+1],weight),"depth_y":lerpf(float(path[i][1]),float(path[i+1][1]),weight),
				"tangent":points[i].direction_to(points[i+1]),"travelled":travelled,"total_length":total}
		distance-=lengths[i]
	return {"position":points[0] if not points.is_empty() else Vector2.ZERO,"depth_y":0.0,
		"tangent":Vector2.UP,"travelled":0.0,"total_length":0.0}

func consume_rule_events()->void:
	var events:Array=rules.drain_events()
	fx.consume_events(events)
	var sound_map:Dictionary={"ant_dispatched":"dispatch","bead_picked_up":"pickup","bead_delivered":"return","cannon_fired":"cannon","armor_broken":"armor_hit","victory":"win","defeat":"lose","load_error":"error","recoverable_error":"error"}
	for event in events:
		if event.type=="team_selected":begin_team_arrival(event)
		if event.type=="bead_delivered":stock_arrivals[event.color]=event.time_us
		if sound_map.has(event.type) and event.type not in ["victory","defeat"]:audio_service.play_event(sound_map[event.type])
		if event.type=="tool_used":
			var tool_id:String=event.tool_id
			var result:Dictionary=event.result
			var target:=Vector2(470,1380)
			if tool_id in ["extra_slot","recall"]:target=slot_effect_point(int(result.slot))
			if tool_id=="scout":
				scout_result=result.duplicate(true);scout_seconds=2.8;sync_scout()
				if not result.exposed_cell_ids.is_empty():
					var cell:Dictionary=rules.board.get(result.exposed_cell_ids[0],{})
					if not cell.is_empty():target=board_plane.center(cell.x,cell.y)
			fx.play_tool(tool_id,true,target)
			audio_service.play_tool("hint" if tool_id=="scout" else tool_id)
		if event.type in ["victory","defeat"] and last_outcome.is_empty():
			last_outcome=event.type
			clear_scout()
			if event.type=="victory":
				# Final hit settles victory and saves immediately. FX only presents the
				# finite collapse; it never controls success, timing or persistence.
				persist_victory()
				pending_victory_presentation_run=rules.run_id
				get_node("TopHUD/PauseButton").disabled=true
			else:
				var completed_run:int=rules.run_id
				get_tree().create_timer(.65).timeout.connect(func():
					if is_inside_tree() and rules.run_id==completed_run:
						show_outcome(false);audio_service.play_event("lose"))
		if capture_play and event.type=="cannon_fired" and not captured_first_fire:
			captured_first_fire=true;call_deferred("save_capture","play-first-fire")
		if capture_play and event.type=="armor_broken" and not captured_first_hit:
			captured_first_hit=true;call_deferred("save_capture","play-first-hit")
		if capture_play and event.type in ["victory","defeat"]:call_deferred("capture_play_end")
		if event.type=="recoverable_error":show_error()
	if not warning_played and rules.status=="running" and rules.dragon_position()>float(level_config.dragon.route_length)*.8:
		warning_played=true;audio_service.play_event("warning")
	apply_gameplay_interaction_motion()

func present_pending_outcome()->void:
	if pending_victory_presentation_run<0:return
	if rules.run_id!=pending_victory_presentation_run or rules.status!="victory":
		pending_victory_presentation_run=-1;return
	if not fx.dragon_pose().get("defeat_complete",false):return
	pending_victory_presentation_run=-1
	get_node("TopHUD/PauseButton").disabled=false
	show_outcome(true);audio_service.play_event("win")

func apply_actor_poses()->void:
	var cp:Dictionary=fx.cannon_pose();var cannon:Control=get_node("TransportScene/Cannon")
	cannon.position=Vector2(385,876)+cp.offset;cannon.rotation=cp.rotation;cannon.scale=cp.scale
	var dp:Dictionary=fx.dragon_pose();var dragon:Control=get_node("DragonRoute/Dragon")
	dragon.position=Vector2(103+287.0*rules.dragon_position()/float(level_config.dragon.route_length),79)+dp.offset;dragon.rotation=dp.rotation;dragon.scale=dp.scale;dragon.modulate=dp.modulate;dragon.visible=bool(dp.get("visible",true))
	if dragon.material is ShaderMaterial:
		var age:float=dp.get("defeat_age",-1.0)
		var collapse:=smoothstep(.10,.92,age) if age>=0 and not fx.reduced_motion else 0.0
		dragon.material.set_shader_parameter("collapse",collapse)

func modal(title:String,rect:Rect2=Rect2(170,520,600,620))->Control:
	# Leaving recall by any route invalidates its selection, without spending it.
	if not recall_selection.is_empty():
		rules.cancel_tool_selection(str(recall_selection.get("token","")));recall_selection.clear()
	if is_instance_valid(pause_overlay):
		ensure_ui_motion();ui_motion.discard_modal(pause_overlay);pause_overlay=null
	var freeze:bool=rules.status in ["ready","running"]
	if freeze:rules.set_paused(true)
	if is_instance_valid(fx):fx.set_paused(freeze)
	return super.modal(title,rect)

func dismiss_modal()->void:
	if not profile_state.get("ready",false):show_load_recovery();return
	if modal_title=="YOUR FIRST RESCUE":finish_tutorial();return
	if modal_title=="SETTINGS" and not commit_settings():return
	if not recall_selection.is_empty():
		rules.cancel_tool_selection(str(recall_selection.get("token","")));recall_selection.clear()
	modal_title=""
	dismiss_modal_visual()
	if rules.status in ["ready","running"]:rules.set_paused(false)
	audio_service.set_music_preview(false)
	audio_service.set_game_paused(false)
	if is_instance_valid(fx):fx.set_paused(false)
	reset_presentation();sync_tool_controls()

func close_current_modal()->void:
	if chooser_from_home and modal_title=="CHOOSE A LEVEL":return_home();return
	if not profile_state.get("ready",false):
		recovery_reset_confirm=false;show_load_recovery();return
	if rules.status=="load_error":
		if modal_title=="CHOOSE A LEVEL":show_error()
		else:show_levels()
		return
	if modal_title=="YOUR FIRST RESCUE":finish_tutorial();return
	if modal_title=="SETTINGS":
		if commit_settings():show_pause()
		return
	if modal_title=="COULDN'T SAVE":
		if pending_save_kind=="victory":show_save_error()
		elif pending_save_kind=="settings":show_settings()
		elif pending_save_kind=="tutorial":show_tutorial()
		else:show_levels()
		return
	if rules.status in ["victory","defeat"]:
		if modal_title=="CHOOSE A LEVEL":show_outcome(rules.status=="victory")
		else:show_levels()
	elif modal_title in ["RESTART LEVEL?","LEAVE THIS LEVEL?","CHOOSE A LEVEL"]:show_pause()
	elif modal_title=="COULDN'T LOAD":show_error()
	else:dismiss_modal()

func reset_presentation()->void:
	# Real state is never reset merely by opening/closing a UI page.
	for path in ["CandidateQueues","WorkSlots","TransportScene"]:
		if has_node(path):get_node(path).show()

func show_pause()->void:
	if pending_victory_presentation_run>=0:return
	if not profile_state.get("ready",false):show_load_recovery();return
	if pending_save_kind=="victory":show_save_error();return
	if rules.status=="load_error":show_error();return
	if modal_title=="YOUR FIRST RESCUE":return
	super.show_pause()
	icon("home",Rect2(430,610,80,70),pause_overlay,INK)
	var home:=Button.new();home.name="HomeButton";home.flat=true;home.position=Vector2(414,588);home.size=Vector2(112,112);home.tooltip_text="Home";pause_overlay.add_child(home);home.pressed.connect(request_home)

func show_settings()->void:
	if not profile_state.get("ready",false):show_load_recovery();return
	super.show_settings()
	for name in ["MusicVolume","SoundVolume"]:
		var slider:HSlider=pause_overlay.get_node(name)
		slider.value_changed.connect(func(_value):settings_dirty=true)
		slider.drag_ended.connect(func(_changed):commit_settings())

func commit_settings()->bool:
	if not settings_dirty:return true
	var result:Dictionary=saves.set_volumes(audio_visual_state.music,audio_visual_state.sound)
	profile_state=result.state
	if not result.ok:
		pending_save_kind="settings";last_save_reason=result.reason;show_save_error();return false
	settings_dirty=false
	if pending_save_kind=="settings":pending_save_kind=""
	return true

func show_tutorial()->void:
	var m:=modal("YOUR FIRST RESCUE",Rect2(149,423,642,800))
	ant("red",Rect2(400,552,140,106),"TutorialAnt",m)
	var steps:Array[String]=["CHOOSE A FRONT-ROW TEAM","5 SLOTS · NO TARGET? TEAMS WAIT","ANTS TAKE REACHABLE MATCHING BEADS","DELIVERED BEADS BECOME AMMO","THE CANNON FIRES AUTOMATICALLY","THE LAST HIT RESCUES HER"]
	for i in steps.size():
		icon("arrow",Rect2(211,674+i*58,26,30),m,Color("d09536"))
		text_label(steps[i],Rect2(251,667+i*58,487,46),18,"StepText%d"%i,m)
	text_label("THE DRAGON WAITS FOR YOUR FIRST TEAM",Rect2(190,1037,560,48),20,"ObservationNotice",m)
	action(m,"LET'S GO",1115,finish_tutorial,true)

func finish_tutorial()->void:
	var result:Dictionary=saves.set_tutorial_completed(true);profile_state=result.state
	if not result.ok:
		pending_save_kind="tutorial";last_save_reason=result.reason;show_save_error();return
	pending_save_kind="";modal_title="";dismiss_modal()

func show_restart()->void:
	var m:=modal("RESTART LEVEL?")
	skin.sprite("game/recall",Rect2(402,666,136,136),m,"RecallEmblem")
	text_label("YOUR CURRENT ROUND WILL RESET",Rect2(204,835,532,54),22,"RestartWarning",m)
	action(m,"RESTART",929,func():replace_level(level_index),true);action(m,"CANCEL",1025,show_pause)

func show_leave()->void:
	var m:=modal("LEAVE THIS LEVEL?")
	icon("arrow",Rect2(402,666,136,136),m,Color("d08436"))
	text_label("SELECTING A LEVEL STARTS A FRESH ROUND",Rect2(193,828,554,54),19,"LeaveWarning",m)
	text_label("SAVED COMPLETIONS STAY UNLOCKED",Rect2(204,881,532,48),20,"ProgressNotice",m)
	action(m,"LEVEL SELECT",971,show_levels,true)
	action(m,"CANCEL",1055,show_pause)

func show_levels(page:int=-1)->void:
	if not profile_state.get("ready",false):show_load_recovery();return
	if pending_save_kind=="victory":show_save_error();return
	profile_state=saves.get_view_state()
	if campaign_drafts:
		show_campaign_levels(page);return
	var m:=modal("CHOOSE A LEVEL",Rect2(149,530,642,530))
	for entry in profile_state.levels:
		var number:int=entry.number;var x:=255+(number-1)*156
		build_level_tile(m,entry,Rect2(x,735,118,100))
	text_label("3 PLAYABLE LEVELS · 30-LEVEL CAMPAIGN IN DEVELOPMENT",Rect2(180,903,580,42),15,"AvailableContent",m)
	text_label("EACH ENTRY STARTS A NEW ROUND",Rect2(200,954,540,40),18,"FreshRoundNotice",m)

func build_level_tile(parent:Control,entry:Dictionary,bounds:Rect2)->void:
	var number:int=entry.number
	frame(bounds,"LevelTile%d"%number,parent,18)
	text_label(str(number),Rect2(bounds.position+Vector2(0,9),Vector2(bounds.size.x,56)),36,"LevelNumber%d"%number,parent,INK if entry.unlocked else Color("a58c70"))
	var marker_bounds:=Rect2(bounds.position+Vector2((bounds.size.x-28)*.5,67),Vector2(28,27))
	if not entry.unlocked:
		var marker:=icon("lock",marker_bounds,parent,INK);marker.name="LevelLock%d"%number
	elif entry.completed:
		var marker:=icon("star",marker_bounds,parent,Color("33873e"));marker.name="LevelComplete%d"%number
	var button:=Button.new();button.name="LevelButton%d"%number;button.position=bounds.position;button.size=bounds.size;button.flat=true;button.disabled=not entry.unlocked;parent.add_child(button)
	button.tooltip_text="LEVEL %d · %s"%[number,"LOCKED" if not entry.unlocked else "COMPLETE" if entry.completed else "READY"]
	button.pressed.connect(func():replace_level(number))

func show_campaign_levels(page:int=-1)->void:
	var page_count := ceili(float(level_ids.size())/Catalog.PAGE_SIZE)
	if page>=0:level_selector_page=page
	elif level_selector_page<0:level_selector_page=(level_index-1)/Catalog.PAGE_SIZE
	level_selector_page=clampi(level_selector_page,0,page_count-1)
	var m:=modal("CHOOSE A LEVEL",Rect2(149,450,642,740))
	text_label("CAMPAIGN PREVIEW",Rect2(200,568,540,38),22,"AvailableContent",m)
	var first := level_selector_page*Catalog.PAGE_SIZE
	for offset in range(mini(Catalog.PAGE_SIZE,level_ids.size()-first)):
		var x := 203+(offset%5)*110
		var y := 644+(offset/5)*132
		build_level_tile(m,profile_state.levels[first+offset],Rect2(x,y,94,106))
	text_label("%d / %d"%[level_selector_page+1,page_count],Rect2(388,971,164,60),25,"PageNumber",m)
	build_page_button(m,"PREVIOUS",Rect2(205,967,174,70),level_selector_page-1,level_selector_page==0)
	build_page_button(m,"NEXT",Rect2(561,967,174,70),level_selector_page+1,level_selector_page==page_count-1)
	text_label("EACH ENTRY STARTS A NEW ROUND",Rect2(200,1090,540,40),18,"FreshRoundNotice",m)

func build_page_button(parent:Control,title:String,bounds:Rect2,page:int,disabled:bool)->void:
	frame(bounds,"PageFrame_"+title,parent,20)
	text_label(title,Rect2(bounds.position+Vector2(5,4),bounds.size-Vector2(10,8)),21,"PageText_"+title,parent,Color("a58c70") if disabled else INK)
	var button:=Button.new();button.name="PageButton_"+title;button.position=bounds.position;button.size=bounds.size;button.flat=true;button.disabled=disabled;parent.add_child(button)
	button.pressed.connect(func():show_levels(page))

func persist_victory()->bool:
	if rules.status!="victory":return false
	var result:Dictionary=saves.mark_complete(str(level_config.level_id),str(level_config.get("content_version","")))
	profile_state=result.state;victory_saved=result.ok
	if result.ok:pending_save_kind=""
	else:pending_save_kind="victory";last_save_reason=result.reason
	return result.ok

func result_action(parent:Control,title:String,y:float,callback:Callable,primary:bool=false)->void:
	# At 375pt portrait width this 118-unit target remains 47pt tall.
	# Artwork and hit rectangle share one bound; nine-slice corners stay uniform.
	var bounds:=Rect2(190,y,560,118)
	frame(bounds,"Action_"+title,parent,30,"54d35b" if primary else "fff4de")
	var glyph := "arrow" if title=="NEXT LEVEL" else ("levels" if title=="LEVEL SELECT" else "recall")
	icon(glyph,Rect2(426,y+15,88,88),parent,Color.WHITE if primary else INK).name="Icon_"+title
	var button:=Button.new();button.name="Button_"+title;button.tooltip_text=title;button.flat=true;button.position=bounds.position;button.size=bounds.size;parent.add_child(button);button.pressed.connect(callback)

func show_outcome(won:bool)->void:
	if won and rules.status=="victory" and not victory_saved:show_save_error();return
	var m:=modal("PRINCESS SAVED!" if won else "TRY AGAIN",Rect2(98,335,744,1040))
	if won:
		get_node("DragonRoute/Dragon").hide()
		art(Rect2(740,20,324,624),Rect2(387,550,166,320),"RescuedPrincess",m)
	else:art(Rect2(22,145,714,480),Rect2(237,570,466,313),"ThreatDragon",m)
	var next_id:String=profile_state.get("next_level_id","") if victory_saved else ""
	if won and not next_id.is_empty():result_action(m,"NEXT LEVEL",934,func():replace_level(level_ids.find(next_id)+1),true)
	result_action(m,"PLAY AGAIN" if won else "RETRY",1076,func():replace_level(level_index),not won or next_id.is_empty())
	result_action(m,"LEVEL SELECT",1218,show_levels)

func show_save_error()->void:
	var m:=modal("COULDN'T SAVE",Rect2(149,520,642,650))
	skin.sprite("game/recall",Rect2(402,662,136,136),m,"SaveRecoveryEmblem")
	var copy:Dictionary={"victory":"LEVEL COMPLETE · SAVE PENDING","settings":"VOLUME CHANGES ARE NOT SAVED","tutorial":"TUTORIAL CHOICE IS NOT SAVED","entrance":"LEVEL ENTRY WAS NOT SAVED"}
	text_label(copy.get(pending_save_kind,"LOCAL SAVE IS UNAVAILABLE"),Rect2(193,823,554,48),21,"SaveStatus",m)
	text_label("RETRY WITHOUT LOSING THIS RESULT" if pending_save_kind=="victory" else "YOUR PREVIOUS SAVE IS KEPT",Rect2(193,880,554,44),19,"SaveNotice",m)
	text_label(last_save_reason.replace("_"," ").to_upper(),Rect2(180,926,580,34),15,"SaveReason",m)
	action(m,"RETRY SAVE",982,retry_save,true)
	if pending_save_kind!="victory":action(m,"BACK",1070,close_current_modal)

func retry_save()->void:
	match pending_save_kind:
		"victory":
			if persist_victory():show_outcome(true)
			else:show_save_error()
		"settings":
			if commit_settings():show_settings()
		"tutorial":finish_tutorial()
		"entrance":replace_level(pending_entrance)
		_:show_load_recovery()

func show_load_recovery()->void:
	var m:=modal("COULDN'T LOAD",Rect2(149,520,642,700))
	text_label("YOUR SAVE HAS NOT BEEN RESET",Rect2(185,654,570,48),23,"RecoveryTitle",m)
	text_label(str(profile_state.get("reason","load_failed")).replace("_"," ").to_upper(),Rect2(170,716,600,48),16,"RecoveryReason",m)
	text_label("PLAY IS BLOCKED UNTIL RECOVERY SUCCEEDS",Rect2(175,778,590,45),18,"RecoveryNotice",m)
	action(m,"RETRY LOAD",854,retry_load,true)
	if profile_state.get("recovery_allowed",false):
		action(m,"RESTORE BACKUP",944,restore_backup)
		action(m,"RESET PROGRESS",1034,confirm_progress_reset)

func retry_load()->void:
	var result:Dictionary=saves.load_save();profile_state=result.state
	if result.ok:spawn_saved_level()
	else:show_load_recovery()

func restore_backup()->void:
	var result:Dictionary=saves.recover_from_backup();profile_state=result.state
	if result.ok:spawn_saved_level()
	else:
		profile_state.reason=result.reason;show_load_recovery()

func confirm_progress_reset()->void:
	recovery_reset_confirm=true
	var m:=modal("COULDN'T LOAD",Rect2(149,570,642,590))
	text_label("RESET ALL COMPLETIONS AND SETTINGS?",Rect2(180,716,580,50),21,"ResetWarning",m)
	text_label("PRESERVED RECOVERY FILES WILL BE KEPT",Rect2(180,780,580,45),18,"PreservationNotice",m)
	action(m,"RESET PROGRESS",900,reset_saved_progress,true)
	action(m,"CANCEL",995,func():recovery_reset_confirm=false;show_load_recovery())

func reset_saved_progress()->void:
	if not recovery_reset_confirm:return
	recovery_reset_confirm=false
	var result:Dictionary=saves.recover_with_defaults(true);profile_state=result.state
	if result.ok:spawn_saved_level()
	else:profile_state.reason=result.reason;show_load_recovery()

func show_error()->void:
	var m:=modal("COULDN'T LOAD")
	text_label("THIS ROUND NEEDS A SAFE RESTART",Rect2(195,773,550,54),22,"ErrorTitle",m)
	text_label("NO AMMO OR PROGRESS WAS INVENTED",Rect2(195,838,550,48),20,"RecoveryNotice",m)
	if not level_load_reason.is_empty():text_label(level_load_reason.replace("_"," ").to_upper(),Rect2(190,890,560,38),16,"LoadReason",m)
	action(m,"TRY AGAIN" if rules.status=="load_error" else "RESTART",951,func():replace_level(level_index),true)
	action(m,"LEVEL SELECT",1041,show_levels)

func replace_level(index:int)->void:
	if replacement_pending or index<1 or index>level_ids.size():return
	if pending_save_kind=="victory":show_save_error();return
	var result:Dictionary=saves.set_current_entrance(level_ids[index-1]);profile_state=result.state
	if not result.ok:
		pending_save_kind="entrance";pending_entrance=index;last_save_reason=result.reason;show_save_error();return
	pending_save_kind="";spawn_saved_level()

func request_home()->void:
	if pending_save_kind=="victory":show_save_error();return
	if rules.status=="running":
		var m:=modal("LEAVE THIS LEVEL?")
		icon("home",Rect2(402,666,136,136),m,Color("d08436"))
		text_label("THIS ROUND WILL START OVER",Rect2(204,828,532,54),24,"LeaveWarning",m)
		text_label("COMPLETED LEVELS STAY UNLOCKED",Rect2(204,881,532,48),20,"ProgressNotice",m)
		action(m,"HOME",971,return_home,true);action(m,"CANCEL",1055,show_pause)
	else:return_home()

func return_home()->void:
	transition_to_startup("home")

func spawn_saved_level()->void:
	transition_to_startup("play")

func transition_to_startup(mode:String)->void:
	if replacement_pending:return
	if pending_save_kind=="victory":show_save_error();return
	replacement_pending=true;ready_to_simulate=false
	if not recall_selection.is_empty():rules.cancel_tool_selection(str(recall_selection.get("token","")))
	# The lightweight boot shell contains no play-scene dependency. All game assets
	# and the destination PackedScene are acquired through its threaded loader.
	var next=load("res://scenes/startup.tscn").instantiate()
	next.use_command_line_catalog=false;next.start_mode=mode
	next.campaign_drafts=campaign_drafts;next.profile_directory=profile_directory;next.profile_directory_resolved=true
	next.auto_replay=auto_replay;next.qa_fixture_mode=qa_fixture_mode;next.qa_level_config=qa_level_config.duplicate(true)
	next.level_index=level_ids.find(profile_state.resume_level_id)+1
	get_tree().root.add_child(next);get_tree().current_scene=next;queue_free()

func _notification(what:int)->void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and ready_to_simulate and rules.status in ["ready","running"] and not is_instance_valid(pause_overlay):
		call_deferred("show_pause")

func capture_play_start()->void:
	await save_capture("play-start-%d"%level_index)

func capture_play_end()->void:
	await get_tree().create_timer(FX.DRAGON_DEFEAT_DURATION+.2 if rules.status=="victory" else .9).timeout
	await save_capture("play-final-"+rules.status)
	var report:Dictionary={"level":level_index,"level_id":level_config.get("level_id",""),"campaign_drafts":campaign_drafts,"production_eligible":false,"status":rules.status,"final_hit_us":rules.time_us,"conservation_errors":rules.conservation_errors(),"audio":audio_service.get_status(),"viewport":get_viewport().get_visible_rect().size,"rendering":RenderingServer.get_current_rendering_method(),"automatic_replay":auto_replay,"human_playtest":false}
	var f:=FileAccess.open("res://reports/ui/graphical-play-report.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	await get_tree().create_timer(1.2).timeout
	get_tree().quit()
