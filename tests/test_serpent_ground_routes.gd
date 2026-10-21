extends SceneTree
const Rules=preload("res://scripts/rescue_rules.gd")
const GroundPlane=preload("res://scripts/board_plane.gd")
const Route=preload("res://scripts/carrier_route.gd")
# Art-ground hull: inward of the masonry; the central bottom neck is the only gate.
var WALKABLE=PackedVector2Array([Vector2(185,300),Vector2(725,300),Vector2(775,350),Vector2(775,845),Vector2(730,885),Vector2(545,895),Vector2(515,940),Vector2(515,1025),Vector2(420,1025),Vector2(420,940),Vector2(190,895),Vector2(135,845),Vector2(130,360)])
var failures:Array[String]=[]
var samples:=0
var paths:=0
func _initialize()->void:
	for level in range(1,4):
		var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-%02d.json"%level))
		var rules:=Rules.new();rules.load_level(config)
		var plane:=GroundPlane.new(config.width,config.height)
		for input in config.solution.inputs:
			rules.update_us(roundi(float(input.at_sec)*1000000)-rules.time_us)
			var result:Dictionary=rules.click_color(input.color)
			if not result.ok:failures.append("input rejected");continue
			var task:Dictionary=rules.tasks[result.task_id]
			var route:Dictionary=Route.build(task.path,plane)
			paths+=1
			for i in range(201):
				var pose:Dictionary=Route.sample(route,float(i)/200)
				samples+=1
				if not Geometry2D.is_point_in_polygon(pose.position,WALKABLE):failures.append("outside walkable ground %s"%str(pose.position));break
			if Route.sample(route,0).position!=Vector2(467,1008):failures.append("nest anchor")
			var goal:Array=task.path[-1]
			if Route.sample(route,1).position.distance_to(plane.center(goal[0],goal[1]))>.001:failures.append("target anchor")
	var report:Dictionary={"path_count":paths,"sample_count":samples,"failures":failures,"scope":"Exact authored input transport paths; render-ground corridor hull and endpoints. Occupied-grid reachability remains Rules authority."}
	print("SERPENT_GROUND_ROUTES ",JSON.stringify(report))
	var f:=FileAccess.open("res://reports/motion/serpent-ground-routes.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close();quit(0 if failures.is_empty() else 1)
