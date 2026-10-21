extends "res://scripts/main.gd"
## Production entry. ResourceLoader owns progress; no minimum duration or fake timer.
const Loader = preload("res://scripts/startup_loader.gd")
const Saves = preload("res://scripts/save_service.gd")
const Catalog = preload("res://scripts/level_catalog.gd")
const TITLE = preload("res://assets/startup/title.png")
const HOME_RESOURCES: Array[String] = [
	"res://assets/serpent/environment.png", "res://assets/characters-atlas.png",
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

func _ready() -> void:
	if DisplayServer.get_name()!="headless":get_window().mode=Window.MODE_MAXIMIZED
	var canvas_scale := minf(1440.0/940.0,2560.0/1672.0)
	size=Vector2(940,1672);scale=Vector2.ONE*canvas_scale;position=(Vector2(1440,2560)-size*scale)*.5
	var args:=OS.get_cmdline_user_args()
	if use_command_line_catalog:campaign_drafts=campaign_drafts or "--campaign-drafts" in args
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
			if arg.begins_with("--level="):level_index=clampi(int(arg.trim_prefix("--level=")),1,Catalog.level_ids(campaign_drafts).size())
	saves=Saves.new(profile_directory,Catalog.level_ids(campaign_drafts),30)
	var result:Dictionary=saves.load_save();profile_state=result.state
	if profile_state.ready and not qa_fixture_mode:
		level_index=Catalog.level_ids(campaign_drafts).find(profile_state.resume_level_id)+1
		for arg in args:
			if use_command_line_catalog and arg.begins_with("--level="):
				var requested:=clampi(int(arg.trim_prefix("--level=")),1,Catalog.level_ids(campaign_drafts).size())
				var entrance:Dictionary=saves.set_current_entrance(Catalog.level_ids(campaign_drafts)[requested-1])
				profile_state=entrance.state
	audio_visual_state={"music":float(profile_state.music_volume),"sound":float(profile_state.sfx_volume),"music_muted":int(profile_state.music_volume)==0,"sound_muted":int(profile_state.sfx_volume)==0}
	theme=Theme.new()
	for state in ["normal","hover","pressed","disabled","focus"]:theme.set_stylebox(state,"Button",StyleBoxEmpty.new())
	build_boot_shell()
	loader=Loader.new();loader.name="StartupLoader";add_child(loader)
	loader.progress_changed.connect(update_progress)
	loader.completed.connect(on_loaded)
	loader.failed.connect(on_load_failed)
	record_event("splash")
	call_deferred("begin_home_load")

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
	loading_label=Label.new();loading_label.name="LoadingStatus";loading_label.text="LOADING";loading_label.position=Vector2(240,1095);loading_label.size=Vector2(460,45);loading_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;loading_label.add_theme_font_size_override("font_size",22);loading_label.add_theme_color_override("font_color",INK);loading_layer.add_child(loading_label)

func begin_home_load() -> void:
	phase="loading";batch="home";record_event("resource_batch_requested")
	var paths:Array[String]=HOME_RESOURCES.duplicate()
	paths.append(AudioService.BGM_PATH)
	for path in AudioService.SFX_PATHS.values():paths.append(str(path))
	loader.start(paths)

func update_progress(value:float) -> void:
	progress_bar.value=value

func on_loaded(_request_id:int) -> void:
	record_event("resource_batch_loaded")
	if batch=="home":
		# Retain the real loaded resources until the destination owns its references.
		for path in HOME_RESOURCES:retained_resources.append(loader.get_resource(path))
		retained_resources.append(loader.get_resource(AudioService.BGM_PATH))
		for path in AudioService.SFX_PATHS.values():retained_resources.append(loader.get_resource(path))
		build_home()
		if start_mode=="play":call_deferred("launch_game",entry_screen)
	else:call_deferred("handover_game")

func build_home() -> void:
	font=loader.get_resource("res://assets/fonts/Title.ttf")
	atlas=loader.get_resource("res://assets/characters-atlas.png")
	ant_atlas=loader.get_resource("res://assets/ants-atlas.png")
	skin=UiSkin.new()
	audio_service=AudioService.new();audio_service.name="AudioService";audio_service.apply_settings_state(audio_visual_state);add_child(audio_service)
	get_tree().node_added.connect(bind_new_button)
	home_art=group("HomeArtwork")
	var bg:=TextureRect.new();bg.name="Garden";bg.texture=loader.get_resource("res://assets/serpent/environment.png");bg.size=size;bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;home_art.add_child(bg)
	var title:=TextureRect.new();title.name="BrandTitle";title.texture=TITLE;title.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;title.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;title.position=Vector2(100,125);title.size=Vector2(740,370);home_art.add_child(title)
	var view=load("res://scripts/serpent_view.gd").new();home_art.add_child(view)
	view.configure({"head_start_s":85.0,"goal_s":100.0,"pitch":6.0},[
		{"position":Vector2(240,1030),"out":Vector2(90,0)},
		{"position":Vector2(690,930),"in":Vector2(-60,110),"out":Vector2(0,-90)},
		{"position":Vector2(430,675),"in":Vector2(130,0)}])
	var segments:Array=[];var ids:Array=[];var positions:Dictionary={}
	for i in range(8):
		var id:="home-%d"%i;ids.append(id);positions[id]=85.0-(i+1)*6.0
		segments.append({"id":id,"color":COLORS[i%6],"hp":1,"kind":"normal"})
	view.sync_snapshot({"paused":true,"speed_multiplier":1,"status":"ready","head_s":85.0,"alive_segment_ids":ids,"segments":segments,"segment_s":positions})
	view.add_princess(home_art,Vector2(145,168))
	art(Rect2(48,654,412,337),Rect2(390,1008,174,142),"HomeCannon",home_art)
	home_button("PlayButton","play",Rect2(290,1240,360,136),func():launch_game(""),true)
	home_button("LevelsButton","levels",Rect2(397,1415,146,112),func():launch_game("levels"),false)
	var level_button:Button=home_art.get_node("LevelsButton");level_button.disabled=not profile_state.ready
	if profile_state.ready:
		text_label("LEVEL %d"%(Catalog.level_ids(campaign_drafts).find(profile_state.resume_level_id)+1),Rect2(270,1371,400,37),22,"SavedEntrance",home_art,INK,true)
		if profile_state.tutorial_completed:text_label("FRESH ROUND · SAVED PROGRESS KEPT",Rect2(185,1530,570,36),17,"ResumeMeaning",home_art,INK,true)
	if campaign_drafts:text_label("CAMPAIGN PREVIEW",Rect2(200,82,540,38),21,"CatalogIdentity",home_art,INK,true)
	home_ready=true;phase="home";loading_layer.hide();home_art.move_to_front();record_event("home_ready")

func home_button(id:String,kind:String,bounds:Rect2,callback:Callable,primary:bool) -> void:
	frame(bounds,id+"Art",home_art,32,"54d35b" if primary else "fff3db")
	icon(kind,Rect2(bounds.get_center()-Vector2(45,45),Vector2(90,90)),home_art,Color("fff9e8") if primary else INK)
	var button:=Button.new();button.name=id;button.position=bounds.position;button.size=bounds.size;button.flat=true;button.tooltip_text="Play saved level" if primary else "Choose a level";home_art.add_child(button);button.pressed.connect(callback)

func launch_game(screen:String="") -> void:
	if launch_pending or not home_ready:return
	launch_pending=true;entry_screen=screen;batch="game";phase="loading"
	loading_layer.show();loading_layer.move_to_front();loading_label.text="LOADING";progress_bar.value=0
	record_event("play_requested")
	var game_paths:Array[String]=["res://scenes/play.tscn"]
	loader.start(game_paths)

func handover_game() -> void:
	if not is_inside_tree() or not launch_pending:return
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

func on_load_failed(error:Dictionary) -> void:
	phase="error";record_event("resource_load_failed")
	loading_label.text="COULDN'T LOAD\nCHECK GAME FILES AND TRY AGAIN"
	loading_label.size.y=95
	progress_bar.hide()
	var existing:=loading_layer.get_node_or_null("RetryButton")
	if existing!=null:loading_layer.remove_child(existing);existing.queue_free()
	var retry:=Button.new();retry.name="RetryButton";retry.text="TRY AGAIN";retry.position=Vector2(300,1230);retry.size=Vector2(340,118)
	retry.add_theme_font_size_override("font_size",28);retry.add_theme_color_override("font_color",INK)
	var outline:=StyleBoxFlat.new();outline.bg_color=Color("edd0a1");outline.set_border_width_all(3);outline.border_color=Color("9a6229");outline.set_corner_radius_all(22)
	for state in ["normal","hover","pressed"]:retry.add_theme_stylebox_override(state,outline)
	loading_layer.add_child(retry)
	retry.pressed.connect(func():
		loading_layer.remove_child(retry);retry.queue_free();loading_label.text="LOADING";progress_bar.show();phase="loading";record_event("retry_requested");loader.retry())
	push_warning("Startup resource unavailable: "+str(error.get("path","scene")))

func reset_presentation() -> void:
	pass

func _unhandled_key_input(event:InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):get_viewport().set_input_as_handled()
