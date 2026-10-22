extends "res://scripts/main.gd"
## P3 adapter: rules own gameplay; verified local saves own progression.
## Presentation consumes events and never settles gameplay from animation.
const SceneLayout = preload("res://scripts/scene_layout.gd")
const Rules = preload("res://scripts/rescue_rules.gd")
const FX = preload("res://scripts/rescue_fx.gd")
const CarrierMotion = preload("res://scripts/directional_carrier.gd")
const ApprovedCarrier = preload("res://scripts/first_level_carrier.gd")
const ApprovedBead = preload("res://scripts/first_level_bead.gd")
const ApprovedLoading = preload("res://scripts/first_level_loading.gd")
const APPROVED_BALL_SIZE:=ApprovedBead.WORLD_SIZE
var carrier_motion:Script=CarrierMotion
const CarrierRoute = preload("res://scripts/carrier_route.gd")
const SerpentView = preload("res://scripts/serpent_view.gd")
const Saves = preload("res://scripts/save_service.gd")
const Catalog = preload("res://scripts/level_catalog.gd")
const Progression = preload("res://scripts/ant_progression.gd")
# Retained as the default catalog contract; opt-in entries use level_ids below.
const LEVEL_IDS = ["serpent-01", "serpent-02", "serpent-03", "serpent-04", "serpent-05", "serpent-06", "serpent-07", "serpent-08", "serpent-09"]
var level_ids: Array[String] = Catalog.level_ids(false)
var campaign_drafts := false
var use_command_line_catalog := true
var profile_directory_resolved := false
var level_selector_page := -1
var entry_screen := ""
var from_startup := false
var chooser_from_home := false
const TOOL_IDS = []
const TOOL_KINDS = []
var profile_directory := ""
# Explicit isolated test fixtures only. Normal entry never uses this override.
var qa_fixture_mode := false
var qa_level_config: Dictionary = {}
var saves: RefCounted
var profile_state: Dictionary = {}
var victory_saved := false
var progression:RefCounted
var economy_run_id:=""
var economy_state:Dictionary={}
var reward_receipt:Dictionary={}
var pending_save_kind := ""
var pending_entrance := 0
var last_save_reason := ""
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
var scene_layout:Dictionary={}
var level_config:Dictionary
var cells:Dictionary={}
var color_buttons:Dictionary={}
var serpent:Control
var serpent_elapsed:=0.0
var view_snapshot:Dictionary={}
var carriers:Dictionary={}
var loading_balls:Dictionary={}
var loading_sources:Dictionary={}
var loader_idle_ball_center:=Vector2(356.367,1048.443)
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
	# Review scope is independent of catalog existence, saves, CLI and QA.
	campaign_drafts=false;level_index=1
	level_ids=Catalog.level_ids(campaign_drafts)
	var requested_level := 0
	for arg in arguments:
		if use_command_line_level and arg.begins_with("--level="):
			var number:=int(arg.trim_prefix("--level="))
			if Catalog.runtime_level_allowed(number,campaign_drafts):requested_level=number
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
	if qa_fixture_mode and loaded.ok and (qa_level_config.is_empty() or Catalog.runtime_config_allowed(qa_level_config,1,false)):
		saves.set_current_entrance(level_ids[0])
		saves.set_tutorial_completed(true)
		profile_state=saves.get_view_state()
	elif loaded.ok and requested_level>0:
		# --level is a request, not an unlock bypass, in either catalog.
		var entrance:Dictionary=saves.set_current_entrance(level_ids[requested_level-1])
		profile_state=entrance.state
	level_index=1 # Preserve historical progress; only the runtime entrance is projected.
	audio_visual_state={"music":float(profile_state.music_volume),"sound":float(profile_state.sfx_volume),"music_muted":int(profile_state.music_volume)==0,"sound_muted":int(profile_state.sfx_volume)==0}
	var config_result:=read_level_configuration(Catalog.level_path(level_index,campaign_drafts))
	if qa_fixture_mode and not qa_level_config.is_empty():
		config_result={"ok":true,"config":qa_level_config.duplicate(true)}
	elif config_result.ok:
		config_result=Catalog.check_identity(config_result.config,level_index,campaign_drafts)
	if not config_result.ok:
		level_load_reason=str(config_result.reason);build_load_failure_ui();return
	level_config=config_result.get("config",{})
	if not Catalog.runtime_config_allowed(level_config,level_index,campaign_drafts):
		level_load_reason="first_level_review_only";build_load_failure_ui();return
	var scene_result:=SceneLayout.load_for(level_config)
	if not scene_result.ok:
		level_load_reason=str(scene_result.reason);build_load_failure_ui();return
	scene_layout=scene_result.data
	carrier_motion=ApprovedCarrier if is_approved_first_level() else CarrierMotion
	# Draft source identity remains unchanged, including its null production number.
	# Rules use level_number 1..30 for the normal 3/6/9/16 unlock context.
	if not campaign_drafts:level_config.level_number=level_index
	rules=Rules.new();next_run_serial+=1;rules.run_id=next_run_serial*100
	if not rules.load_level(level_config):
		level_load_reason=str(config_result.get("reason","invalid_level_configuration"))
		build_load_failure_ui();return
	progression=Progression.new(profile_directory)
	var economy_loaded:Dictionary=progression.load_save();economy_state=economy_loaded.state
	if not economy_loaded.ok:
		level_load_reason="economy_"+str(economy_loaded.reason);build_load_failure_ui();return
	economy_run_id=Progression.generate_run_id()
	var thresholds:Dictionary=level_config.get("rewards",{})
	var created:Dictionary=progression.create_run(economy_run_id,str(level_config.level_id),thresholds.get("fast_seconds"),thresholds.get("normal_seconds"))
	if not created.ok or not rules.set_ant_loadout(created.get("run",{}).get("loadout",{})):
		level_load_reason=str(created.get("reason","loadout_unavailable"));build_load_failure_ui();return
	if campaign_drafts:
		print("CAMPAIGN_PREVIEW ",JSON.stringify({"level_id":level_config.level_id,"human_playtest":level_config.get("validation",{}).get("human_playtest","NOT_RUN"),"production_eligible":false,"profile":profile_directory,"automatic_replay":auto_replay}))
	shield_shader=preload("res://scripts/combat_tint.gdshader")
	super._ready()
	fx=FX.new();fx.name="RescueFX";add_child(fx)
	fx.set_layout({"board_origin":grid_origin+Vector2.ONE*cell_edge*.5,"cell_size":Vector2.ONE*cell_edge,"cannon_muzzle":SceneLayout.point(scene_layout.cannon.muzzle),"cannon_center":SceneLayout.point(scene_layout.cannon.center),"rescue_center":SceneLayout.point(scene_layout.defense_target.foot),"nest":SceneLayout.point(scene_layout.nest.position),"segment_mode":true})
	var stock_points:Dictionary={}
	var stock_colors:Array=[]
	for color in COLORS:
		if int(rules.initial_counts.get(color,0))>0:stock_colors.append(color)
	for i in stock_colors.size():stock_points[stock_colors[i]]=SceneLayout.stock_anchor(scene_layout,i)+Vector2(24,0)
	var cell_points:Dictionary={}
	for cell in rules.board.values():cell_points["%d,%d"%[cell.x,cell.y]]=board_plane.center(cell.x,cell.y)
	fx.set_layout({"stock_points":stock_points,"cell_points":cell_points})
	if is_approved_first_level():fx.set_layout({"round_ball_size":APPROVED_BALL_SIZE,"round_ball_asset":ApprovedBead.TEXTURE_PATH,"round_ball_regions":JSON.parse_string(FileAccess.get_file_as_string(ApprovedBead.REGIONS_PATH)),"stock_hud_feedback":false,"authoritative_charge_preview":true,"event_clock_presentation":true})
	fx.auto_advance=false
	ready_to_simulate=true
	sync_view();consume_rule_events()
	if not profile_state.ready:show_load_recovery()
	elif not profile_state.tutorial_completed and not is_instance_valid(pause_overlay):show_tutorial()
	elif cold_entry and loaded.reason=="loaded" and not qa_fixture_mode:
		# Existing progress restores an entrance, never a partly played round.
		# This is nonmodal and clears on the first successful team, not a new step.
		text_label("FRESH ROUND · SAVED PROGRESS KEPT",Rect2(149,1570,642,32),18,"RoundRestartNotice",self,INK,true)
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
	# Failure can occur before rules are constructed. Keep recovery navigation
	# operational without fabricating a playable board, run or reward.
	if not is_instance_valid(rules):rules=Rules.new()
	rules.status="load_error";ready_to_simulate=false
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

func is_approved_first_level()->bool:
	return str(scene_layout.get("id",""))=="first_level_approved"

func bead(id:String,pos:Vector2,edge:float,parent:Node=self)->Control:
	if not is_approved_first_level():return super.bead(id,pos,edge,parent)
	var b:=ApprovedBead.new();b.color_id=id;b.edge=edge;b.position=pos;b.size=Vector2(edge,edge);b.footprint_height=edge;parent.add_child(b);return b

func place_board_bead(color_id:String,x:int,y:int,plane:RefCounted,parent:Node)->Control:
	if not is_approved_first_level():return super.place_board_bead(color_id,x,y,plane,parent)
	var span:Vector2=APPROVED_BALL_SIZE;var center:Vector2=plane.center(x,y)
	var b:=ApprovedBead.new();b.color_id=color_id;b.edge=span.x;b.footprint_height=span.y;b.position=center-span*.5;b.size=span;parent.add_child(b);return b

func approved_texture(path:String,region:Rect2,bounds:Rect2,parent:Node,id:String)->TextureRect:
	var texture:=AtlasTexture.new();texture.atlas=load(path);texture.region=region;texture.filter_clip=true
	return UiSkin.place_texture(texture,bounds,parent,id)

func approved_tint(target:CanvasItem,color:String)->void:
	var material:=ShaderMaterial.new();material.shader=preload("res://scripts/first_level_color.gdshader");material.set_shader_parameter("tint",COLOR_VALUES[color]);target.material=material

func build_mosaic()->void:
	var board:=group("Mosaic")
	board_plane=BoardPlane.new(int(level_config.width),int(level_config.height),scene_layout,level_config.transport.get("entrance_cell",[]))
	cell_edge=minf(660.0/float(level_config.width),570.0/float(level_config.height))
	grid_origin=Vector2((940.0-cell_edge*float(level_config.width))*.5,315)
	for cell in rules.board.values():
		var b:=place_board_bead(cell.color,cell.x,cell.y,board_plane,board)
		b.name="Bead%d"%cell.id;cells[cell.id]=b;bead_nodes.append(b);counts[cell.color]+=1

func create_fixture()->void:
	fixture={"visual_only":false,"stock":rules.inventory.duplicate(),"active":{},"board":counts,"initial":rules.initial_counts}
	pull_team_view()

func pull_team_view()->void:
	view_snapshot=rules.snapshot()
	fixture.remaining=view_snapshot.get("available_counts",{}).duplicate()
	fixture.stock=rules.inventory.duplicate()
	slot_teams=[]

static func color_control_layout(count:int)->Array[Rect2]:
	var layout:Array[Rect2]=[]
	if count<=0:return layout
	var gap:=20.0
	var width:=minf(234.0,(848.0-float(count-1)*gap)/float(count))
	var start:=(940.0-float(count)*width-float(count-1)*gap)*.5
	for index in count:layout.append(Rect2(start+float(index)*(width+gap),1282.0,width,116.0))
	return layout

func build_candidates()->void:
	var layer:=group("CandidateQueues")
	var active_colors:Array=[]
	for color in COLORS:
		if int(rules.initial_counts.get(color,0))>0:active_colors.append(color)
	if is_approved_first_level():active_colors=["blue","red","yellow","green","purple"]
	var layout:=color_control_layout(active_colors.size())
	var portrait_data:Dictionary={}
	if is_approved_first_level():
		portrait_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/first-level/card-portrait.json"))
		layout.clear()
		var gap:=12.0;var width:=(816.0-float(active_colors.size()-1)*gap)/float(active_colors.size())
		for index in active_colors.size():layout.append(Rect2(62+index*(width+gap),1342,width,176))
	for i in active_colors.size():
		var color:String=active_colors[i]
		var bounds:Rect2=layout[i]
		var x:=bounds.position.x;var y:=bounds.position.y;var width:=bounds.size.x
		var ant_width:=minf(76.0,width*.39)
		if is_approved_first_level():
			var card:=approved_texture("res://assets/first-level/color-card.png",Rect2(122,120,1049,999),Rect2(x,y+11,width,width*999.0/1049.0),layer,"ColorPlate_"+color)
			approved_tint(card,color)
			# HUD portraits are not world carriers. Preserve the five true controls,
			# their count rectangles, and all moving-ant/cargo geometry unchanged.
			var region:Rect2=SceneLayout.rect(portrait_data.region)
			var factor:=minf(width*float(portrait_data.max_width_ratio)/region.size.x,float(portrait_data.max_height)/region.size.y)
			var span:Vector2=region.size*factor
			var at:=Vector2(x+width*float(portrait_data.center_x_ratio)-span.x*.5,y+float(portrait_data.top_offset))
			var portrait:=approved_texture(str(portrait_data.texture),region,Rect2(at,span),layer,"ColorAnt_"+color)
			approved_tint(portrait,color)
		else:
			frame(bounds,"ColorPlate_"+color,layer,18)
			var actor:=ground_ant(color,Vector2(x+width*.32,y+85),"ColorAnt_"+color,layer,ant_width)
			carrier_motion.prepare(actor,color,ant_width)
			carrier_motion.apply(actor,{"time":0.0,"distance":0.0,"moving":false,"direction":Vector2.UP,"stage":"idle","pickup":0.0,"diameter":ant_width,"phase":0.0})
		var count_rect:=Rect2(x+width*.56,y+(94 if is_approved_first_level() else 27),width*.39,65)
		var count_label:=text_label(str(fixture.remaining.get(color,0)),count_rect,clampi(roundi(width*.25 if is_approved_first_level() else width*.19),28,42),"Remaining_"+color,layer,Color("fff2cf") if is_approved_first_level() else INK)
		if is_approved_first_level():count_label.add_theme_color_override("font_outline_color",Color("301a08"));count_label.add_theme_constant_override("outline_size",5)
		var button:=Button.new();button.name="ColorButton_"+color;button.position=bounds.position;button.size=bounds.size;button.flat=true;button.tooltip_text="Send one "+color+" ant";layer.add_child(button)
		button.pressed.connect(func():select_color(color));color_buttons[color]=button
		var state_icon:=icon("barrier",Rect2(x+width-35,y+8,24,24),layer,INK);state_icon.name="ColorState_"+color;state_icon.hide()

func select_color(color:String)->bool:
	if is_instance_valid(pause_overlay) or not profile_state.get("ready",false):return false
	var result:Dictionary=rules.click_color(color)
	if not result.ok:
		var messages:Dictionary={"carrier_limit":"ALL FOUR ANTS ARE BUSY","color_blocked":"NO REACHABLE BALL","color_all_reserved":"THESE BALLS ARE ALREADY CLAIMED","color_collected":"ALL COLLECTED","simulation_frozen":"PAUSED"}
		show_click_feedback(str(messages.get(result.get("reason",""),"NOT AVAILABLE")))
		return false
	var notice:=get_node_or_null("RoundRestartNotice")
	if notice:remove_child(notice);notice.queue_free()
	sync_view();consume_rule_events();return true

func show_click_feedback(message:String)->void:
	var old:=get_node_or_null("ClickFeedback")
	if old:remove_child(old);old.queue_free()
	var bounds:=Rect2(52,1534,340,94) if is_approved_first_level() else Rect2(130,1530,680,42)
	var label:=text_label(message,bounds,22,"ClickFeedback",self,Color("fff3d7"))
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_outline_color",Color("513316"));label.add_theme_constant_override("outline_size",4)
	ensure_ui_motion();ui_motion.reveal_hint(label);audio_service.play_event("error")
	feedback_serial+=1;var serial:=feedback_serial
	get_tree().create_timer(1.7).timeout.connect(func():
		if is_inside_tree() and feedback_serial==serial and is_instance_valid(label):label.queue_free())

func tint_red(target:CanvasItem,color:String)->void:
	if is_approved_first_level() and target.name=="Cannon":return # Preserve bronze; ammo and muzzle FX show the live color.
	var material:ShaderMaterial
	if target.material is ShaderMaterial:material=target.material
	else:material=ShaderMaterial.new();material.shader=shield_shader;target.material=material
	material.set_shader_parameter("tint",COLOR_VALUES[color])
	if target.name=="Cannon":material.set_shader_parameter("tint_region",Vector4(180.0/1536.0,654.0/1024.0,395.0/1536.0,851.0/1024.0))

func build_environment()->void:
	var bg:=TextureRect.new();bg.name="Environment";bg.texture=load(str(scene_layout.get("background","res://assets/serpent/environment.png")))
	bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;bg.size=Vector2(940,1672);bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(bg)

func build_threat()->void:
	var route:=group("DragonRoute")
	serpent=SerpentView.new();route.add_child(serpent)
	if not serpent.configure(level_config.serpent,SceneLayout.knots(scene_layout)):push_error("Serpent production atlas is missing")
	SceneLayout.add_target(route,scene_layout)

func build_transport()->void:
	var layer:=group("TransportScene")
	SceneLayout.add_nest(layer,scene_layout)
	var cannon:TextureRect
	if is_approved_first_level():
		cannon=approved_texture(str(scene_layout.cannon.texture),SceneLayout.rect(scene_layout.cannon.region),SceneLayout.rect(scene_layout.cannon.rect),layer,"Cannon")
	else:cannon=art(Rect2(48,654,412,337),SceneLayout.rect(scene_layout.cannon.rect),"Cannon",layer)
	cannon.pivot_offset=SceneLayout.point(scene_layout.cannon.pivot)
	if is_approved_first_level():
		var hopper:=bead("blue",SceneLayout.point(scene_layout.cannon.hopper)-cannon.position-APPROVED_BALL_SIZE*.5,APPROVED_BALL_SIZE.x,cannon);hopper.name="HopperAmmo";hopper.hide()
		ApprovedLoading.prepare_ball(hopper,cannon,SceneLayout.point(scene_layout.cannon.hopper)-cannon.position)
		ApprovedLoading.build_gunner(cannon)
	var live:=group("LiveCarriers",layer);layer.move_child(live,1)
	# The approved first-level scene has no side inventory HUD. Ammo remains
	# authoritative in Rules; real carriers, the hopper and shots are retained.
	if is_approved_first_level():return
	var stock:=group("Stock",layer)
	var stock_colors:Array=[]
	for color in COLORS:
		if int(rules.initial_counts.get(color,0))>0:stock_colors.append(color)
	for j in stock_colors.size():
		var color:String=stock_colors[j];var anchor:=SceneLayout.stock_anchor(scene_layout,j)
		bead(color,anchor+Vector2(12,-18),25,stock)
		var label:=text_label("0",Rect2(anchor+Vector2(0,13),Vector2(53,34)),23,"Count_"+color,stock,Color("fff7d9"));label.add_theme_color_override("font_outline_color",Color("573719"));label.add_theme_constant_override("outline_size",5)

func build_hud()->void:
	if is_approved_first_level():build_approved_hud();return
	var hud:=group("TopHUD")
	frame(Rect2(405,24,130,65),"Level",hud,8)
	text_label("%02d"%level_index,Rect2(410,27,120,54),32,"LevelNumber",hud)
	icon("pause",Rect2(839,26,61,61),hud,Color("fff3d9"))
	var pause_button:=Button.new();pause_button.name="PauseButton";pause_button.position=Vector2(824,13);pause_button.size=Vector2(88,88);pause_button.flat=true;pause_button.tooltip_text="Pause";hud.add_child(pause_button);pause_button.pressed.connect(show_pause)
	var speed:=Button.new();speed.name="SpeedButton";speed.position=Vector2(30,20);speed.size=Vector2(88,65);speed.flat=true;speed.tooltip_text="Simulation speed";hud.add_child(speed)
	text_label("×1",Rect2(30,20,88,65),28,"SpeedLabel",hud,Color("fff5df"),true)
	speed.pressed.connect(func():rules.set_speed(2 if rules.speed_multiplier==1 else 1))

func approved_medallion(parent:Node,bounds:Rect2,id:String)->TextureRect:
	return approved_texture("res://assets/first-level/deck-controls.png",Rect2(1279,91,590,581),bounds,parent,id)

func build_approved_hud()->void:
	var hud:=group("TopHUD")
	text_label("01",Rect2(410,25,120,54),32,"LevelNumber",hud,Color("fff3d9"),true)
	for entry in [["PauseButton","pause",Vector2(21,15)],["SettingsButton","settings",Vector2(831,15)]]:
		var at:Vector2=entry[2]
		approved_medallion(hud,Rect2(at,Vector2(88,86.66)),"Disc_"+str(entry[0]))
		if str(entry[1])=="pause":icon("pause",Rect2(at+Vector2(23,21),Vector2(42,44)),hud,Color("ffe4a1"))
		else:
			var gear:=preload("res://scripts/first_level_medallion.gd").new();gear.position=at;gear.size=Vector2(88,88);gear.kind="gear_only";hud.add_child(gear)
		var button:=Button.new();button.name=str(entry[0]);button.position=at;button.size=Vector2(88,88);button.flat=true;hud.add_child(button)
		button.pressed.connect(show_pause if str(entry[0])=="PauseButton" else show_settings)
	for entry in [["SpeedButton","speed",420]]:
		var bounds:=Rect2(float(entry[2]),1530,100,98.5)
		approved_medallion(hud,bounds,"Disc_"+str(entry[0]))
		var button:=Button.new();button.name=str(entry[0]);button.position=bounds.position;button.size=Vector2(100,100);button.flat=true;hud.add_child(button)
		if str(entry[1])=="speed":
			text_label("×1",Rect2(bounds.position+Vector2(12,19),Vector2(76,58)),27,"SpeedLabel",hud,Color("ffe5b0"))
			button.pressed.connect(func():rules.set_speed(2 if rules.speed_multiplier==1 else 1))
		else:
			icon(str(entry[1]),Rect2(bounds.position+Vector2(24,22),Vector2(52,54)),hud,Color("ffe5b0"))
			button.pressed.connect(request_home if str(entry[1])=="home" else show_restart)

func build_slots()->void:
	var layer:=group("WorkSlots")
	if is_approved_first_level():
		for index in 4:
			var x:=165.0+float(index)*161.0
			approved_texture("res://assets/first-level/deck-controls.png",Rect2(101,163,948,476),Rect2(x-55,1250,132,66.28),layer,"TransportPedestal%d"%index)
			var actor:=ground_ant("blue",Vector2(x+11,1287),"TransportPreview%d"%index,layer,73)
			carrier_motion.prepare(actor,"blue",73);carrier_motion.apply(actor,{"time":0.0,"moving":false,"direction":Vector2.RIGHT,"stage":"idle","diameter":73})
			actor.hide()
		text_label("0 / 4",Rect2(388,1309,164,35),23,"CarrierCount",layer,Color("fff1d2"),true)
		text_label("",Rect2(570,1309,120,35),18,"CapacityState",layer,Color("fff1d2"),true)
		return
	ant("yellow",Rect2(405,1222,54,44),"CarrierCapacity",layer)
	text_label("0 / 4",Rect2(465,1222,100,46),25,"CarrierCount",layer,Color("fff1d2"),true)
	text_label("",Rect2(567,1224,90,42),18,"CapacityState",layer,Color("fff1d2"),true)

func sync_approved_transport_displays()->void:
	if not is_approved_first_level():return
	var tasks:Array=rules.tasks.values()
	for index in 4:
		var actor:Control=get_node("WorkSlots/TransportPreview%d"%index)
		actor.visible=index<tasks.size()
		if not actor.visible:continue
		var task:Dictionary=tasks[index]
		var state:Dictionary=actor.get_meta(carrier_motion.CACHE_KEY)
		state.material.set_shader_parameter("tint",COLOR_VALUES[task.color])
		actor.tooltip_text="In transit · "+str(task.color)

func build_tools()->void:
	pass

func sync_tool_controls()->void:
	pass

func clear_scout()->void:
	pass

func _process(delta:float)->void:
	if not ready_to_simulate:return
	if not rules.paused and scout_seconds>0:
		scout_seconds-=delta
		if scout_seconds<=0:clear_scout()
	if auto_replay and not rules.paused:advance_replay(delta)
	else:rules.update(delta)
	sync_view();consume_rule_events();fx.advance(delta);serpent.advance(delta)
	apply_gameplay_interaction_motion()
	apply_actor_poses()
	present_pending_outcome()

func advance_replay(delta:float)->void:
	var left:=roundi(delta*1000000)
	var solution:Array=level_config.get("solution",{}).get("inputs",[])
	while left>0 and rules.status in ["ready","running"]:
		while replay_index<solution.size() and roundi(float(solution[replay_index].at_sec)*1000000.0)<=rules.time_us:
			var entry:Dictionary=solution[replay_index];rules.click_color(entry.color);replay_index+=1
		var step:=left
		if replay_index<solution.size():step=mini(step,maxi(1,roundi(float(solution[replay_index].at_sec)*1000000.0)-rules.time_us))
		rules.update_us(step);left-=step

func sync_view()->void:
	if not ready_to_simulate:return
	for id in cells:
		if is_instance_valid(cells[id]):cells[id].visible=rules.board.has(id)
	pull_team_view()
	for color in color_buttons:
		get_node("CandidateQueues/Remaining_"+color).text=str(fixture.remaining.get(color,0))
		color_buttons[color].disabled=rules.paused or rules.status not in ["ready","running"]
		var state:String=str(view_snapshot.color_states[color].state)
		get_node("CandidateQueues/ColorAnt_"+color).modulate=Color(.55,.55,.55,.72) if state in ["collected","blocked"] else Color.WHITE
		var indicator:Control=get_node("CandidateQueues/ColorState_"+color)
		indicator.visible=state!="ready";indicator.kind="check" if state=="collected" else ("clock" if state=="all_reserved" else "barrier");indicator.queue_redraw()
		color_buttons[color].tooltip_text="All four ants are busy" if view_snapshot.capacity_full else ({"ready":"Send one ant","blocked":"No reachable ball","all_reserved":"Matching balls are already claimed","collected":"All balls collected"}.get(state,"Send one ant"))
	get_node("WorkSlots/CarrierCount").text="%d / %d"%[int(view_snapshot.carrier_count),int(view_snapshot.carrier_limit)]
	get_node("WorkSlots/CapacityState").text="BUSY" if view_snapshot.capacity_full else ""
	sync_approved_transport_displays()
	if not is_approved_first_level():
		for color in color_buttons:get_node("TransportScene/Stock/Count_"+color).text=str(rules.inventory.get(color,0))
	get_node("TopHUD/SpeedLabel").text="×%d"%rules.speed_multiplier
	serpent.sync_snapshot(view_snapshot)
	var projectile:Dictionary=rules.projectile
	if not projectile.is_empty():
		fx.set_layout({"dragon_hit":serpent.target_point(str(projectile.target_segment_id),rules.head_s())})
		tint_red(get_node("TransportScene/Cannon"),str(projectile.color))
	else:
		var next_target:Dictionary=rules.next_fire_target()
		if not next_target.is_empty():tint_red(get_node("TransportScene/Cannon"),str(next_target.color))
	fx.sync_snapshot(view_snapshot)
	if is_approved_first_level():sync_hopper_ammo()
	sync_carriers()
	if is_instance_valid(fx):move_child(fx,-1)
	if is_instance_valid(pause_overlay):move_child(pause_overlay,-1)
	apply_gameplay_interaction_motion()

func sync_hopper_ammo()->void:
	var hopper:Control=get_node("TransportScene/Cannon/HopperAmmo");hopper.hide()
	fx.set_cannon_charge(0.0,"blue")
	# A fired ball is no longer in the hopper. During cooldown preview only the
	# same target/color the authoritative next-fire selector would actually use.
	if not rules.projectile.is_empty() or rules.status not in ["ready","running"]:return
	var target:Dictionary=rules.next_fire_target()
	if target.is_empty():return
	hopper.color_id=str(target.color);hopper.queue_redraw();hopper.show()
	fx.set_cannon_charge(1.0,str(target.color))

func apply_gameplay_interaction_motion()->void:
	if not ready_to_simulate:return
	for color in stock_arrivals.keys():
		var label:=get_node_or_null("TransportScene/Stock/Count_"+color) as Control
		var t:=clampf(float(rules.time_us-int(stock_arrivals[color]))/260000.0,0,1)
		if label:
			label.pivot_offset=label.size*.5;label.scale=Vector2.ONE*(1.0+sin(t*PI)*.13*(1.0-t))
		if t>=1:stock_arrivals.erase(color)

func map_path_point(point:Variant)->Vector2:
	if Vector2(float(point[0]),float(point[1]))==board_plane.entrance_cell:return SceneLayout.point(scene_layout.nest.position)
	return board_plane.center(float(point[0]),float(point[1]))

func sync_carriers()->void:
	var container:=get_node("TransportScene/LiveCarriers")
	for id in carriers.keys():
		if not rules.tasks.has(id):carriers[id].queue_free();carriers.erase(id)
	for id in rules.tasks:
		var task:Dictionary=rules.tasks[id]
		if not carriers.has(id):
			var carrier_diameter:=ApprovedCarrier.WORLD_DIAMETER if is_approved_first_level() else 48.0
			var actor:=ground_ant(task.color,Vector2.ZERO,"Carrier%d"%id,container,carrier_diameter)
			var target_cell:Array=task.path[-1]
			var cargo_size:Vector2=APPROVED_BALL_SIZE if is_approved_first_level() else Vector2(24,27)
			var carried:=bead(task.color,Vector2(-cargo_size.x*.5,-48),cargo_size.x,actor);carried.name="CarriedBead"
			if is_approved_first_level():carried.footprint_height=cargo_size.y;carried.size=cargo_size;carried.set_meta("world_size",cargo_size)
			carrier_motion.prepare(actor,task.color,carrier_diameter)
			actor.set_meta("carrier_route",CarrierRoute.build(task.path,board_plane,SceneLayout.point(scene_layout.nest.position)))
			carriers[id]=actor
		var return_depart:int=task.get("return_depart_us",task.pickup_us)
		var holding:bool=task.stage=="returning" and rules.time_us<return_depart
		var hold_fraction:=clampf(float(rules.time_us-task.pickup_us)/maxf(1,float(return_depart-task.pickup_us)),0,1)
		var t:float
		if task.stage=="outbound":t=clampf(float(rules.time_us-task.depart_us)/maxf(1,float(task.pickup_us-task.depart_us)),0,1)
		elif holding:t=1.0
		elif task.stage=="unloading":t=0.0
		else:t=1.0-clampf(float(rules.time_us-return_depart)/maxf(1,float(task.get("unload_us",task.delivery_us)-return_depart)),0,1)
		var actor:Control=carriers[id]
		var pose:Dictionary=CarrierRoute.sample(actor.get_meta("carrier_route"),t)
		actor.position=pose.position
		actor.scale=Vector2.ONE*board_plane.depth_scale(pose.depth_y)
		actor.get_node("CarriedBead").visible=task.stage in ["returning","unloading"]
		var direction:Vector2=pose.tangent
		if task.stage in ["returning","unloading"] and not holding:direction=-direction
		var elapsed:=float(rules.time_us-task.depart_us)/1000000.0
		var leg_sec:=float(task.pickup_us-task.depart_us)/1000000.0
		# Continue the stride rather than snapping phase when the load is acquired.
		var stride_time:float=minf(elapsed,leg_sec)*carrier_motion.OUTBOUND_CADENCE
		if task.stage=="returning":stride_time+=maxf(0.0,float(rules.time_us-return_depart)/1000000.0)*carrier_motion.LOADED_CADENCE
		var travelled:float=pose.travelled if task.stage=="outbound" else pose.total_length*2.0-pose.travelled
		var carried:=actor.get_node("CarriedBead") as Control
		if is_approved_first_level():carried.scale=Vector2.ONE/actor.scale
		carrier_motion.apply(actor,{"time":float(rules.time_us)/1000000.0,
			"distance":pose.travelled if task.stage=="outbound" else pose.total_length*2.0-pose.travelled,
			"outbound_distance":minf(travelled,pose.total_length),"loaded_distance":maxf(0.0,travelled-pose.total_length),"phase_offset":float(id)*1.7,
			"moving":not holding and task.stage!="unloading","direction":direction,"stage":"pickup" if holding else ("returning" if task.stage=="unloading" else task.stage),
			"pickup":hold_fraction if holding else 0.0,"diameter":ApprovedCarrier.WORLD_DIAMETER if is_approved_first_level() else 48.0,"phase":stride_time*TAU+float(id)*1.7})
		if is_approved_first_level():
			# Lift the unchanged ball from its real source-cell center to this view
			# of the back. The existing pickup hold still owns all timing/events.
			if holding:carried.position=(-carried.size*carried.scale*.5).lerp(carried.position,smoothstep(0,1,hold_fraction))
			if task.stage=="unloading" and rules.status in ["ready","running"]:
				# Ownership is a single transport task, not new inventory. Only
				# its cannon-attached view is visible during the real unload window.
				if not loading_sources.has(id):
					var layer:Control=get_node("TransportScene")
					loading_sources[id]=layer.get_global_transform().affine_inverse()*(carried.get_global_transform()*(carried.size*.5))
				if not loading_balls.has(id):
					var incoming:=bead(task.color,Vector2.ZERO,APPROVED_BALL_SIZE.x,get_node("TransportScene/Cannon"))
					incoming.name="LoadingBall%d"%id;incoming.set_meta("transport_task_id",id)
					incoming.set_meta("delivery_us",int(task.delivery_us))
					ApprovedLoading.prepare_ball(incoming,get_node("TransportScene/Cannon"),SceneLayout.point(scene_layout.cannon.hopper)-SceneLayout.rect(scene_layout.cannon.rect).position)
					loading_balls[id]=incoming
			if loading_balls.has(id):carried.hide()
		else:
			carried.scale=Vector2.ONE*lerpf(.65,1.0,smoothstep(0,1,hold_fraction)) if holding else Vector2.ONE
			if holding:carried.position.y+=(1.0-smoothstep(0,1,hold_fraction))*6.0
	if is_approved_first_level():sync_loading_ball_poses()

func sync_loading_ball_poses()->void:
	var cannon:Control=get_node("TransportScene/Cannon")
	var hopper:Control=cannon.get_node("HopperAmmo")
	var anchor:Vector2=SceneLayout.point(scene_layout.cannon.hopper)-SceneLayout.rect(scene_layout.cannon.rect).position
	ApprovedLoading.attach_ball(hopper,cannon,cannon.get_transform()*anchor)
	for id in loading_balls.keys():
		if not rules.tasks.has(id) or rules.tasks[id].stage!="unloading":
			loading_balls[id].hide();loading_balls[id].queue_free();loading_balls.erase(id);loading_sources.erase(id);continue
		var task:Dictionary=rules.tasks[id]
		var point:Vector2=ApprovedLoading.transfer_center(loading_sources[id],cannon.get_transform()*anchor,int(task.unload_us),int(task.delivery_us),rules.time_us)
		var ball:Control=loading_balls[id]
		if rules.status not in ["ready","running"]:
			if not ball.has_meta("terminal_center"):
				ball.set_meta("terminal_center",point);ball.set_meta("terminal_rotation",cannon.rotation)
			point=ball.get_meta("terminal_center")
			ball.rotation=float(ball.get_meta("terminal_rotation"))-cannon.rotation
		else:ball.rotation=0.0
		ApprovedLoading.attach_ball(ball,cannon,point)
	var gunner:Node2D=cannon.get_node("LoaderAnt")
	# The approved cannon-side worker is a planted receiving station. Do not
	# teleport one loader between overlapping unloading tasks or across brass.
	var push:=Vector2.ZERO
	var receive:Vector2=loader_idle_ball_center
	for id in loading_balls:
		var task:Dictionary=rules.tasks[id]
		var elapsed:=float(rules.time_us-int(task.unload_us))/1000000.0
		if elapsed>=.20 and elapsed<.40:
			var direction:Vector2=(cannon.get_transform()*anchor-Vector2(loading_sources[id])).normalized()
			var candidate:Vector2=direction*sin((elapsed-.20)/.20*PI)*4.0
			if candidate.length()>push.length():push=candidate
	if rules.status not in ["ready","running"]:
		if not gunner.has_meta("terminal_push"):gunner.set_meta("terminal_push",push)
		push=gunner.get_meta("terminal_push")
	ApprovedLoading.pose_gunner(gunner,cannon,receive,push)

func sample_carrier_path(path:Array,t:float)->Dictionary:
	# Direct diagnostics only; live carriers cache this immutable route once.
	return CarrierRoute.sample(CarrierRoute.build(path,board_plane,SceneLayout.point(scene_layout.nest.position)),t)

func consume_rule_events()->void:
	var events:Array=rules.drain_events()
	var sound_map:Dictionary={"ant_dispatched":"dispatch","bead_picked_up":"pickup","bead_delivered":"return","cannon_fired":"cannon","segment_hit":"armor_hit","load_error":"error","recoverable_error":"error"}
	for event in events:
		if event.type in ["cannon_fired","segment_hit","segment_removed"]:
			fx.set_layout({"dragon_hit":serpent.target_point(str(event.get("target_segment_id",event.get("segment_id",""))),float(event.get("target_s",rules.head_s())))})
		fx.consume_event(event);serpent.consume_event(event)
		if event.type=="bead_delivered" and not is_approved_first_level():stock_arrivals[event.color]=event.time_us
		if sound_map.has(event.type):audio_service.play_event(sound_map[event.type])
		if event.type in ["victory","defeat"] and last_outcome.is_empty():
			last_outcome=event.type
			if event.type=="victory":
				persist_victory();pending_victory_presentation_run=rules.run_id;get_node("TopHUD/PauseButton").disabled=true
			else:
				progression.settle_run(economy_run_id,"lost",elapsed_round_seconds())
				var completed_run:int=rules.run_id
				get_tree().create_timer(.65).timeout.connect(func():
					if is_inside_tree() and rules.run_id==completed_run:show_outcome(false);audio_service.play_event("lose"))
		if capture_play and event.type=="cannon_fired" and not captured_first_fire:
			captured_first_fire=true;call_deferred("save_capture","play-first-fire")
		if capture_play and event.type=="segment_hit" and not captured_first_hit:
			captured_first_hit=true;call_deferred("save_capture","play-first-hit")
		if capture_play and event.type in ["victory","defeat"]:call_deferred("capture_play_end")
		if event.type=="recoverable_error":show_error()
	if not warning_played and rules.status=="running" and rules.head_s()>float(level_config.serpent.goal_s)*.8:
		warning_played=true;audio_service.play_event("warning")

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
	cannon.position=SceneLayout.rect(scene_layout.cannon.rect).position+cp.offset;cannon.rotation=cp.rotation;cannon.scale=cp.scale
	if is_approved_first_level():sync_loading_ball_poses()

func modal(title:String,rect:Rect2=Rect2(170,520,600,620))->Control:
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

func tutorial_ant(parent:Control,foot:Vector2,diameter:float,id:String)->Control:
	var actor:=Control.new();actor.name=id;actor.position=foot;actor.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(actor)
	var sprite:=TextureRect.new();sprite.name="Ant";sprite.mouse_filter=Control.MOUSE_FILTER_IGNORE;actor.add_child(sprite)
	ApprovedCarrier.prepare(actor,"blue",diameter)
	ApprovedCarrier.apply(actor,{"time":0.0,"moving":false,"direction":Vector2(1,1),"stage":"idle","diameter":diameter})
	return actor

func show_tutorial()->void:
	var m:=modal("YOUR FIRST RESCUE",Rect2(70,330,800,1125))
	# Game illustrations and four short rules, sized for a 360-wide phone view.
	# HUD illustrations reuse actual art; they are not live transport tasks.
	tutorial_ant(m,Vector2(226,576),116,"TutorialAnt")
	for index in 4:tutorial_ant(m,Vector2(153+index*48,745),48,"CapacityAnt%d"%index)
	var ball:=ApprovedBead.new();ball.name="TutorialBall";ball.color_id="blue";ball.edge=60;ball.footprint_height=60;ball.size=Vector2(60,60);ball.position=Vector2(143,865);m.add_child(ball)
	icon("arrow",Rect2(205,878,28,28),m,INK)
	approved_texture(str(scene_layout.cannon.texture),SceneLayout.rect(scene_layout.cannon.region),Rect2(239,831,91,125),m,"TutorialCannon")
	serpent.add_head_portrait(m,Rect2(123,1009,155,153))
	var target:=SceneLayout.target_texture(scene_layout)
	UiSkin.place_texture(target,Rect2(285,1040,51,88),m,"TutorialPrincess",true)
	var steps:Array[String]=["TAP A COLOR\nSEND ONE ANT","UP TO FOUR ANTS\nCARRY AT ONCE","MATCHING BALLS\nLOAD THE CANNON","CLEAR THE DRAGON\nBEFORE IT REACHES HER"]
	for index in steps.size():
		var line:=text_label(steps[index],Rect2(350,470+index*180,480,125),36,"StepText%d"%index,m)
		line.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	text_label("DRAGON MOVES AFTER YOUR FIRST ANT",Rect2(110,1188,720,50),30,"ObservationNotice",m)
	var bounds:=Rect2(190,1275,560,140)
	frame(bounds,"TutorialContinueArt",m,30,"54d35b")
	text_label("LET'S GO",Rect2(210,1304,520,76),42,"TutorialContinueLabel",m,Color.WHITE,true)
	var next:=Button.new();next.name="TutorialContinue";next.flat=true;next.position=bounds.position;next.size=bounds.size;next.tooltip_text="Start the first rescue";m.add_child(next);next.pressed.connect(finish_tutorial)
	var close:Button=m.get_node("CloseButton");close.size=Vector2(128,128);close.position+=Vector2(-8,-8)

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

func show_levels(_page:int=-1)->void:
	if pending_save_kind=="victory":show_save_error();return
	if rules.status=="running":
		var m:=modal("LEAVE THIS LEVEL?")
		text_label("THIS ROUND WILL START OVER",Rect2(204,790,532,54),24,"LeaveWarning",m)
		action(m,"LEAVE",945,func():transition_to_startup("map"),true)
		action(m,"CANCEL",1040,show_pause)
	else:transition_to_startup("map")

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

func elapsed_round_seconds()->float:
	return maxf(0.,float((rules.terminal_time_us if rules.terminal_time_us>=0 else rules.time_us)-maxi(0,rules.threat_started_us))/1000000.)

func persist_victory()->bool:
	if rules.status!="victory":return false
	var reward:Dictionary=progression.settle_run(economy_run_id,"won",elapsed_round_seconds())
	if not reward.ok:
		pending_save_kind="victory";last_save_reason=reward.reason;victory_saved=false;return false
	economy_state=reward.state;reward_receipt=reward.run.receipt

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
	var m:=modal("SAVED!" if won else "TRY AGAIN",Rect2(98,335,744,1140 if won else 1040))
	if won:
		serpent.hide()
		UiSkin.place_texture(SceneLayout.target_texture(scene_layout),Rect2(310,535,320,270),m,"SavedDefenseTarget",true)
		UiSkin.place_texture(load("res://assets/meta-ui/ant-coin.png"),Rect2(357,829,62,62),m,"RewardCoin",true)
		text_label("+%d"%int(reward_receipt.get("total",0)),Rect2(427,825,205,67),40,"PointsEarned",m,INK,true)
		text_label("%d BASE + %d TIME  ·  %.1fs"%[int(reward_receipt.get("base",0)),int(reward_receipt.get("time_bonus",0)),elapsed_round_seconds()],Rect2(230,891,480,34),19,"RewardBreakdown",m)

		# No SDK is connected. Expose the unavailable optional bonus honestly,
		# without a mock ad, reward callback, or a gate on normal progression.
		var ad:=Button.new();ad.name="RewardedAdUnavailable";ad.disabled=true
		ad.position=Vector2(190,934);ad.size=Vector2(560,80)
		ad.tooltip_text="Rewarded ads are not connected. Your points are already saved."
		frame(Rect2(ad.position,ad.size),"AdUnavailablePanel",m,24,"e6dfc9")
		text_label("BONUS ADS UNAVAILABLE",Rect2(210,941,520,32),21,"AdStatus",m,INK,true)
		text_label("YOUR POINTS ARE SAVED · CONTINUE ANY TIME",Rect2(210,977,520,27),16,"AdExplanation",m)
		m.add_child(ad)
	else:serpent.add_head_portrait(m,Rect2(290,570,360,300))
	var next_id:String=profile_state.get("next_level_id","") if victory_saved else ""
	if not Catalog.runtime_level_allowed(level_ids.find(next_id)+1,campaign_drafts):next_id=""
	if won and not next_id.is_empty():result_action(m,"NEXT LEVEL",1034,func():replace_level(level_ids.find(next_id)+1),true)
	result_action(m,"PLAY AGAIN" if won else "RETRY",1176 if won else 1076,func():replace_level(level_index),not won or next_id.is_empty())
	var footer_y:=1318. if won else 1218.
	var map_bounds:=Rect2(190,footer_y,260,118)
	frame(map_bounds,"MapAction",m,30);icon("levels",Rect2(280,footer_y+19,80,80),m,INK)
	var map_button:=Button.new();map_button.name="MapButton";map_button.flat=true;map_button.position=map_bounds.position;map_button.size=map_bounds.size;map_button.tooltip_text="Adventure map";m.add_child(map_button);map_button.pressed.connect(show_levels)
	var shop_bounds:=Rect2(490,footer_y,260,118)
	frame(shop_bounds,"ShopAction",m,30)
	UiSkin.place_texture(load("res://assets/meta-ui/ant-coin.png"),Rect2(580,footer_y+19,80,80),m,"ShopCoin",true)
	var shop_button:=Button.new();shop_button.name="ShopButton";shop_button.flat=true;shop_button.position=shop_bounds.position;shop_button.size=shop_bounds.size;shop_button.tooltip_text="Ant shop";m.add_child(shop_button);shop_button.pressed.connect(func():transition_to_startup("shop"))

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
	if not Catalog.runtime_level_allowed(index,campaign_drafts):return
	if pending_save_kind=="victory":show_save_error();return
	var result:Dictionary=saves.set_current_entrance(level_ids[index-1]);profile_state=result.state
	if not result.ok:
		pending_save_kind="entrance";pending_entrance=index;last_save_reason=result.reason;show_save_error();return
	pending_save_kind="";transition_to_startup("play" if index==level_index else "preparation")

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
	if is_instance_valid(progression) and rules.status not in ["victory","defeat"]:progression.settle_run(economy_run_id,"cancelled",elapsed_round_seconds())
	replacement_pending=true;ready_to_simulate=false
	# The lightweight boot shell contains no play-scene dependency. All game assets
	# and the destination PackedScene are acquired through its threaded loader.
	var next=load("res://scenes/startup.tscn").instantiate()
	next.use_command_line_catalog=false;next.start_mode=mode
	next.campaign_drafts=campaign_drafts;next.profile_directory=profile_directory;next.profile_directory_resolved=true
	next.auto_replay=auto_replay;next.qa_fixture_mode=qa_fixture_mode;next.qa_level_config=qa_level_config.duplicate(true)
	next.level_index=1
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
