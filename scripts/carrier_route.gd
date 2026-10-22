extends RefCounted
## Presentation-only route geometry. Build once per task, then sample in either
## direction using the Rules' existing normalized progress and timestamps.
## Rules paths contain empty transit cells and one occupied final target. Only
## interior transit-cell right angles are rounded. A scene may explicitly opt
## into bounded exterior-screen corners; occupied endpoints are never changed.
const CORNER_RADIUS := 0.22
const ARC_STEPS := 12
const EPSILON := 0.000001
const NEST_POSITION := Vector2(467.0, 1008.0)

static func build(path: Array, plane: RefCounted, nest: Vector2 = NEST_POSITION) -> Dictionary:
	var cells: Array[Vector2] = []
	for point in path:
		var cell := Vector2(float(point[0]), float(point[1]))
		if not cell.is_finite():
			continue
		if cells.is_empty() or not cell.is_equal_approx(cells[-1]):
			cells.append(cell)
	var route := {"segments": [], "ends": PackedFloat64Array(), "total_length": 0.0,
		"start_position": Vector2.ZERO, "end_position": Vector2.ZERO,
		"start_depth": 0.0, "end_depth": 0.0}
	if cells.is_empty():
		return route
	route.start_position = _map(cells[0], plane, nest)
	# The nest is outside the logical board. Use the actual clear gateway before
	# joining the exterior BFS origin, never a long diagonal into a side lane.
	if _is_nest(cells[0], plane):
		route.start_position = nest
		var gateway:Vector2=plane.gateway
		_append_screen_leg(route,nest,gateway,cells[0])
		_append_screen_leg(route,gateway,_map(cells[0],plane,nest),cells[0])
	route.end_position = _map(cells[-1], plane, nest)
	route.start_depth = cells[0].y
	route.end_depth = cells[-1].y
	var previous := cells[0]
	var previous_screen := _map(previous,plane,nest)
	for i in range(1, cells.size() - 1):
		var cell := cells[i]
		var incoming := cell - cells[i - 1]
		var outgoing := cells[i + 1] - cell
		# A displaced nest is not a projected grid cell. Keep its adjoining
		# segments exact rather than cutting across the long entrance approach.
		var can_round := cell.x >= 0.0 and cell.x < float(plane.columns) \
			and cell.y >= 0.0 and cell.y < float(plane.rows) \
			and not _is_nest(cells[i - 1], plane) and not _is_nest(cells[i + 1], plane) \
			and absf(incoming.length_squared() - 1.0) < EPSILON \
			and absf(outgoing.length_squared() - 1.0) < EPSILON \
			and absf(incoming.dot(outgoing)) < EPSILON
		if can_round:
			var entry := cell - incoming * CORNER_RADIUS
			var exit := cell + outgoing * CORNER_RADIUS
			_append_mapped_segment(route,previous_screen,previous_screen,_map(entry,plane,nest),previous,previous,entry,false)
			# This quadratic's whole control hull is inside this one empty cell.
			# Adjacent occupied cells and the final target cannot be cut across.
			_append_segment(route, entry, cell, exit, true, plane, nest)
			previous = exit
			previous_screen = _map(exit,plane,nest)
		else:
			var current_screen:=_map(cell,plane,nest)
			var screen_in:=current_screen-_map(cells[i-1],plane,nest)
			var screen_out:=_map(cells[i+1],plane,nest)-current_screen
			var exterior:bool=cell.x<0 or cell.x>=plane.columns or cell.y<0 or cell.y>=plane.rows
			var exterior_bend:bool=plane.exterior_corner_radius_px>0 and exterior and not _is_nest(cell,plane) \
				and not _is_nest(cells[i-1],plane) and not _is_nest(cells[i+1],plane) \
				and screen_in.length()>EPSILON and screen_out.length()>EPSILON \
				and screen_in.normalized().dot(screen_out.normalized())<.995
			if exterior_bend:
				var radius:=minf(plane.exterior_corner_radius_px,minf(screen_in.length(),screen_out.length())*.45)
				var entry_screen:=current_screen-screen_in.normalized()*radius
				var exit_screen:=current_screen+screen_out.normalized()*radius
				var entry:=cell-incoming*(radius/screen_in.length())
				var exit:=cell+outgoing*(radius/screen_out.length())
				_append_mapped_segment(route,previous_screen,previous_screen,entry_screen,previous,previous,entry,false)
				_append_mapped_segment(route,entry_screen,current_screen,exit_screen,entry,cell,exit,true)
				previous=exit;previous_screen=exit_screen
			else:
				_append_mapped_segment(route,previous_screen,previous_screen,current_screen,previous,previous,cell,false)
				previous=cell;previous_screen=current_screen
	_append_mapped_segment(route,previous_screen,previous_screen,_map(cells[-1],plane,nest),previous,previous,cells[-1],false)
	return route

static func sample(route: Dictionary, t: float) -> Dictionary:
	var segments: Array = route.get("segments", [])
	var total := float(route.get("total_length", 0.0))
	var fraction := clampf(t, 0.0, 1.0) if is_finite(t) else 0.0
	var travelled := fraction * total
	if segments.is_empty() or total <= EPSILON:
		return _pose(route.get("start_position", Vector2.ZERO),
			float(route.get("start_depth", 0.0)), Vector2.UP, 0.0, 0.0)
	var ends: PackedFloat64Array = route.ends
	var index := _lower_bound(ends, travelled)
	var segment: Dictionary = segments[index]
	var distance := clampf(travelled - float(segment.start), 0.0, float(segment.length))
	var weight := distance / float(segment.length)
	if segment.curved:
		var lengths: PackedFloat64Array = segment.arc_lengths
		var step := maxi(1, _lower_bound(lengths, distance))
		var span := lengths[step] - lengths[step - 1]
		var local := (distance - lengths[step - 1]) / maxf(EPSILON, span)
		weight = (float(step - 1) + clampf(local, 0.0, 1.0)) / float(ARC_STEPS)
	var position: Vector2
	var depth: float
	var tangent: Vector2
	if segment.curved:
		position = _quadratic(segment.a, segment.b, segment.c, weight)
		depth = _quadratic(segment.logical_a, segment.logical_b, segment.logical_c, weight).y
		tangent = (segment.b - segment.a).lerp(segment.c - segment.b, weight).normalized()
	else:
		position = segment.a.lerp(segment.c, weight)
		depth = lerpf(segment.logical_a.y, segment.logical_c.y, weight)
		tangent = segment.a.direction_to(segment.c)
	# Preserve exact caller endpoints, including the special entrance anchor.
	if fraction <= 0.0:
		position = route.start_position
		depth = route.start_depth
	elif fraction >= 1.0:
		position = route.end_position
		depth = route.end_depth
	return _pose(position, depth, tangent, travelled, total)

static func _append_segment(route: Dictionary, a: Vector2, b: Vector2, c: Vector2,
		curved: bool, plane: RefCounted, nest: Vector2) -> void:
	var screen_a := _map(a, plane, nest)
	var screen_b := _map(b, plane, nest)
	var screen_c := _map(c, plane, nest)
	_append_mapped_segment(route,screen_a,screen_b,screen_c,a,b,c,curved)

static func _append_mapped_segment(route:Dictionary,screen_a:Vector2,screen_b:Vector2,screen_c:Vector2,
		a:Vector2,b:Vector2,c:Vector2,curved:bool)->void:
	var lengths := PackedFloat64Array([0.0])
	var length := 0.0
	if curved:
		var previous := screen_a
		for step in range(1, ARC_STEPS + 1):
			var point := _quadratic(screen_a, screen_b, screen_c, float(step) / float(ARC_STEPS))
			length += previous.distance_to(point)
			lengths.append(length)
			previous = point
	else:
		length = screen_a.distance_to(screen_c)
	if length <= EPSILON:
		return
	route.segments.append({"a": screen_a, "b": screen_b, "c": screen_c,
		"logical_a": a, "logical_b": b, "logical_c": c,
		"curved": curved, "arc_lengths": lengths, "start": route.total_length, "length": length})
	route.total_length += length
	route.ends.append(route.total_length)

static func _is_nest(cell: Vector2, plane: RefCounted) -> bool:
	return cell == plane.entrance_cell

static func _map(cell: Vector2, plane: RefCounted, nest: Vector2) -> Vector2:
	return plane.center(cell.x, cell.y)

static func _quadratic(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)

static func _lower_bound(values: PackedFloat64Array, target: float) -> int:
	var low := 0
	var high := values.size() - 1
	while low < high:
		var middle := (low + high) / 2
		if values[middle] < target:
			low = middle + 1
		else:
			high = middle
	return low

static func _pose(position: Vector2, depth: float, tangent: Vector2, travelled: float, total: float) -> Dictionary:
	if not tangent.is_finite() or tangent.length_squared() < EPSILON:
		tangent = Vector2.UP
	return {"position": position, "depth_y": depth, "tangent": tangent,
		"heading": tangent.angle(), "travelled": travelled, "total_length": total}

static func _append_screen_leg(route:Dictionary,a:Vector2,c:Vector2,logical:Vector2)->void:
	var length:=a.distance_to(c)
	if length<=EPSILON:return
	route.segments.append({"a":a,"b":a,"c":c,"logical_a":logical,"logical_b":logical,"logical_c":logical,"curved":false,"arc_lengths":PackedFloat64Array([0.0]),"start":route.total_length,"length":length,"entrance":true})
	route.total_length+=length
	route.ends.append(route.total_length)
