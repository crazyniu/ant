extends SceneTree
const Layout=preload("res://scripts/scene_layout.gd")
const Rules=preload("res://scripts/rescue_rules.gd")
const GroundPlane=preload("res://scripts/board_plane.gd")
const Route=preload("res://scripts/carrier_route.gd")
const Path=preload("res://scripts/serpent_path.gd")
var failures:Array=[]
var checks:=0
var sampled:=0
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures.append(label);push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-04.json"))
	var result:=Layout.load_for(config);check(result.ok,"ruins assets and scene contract load")
	if not result.ok:quit(1);return
	var data:Dictionary=result.data
	var plane:=GroundPlane.new(config.width,config.height,data,config.transport.entrance_cell)
	var hull:=PackedVector2Array()
	for point in data.walkable_polygon:hull.append(Layout.point(point))
	var rules:=Rules.new();check(rules.load_level(config),"level rules load")
	var path:=Path.new();path.configure(Layout.knots(data),config.serpent.goal_s)
	check(path.point_at(0).distance_to(path.point_at(config.serpent.goal_s))>500,"open finite route, never circular wrap")
	check(path.point_at(config.serpent.goal_s).distance_to(Layout.point(data.defense_target.foot))<100,"goal touches cart footprint")
	check(data.defense_target.id=="supply_cart" and data.defense_target.fixed,"fixed cart not princess or moving escort")
	var min_separation:=10000.0
	for input in config.solution.inputs:
		rules.update_us(Rules.seconds_to_us(input.at_sec)-rules.time_us)
		var accepted:Dictionary=rules.click_color(input.color)
		check(accepted.ok,"actual authored color accepted")
		if not accepted.ok:continue
		var task:Dictionary=rules.tasks[accepted.task_id]
		var route:=Route.build(task.path,plane,Layout.point(data.nest.position))
		check(Route.sample(route,0).position==Layout.point(data.nest.position),"configured nest anchor")
		check(Route.sample(route,1).position.distance_to(plane.center(task.path[-1][0],task.path[-1][1]))<.001,"configured target anchor")
		var inside:=true
		for i in range(201):
			var position:Vector2=Route.sample(route,float(i)/200).position;sampled+=1
			if not Geometry2D.is_point_in_polygon(position,hull):inside=false;failures.append("outside art-ground hull: "+str(position));break
			min_separation=minf(min_separation,path.curve.get_closest_point(position).distance_to(position))
		check(inside,"carrier route stays inside open inner ground")
	check(min_separation>52,"ant centerline separated from enemy road by both body radii")
	var forest_config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-01.json"))
	var forest:=Layout.load_for(forest_config);check(forest.ok,"default woodland remains available")
	var old_plane:=GroundPlane.new(10,8);var new_plane:=GroundPlane.new(10,8,forest.data)
	check(old_plane.center(0,0)==new_plane.center(0,0) and old_plane.center(9,7)==new_plane.center(9,7),"existing board coordinates unchanged")
	var malformed:=config.duplicate(true);malformed.scene_layout="res://data/scenes/missing-scene.json"
	check(not Layout.load_for(malformed).ok,"missing scene rejected, not silently wrong background")
	var adventure=load("res://scripts/adventure_view.gd").new()
	adventure.set_data([config],{"ready":true,"completed_level_ids":[],"unlocked_level_ids":["serpent-04"],"unlocked_level":4},{"points":0,"owned_types":["worker"],"equipped_type":"worker","carry_level":1})
	root.add_child(adventure)
	# Explicit detached unlocked view fixture only; no save or balance fabricated.
	adventure.progress={"ready":true,"available_unlocked":4,"completed_levels":[]}
	adventure.selected_level=4;adventure.screen="preparation";adventure._render_page()
	await process_frame
	var inside_panel:=true
	for color in ["red","blue","green","yellow"]:
		var label:Label=adventure.get_node("AdventurePage/Need_"+color)
		if label.position.x<600 or label.get_rect().end.x>872 or label.position.y<850 or label.get_rect().end.y>958:inside_panel=false
	check(inside_panel,"four-color needs fit inside preparation information area")
	check(adventure.get_node("AdventurePage/ScenePreview/ActualLevelScene/DefenseTarget").get_meta("guardian_id")=="supply_cart","preview guardian uses identical scene contract")
	adventure.queue_free();await process_frame
	# Actual production scene and actual victory presentation, driven by its timed solution.
	var play=load("res://scenes/play.tscn").instantiate();play.auto_replay=true;play.use_command_line_catalog=false;play.use_command_line_level=false;play.level_index=4
	root.add_child(play);current_scene=play
	await process_frame
	check(play.ready_to_simulate,"production level4 instantiates")
	if play.ready_to_simulate:
		play.set_process(false)
		check(play.get_node("DragonRoute/DefenseTarget").get_meta("guardian_id")=="supply_cart","live guardian independent node")
		check(play.color_buttons.size()==4,"four real color controls")
		for i in range(800):
			play.advance_replay(.05);play.sync_view();play.consume_rule_events();play.fx.advance(.05);play.serpent.advance(.05);play.apply_actor_poses()
			if play.rules.status=="victory":break
		check(play.rules.status=="victory" and play.victory_saved,"actual last hit saves cart victory")
		play.fx.advance(2.0);play.serpent.advance(2.0);play.present_pending_outcome()
		check(play.pause_overlay!=null and play.pause_overlay.has_node("SavedDefenseTarget"),"result uses actual guardian art")
		check(play.modal_title=="SAVED!","result no princess-only text")
		await process_frame
		check(play.pause_overlay.get_node("SavedDefenseTarget").size==Vector2(320,270),"guardian intrinsic texture size cannot expand result")
		var compact_icons:=true
		for node in play.pause_overlay.get_children():
			if node is TextureRect and node.texture!=null and node.texture.resource_path.ends_with("ant-coin.png"):
				if node.size.x>80 or node.size.y>80:compact_icons=false
		check(compact_icons,"result coin native size cannot expand reward or shop action")
	var report:Dictionary={"checks":checks,"failures":failures,"carrier_path_samples":sampled,"minimum_enemy_centerline_separation":min_separation,"scope":"One new ruins level scene/ground/preview-source contract and production victory; automated, not human review."}
	print("RUINS_SCENE ",JSON.stringify(report))
	var file:=FileAccess.open("res://reports/ui/ruins-scene.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	play.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
