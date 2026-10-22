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
func inspect_mobile_label(label:Label,minimum_phone_px:float,note:String)->void:
	var px:=label.get_theme_font_size("font_size")
	var source:=label.get_theme_font("font")
	check(px*360.0/940.0>=minimum_phone_px,note+" phone-size role minimum")
	for line in label.text.split("\n"):
		check(source.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x<=label.size.x,note+" line width")
	check(source.get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,px).y<=label.size.y,note+" text height")
func inspect_loading_button(button:Button,label:String)->void:
	check(button.size==Vector2(560,136) and button.get_theme_font_size("font_size")==38,label+" mobile text/touch bounds")
	for state in ["normal","hover","pressed","hover_pressed","disabled"]:
		var paint:=button.get_theme_stylebox(state)
		check(paint is StyleBoxTexture and paint.texture is AtlasTexture and paint.texture.atlas.resource_path=="res://assets/ui/v03/game-skin-atlas.png",label+" existing painted atlas in "+state)
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color","font_disabled_color"]:
		check(button.get_theme_color(state)==Color("682b0c"),label+" preserves dark readable ink in "+state)
	check(button.get_theme_stylebox("normal").texture.region==Rect2(671,416,570,215),label+" authoritative secondary region")
	var text_width:=button.get_theme_font("font").get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,38).x
	check(text_width<=button.size.x-64,label+" text fits its actual skin content area")
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
	var entrance:Label=home.home_art.get_node("SavedEntrance")
	inspect_mobile_label(entrance,14,"Home current level")
	check(entrance.get_theme_color("font_color")==Color("fff9e8") and entrance.get_theme_color("font_outline_color")==Color("682b0c"),"Home wood uses light text with dark outline")
	inspect_preview(home.home_art.get_node("HomeLevelPreview"),"Home")
	check(not home.home_art.has_node("HomeCannon"),"Legacy red cannon removed")
	var preview:Control=home.home_art.get_node("HomeLevelPreview")
	check(preview.get_rect()==Rect2(0,0,940,1672) and preview.get_node("ActualLevelScene").scale==Vector2.ONE,"Home is one full, unscaled scene, not an inset rectangle")
	check(not home.home_art.has_node("Garden") and home.home_art.find_children("Forest","TextureRect",true,false).size()==1,"Exactly one forest background, no duplicate outer map")
	var title:Control=home.home_art.get_node("BrandTitle")
	check(title.get_index()>preview.get_index() and title.position.y>=Layout.rect(layout.cannon.rect).end.y,"Home branding layered above the single scene on the wooden footer below the cannon")
	for id in ["SavedEntrance","PlayButton","LevelsButton"]:
		var control:Control=home.home_art.get_node(id)
		check(Rect2(20,20,900,1632).encloses(control.get_rect()) and not title.get_rect().intersects(control.get_rect()),"Home footer clearance: "+id)
	check(home.home_art.get_node("LevelsButton").size.y>=128,"Map entrance retains phone-size touch bounds")
	var progress_before:=FileAccess.get_file_as_bytes(profile.path_join("save.json"))
	var economy_before:=FileAccess.get_file_as_bytes(home.progression.base_path.path_join("progression.json"))
	home.open_adventure("preparation",1)
	inspect_preview(home.adventure.get_node("AdventurePage/ScenePreview"),"Prep")
	check(not home.adventure.get_node("AdventurePage/BossDetails").tooltip_text.to_upper().contains("ARMORED"),"No disabled armor teaching in first-level Prep")
	check(home.adventure.get_node("AdventurePage").get_meta("level_summary").armored==0,"Zero armor remains an actual rule fact")
	var page:Control=home.adventure.get_node("AdventurePage")
	check(page.find_children("Need_*","Label",false,false).is_empty(),"No five tiny redundant per-color counts")
	check(page.get_node("NormalCount").text=="20","Prominent true normal-segment total remains")
	for name in ["LevelHeading","NormalCount","LoadoutSummary"]:inspect_mobile_label(page.get_node(name),14,"Prep "+name)
	inspect_mobile_label(page.get_node("PointBalance"),12,"Prep points")
	for kind in ["worker","swift"]:
		var card:Control=page.get_node("AntChoice_"+kind)
		var capacity:Label=card.get_node("Capacity");var speed:Label=card.get_node("MovementSpeed")
		inspect_mobile_label(capacity,14,kind+" capacity");inspect_mobile_label(speed,14,kind+" speed")
		check(capacity.get_rect().get_center().x==speed.get_rect().get_center().x,kind+" numeric states share an axis")
		check(speed.get_rect().end.y+12<=card.get_node("Equip_"+kind).position.y,kind+" speed does not collide with selection button")
		check(speed.get_theme_font("font").get_string_size("+38%",HORIZONTAL_ALIGNMENT_LEFT,-1,38).x+12<=speed.size.x,kind+" max upgrade text has side clearance")
	var summary:Label=page.get_node("LoadoutSummary")
	check(summary.get_theme_font("font").get_string_size("Lv.4   +38%",HORIZONTAL_ALIGNMENT_LEFT,-1,38).x+20<=summary.size.x,"Maximum real loadout text fits without shrinking")
	check(summary.get_rect().end.y+10<=page.get_node("BeginLevel").position.y,"Loadout text clears Begin control")
	var color_icons:=page.find_children("RequiredColor_*","Control",false,false)
	check(color_icons.size()==5,"Actual five-color palette remains")
	for ball in color_icons:check(ball.size==Vector2(34,34) and config.palette.values().has(ball.color_id),"Palette icon is an actual first-level color")
	var before_runs:int=home.progression._record.runs.size()
	home.adventure.show_map();home.adventure.show_preparation(1)
	check(home.adventure.get_node("AdventurePage").find_children("ScenePreview","Control",false,false).size()==1,"Repeated navigation has one preview")
	check(home.progression._record.runs.size()==before_runs and FileAccess.get_file_as_bytes(profile.path_join("save.json"))==progress_before and FileAccess.get_file_as_bytes(home.progression.base_path.path_join("progression.json"))==economy_before,"Read-only previews do not create runs or alter saves/economy")
	home.launch_game()
	check(home.phase=="loading" and home.launch_pending,"Normal launch exposes real loading state")
	inspect_mobile_label(home.loading_label,14,"Loading status")
	check(home.loading_label.get_theme_font("font").resource_path=="res://assets/fonts/Title.ttf","Loading uses the official font")
	inspect_loading_button(home.loading_layer.get_node("BackButton"),"Loading Back")
	var generation:int=home.load_generation
	home.loading_layer.get_node("BackButton").pressed.emit()
	await process_frame;await process_frame
	check(home.phase=="preparation" and not home.launch_pending and home.load_generation>generation and current_scene==home,"Painted Back still cancels the pending owner and returns to Preparation; deferred handover remains invalidated")
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
		check(px>=38,"Primary body at least 38 logical pixels")
		inspect_mobile_label(step,14,"Tutorial "+str(step.name))
		for line in step.text.split("\n"):
			var measured:float=step.get_theme_font("font").get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
			check(measured+10<=490 and step.size.x==490,"Tutorial text has horizontal clearance: "+line)
	inspect_mobile_label(modal.get_node("ObservationNotice"),12,"Tutorial timing notice")
	check(modal.has_node("TutorialIllustration2/TutorialCannon") and modal.has_node("TutorialIllustration2/TutorialBall") and modal.has_node("TutorialIllustration3/TutorialPrincess"),"Actual independent game illustrations belong to their teaching rows")
	check(not modal.has_node("ThreatDragon"),"No top-level tutorial dragon escapes the fourth row")
	for sample in 6:
		await create_timer(.06).timeout
		for index in 4:
			var row:Control=modal.get_node("TutorialIllustration%d"%index)
			check(row.clip_contents and row.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Each illustrated row is clipped and ignores input during reveal")
		var row:Control=modal.get_node("TutorialIllustration3")
		for id in ["ThreatDragon","TutorialPrincess"]:
			var illustration:Control=row.get_node(id)
			check(Rect2(Vector2.ZERO,row.size).encloses(illustration.get_rect()),"Fourth-row portrait stays within local bounds during/after reveal: "+id)
	check(modal.get_node("TutorialIllustration3").position==Vector2(110,990),"Tween restores the correct fourth-row resting position, not origin")
	check(modal.get_node("TutorialIllustration3/ThreatDragon").get_global_rect().position.y>=990,"Settled dragon is beside the princess, not at screen origin")
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
	inspect_mobile_label(failed.loading_label,14,"Loading actual failure message")
	check(failed.loading_label.get_rect().end.y+30<=failed.loading_layer.get_node("RetryButton").position.y,"Error text clears retry target")
	inspect_loading_button(failed.loading_layer.get_node("RetryButton"),"Bootstrap error Retry")
	failed.fail_preview=false;failed.retry_loading();deadline=Time.get_ticks_msec()+10000
	while failed.phase!="home" and Time.get_ticks_msec()<deadline:await process_frame
	check(failed.phase=="home" and failed.find_children("HomeArtwork","Control",false,false).size()==1,"Real retry builds one valid Home after preview failure")
	await dispose(failed)
	check(config_bytes==FileAccess.get_file_as_bytes("res://data/serpent-levels/serpent-01.json"),"No rule/config edits")
	var report:Dictionary={"checks":checks,"failures":failures,"phone_metrics":metrics,"scope":"Only approved first-level normal Home/Prep/HowTo read-only nodes and actual tutorial-save handler. No other level, real GL, touch, audio or natural play."}
	var path:=OS.get_environment("ANT_PREVIEW_REPORT");if path.is_empty():path="/tmp/ant-preview-report.json"
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close();print("FIRST_LEVEL_PREVIEWS ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
