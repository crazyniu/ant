extends SceneTree
## First-level-only read-only production geometry exporter. No scene, saves, GL,
## altered rules, combat rebalance, or production files are exercised/written.
const Rules = preload("res://scripts/rescue_rules.gd")
const GroundPlane = preload("res://scripts/board_plane.gd")
const Route = preload("res://scripts/carrier_route.gd")
const Dragon = preload("res://scripts/serpent_path.gd")
var records: Dictionary = {}
var plane: RefCounted
var nest: Vector2
func _initialize()->void: call_deferred("run")
func clean(v:Variant)->Variant:
	if v is Vector2:return [v.x,v.y]
	if v is Dictionary:
		var result:Dictionary={}
		for k in v:result[k]=clean(v[k])
		return result
	if v is Array or v is PackedFloat64Array or v is PackedVector2Array:
		var result:Array=[]
		for a in v:result.append(clean(a))
		return result
	return v
func capture(r:RefCounted,label:String)->void:
	r.reachable_cell_ids()
	for logical in r.get("_routes").values():
		var key:=JSON.stringify(logical.path)
		if records.has(key):
			if label not in records[key].sources:records[key].sources.append(label)
			continue
		var route:Dictionary=Route.build(logical.path,plane,nest)
		var probes:Array=[]
		for i in range(101):probes.append(clean(Route.sample(route,float(i)/100.0)))
		records[key]={"path":logical.path,"distance_cells":logical.distance,"sources":[label],"route":clean(route),"production_probes":probes}
func run()->void:
	var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-01.json"))
	var l:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(c.scene_layout))
	assert(int(c.level_number)==1)
	plane=GroundPlane.new(c.width,c.height,l,c.transport.get("entrance_cell",[]));nest=Vector2(l.nest.position[0],l.nest.position[1])
	var r:=Rules.new();assert(r.load_level(c))
	capture(r,"initial")
	var index:=0
	while r.status in ["ready","running"] and r.time_us<160000000:
		while index<c.solution.inputs.size() and Rules.seconds_to_us(c.solution.inputs[index].at_sec)<=r.time_us:
			assert(r.click_color(c.solution.inputs[index].color).ok);index+=1
		r.update_us(5000)
		if r.get("_routes_dirty"):capture(r,"authored_replay")
	var result:Dictionary={"scope":"Only serpent-01. Production Rules reachable routes and production CarrierRoute geometry. Additional peel states are geometry fixtures, not naturally playable timing evidence.","authored_status":r.status,"authored_time_us":r.terminal_time_us,"records":[]}
	var peel:=Rules.new();assert(peel.load_level(c));var layers:Array=[]
	while not peel.board.is_empty():
		capture(peel,"peel_layer_%d"%layers.size())
		var ids:Array=peel.reachable_cell_ids();assert(not ids.is_empty());layers.append(ids)
		for id in ids:peel.board.erase(id)
		peel.set("_routes_dirty",true)
	if records.is_empty():push_error("No production routes exported");quit(1);return
	result.peel_layers=layers;result.records=records.values()
	result.hashes={}
	for input in ["scripts/carrier_route.gd","scripts/board_plane.gd","data/scenes/first-level-approved.json","data/serpent-levels/serpent-01.json","scripts/rescue_rules.gd"]:result.hashes[input]=FileAccess.get_sha256("res://"+input)
	var dragon:=Dragon.new();var knots:Array=[]
	for k in l.route:
		var knot:Dictionary={"position":Vector2(k.position[0],k.position[1])}
		for field in ["in","out"]:
			if k.has(field):knot[field]=Vector2(k[field][0],k[field][1])
		knots.append(knot)
	dragon.configure(knots,c.serpent.goal_s);result.dragon_baked_points=clean(dragon.points());result.dragon_baked_length=dragon.baked_length
	result.plane_centers={}
	for y in range(-1,16):
		for x in range(-1,17):result.plane_centers["%d,%d"%[x,y]]=clean(plane.center(x,y))
	var f:=FileAccess.open("res://reports/first-level/batch-2/audit_footpath_production_routes.json",FileAccess.WRITE);f.store_string(JSON.stringify(result));f.close()
	print("FOOTPATH_EXPORT ",JSON.stringify({"routes":records.size(),"resource_cells":240,"peel_layers":layers.size(),"authored_status":r.status,"authored_time_us":r.terminal_time_us}));quit()
