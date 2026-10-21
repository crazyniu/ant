extends SceneTree
const Rules=preload("res://scripts/rescue_rules.gd")
const Check=preload("res://tools/validate_serpent_level.gd")
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
	var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-06.json"))
	var proof:=Check.inspect(c,true)
	check(proof.ok and proof.terminal_time_us==20850000,"authored basic worker solution")
	check(proof.remaining_beads==6 and proof.required_damage_by_color=={"red":4,"green":3,"blue":5},"different18 bead12HP color budget")
	check(proof.longest_no_dispatch_opportunity_us==0,"authored stagger never removes all legal opportunities")
	var core_picked:=0
	for event in proof.events:
		if event.type=="bead_picked_up" and event.cell_id in [45,46]:core_picked+=1
	check(core_picked>=1,"blue demand exceeds four exterior blue beads, actual core reached")
	var openings:Array=[]
	for choice in [{"color":"red","cell":55,"distance":3,"opens":45},{"color":"green","cell":56,"distance":4,"opens":46},{"color":"blue","cell":73,"distance":3,"opens":-1}]:
		var r:=Rules.new();r.load_level(c)
		var target:Dictionary=r.best_target(choice.color)
		check(target.cell_id==choice.cell and target.distance==choice.distance,"real initial choice "+choice.color)
		check(not r.reachable_cell_ids("blue").has(45) and not r.reachable_cell_ids("blue").has(46),"both blue core cells initially enclosed")
		var accepted:Dictionary=r.click_color(choice.color);check(accepted.ok,"explicit initial click")
		var pickup_us:int=r.tasks[accepted.task_id].pickup_us;r.update_us(pickup_us-1)
		check(r.board.has(choice.cell) and not r.reachable_cell_ids("blue").has(45) and not r.reachable_cell_ids("blue").has(46),"reservation does not open core")
		r.update_us(1)
		check(not r.board.has(choice.cell),"real pickup removes gate")
		if choice.opens>=0:check(r.reachable_cell_ids("blue").has(choice.opens),"different gate exposes different core cell")
		else:check(not r.reachable_cell_ids("blue").has(45) and not r.reachable_cell_ids("blue").has(46),"outer blue supplies ammo without opening core")
		r.update_us(5000000-r.time_us)
		var events:Array=r.drain_events()
		var hit:Array=events.filter(func(e:Dictionary)->bool:return e.type=="segment_hit")
		check(hit.size()==1 and r.conservation_errors().is_empty(),"one delivered bead causes exactly one real hit")
		if choice.color=="blue":check(hit[0].kind=="armored" and hit[0].hp==1,"outer blue first shot cracks blue armor")
		elif choice.color=="red":check(hit[0].hp==0,"near red first shot removes normal red segment")
		openings.append({"color":choice.color,"target":choice.cell,"path_cells":choice.distance,"pickup_us":pickup_us,"core_opened":choice.opens})
	var layout:=Layout.load_for(c);check(layout.ok,"scene contract loads")
	var data:Dictionary=layout.data
	var plane:=GroundPlane.new(c.width,c.height,data,c.transport.entrance_cell)
	var enemy:=EnemyPath.new();enemy.configure(Layout.knots(data),c.serpent.goal_s)
	var hull:=PackedVector2Array();for v in data.walkable_polygon:hull.append(Layout.point(v))
	var rules:=Rules.new();rules.load_level(c)
	var sampled:=0;var separation:=10000.0
	for input in c.solution.inputs:
		rules.update_us(Rules.seconds_to_us(input.at_sec)-rules.time_us)
		var accepted:Dictionary=rules.click_color(input.color);check(accepted.ok,"route input accepted")
		var task:Dictionary=rules.tasks[accepted.task_id]
		var route:=Route.build(task.path,plane,Layout.point(data.nest.position));var inside:=true
		for i in range(201):
			var position:Vector2=Route.sample(route,i/200.0).position;sampled+=1
			if not Geometry2D.is_point_in_polygon(position,hull):inside=false
			separation=minf(separation,enemy.curve.get_closest_point(position).distance_to(position))
		check(inside,"real route remains on inner ground")
	check(separation>52,"ant and serpent body radii remain separated")
	check(enemy.point_at(c.serpent.goal_s).distance_to(Layout.point(data.defense_target.foot))<100,"finite route reaches fixed cart footprint")
	var report:Dictionary={"checks":checks,"failures":failures,"openings":openings,"path_samples":sampled,"minimum_enemy_centerline_separation":separation,"level_sha256":FileAccess.get_sha256("res://data/serpent-levels/serpent-06.json"),"rule_sha256":FileAccess.get_sha256("res://scripts/rescue_rules.gd"),"summary":{}}
	for key in ["terminal_time_us","contact_time_us","path_cells","remaining_beads","hit_counts","longest_no_dispatch_opportunity_us"]:report.summary[key]=proof[key]
	var file:=FileAccess.open("res://reports/rules/ruins-fork.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("RUINS_FORK ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
