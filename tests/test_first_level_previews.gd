extends SceneTree
const Preview=preload("res://scripts/first_level_preview.gd")
class FailedPreviewStartup extends "res://scripts/startup.gd":
	var fail_preview:=true
	func read_first_preview_configuration()->Dictionary:
		if fail_preview:return {"ok":false,"reason":"controlled_missing_preview_config"}
		return super.read_first_preview_configuration()
const Ball=preload("res://scripts/first_level_bead.gd")
const Layout=preload("res://scripts/scene_layout.gd")
const BoardProjection=preload("res://scripts/board_plane.gd")
var checks:=0
var failures:Array[String]=[]
var profile:="/tmp/ant-rescue-preview-%d"%Time.get_ticks_usec()
var config:Dictionary
var layout:Dictionary
var metrics:Dictionary={}
func _initialize()->void:call_deferred("run")
func check(ok:bool,note:String)->void:
	checks+=1
	if not ok:failures.append(note);push_error(note)
func inspect_preview(view:Control,label:String)->void:
	check(view.get_meta("read_only_first_level",false),label+" is the read-only shared scene")
	var scene:=view.get_node("ActualLevelScene")
	var plane:=BoardProjection.new(16,15,layout,config.get("transport",{}).get("entrance_cell",[]))
	var counts:Dictionary={};var count:=0
	for child in scene.get_children():
		if child.get_script()!=Ball:continue
		count+=1;counts[child.color_id]=int(counts.get(child.color_id,0))+1
		var cell:Vector2i=child.get_meta("cell")
		check(child.size==Ball.WORLD_SIZE,label+" ball size %s"%cell)
		check(child.position.distance_to(plane.center(cell.x,cell.y)-Ball.WORLD_SIZE*.5)<.001,label+" center %s"%cell)
		check(child.color_id==config.palette[str(config.grid[cell.y])[cell.x]],label+" color %s"%cell)
	check(count==240 and counts=={"blue":80,"green":67,"red":44,"purple":33,"yellow":16},label+" uses all 240 actual color cells")
	var serpent:=scene.get_node("PreviewSerpent")
	check(serpent.bodies.size()==20 and serpent.suspended and serpent.head_s==config.serpent.head_start_s,label+" real 20-segment initial paused snapshot")
	var cannon:TextureRect=scene.get_node("PreviewCannon")
	check(cannon.texture.atlas.resource_path==layout.cannon.texture and cannon.texture.region==Layout.rect(layout.cannon.region),label+" actual bronze atlas/region")
	check(cannon.position==Layout.point(layout.cannon.rect.slice(0,2)) and cannon.size==Layout.point(layout.cannon.rect.slice(2,4)),label+" actual cannon rect")
	check(cannon.pivot_offset==Layout.point(layout.cannon.pivot),label+" actual pivot")
	check(cannon.has_node("LoaderAnt") and not scene.has_node("PreviewWorker") and not scene.has_node("PreviewWorker2"),label+" idle loader, no fictional carrier tasks")
	check(scene.get_node("DefenseTarget").texture.atlas.resource_path==layout.defense_target.texture,label+" actual princess")
	check(view.mouse_filter==Control.MOUSE_FILTER_IGNORE and scene.mouse_filter==Control.MOUSE_FILTER_IGNORE,label+" artwork does not consume input")
func dispose(node:Node)->void:
	if is_instance_valid(node.audio_service):node.audio_service.stop_music();node.audio_service.stop_all_sfx()
	await create_timer(.3).timeout;node.queue_free();await process_frame;await process_frame
func run()->void:
	var config_bytes:=FileAccess.get_file_as_bytes("res://data/serpent-levels/serpent-01.json")
	config=JSON.parse_string(config_bytes.get_string_from_utf8());layout=Layout.load_for(config).data
	var home=load("res://scenes/startup.tscn").instantiate();home.profile_directory=profile;home.profile_directory_resolved=true;home.use_command_line_catalog=false
	root.add_child(home);current_scene=home
	var deadline:=Time.get_ticks_msec()+10000
	while home.phase!="home" and Time.get_ticks_msec()<deadline:await process_frame
	check(home.phase=="home","Normal startup reaches Home")
	inspect_preview(home.home_art.get_node("HomeLevelPreview"),"Home")
	check(not home.home_art.has_node("HomeCannon"),"Legacy red cannon removed")
	var preview_rect:Rect2=home.home_art.get_node("HomeLevelPreview").get_rect()
	check(not preview_rect.intersects(home.home_art.get_node("BrandTitle").get_rect()) and not preview_rect.intersects(home.home_art.get_node("PlayButton").get_rect()),"Home preview cannot cover title or Play")
	var progress_before:=FileAccess.get_file_as_bytes(profile.path_join("save.json"))
	var economy_before:=FileAccess.get_file_as_bytes(home.progression.base_path.path_join("progression.json"))
	home.open_adventure("preparation",1)
	inspect_preview(home.adventure.get_node("AdventurePage/ScenePreview"),"Prep")
	check(not home.adventure.get_node("AdventurePage/BossDetails").tooltip_text.to_upper().contains("ARMORED"),"No disabled armor teaching in first-level Prep")
	check(home.adventure.get_node("AdventurePage").get_meta("level_summary").armored==0,"Zero armor remains an actual rule fact")
	var before_runs:int=home.progression._record.runs.size()
	home.adventure.show_map();home.adventure.show_preparation(1)
	check(home.adventure.get_node("AdventurePage").find_children("ScenePreview","Control",false,false).size()==1,"Repeated navigation has one preview")
	check(home.progression._record.runs.size()==before_runs and FileAccess.get_file_as_bytes(profile.path_join("save.json"))==progress_before and FileAccess.get_file_as_bytes(home.progression.base_path.path_join("progression.json"))==economy_before,"Read-only previews do not create runs or alter saves/economy")
	await dispose(home)
	var game=load("res://scenes/play.tscn").instantiate();game.profile_directory=profile;game.profile_directory_resolved=true;game.use_command_line_catalog=false;game.use_command_line_level=false
	root.add_child(game);current_scene=game;game.set_process(false)
	check(game.modal_title=="YOUR FIRST RESCUE","First normal entry actually shows the tutorial")
	var modal:Control=game.pause_overlay
	var steps:=modal.find_children("StepText*","Label",false,false)
	check(steps.size()==4,"Four short illustrated instructions")
	var min_font:=999
	for step in steps:
		check(not step.text.contains("ARMORED") and not step.text.contains("TWO HITS"),"No inactive armor mechanic")
		var px:int=step.get_theme_font_size("font_size");min_font=mini(min_font,px)
		check(px>=36,"Primary body at least 36 logical pixels")
		for line in step.text.split("\n"):
			var measured:float=step.get_theme_font("font").get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
			check(measured<=480 and step.size.x<=480,"Tutorial text fits declared line: "+line)
	check(modal.has_node("TutorialCannon") and modal.has_node("TutorialBall") and modal.has_node("TutorialPrincess"),"Actual independent game illustrations are present")
	var button:Button=modal.get_node("TutorialContinue")
	check(button.size.y>=140 and modal.get_node("CloseButton").size.y>=128,"Primary and close touch bounds scale to phone proportions")
	check(game.rules.tasks.is_empty() and game.rules.inventory.values().all(func(value):return value==0),"Illustrations do not create tasks or ammo")
	metrics={"body_px_at_360_width":min_font*360.0/940,"continue_height_at_360_width":button.size.y*360.0/940,"close_height_at_360_width":128.0*360/940,"scope":"Layout/node metrics only, not phone GL, touch, or user acceptance."}
	button.pressed.emit();check(game.saves.get_view_state().tutorial_completed,"Actual tutorial continuation persists completion")
	await dispose(game)
	var bad_config:Dictionary=config.duplicate(true);bad_config.grid=[]
	check(not Preview.valid_config(bad_config),"Malformed preview shape is rejected before node creation")
	var bad_file_path:=profile.path_join("invalid-preview.json");var bad_file:=FileAccess.open(bad_file_path,FileAccess.WRITE);bad_file.store_string("[]");bad_file.close()
	check(not Preview.read_configuration(bad_file_path).ok,"Non-object JSON uses explicit preview failure")
	check(not Preview.read_configuration(profile.path_join("missing.json")).ok,"Missing preview file uses explicit failure")
	var failed:=FailedPreviewStartup.new();failed.profile_directory=profile;failed.profile_directory_resolved=true;failed.use_command_line_catalog=false;root.add_child(failed);current_scene=failed
	deadline=Time.get_ticks_msec()+10000
	while failed.phase not in ["home","error"] and Time.get_ticks_msec()<deadline:await process_frame
	check(failed.phase=="error" and not is_instance_valid(failed.home_art) and not is_instance_valid(failed.audio_service),"Preview failure reaches real loader error before Home/audio creation")
	failed.fail_preview=false;failed.retry_loading();deadline=Time.get_ticks_msec()+10000
	while failed.phase!="home" and Time.get_ticks_msec()<deadline:await process_frame
	check(failed.phase=="home" and failed.find_children("HomeArtwork","Control",false,false).size()==1,"Real retry builds one valid Home after preview failure")
	await dispose(failed)
	check(config_bytes==FileAccess.get_file_as_bytes("res://data/serpent-levels/serpent-01.json"),"No rule/config edits")
	var report:Dictionary={"checks":checks,"failures":failures,"phone_metrics":metrics,"scope":"Only approved first-level normal Home/Prep/HowTo read-only nodes and actual tutorial-save handler. No other level, real GL, touch, audio or natural play."}
	var path:=OS.get_environment("ANT_PREVIEW_REPORT");if path.is_empty():path="/tmp/ant-preview-report.json"
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close();print("FIRST_LEVEL_PREVIEWS ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
