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
	var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-13.json"))
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
	var view=load("res://scripts/adventure_view.gd").new();view.set_data([c],{"ready":true,"available_unlocked":13},{"points":0,"owned_types":["worker"],"equipped_type":"worker","carry_level":1});root.add_child(view)
	view.selected_level=13;view.screen="preparation";view._render_page();await process_frame
	var serpent=view.get_node("AdventurePage/ScenePreview/ActualLevelScene/PreviewSerpent")
	check(serpent.manifest.get("skin_id", "default")=="ice_crest","preparation uses ice-crest appearance")
	check(view.get_node("AdventurePage/ScenePreview/ActualLevelScene/DefenseTarget").get_meta("guardian_id")=="winter_camp","preview fixed camp identity")
	for color in c.palette.values():
		var count:Label=view.get_node("AdventurePage/Need_"+color)
		check(count.get_rect().end.x<=872 and count.get_rect().end.y<=958,"real five-color needs fit")
	var target:TextureRect=view.get_node("AdventurePage/ScenePreview/ActualLevelScene/DefenseTarget")
	check(target.size.x<210 and target.size.y<165,"camp TextureRect remains layout-sized, not source-sized")
	check(target.get_meta("ground_anchor")==Layout.point(layout.defense_target.foot),"camp foot uses the shared fixed goal anchor")
	var scene:Control=load("res://scenes/play.tscn").instantiate()
	scene.auto_replay=true;scene.use_command_line_catalog=false;scene.use_command_line_level=false;scene.level_index=13
	root.add_child(scene);scene.set_process(false);scene.auto_replay=false;await process_frame
	check(scene.ready_to_simulate and scene.rules.time_us==0,"actual production level13 initializes without simulation")
	check(scene.color_buttons.size()==5,"five authored colors produce five real controls")
	var prior:Rect2=Rect2()
	for color in scene.color_buttons:
		var button:Button=scene.color_buttons[color];var bounds:=button.get_rect()
		check(bounds.size.x>=110.3 and bounds.size.y>=110.3,"new five-color control retains44point-equivalent hit area")
		check(bounds.position.y==1282 and bounds.end.x<=920,"five color controls stay one row inside canvas")
		if prior.size.x>0:check(not prior.intersects(bounds),"adjacent live color buttons do not overlap")
		prior=bounds
	check(scene.select_color(str(c.solution.inputs[0].color)) and scene.rules.tasks.size()==1,"first authored color input dispatches exactly one actual carrier")
	check(scene.get_node("DragonRoute/DefenseTarget").get_meta("guardian_id")=="winter_camp","gameplay uses actual fixed camp")
	var stock_rects:Array[Rect2]=[]
	var active_colors:Array=[]
	for color in scene.COLORS:
		if scene.rules.initial_counts.get(color,0)>0:active_colors.append(color)
	for index in active_colors.size():
		var color:String=active_colors[index]
		var anchor:=Layout.stock_anchor(layout,index)
		var count:Label=scene.get_node("TransportScene/Stock/Count_"+color)
		check(count.position==anchor+Vector2(0,13),"inventory count shares scene anchor: "+color)
		check(scene.fx._layout.stock_points[color]==anchor+Vector2(24,0),"delivery effect shares scene anchor: "+color)
		var bounds:=Rect2(anchor+Vector2(0,-18),Vector2(53,65))
		check(not bounds.intersects(Layout.rect(layout.cannon.rect)) and bounds.end.y<1210,"stock avoids cannon and capacity HUD: "+color)
		for old_bounds in stock_rects:check(not old_bounds.intersects(bounds),"five stock icons/counts do not overlap")
		stock_rects.append(bounds)
	scene.queue_free();view.queue_free();await process_frame;await process_frame

	var report:Dictionary={"checks":checks,"failures":failures,"path_samples":sampled,"minimum_enemy_centerline_separation":separation,"level_sha256":FileAccess.get_sha256("res://data/serpent-levels/serpent-13.json"),"scope":"one integrated ice supply-channel ground/preview/five-color input contract, no prior campaign rerun"}
	var file:=FileAccess.open("res://reports/ui/icechannel-scene.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close();print("ICECHANNEL_SCENE ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
