extends SceneTree
const Rules=preload("res://scripts/rescue_rules.gd")
const Layout=preload("res://scripts/scene_layout.gd")
const GroundPlane=preload("res://scripts/board_plane.gd")
const Route=preload("res://scripts/carrier_route.gd")
const EnemyPath=preload("res://scripts/serpent_path.gd")
var checks:=0
var failures:Array=[]
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures.append(label);push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-07.json"))
	var loaded:=Layout.load_for(c);check(loaded.ok,"scene and configured appearance resolve")
	if not loaded.ok:quit(1);return
	var layout:Dictionary=loaded.data
	var plane:=GroundPlane.new(c.width,c.height,layout,c.transport.entrance_cell)
	var enemy:=EnemyPath.new();enemy.configure(Layout.knots(layout),c.serpent.goal_s)
	var hull:=PackedVector2Array();for p in layout.walkable_polygon:hull.append(Layout.point(p))
	var rules:=Rules.new();rules.load_level(c)
	var sampled:=0;var separation:=10000.0
	for input in c.solution.inputs:
		rules.update_us(Rules.seconds_to_us(input.at_sec)-rules.time_us)
		var accepted:Dictionary=rules.click_color(input.color);check(accepted.ok,"authored carrier path accepted")
		if not accepted.ok:continue
		var route:=Route.build(rules.tasks[accepted.task_id].path,plane,Layout.point(layout.nest.position));var inside:=true
		for i in range(201):
			var point:Vector2=Route.sample(route,i/200.0).position;sampled+=1
			if not Geometry2D.is_point_in_polygon(point,hull):inside=false
			separation=minf(separation,enemy.curve.get_closest_point(point).distance_to(point))
		check(inside,"carrier follows inner clear snow ground")
	check(separation>52,"transport and outer enemy road remain separate")
	check(enemy.point_at(c.serpent.goal_s).distance_to(Layout.point(layout.defense_target.foot))<100,"finite endpoint reaches actual camp footprint")
	var view=load("res://scripts/adventure_view.gd").new();view.set_data([c],{"ready":true,"available_unlocked":7},{"points":0,"owned_types":["worker"],"equipped_type":"worker","carry_level":1});root.add_child(view)
	view.selected_level=7;view.screen="preparation";view._render_page();await process_frame
	var serpent=view.get_node("AdventurePage/ScenePreview/ActualLevelScene/PreviewSerpent")
	check(serpent.manifest.get("skin_id")=="ice_crest","preparation uses actual level skin")
	check(view.get_node("AdventurePage/ScenePreview/ActualLevelScene/DefenseTarget").get_meta("guardian_id")=="winter_camp","preview fixed camp identity")
	for color in c.palette.values():
		var count:Label=view.get_node("AdventurePage/Need_"+color)
		check(count.get_rect().end.x<=872 and count.get_rect().end.y<=958,"real four-color needs fit")
	view.queue_free();await process_frame;await process_frame
	var report:Dictionary={"checks":checks,"failures":failures,"path_samples":sampled,"minimum_enemy_centerline_separation":separation,"level_sha256":FileAccess.get_sha256("res://data/serpent-levels/serpent-07.json"),"scope":"one integrated ice supply-ridge ground/preview/appearance contract, no prior campaign rerun"}
	var file:=FileAccess.open("res://reports/ui/ice-supply-scene.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close();print("ICE_SUPPLY_SCENE ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
