extends "res://scripts/main.gd"
## Production entry. ResourceLoader owns progress; no minimum duration or fake timer.
const Loader = preload("res://scripts/startup_loader.gd")
const Saves = preload("res://scripts/save_service.gd")
const Catalog = preload("res://scripts/level_catalog.gd")
const Progression = preload("res://scripts/ant_progression.gd")
const Adventure = preload("res://scripts/adventure_view.gd")
const Shop = preload("res://scripts/ant_shop_view.gd")
const Rules = preload("res://scripts/rescue_rules.gd")
const SceneLayout = preload("res://scripts/scene_layout.gd")
const FirstPreview = preload("res://scripts/first_level_preview.gd")
const TITLE = preload("res://assets/startup/title.png")
# These existing paint/font resources belong to the bootstrap shell, not its
# asynchronous game batch. Error/Back controls never wait on their own loader.
const BOOT_BUTTON_ATLAS = preload("res://assets/ui/v03/game-skin-atlas.png")
const BOOT_FONT = preload("res://assets/fonts/Title.ttf")
const HOME_RESOURCES: Array[String] = [
	"res://assets/first-level/round-beads.png", "res://assets/first-level/bronze-cannon.png",
	"res://assets/first-level/princess.png", "res://assets/first-level/slender-ants.png", "res://assets/first-level/cannon-loader.png",
	"res://assets/worlds/ruins-courtyard.png", "res://assets/worlds/supply-cart.png",
	"res://assets/worlds/ice-valley.png", "res://assets/worlds/winter-camp.png",
	"res://assets/worlds/forest-traveler.png",
	"res://assets/meta-ui/shop-workshop-background.png", "res://assets/meta-ui/adventure.png", "res://assets/meta-ui/ready.png", "res://assets/meta-ui/ant-shop.png",
	"res://assets/meta-ui/worker.png", "res://assets/meta-ui/swift.png", "res://assets/meta-ui/training.png", "res://assets/meta-ui/swift-wing.png", "res://assets/meta-ui/ant-coin.png",
	"res://assets/serpent/environment.png", "res://assets/characters-atlas.png",
	"res://assets/serpent/ice-serpent-atlas.png", "res://assets/serpent/carapace-serpent-atlas.png",
	"res://assets/serpent/nest-entry.png", "res://assets/serpent/serpent-atlas.png", "res://assets/serpent/serpent-armor-atlas.png",
	"res://assets/motion/ant-directions.png",
	"res://assets/ants-atlas.png", "res://assets/fonts/Title.ttf",
	"res://assets/ui/fusion/beads.png", "res://assets/ui/fusion/audio-icons.png",
	"res://assets/ui/v03/title-atlas.png", "res://assets/ui/v03/game-skin-atlas.png",
	"res://assets/ui/v03/settings-skin-atlas.png",
]
var campaign_drafts := false
var use_command_line_catalog := true
var profile_directory := ""
var profile_directory_resolved := false
var start_mode := "home"
var entry_screen := ""
var auto_replay := false
var qa_fixture_mode := false
var qa_level_config: Dictionary = {}
var level_index := 1
var phase := "splash"
var batch := "home"
var loader: Node
var saves: RefCounted
var profile_state: Dictionary = {}
var home_art: Control
var loading_layer: Control
var progress_bar: ProgressBar
var loading_label: Label
var home_ready := false
var launch_pending := false
var boot_events: Array[Dictionary] = []
var retained_resources: Array[Resource] = []
var progression:RefCounted
var economy_state:Dictionary={}
var adventure:Control
var shop:Control
var shop_return_screen:="map"
var meta_settings_dirty:=false
var meta_settings_recovery_pending:=false
var meta_navigation_recovery_pending:=false
var load_generation := 0
var active_request_id := -1
var launch_origin := "preparation"
var loader_owner_id := 0

func _ready() -> void:
	if DisplayServer.get_name()!="headless":get_window().mode=Window.MODE_MAXIMIZED
	var canvas_scale := minf(1440.0/940.0,2560.0/1672.0)
	size=Vector2(940,1672);scale=Vector2.ONE*canvas_scale;position=(Vector2(1440,2560)-size*scale)*.5
	var args:=OS.get_cmdline_user_args()
	# First-level review scope cannot be widened by CLI, QA or restored progress.
	campaign_drafts=false;level_index=1
	if not profile_directory_resolved:
		var profile_root:=profile_directory
		if profile_root.is_empty():profile_root=OS.get_environment("ANT_RESCUE_PROFILE_DIR")
		profile_directory=Catalog.profile_path(profile_root,campaign_drafts)
	profile_directory_resolved=true
	# Explicit replay CLI retains its separate temporary saves, never writes normal progress.
	if use_command_line_catalog and "--auto-replay" in args:
		auto_replay=true;qa_fixture_mode=true;start_mode="play"
		profile_directory="/tmp/ant-rescue-replay-%d-%d"%[OS.get_process_id(),Time.get_ticks_usec()]
		for arg in args:
			if arg.begins_with("--level=") and Catalog.runtime_level_allowed(int(arg.trim_prefix("--level="))):level_index=1
	saves=Saves.new(profile_directory,Catalog.level_ids(campaign_drafts),30)
	var result:Dictionary=saves.load_save();profile_state=result.state
	progression=Progression.new(profile_directory)
	economy_state=progression.load_save().state
	if profile_state.ready and not qa_fixture_mode:
		level_index=1 # Project the entrance without erasing historical saves.
		for arg in args:
			if use_command_line_catalog and arg.begins_with("--level="):
				var requested:=int(arg.trim_prefix("--level="))
				if not Catalog.runtime_level_allowed(requested,campaign_drafts):continue
				var entrance:Dictionary=saves.set_current_entrance(Catalog.level_ids(campaign_drafts)[requested-1])
				profile_state=entrance.state
	audio_visual_state={"music":float(profile_state.music_volume),"sound":float(profile_state.sfx_volume),"music_muted":int(profile_state.music_volume)==0,"sound_muted":int(profile_state.sfx_volume)==0}
	theme=Theme.new()
	for state in ["normal","hover","pressed","disabled","focus"]:theme.set_stylebox(state,"Button",StyleBoxEmpty.new())
	build_boot_shell()
	create_loader()
	record_event("splash")
	call_deferred("begin_home_load")

func create_loader() -> void:
	loader_owner_id+=1
	loader=Loader.new();loader.name="StartupLoader";add_child(loader)
	loader.progress_changed.connect(update_progress.bind(loader_owner_id))
	loader.completed.connect(on_loaded.bind(loader_owner_id))
	loader.failed.connect(on_load_failed.bind(loader_owner_id))

func start_resource_batch(paths:Array[String]) -> void:
	# start() can fail synchronously, so establish ownership before calling it.
	active_request_id=loader.request_id+1
	loader.start(paths)

func record_event(event:String) -> void:
	var row:Dictionary={"event":event,"ticks_us":Time.get_ticks_usec(),"phase":phase,"batch":batch,"profile":profile_directory,"campaign":campaign_drafts}
	boot_events.append(row);print("STARTUP_EVENT ",JSON.stringify(row))

func build_boot_shell() -> void:
	loading_layer=group("LoadingLayer");loading_layer.size=size;loading_layer.mouse_filter=Control.MOUSE_FILTER_STOP
	var gradient:=Gradient.new();gradient.set_color(0,Color("9bcfd4"));gradient.set_color(1,Color("e7c782"))
	var tex:=GradientTexture2D.new();tex.gradient=gradient;tex.fill_from=Vector2(.4,0);tex.fill_to=Vector2(.6,1)
	var bg:=TextureRect.new();bg.name="BootLight";bg.texture=tex;bg.size=size;loading_layer.add_child(bg)
	var title:=TextureRect.new();title.name="BrandTitle";title.texture=TITLE;title.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;title.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;title.position=Vector2(100,400);title.size=Vector2(740,370);loading_layer.add_child(title)
	progress_bar=ProgressBar.new();progress_bar.name="ResourceProgress";progress_bar.position=Vector2(260,1055);progress_bar.size=Vector2(420,18);progress_bar.show_percentage=false;progress_bar.max_value=1;loading_layer.add_child(progress_bar)
	var back:=StyleBoxFlat.new();back.bg_color=Color("725731");back.set_corner_radius_all(9);back.set_border_width_all(2);back.border_color=Color("f7df96")
	var fill_style:=StyleBoxFlat.new();fill_style.bg_color=Color("fff0b2");fill_style.set_corner_radius_all(7)
	progress_bar.add_theme_stylebox_override("background",back);progress_bar.add_theme_stylebox_override("fill",fill_style)
	# At 360px portrait width, 38 logical pixels remains readable body text.
	# Leave room for the actual two-line load error, not just "LOADING".
	loading_label=Label.new();loading_label.name="LoadingStatus";loading_label.text="LOADING";loading_label.position=Vector2(95,1095);loading_label.size=Vector2(750,52);loading_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;loading_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;loading_label.add_theme_font_override("font",BOOT_FONT);loading_label.add_theme_font_size_override("font_size",38);loading_label.add_theme_color_override("font_color",INK);loading_layer.add_child(loading_label)

func begin_home_load() -> void:
	load_generation+=1
	phase="loading";batch="home";record_event("resource_batch_requested")
	var paths:Array[String]=HOME_RESOURCES.duplicate()
	paths.append(AudioService.BGM_PATH)
	for path in AudioService.SFX_PATHS.values():paths.append(str(path))
	start_resource_batch(paths)

func update_progress(value:float,owner_id:int) -> void:
	if owner_id==loader_owner_id and phase=="loading":progress_bar.value=value

func on_loaded(finished_request_id:int,owner_id:int) -> void:
	if owner_id!=loader_owner_id or phase!="loading" or finished_request_id!=active_request_id:return
	record_event("resource_batch_loaded")
	if batch=="home":
		# Retain the real loaded resources until the destination owns its references.
		for path in HOME_RESOURCES:retained_resources.append(loader.get_resource(path))
		retained_resources.append(loader.get_resource(AudioService.BGM_PATH))
		for path in AudioService.SFX_PATHS.values():retained_resources.append(loader.get_resource(path))
		build_home()
		if start_mode=="play" and profiles_ready():call_deferred("launch_game",entry_screen)
	else:call_deferred("handover_game",load_generation)

func read_first_preview_configuration()->Dictionary:
	return FirstPreview.read_configuration(Catalog.level_path(1,false))

func build_home() -> void:
	var preview_source:=read_first_preview_configuration()
	if not preview_source.ok:
		on_load_failed({"reason":preview_source.reason});return
	font=loader.get_resource("res://assets/fonts/Title.ttf")
	atlas=loader.get_resource("res://assets/characters-atlas.png")
	ant_atlas=loader.get_resource("res://assets/ants-atlas.png")
	skin=UiSkin.new()
	audio_service=AudioService.new();audio_service.name="AudioService";audio_service.apply_settings_state(audio_visual_state);add_child(audio_service)
	get_tree().node_added.connect(bind_new_button)
	home_art=group("HomeArtwork")
	# One full, coherent scene. Do not place a smaller opaque map over another
	# copy of the same map. Branding/actions occupy the existing wooden footer.
	var first_config:Dictionary=preview_source.config
	FirstPreview.build(first_config,Rect2(Vector2.ZERO,size),home_art,"HomeLevelPreview")
	var title:=TextureRect.new();title.name="BrandTitle";title.texture=TITLE;title.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;title.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;title.position=Vector2(250,1208);title.size=Vector2(440,220);title.mouse_filter=Control.MOUSE_FILTER_IGNORE;home_art.add_child(title)
	home_button("PlayButton","play",Rect2(270,1485,400,136),func():open_adventure("preparation",level_index),true)
	home_button("LevelsButton","levels",Rect2(744,1489,128,128),func():open_adventure("map"),false)
	refresh_home_profile_controls()
	if campaign_drafts:text_label("CAMPAIGN PREVIEW",Rect2(200,82,540,38),21,"CatalogIdentity",home_art,INK,true)
	home_ready=true;phase="home";loading_layer.hide();home_art.move_to_front();record_event("home_ready")
	if not profiles_ready():show_profile_recovery();return
	if start_mode in ["map","preparation","shop"]:
		open_adventure("preparation" if start_mode=="preparation" else "map",level_index)
		if start_mode=="shop":open_shop()

func profiles_ready()->bool:
	return profile_state.get("ready",false) and economy_state.get("ready",false)

func refresh_home_profile_controls()->void:
	home_art.get_node("LevelsButton").disabled=not profiles_ready()
	for id in ["SavedEntrance","ResumeMeaning"]:
		var old:=home_art.get_node_or_null(id)
		if old!=null:home_art.remove_child(old);old.queue_free()
	if profile_state.ready:
		var entrance_text:="LEVEL 1 · FRESH ROUND" if profile_state.tutorial_completed else "LEVEL 1"
		var entrance:=text_label(entrance_text,Rect2(170,1431,600,50),38,"SavedEntrance",home_art,Color("fff9e8"),true)
		entrance.add_theme_color_override("font_outline_color",INK)
		entrance.add_theme_constant_override("outline_size",5)

func show_profile_recovery(last_error:String="")->void:
	var m:=modal("COULDN'T LOAD",Rect2(130,350,680,1080))
	modal_copy("YOUR SAVE\nHAS NOT BEEN RESET",Rect2(190,490,560,110),38,"RecoveryTitle",m)
	var reasons:Array[String]=[]
	if not profile_state.get("ready",false):reasons.append("PROGRESS: "+str(profile_state.get("reason","load_failed")).replace("_"," ").to_upper())
	if not economy_state.get("ready",false):reasons.append("POINTS: "+str(economy_state.get("reason","load_failed")).replace("_"," ").to_upper())
	if not last_error.is_empty():reasons.append(last_error.replace("_"," ").to_upper())
	modal_copy("\n".join(reasons),Rect2(190,612,560,224),32,"RecoveryReason",m)
	modal_copy("PLAY IS BLOCKED UNTIL\nRECOVERY SUCCEEDS",Rect2(190,850,560,95),32,"RecoveryNotice",m)
	action(m,"RETRY LOAD",975,retry_profile_load,true)
	if profile_state.get("recovery_allowed",false) or economy_state.get("recovery_allowed",false):
		action(m,"RESTORE BACKUP",1115,restore_profile_backups)
		modal_copy("RESTORES THE LAST VALID\nLOCAL BACKUP",Rect2(190,1255,560,95),32,"BackupNotice",m)

func retry_profile_load()->void:
	profile_state=saves.load_save().state;economy_state=progression.load_save().state
	if profiles_ready():finish_profile_recovery()
	else:show_profile_recovery()

func restore_profile_backups()->void:
	# Restore only failed stores, through their existing checked/quarantined path.
	# Never reset defaults, mint rewards, or overwrite a healthy companion store.
	var last_error:=""
	if not profile_state.get("ready",false) and profile_state.get("recovery_allowed",false):
		var restored:Dictionary=saves.recover_from_backup();profile_state=restored.state
		if not restored.ok:last_error=str(restored.reason)
	if not economy_state.get("ready",false) and economy_state.get("recovery_allowed",false):
		var restored:Dictionary=progression.recover_from_backup();economy_state=restored.state
		if not restored.ok:last_error=str(restored.reason)
	if profiles_ready():finish_profile_recovery()
	else:show_profile_recovery(last_error)

func finish_profile_recovery()->void:
	level_index=1
	audio_visual_state={"music":float(profile_state.music_volume),"sound":float(profile_state.sfx_volume),"music_muted":int(profile_state.music_volume)==0,"sound_muted":int(profile_state.sfx_volume)==0}
	audio_service.apply_settings_state(audio_visual_state)
	meta_settings_dirty=false;meta_settings_recovery_pending=false
	close_current_modal();refresh_home_profile_controls()
	if is_instance_valid(adventure):adventure.hide()
	if is_instance_valid(shop):shop.hide()
	home_art.show();home_art.move_to_front();phase="home";start_mode="home"
	record_event("profile_recovered")

func home_button(id:String,kind:String,bounds:Rect2,callback:Callable,primary:bool) -> void:
	frame(bounds,id+"Art",home_art,32,"54d35b" if primary else "fff3db")
	icon(kind,Rect2(bounds.get_center()-Vector2(45,45),Vector2(90,90)),home_art,Color("fff9e8") if primary else INK)
	var button:=Button.new();button.name=id;button.position=bounds.position;button.size=bounds.size;button.flat=true;button.tooltip_text="Start the first level" if primary else "Choose a level";home_art.add_child(button);button.pressed.connect(callback)

func launch_game(screen:String="") -> void:
	if launch_pending or not home_ready:return
	if not Catalog.runtime_level_allowed(level_index,campaign_drafts):return
	if not profiles_ready():show_profile_recovery();return
	launch_origin=phase if phase in ["preparation","map"] else "preparation"
	launch_pending=true;entry_screen=screen;batch="game";phase="loading";load_generation+=1
	reset_loading_controls()
	loading_layer.show();loading_layer.move_to_front()
	show_loading_back()
	record_event("play_requested")
	call_deferred("prepare_game_resources",load_generation)

func prepare_game_resources(expected_generation:int) -> void:
	if expected_generation!=load_generation or phase!="loading" or not launch_pending:return
	if not Catalog.runtime_level_allowed(level_index,campaign_drafts):
		on_load_failed({"reason":"first_level_review_only"});return
	var path:=Catalog.level_path(level_index,campaign_drafts)
	var config:Variant=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if qa_fixture_mode and not qa_level_config.is_empty():config=qa_level_config.duplicate(true)
	if not config is Dictionary:
		on_load_failed({"path":path,"reason":"level_data_unavailable"});return
	if not Catalog.runtime_config_allowed(config,level_index,campaign_drafts):
		on_load_failed({"path":path,"reason":"first_level_review_only"});return
	if not qa_fixture_mode and not Catalog.check_identity(config,level_index,campaign_drafts).ok:
		on_load_failed({"path":path,"reason":"level_identity_invalid"});return
	if not Rules.validate_level(config).is_empty():
		on_load_failed({"path":path,"reason":"level_rules_invalid"});return
	var layout:Dictionary=SceneLayout.load_for(config)
	if not layout.ok:
		on_load_failed({"path":path,"reason":layout.reason});return
	var game_paths:Array[String]=["res://scenes/play.tscn",str(layout.data.background),str(layout.data.defense_target.texture)]
	start_resource_batch(game_paths)

func clear_loading_actions() -> void:
	for id in ["RetryButton","BackButton"]:
		var button:=loading_layer.get_node_or_null(id)
		if button!=null:loading_layer.remove_child(button);button.queue_free()

func reset_loading_controls() -> void:
	clear_loading_actions();loading_label.text="LOADING";loading_label.size.y=52
	progress_bar.show();progress_bar.value=0

func loading_button(id:String,title:String,y:float,callback:Callable) -> void:
	var button:=Button.new();button.name=id;button.text=title;button.position=Vector2(190,y);button.size=Vector2(560,136)
	button.add_theme_font_override("font",BOOT_FONT);button.add_theme_font_size_override("font_size",38);button.add_theme_color_override("font_color",INK)
	for state in ["font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color","font_disabled_color"]:button.add_theme_color_override(state,INK)
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/v03/regions.json"))
	var r:Array=data.game.secondary
	var texture:=AtlasTexture.new();texture.atlas=BOOT_BUTTON_ATLAS;texture.region=Rect2(r[0],r[1],r[2],r[3]);texture.filter_clip=true
	for state in ["normal","hover","pressed","hover_pressed","disabled"]:
		var painted:=StyleBoxTexture.new();painted.texture=texture
		for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:painted.set_texture_margin(side,48);painted.set_content_margin(side,32 if side in [SIDE_LEFT,SIDE_RIGHT] else 8)
		if state in ["pressed","hover_pressed"]:painted.modulate_color=Color(.82,.76,.65)
		elif state=="disabled":painted.modulate_color=Color(.65,.65,.65,.8)
		button.add_theme_stylebox_override(state,painted)
	loading_layer.add_child(button);button.pressed.connect(callback)

func show_loading_back() -> void:
	if home_ready:loading_button("BackButton","BACK TO PREPARATION" if launch_origin=="preparation" else "BACK TO MAP",1380,return_from_loading)

func return_from_loading() -> void:
	if not home_ready or batch!="game" or phase not in ["loading","error"]:return
	# Godot cannot cancel a native load. Detach our old owner immediately so its
	# completion cannot call back, and invalidate any already deferred handover.
	load_generation+=1;active_request_id=-1;launch_pending=false;start_mode="home"
	remove_child(loader);loader.queue_free();create_loader()
	clear_loading_actions();loading_layer.hide()
	if is_instance_valid(adventure):adventure.release_begin_lock()
	open_adventure(launch_origin,level_index)
	record_event("load_returned")

func retry_loading() -> void:
	if phase!="error":return
	reset_loading_controls();phase="loading";load_generation+=1
	show_loading_back();record_event("retry_requested")
	if batch=="game":call_deferred("prepare_game_resources",load_generation)
	else:begin_home_load()

func handover_game(expected_generation:int) -> void:
	if not is_inside_tree() or not launch_pending or phase!="loading" or expected_generation!=load_generation:return
	if not Catalog.runtime_level_allowed(level_index,campaign_drafts) or (qa_fixture_mode and not qa_level_config.is_empty() and not Catalog.runtime_config_allowed(qa_level_config,level_index,campaign_drafts)):
		on_load_failed({"reason":"first_level_review_only"});return
	var packed:PackedScene=loader.get_resource("res://scenes/play.tscn")
	if packed==null:on_load_failed({"message":"The game scene could not be opened."});return
	var next=packed.instantiate()
	next.use_command_line_catalog=false;next.use_command_line_level=false
	next.campaign_drafts=campaign_drafts;next.profile_directory=profile_directory;next.profile_directory_resolved=true
	next.entry_screen=entry_screen;next.from_startup=true
	next.auto_replay=auto_replay;next.qa_fixture_mode=qa_fixture_mode;next.qa_level_config=qa_level_config.duplicate(true);next.level_index=level_index
	phase="game";record_event("game_handover")
	# Stop the outgoing stream before adding the destination, avoiding doubled BGM.
	remove_child(audio_service);audio_service.queue_free()
	get_tree().root.add_child(next);get_tree().current_scene=next
	loader.release_resources();retained_resources.clear();queue_free()

func on_load_failed(error:Dictionary,owner_id:int=-1) -> void:
	if owner_id>=0 and owner_id!=loader_owner_id:return
	if phase!="loading" or (error.has("request_id") and int(error.request_id)!=active_request_id):return
	phase="error";record_event("resource_load_failed")
	loading_label.text="COULDN'T LOAD\nCHECK GAME FILES AND TRY AGAIN"
	loading_label.size.y=100;progress_bar.hide();clear_loading_actions()
	loading_button("RetryButton","TRY AGAIN",1230,retry_loading)
	show_loading_back()
	push_warning("Startup resource unavailable: "+str(error.get("path","scene"))+" · "+str(error.get("reason",error.get("message","load_failed"))))

func reset_presentation() -> void:
	pass

func _unhandled_key_input(event:InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if phase in ["loading","error"] and batch=="game":return_from_loading()
		elif is_instance_valid(pause_overlay):close_current_modal()
		elif phase=="shop":close_shop()
		elif phase=="preparation":open_adventure("map")
		elif phase=="map":show_home_again()
		get_viewport().set_input_as_handled()


func meta_levels()->Array:
	var result:Array=[]
	for number in [1]:
		var path:=Catalog.level_path(number,campaign_drafts)
		if not FileAccess.file_exists(path):continue
		var config=JSON.parse_string(FileAccess.get_file_as_string(path))
		if config is Dictionary and Catalog.check_identity(config,number,campaign_drafts).ok:result.append({"number":number,"config":config})
	return result

func save_navigation()->bool:
	if not is_instance_valid(adventure):return true
	if not economy_state.get("ready",false):show_profile_recovery();return false
	var state:Dictionary=adventure.get_navigation_state()
	var result:Dictionary=progression.set_navigation({"region_id":str(state.region_id),"scroll_y":maxf(0.,float(state.scroll_y)),"selected_level":int(state.selected_level)})
	if not result.ok:
		show_meta_failure(result.reason,false,true);return false
	economy_state=result.state;meta_navigation_recovery_pending=false;return true

func open_adventure(screen:String="map",number:int=-1)->void:
	if launch_pending:return
	if not profiles_ready():show_profile_recovery();return
	if not Catalog.runtime_level_allowed(number,campaign_drafts):number=1
	home_art.hide()
	if is_instance_valid(shop):shop.hide()
	if not is_instance_valid(adventure):
		adventure=Adventure.new();adventure.font=font;adventure.skin=skin
		adventure.title_textures={"ADVENTURE":load("res://assets/meta-ui/adventure.png"),"READY":load("res://assets/meta-ui/ready.png")}
		adventure.set_data(meta_levels(),profile_state,economy_state)
		add_child(adventure)
		adventure.restore_navigation_state(economy_state.get("navigation",{}))
		adventure.choose_level.connect(choose_prepared_level)
		adventure.begin_level.connect(begin_prepared_level)
		adventure.shop_requested.connect(open_shop)
		adventure.settings_requested.connect(show_settings)
		adventure.back_requested.connect(func():
			if phase=="preparation":open_adventure("map")
			else:show_home_again())
	else:adventure.set_data(meta_levels(),profile_state,economy_state)
	phase=screen
	if screen=="preparation":adventure.show_preparation(number if number>0 else level_index)
	else:adventure.show_map()
	adventure.show();adventure.move_to_front();record_event("adventure_"+screen)

func choose_prepared_level(number:int)->void:
	if not Catalog.runtime_level_allowed(number,campaign_drafts):return
	if adventure.show_preparation(number):phase="preparation";save_navigation()

func begin_prepared_level(number:int,type_id:String)->void:
	if launch_pending:return
	if not Catalog.runtime_level_allowed(number,campaign_drafts):
		if is_instance_valid(adventure):adventure.release_begin_lock()
		return
	var equipped:Dictionary=progression.equip(type_id)
	if not equipped.ok:adventure.release_begin_lock();show_meta_failure(equipped.reason);return
	economy_state=equipped.state
	var entered:Dictionary=saves.set_current_entrance(Catalog.level_ids(campaign_drafts)[number-1])
	if not entered.ok:adventure.release_begin_lock();show_meta_failure(entered.reason);return
	profile_state=entered.state;level_index=number
	if not save_navigation():adventure.release_begin_lock();return
	launch_game("")

func open_shop()->void:
	if not profiles_ready():show_profile_recovery();return
	shop_return_screen=phase if phase in ["map","preparation"] else "map"
	if not save_navigation():return
	if is_instance_valid(adventure):adventure.hide()
	home_art.hide()
	if not is_instance_valid(shop):
		shop=Shop.new();shop.set_data(economy_state,JSON.parse_string(FileAccess.get_file_as_string("res://data/ant-progression.json")));add_child(shop)
		shop.back_requested.connect(close_shop)
		shop.equip_requested.connect(func(type):
			var result:Dictionary=progression.equip(type);economy_state=result.state;shop.set_data(economy_state,JSON.parse_string(FileAccess.get_file_as_string("res://data/ant-progression.json")))
			if not result.ok:shop.show_feedback(result.reason))
		shop.purchase_requested.connect(func(product):
			var result:Dictionary=progression.purchase(Progression.generate_run_id(),product);economy_state=result.state;shop.set_data(economy_state,JSON.parse_string(FileAccess.get_file_as_string("res://data/ant-progression.json")))
			if not result.ok:shop.show_feedback(result.reason)
			else:audio_service.play_event("tool_plus"))
	else:shop.set_data(economy_state,JSON.parse_string(FileAccess.get_file_as_string("res://data/ant-progression.json")))
	shop.show();shop.move_to_front();phase="shop";record_event("shop_ready")

func close_shop()->void:
	if is_instance_valid(shop):shop.hide()
	var number:int=int(economy_state.get("navigation",{}).get("selected_level",level_index))
	open_adventure(shop_return_screen,number)

func show_home_again()->void:
	if not save_navigation():return
	if is_instance_valid(adventure):adventure.hide()
	if is_instance_valid(shop):shop.hide()
	home_art.show();home_art.move_to_front();phase="home"

func show_settings()->void:
	super.show_settings()
	for id in ["MusicVolume","SoundVolume"]:
		var slider:HSlider=pause_overlay.get_node(id)
		slider.value_changed.connect(func(_value):meta_settings_dirty=true)
		slider.drag_ended.connect(func(_changed):save_meta_settings())

func save_meta_settings()->bool:
	if not meta_settings_dirty:return true
	var result:Dictionary=saves.set_volumes(audio_visual_state.music,audio_visual_state.sound);profile_state=result.state
	if not result.ok:show_meta_failure(result.reason,true);return false
	meta_settings_dirty=false;meta_settings_recovery_pending=false;return true

func close_current_modal()->void:
	if modal_title=="COULDN'T SAVE" and meta_settings_recovery_pending:
		show_settings();return
	if modal_title=="SETTINGS" and not save_meta_settings():return
	if is_instance_valid(pause_overlay):ui_motion.discard_modal(pause_overlay)
	pause_overlay=null;modal_title="";audio_service.set_music_preview(false);audio_service.set_game_paused(false)

func show_meta_failure(reason:String,retry_settings:bool=false,retry_navigation:bool=false)->void:
	meta_settings_recovery_pending=retry_settings
	meta_navigation_recovery_pending=retry_navigation
	var m:=modal("COULDN'T SAVE",Rect2(130,470,680,790))
	modal_copy("VOLUME CHANGES\nARE NOT SAVED" if retry_settings else ("MAP POSITION\nIS NOT SAVED" if retry_navigation else "YOUR SAVED PROGRESS\nIS KEPT"),Rect2(190,670,560,110),38,"SafeSave",m)
	modal_copy(reason.replace("_"," ").to_upper(),Rect2(190,810,560,140),32,"SaveReason",m)
	action(m,"TRY AGAIN",1060,func():
		if meta_navigation_recovery_pending:
			if save_navigation():close_current_modal()
			return
		if meta_settings_recovery_pending:
			# Retry the failed write with the values the player selected. A successful
			# read of the old file is not a successful settings transaction.
			if save_meta_settings():show_settings()
			return
		var state:Dictionary=progression.load_save();economy_state=state.state
		var loaded:Dictionary=saves.load_save();profile_state=loaded.state
		if state.ok and loaded.ok:close_current_modal();open_adventure("map")
		else:show_meta_failure(state.reason),true)
