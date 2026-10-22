extends SceneTree
const Ball=preload("res://scripts/first_level_bead.gd")
var checks:=0
var failures:Array[String]=[]
var profile:="/tmp/ant-map-visible-%d"%Time.get_ticks_usec()
var samples:Array=[]
func _initialize()->void:call_deferred("run")
func check(value:bool,note:String)->void:
	checks+=1
	if not value:failures.append(note);push_error(note)
func settle()->void:
	for _i in 4:await process_frame
func inspect_map(home:Node,source:String)->void:
	await settle()
	var view=home.adventure
	check(home.phase=="map" and view.screen=="map",source+" reaches map")
	var page:Control=view.get_node("AdventurePage")
	var scroll:ScrollContainer=page.get_node("MapScroll")
	var canvas:Control=scroll.get_node("MapCanvas")
	check(view.level_definitions.size()==1 and canvas.find_children("LevelNode*","Control",false,false).size()==1,source+" exactly one real level")
	check(view.map_scroll==0 and scroll.scroll_vertical==0 and canvas.size.y<=scroll.size.y,source+" no hidden long-trail offset")
	var sign:Control=canvas.get_node("SceneSign1")
	var node:Control=canvas.get_node("LevelNode1")
	for item in [sign,node,canvas.get_node("CompletionProgress"),canvas.get_node("Region_0")]:
		check(scroll.get_global_rect().encloses(item.get_global_rect()),source+" visible whole "+str(item.name))
	check(sign.get_global_rect().end.y+40<=page.get_node("ShopButton").get_global_rect().position.y,source+" scene card clears footer control")
	var preview:Control=sign.get_node("ScenePreview")
	check(preview.get_meta("read_only_first_level",false) and preview.get_node("ActualLevelScene").scale.is_equal_approx(Vector2.ONE*448.0/940.0),source+" shared actual scene at proportional scale")
	var counts:Dictionary={}
	for child in preview.get_node("ActualLevelScene").get_children():
		if child.get_script()==Ball:counts[child.color_id]=int(counts.get(child.color_id,0))+1
	check(counts=={"blue":80,"green":67,"red":44,"purple":33,"yellow":16},source+" real 240 round balls, not old grid")
	check(preview.get_node("ActualLevelScene/PreviewSerpent").bodies.size()==20 and preview.has_node("ActualLevelScene/PreviewCannon"),source+" actual first-level boss/cannon")
	var heading:Label=sign.get_node("SceneTitle")
	var font=heading.get_theme_font("font");var size:=heading.get_theme_font_size("font_size")
	check(size==38 and heading.autowrap_mode==TextServer.AUTOWRAP_WORD_SMART and heading.get_rect()==Rect2(46,20,408,110),source+" actual Label enables bounded wrapping, not just a font estimate")
	check(heading.get_line_count()==2 and font.get_height(size)*heading.get_line_count()<=heading.size.y,source+" complete title fits two rendered-layout lines at mobile body size")
	check(sign.get_node("LevelState").get_theme_font_size("font_size")==38 and canvas.get_node("CompletionProgress").get_theme_font_size("font_size")==38,source+" real state text readable")
	for button in [node.get_node("ChooseLevel1"),sign.get_node("ChooseLevelPreview1"),page.get_node("BackButton"),page.get_node("SettingsButton"),page.get_node("ShopButton")]:
		check(button.size.x>=116 and button.size.y>=116,source+" actual touch dimensions "+str(button.name))
		check(not button.disabled,source+" valid enabled target "+str(button.name))
	check(not node.get_global_rect().intersects(sign.get_global_rect()),source+" distinct activation targets do not overlap")
	samples.append({"entry":source,"scroll_y":scroll.scroll_vertical,"canvas_height":canvas.size.y,"card_local":str(sign.get_rect()),"viewport_height":scroll.size.y})
func dispose(node:Node)->void:
	if not is_instance_valid(node):return
	if is_instance_valid(node.audio_service):node.audio_service.stop_music();node.audio_service.stop_all_sfx()
	await create_timer(.3).timeout;node.queue_free();await settle()
func run()->void:
	var config_bytes:=FileAccess.get_file_as_bytes("res://data/serpent-levels/serpent-01.json")
	var home=load("res://scenes/startup.tscn").instantiate();home.profile_directory=profile;home.profile_directory_resolved=true;home.use_command_line_catalog=false
	root.add_child(home);current_scene=home
	var deadline:=Time.get_ticks_msec()+10000
	while home.phase!="home" and Time.get_ticks_msec()<deadline:await process_frame
	check(home.phase=="home","Normal startup Home")
	home.home_art.get_node("LevelsButton").pressed.emit();await inspect_map(home,"Home map button")
	var choices:Array=[];home.adventure.choose_level.connect(func(n):choices.append(n))
	home.adventure.get_node("AdventurePage/MapScroll/MapCanvas/SceneSign1/ChooseLevelPreview1").pressed.emit()
	check(home.phase=="preparation" and choices==[1],"Scene preview activation selects first level once")
	home.adventure.get_node("AdventurePage/BackButton").pressed.emit();await inspect_map(home,"Preparation Back")
	home.adventure.get_node("AdventurePage/MapScroll/MapCanvas/LevelNode1/ChooseLevel1").pressed.emit()
	check(home.phase=="preparation" and choices==[1,1],"Medallion activation selects first level once")
	for old_scroll in [-1,0,411,99999]:
		home.open_adventure("map",1)
		home.adventure.restore_navigation_state({"screen":"map","region_id":"forest","selected_level":1,"scroll_y":old_scroll})
		await inspect_map(home,"Saved offset %d"%old_scroll)
	# Actual in-game Leave transition, with a stale preparation navigation value.
	home.open_adventure("preparation",1);home.adventure.map_scroll=99999
	check(home.save_navigation(),"Persist fixture stale navigation through real save boundary")
	await dispose(home)
	var game=load("res://scenes/play.tscn").instantiate();game.profile_directory=profile;game.profile_directory_resolved=true;game.use_command_line_catalog=false;game.use_command_line_level=false
	root.add_child(game);current_scene=game;game.set_process(false)
	if game.modal_title=="YOUR FIRST RESCUE":game.finish_tutorial()
	check(game.select_color("blue"),"Real first-level carrier starts round before Leave")
	game.show_pause();game.pause_overlay.get_node("Button_LEVEL SELECT").pressed.emit()
	check(game.modal_title=="LEAVE THIS LEVEL?","Pause Level Select opens real Leave confirmation")
	game.pause_overlay.get_node("Button_LEAVE").pressed.emit()
	deadline=Time.get_ticks_msec()+10000
	while (current_scene==game or current_scene.get("phase")!="map") and Time.get_ticks_msec()<deadline:await process_frame
	home=current_scene;check(home.get("phase")=="map","Leave constructs startup in map mode")
	await inspect_map(home,"In-game Leave")
	check(not home.launch_pending and home.adventure.selected_level==1,"Leave never starts or enables a later level")
	await dispose(home)
	check(config_bytes==FileAccess.get_file_as_bytes("res://data/serpent-levels/serpent-01.json"),"No first-level gameplay/config changes")
	var report={"checks":checks,"failures":failures,"samples":samples,"scope":"Headless first-level production navigation/callbacks, viewport layout, current preview nodes and saved offsets. Not real GPU appearance, engine/physical touch or final visual approval."}
	var path:=OS.get_environment("ANT_MAP_REPORT");if path.is_empty():path="/tmp/ant-map-visibility-report.json"
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close();print("FIRST_LEVEL_MAP_VISIBILITY ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
