class_name RescueRules
extends RefCounted
## Deterministic single-click transport and segmented serpent simulation. No Nodes, callbacks, RNG or save I/O.
## Time is integer microseconds. Only update/update_us advances it; views consume events.
const API_VERSION := "3.1.0"
const TIMEBASE := 1000000
const CARRIER_LIMIT := 4
const NEVER := 9223372036854775807
const DIRECTIONS := [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]

var run_id: int = 0
var time_us: int = 0
var status: String = "unloaded"
var paused: bool = false
var speed_multiplier: int = 1
var ant_loadout:Dictionary={"ant_type":"worker","level":1,"speed_multiplier":1.0}
var threat_started_us:int=-1
var level: Dictionary = {}
var board: Dictionary = {}
var reservations: Dictionary = {}
var tasks: Dictionary = {}
var inventory: Dictionary = {}
var initial_counts: Dictionary = {}
var delivered_counts: Dictionary = {}
var spent_counts: Dictionary = {}
var dispatched_counts: Dictionary = {}
var segments: Array = []
var alive_segment_ids: Array = []
var hit_counts: Dictionary = {}
var shot_counts: Dictionary = {}
var refunded_counts: Dictionary = {}
var projectile: Dictionary = {}
var cooldown_until_us: int = 0
var terminal_time_us: int = -1
var terminal_reason: String = ""
var validation_errors: Array[String] = []
var _events: Array = []
var _event_sequence: int = 0
var _task_sequence: int = 0
var _projectile_sequence: int = 0
var _fractional_us: float = 0.0
var _dragon_anchor_us: int = 0
var _dragon_anchor_position: float = 0.0
var _contact_us: int = NEVER
var _routes: Dictionary = {}
var _routes_dirty: bool = true
var _recoverable_error: bool = false

static func seconds_to_us(seconds: float) -> int:
	return int(round(seconds * TIMEBASE))

static func _is_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))

static func _is_integer(value: Variant) -> bool:
	return _is_number(value) and float(value) == floor(float(value))

static func validate_level(config: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for field in ["palette", "parameters", "serpent", "transport"]:
		if not config.get(field) is Dictionary:
			errors.append(field + " must be an object")
	for field in ["grid", "segments"]:
		if not config.get(field) is Array:
			errors.append(field + " must be an array")
	for field in ["schema_version", "width", "height"]:
		if not _is_integer(config.get(field)):
			errors.append(field + " must be an integer")
	if not errors.is_empty():
		return errors
	if int(config.schema_version) != 3:
		errors.append("schema_version must be 3; automatic-team levels are superseded")
	var width := int(config.width)
	var height := int(config.height)
	if width < 1 or height < 1 or config.grid.size() != height:
		errors.append("grid dimensions are invalid")
	var counts: Dictionary = {}
	for row in config.grid:
		if not row is String:
			errors.append("grid rows must be strings")
			continue
		if row.length() != width:
			errors.append("grid row width mismatch")
		for symbol in row:
			if symbol == ".":
				continue
			if not config.palette.has(symbol) or not config.palette[symbol] is String or str(config.palette[symbol]).is_empty():
				errors.append("unknown board symbol: " + symbol)
				continue
			var color := str(config.palette[symbol])
			counts[color] = int(counts.get(color, 0)) + 1
	if counts.is_empty():
		errors.append("board must contain beads")
	var segment_counts: Dictionary = {}
	var segment_ids: Dictionary = {}
	if config.segments.is_empty():
		errors.append("at least one visible segment is required")
	for segment in config.segments:
		if not segment is Dictionary or not _is_integer(segment.get("hp")):
			errors.append("segment must be an object with integer hp")
			continue
		var segment_id := str(segment.get("id", ""))
		var color := str(segment.get("color", ""))
		if segment_id.is_empty() or segment_ids.has(segment_id):
			errors.append("segment IDs must be nonempty and unique")
		var kind := str(segment.get("kind", "normal"))
		if kind not in ["normal", "armored"] or color.is_empty():
			errors.append("segment kind/color invalid: " + segment_id)
		elif int(segment.hp) != (2 if kind == "armored" else 1):
			errors.append("normal requires HP1; armored requires HP2: " + segment_id)
		segment_ids[segment_id] = true
		segment_counts[color] = int(segment_counts.get(color, 0)) + int(segment.hp)
	var all_colors := counts.duplicate()
	all_colors.merge(segment_counts, false)
	for color in all_colors:
		if int(counts.get(color, 0)) < int(segment_counts.get(color, 0)):
			errors.append("insufficient segment supply: " + str(color))
	var params: Dictionary = config.parameters
	if not _is_number(params.get("projectile_flight_sec")) or float(params.get("projectile_flight_sec", 0)) <= 0.0:
		errors.append("projectile_flight_sec must be finite and positive")
	elif seconds_to_us(float(params.projectile_flight_sec)) < 1:
		errors.append("projectile flight must be at least one microsecond")
	if not _is_number(params.get("cannon_cooldown_sec")) or float(params.get("cannon_cooldown_sec", -1)) < 0:
		errors.append("cannon cooldown must be finite and nonnegative")
	if not _is_integer(params.get("max_inflight_ants")) or int(params.get("max_inflight_ants", 0)) != CARRIER_LIMIT:
		errors.append("current slice requires exactly four transport places")
	var transport: Dictionary = config.transport
	if transport.has("entrance_cell"):
		var entry:Variant=transport.entrance_cell
		if not entry is Array or entry.size()!=2 or not _is_integer(entry[0]) or not _is_integer(entry[1]):
			errors.append("entrance_cell must be two integer coordinates")
		elif int(entry[0]) < -1 or int(entry[0]) > width or int(entry[1]) < -1 or int(entry[1]) > height or (int(entry[0])>=0 and int(entry[0])<width and int(entry[1])>=0 and int(entry[1])<height):
			errors.append("entrance_cell must lie on the exterior transit ring")
	if str(transport.get("carrier_type", "")) != "worker":
		errors.append("current slice supports the basic worker transport only")
	for key in ["outbound_speed_cells_sec", "returning_speed_cells_sec"]:
		if not _is_number(transport.get(key)) or float(transport.get(key, 0)) <= 0.0:
			errors.append(key + " must be finite and positive")
	for key in ["pickup_pause_sec", "unload_pause_sec"]:
		if not _is_number(transport.get(key)) or float(transport.get(key, -1)) < 0.0:
			errors.append(key + " must be finite and nonnegative")
	var serpent: Dictionary = config.serpent
	var serpent_numeric := true
	for key in ["head_start_s", "goal_s", "speed_units_sec", "pitch"]:
		if not _is_number(serpent.get(key)):
			errors.append("serpent parameter must be numeric and finite: " + key)
			serpent_numeric = false
	if serpent_numeric:
		if float(serpent.pitch) <= 0 or float(serpent.speed_units_sec) <= 0:
			errors.append("serpent pitch and speed must be positive")
		if float(serpent.head_start_s) < config.segments.size() * float(serpent.pitch):
			errors.append("head_start_s must hold the complete initial body on the finite route")
		if float(serpent.goal_s) <= float(serpent.head_start_s):
			errors.append("goal_s must be after head_start_s")
	for field in ["production_level_number", "level_number"]:
		if config.get(field) != null and (not _is_integer(config[field]) or int(config[field]) < 1):
			errors.append(field + " must be a positive integer or null")
	return errors

func load_level(config: Dictionary) -> bool:
	run_id += 1
	time_us = 0
	status = "unloaded"
	paused = false
	speed_multiplier = 1
	ant_loadout={"ant_type":"worker","level":1,"speed_multiplier":1.0}
	threat_started_us=-1
	level = config.duplicate(true)
	board.clear()
	reservations.clear()
	tasks.clear()
	inventory.clear()
	initial_counts.clear()
	delivered_counts.clear()
	spent_counts.clear()
	dispatched_counts.clear()
	segments.clear()
	alive_segment_ids.clear()
	hit_counts.clear()
	shot_counts.clear()
	refunded_counts.clear()
	projectile.clear()
	cooldown_until_us = 0
	terminal_time_us = -1
	terminal_reason = ""
	_events.clear()
	_event_sequence = 0
	_task_sequence = 0
	_projectile_sequence = 0
	_fractional_us = 0.0
	_dragon_anchor_us = 0
	_dragon_anchor_position = 0.0
	_contact_us = NEVER
	_routes.clear()
	_routes_dirty = true
	_recoverable_error = false
	validation_errors = validate_level(config)
	if not validation_errors.is_empty():
		status = "load_error"
		_emit("load_error", {"errors": validation_errors.duplicate()})
		return false
	for y in range(int(level.height)):
		var row: String = level.grid[y]
		for x in range(int(level.width)):
			var symbol := row.substr(x, 1)
			if symbol == ".":
				continue
			var color := str(level.palette[symbol])
			var cell_id: int = y * int(level.width) + x
			board[cell_id] = {"id": cell_id, "x": x, "y": y, "color": color}
			initial_counts[color] = int(initial_counts.get(color, 0)) + 1
	for color in initial_counts:
		inventory[color] = 0
		delivered_counts[color] = 0
		spent_counts[color] = 0
		dispatched_counts[color] = 0
	for color in initial_counts:
		hit_counts[color] = 0
		shot_counts[color] = 0
		refunded_counts[color] = 0
	segments = level.segments.duplicate(true)
	for segment in segments:
		segment["kind"] = str(segment.get("kind", "normal"))
		segment["max_hp"] = int(segment.hp)
		alive_segment_ids.append(str(segment.id))
	_dragon_anchor_position = float(level.serpent.head_start_s)
	status = "ready"
	_emit("level_loaded", {"level_id": level.get("level_id", ""), "api_version": API_VERSION})
	return true

func restart() -> bool:
	return load_level(level.duplicate(true))

func available_counts() -> Dictionary:
	# The displayed number is every bead not yet picked up, including reservations.
	var result: Dictionary = {}
	for color in initial_counts:
		result[color] = 0
	for bead in board.values():
		result[bead.color] = int(result[bead.color]) + 1
	return result

func color_states() -> Dictionary:
	var result: Dictionary = {}
	var counts := available_counts()
	for color in initial_counts:
		var reserved := 0
		for cell_id in reservations:
			if board.has(cell_id) and str(board[cell_id].color) == str(color):
				reserved += 1
		var clickable := reachable_cell_ids(str(color)).size()
		var state := "ready"
		if int(counts[color]) == 0:
			state = "collected"
		elif reserved == int(counts[color]):
			state = "all_reserved"
		elif clickable == 0:
			state = "blocked"
		result[color] = {"state": state, "available_count": int(counts[color]), "reserved_count": reserved, "clickable_count": clickable, "capacity_full": tasks.size() >= CARRIER_LIMIT}
	return result

func set_ant_loadout(value:Dictionary)->bool:
	# Equipment is frozen before any successful dispatch. It changes only travel
	# speed, never pickup/unload, capacity, projectile timing or enemy parameters.
	if status!="ready" or not tasks.is_empty() or threat_started_us>=0:return false
	if value.get("ant_type","") not in ["worker","swift"]:return false
	if not _is_number(value.get("speed_multiplier")) or float(value.speed_multiplier)<1.0 or float(value.speed_multiplier)>1.5:return false
	if not _is_integer(value.get("level")) or int(value.level)<1 or int(value.level)>4:return false
	ant_loadout=value.duplicate(true)
	return true

func click_color(color: String) -> Dictionary:
	if paused or status not in ["ready", "running"]:
		return {"ok": false, "reason": "simulation_frozen", "queued": false}
	if not initial_counts.has(color):
		return {"ok": false, "reason": "unknown_color", "queued": false}
	if tasks.size() >= CARRIER_LIMIT:
		return {"ok": false, "reason": "carrier_limit", "queued": false}
	var target := best_target(color)
	if target.is_empty():
		return {"ok": false, "reason": "color_" + str(color_states()[color].state), "queued": false}
	if status == "ready":
		status = "running"
		threat_started_us=time_us
		_dragon_anchor_us = time_us
		_recompute_contact()
		_emit("dragon_started", {"head_s": head_s(), "goal_s": float(level.serpent.goal_s)})
	_task_sequence += 1
	var efficiency:float=float(ant_loadout.speed_multiplier)
	var outbound_us := maxi(1, int(ceil(float(target.distance) / (float(level.transport.outbound_speed_cells_sec)*efficiency) * TIMEBASE)))
	var return_us := maxi(1, int(ceil(float(target.distance) / (float(level.transport.returning_speed_cells_sec)*efficiency) * TIMEBASE)))
	var pickup_us := time_us + outbound_us
	var return_depart_us := pickup_us + seconds_to_us(float(level.transport.pickup_pause_sec))
	var unload_us := return_depart_us + return_us
	var task := {"id": _task_sequence, "run_id": run_id, "carrier_type": "worker", "color": color, "cell_id": int(target.cell_id), "path": target.path.duplicate(true), "distance_cells": int(target.distance), "depart_us": time_us, "pickup_us": pickup_us, "return_depart_us": return_depart_us, "unload_us": unload_us, "delivery_us": unload_us + seconds_to_us(float(level.transport.unload_pause_sec)), "leg_duration_us": outbound_us, "outbound_duration_us": outbound_us, "return_duration_us": return_us, "stage": "outbound"}
	task.carrier_type=ant_loadout.ant_type
	task.speed_multiplier=efficiency
	# One accepted click -> exactly one reservation and one task. No queue or timer.
	reservations[task.cell_id] = task.id
	dispatched_counts[color] = int(dispatched_counts[color]) + 1
	tasks[task.id] = task
	_emit("color_clicked", {"color": color, "task_id": task.id, "carrier_count": tasks.size(), "carrier_limit": CARRIER_LIMIT})
	_emit("target_reserved", _task_event(task))
	_emit("ant_dispatched", _task_event(task))
	return {"ok": true, "task_id": task.id, "cell_id": task.cell_id, "color": color, "run_id": run_id, "queued": false}

func select_team(_team_id: String) -> Dictionary:
	return {"ok": false, "reason": "automatic_team_dispatch_removed", "queued": false}

func select_front(_team_id: Variant, _expected_team_id: String = "") -> Dictionary:
	return {"ok": false, "reason": "automatic_team_dispatch_removed", "queued": false}

func set_paused(value: bool) -> void:
	if status not in ["ready", "running"] or paused == value:
		return
	paused = value
	# Any pause, including a modal/focus loss, returns to normal speed.
	if paused:
		speed_multiplier = 1
	_emit("pause_changed", {"paused": paused, "speed_multiplier": speed_multiplier})

func set_speed(multiplier: int) -> bool:
	if multiplier not in [1, 2] or paused or status not in ["ready", "running"]:
		return false
	speed_multiplier = multiplier
	_emit("speed_changed", {"speed_multiplier": multiplier})
	return true

func update(real_delta_sec: float) -> void:
	if paused or status != "running" or not is_finite(real_delta_sec) or real_delta_sec <= 0.0:
		return
	var exact := real_delta_sec * TIMEBASE * speed_multiplier + _fractional_us
	var elapsed := int(floor(exact + 0.00000001))
	_fractional_us = exact - elapsed
	_advance_to(time_us + elapsed)

func update_us(real_delta_us: int) -> void:
	if paused or status != "running" or real_delta_us <= 0:
		return
	_advance_to(time_us + real_delta_us * speed_multiplier)

func _advance_to(target_us: int) -> void:
	while status == "running" and not paused:
		var due := _next_event_time()
		if due > target_us:
			time_us = target_us
			break
		time_us = due
		_process_current_time()

func _next_event_time() -> int:
	var due: int = _contact_us
	if not projectile.is_empty():
		due = mini(due, int(projectile.hit_us))
	for task in tasks.values():
		var task_due: int = int(task.pickup_us) if task.stage == "outbound" else (int(task.unload_us) if task.stage == "returning" else int(task.delivery_us))
		due = mini(due, task_due)
	if projectile.is_empty() and not next_fire_target().is_empty():
		due = mini(due, maxi(time_us, cooldown_until_us))
	return due

func _process_current_time() -> void:
	if status != "running" or paused:
		return
	# Exact-time priority: scheduled hit, contact, pickup/unload/delivery, fire.
	# A later hit in the same update() never runs after an earlier contact failure.
	if not projectile.is_empty() and int(projectile.hit_us) <= time_us:
		_hit_projectile()
	if status != "running":
		return
	if _contact_us <= time_us:
		_finish("defeat", "dragon_contact")
		return
	var task_ids := tasks.keys()
	task_ids.sort()
	for task_id in task_ids:
		if not tasks.has(task_id):
			continue
		var task: Dictionary = tasks[task_id]
		if int(task.run_id) != run_id:
			continue
		if task.stage == "outbound" and int(task.pickup_us) <= time_us:
			if not board.has(task.cell_id) or int(reservations.get(task.cell_id, -1)) != int(task.id):
				_transport_error("reserved bead missing at pickup", task)
				return
			board.erase(task.cell_id)
			reservations.erase(task.cell_id)
			task.stage = "returning"
			_routes_dirty = true
			_emit("bead_picked_up", _task_event(task))
		if task.stage == "returning" and int(task.unload_us) <= time_us:
			task.stage = "unloading"
			_emit("bead_unloading", _task_event(task))
		if task.stage == "unloading" and int(task.delivery_us) <= time_us:
			inventory[task.color] = int(inventory[task.color]) + 1
			delivered_counts[task.color] = int(delivered_counts[task.color]) + 1
			tasks.erase(task_id)
			_emit("bead_delivered", _task_event(task))
	_check_fire()


func best_target(color: String) -> Dictionary:
	_ensure_routes()
	var best: Dictionary = {}
	for cell_id in _routes:
		if reservations.has(cell_id) or str(board[cell_id].color) != color:
			continue
		var route: Dictionary = _routes[cell_id]
		if best.is_empty() or int(route.distance) < int(best.distance) or (int(route.distance) == int(best.distance) and int(cell_id) < int(best.cell_id)):
			best = {"cell_id": int(cell_id), "distance": int(route.distance), "path": route.path}
	return best.duplicate(true)

func reachable_cell_ids(color: String = "", include_reserved: bool = false) -> Array:
	_ensure_routes()
	var result: Array = []
	for cell_id in _routes:
		if (color.is_empty() or str(board[cell_id].color) == color) and (include_reserved or not reservations.has(cell_id)):
			result.append(int(cell_id))
	result.sort()
	return result

func _ensure_routes() -> void:
	if not _routes_dirty:
		return
	_routes.clear()
	_routes_dirty = false
	if level.is_empty() or status in ["unloaded", "load_error"]:
		return
	var width := int(level.width)
	var height := int(level.height)
	# The one-cell exterior ring is connected to every board edge, including the top.
	var entrance:Array=level.transport.get("entrance_cell",[width/2,height])
	var origin := Vector2i(int(entrance[0]),int(entrance[1]))
	var queue: Array[Vector2i] = [origin]
	var distances: Dictionary = {origin: 0}
	var parents: Dictionary = {}
	var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]
		cursor += 1
		for direction in DIRECTIONS:
			var next: Vector2i = cell + direction
			if next.x < -1 or next.x > width or next.y < -1 or next.y > height:
				continue
			var next_id := next.y * width + next.x
			var in_board := next.x >= 0 and next.x < width and next.y >= 0 and next.y < height
			if in_board and board.has(next_id):
				if not _routes.has(next_id):
					var reverse_path: Array = [[next.x, next.y]]
					var back := cell
					reverse_path.append([back.x, back.y])
					while back != origin:
						back = parents[back]
						reverse_path.append([back.x, back.y])
					reverse_path.reverse()
					_routes[next_id] = {"distance": int(distances[cell]) + 1, "path": reverse_path}
				continue
			if distances.has(next):
				continue
			distances[next] = int(distances[cell]) + 1
			parents[next] = cell
			queue.append(next)


func get_segment(segment_id: String) -> Dictionary:
	for segment in segments:
		if str(segment.id) == segment_id:
			return segment
	return {}

func frontmost_segment_for_color(color: String) -> Dictionary:
	for segment_id in alive_segment_ids:
		var segment := get_segment(str(segment_id))
		if str(segment.color) == color and int(segment.hp) > 0:
			return segment.duplicate(true)
	return {}

func next_fire_target() -> Dictionary:
	# All stock colors compete. The frontmost live legal segment wins; a headward
	# segment without matching stock never blocks another color farther back.
	for segment_id in alive_segment_ids:
		var segment := get_segment(str(segment_id))
		if int(segment.hp) > 0 and int(inventory.get(segment.color, 0)) > 0:
			return segment.duplicate(true)
	return {}

func _check_fire() -> void:
	if status != "running" or not projectile.is_empty() or time_us < cooldown_until_us:
		return
	var target := next_fire_target()
	if target.is_empty():
		return
	var color := str(target.color)
	inventory[color] = int(inventory[color]) - 1
	spent_counts[color] = int(spent_counts[color]) + 1
	shot_counts[color] = int(shot_counts[color]) + 1
	cooldown_until_us = time_us + seconds_to_us(float(level.parameters.get("cannon_cooldown_sec", 0.0)))
	_projectile_sequence += 1
	projectile = {"id": _projectile_sequence, "run_id": run_id, "target_segment_id": str(target.id), "color": color, "amount": 1, "flight_us": seconds_to_us(float(level.parameters.projectile_flight_sec)), "fire_us": time_us, "hit_us": time_us + seconds_to_us(float(level.parameters.projectile_flight_sec))}
	_emit("cannon_fired", projectile.duplicate(true))

func _refund_projectile(reason: String) -> void:
	if projectile.is_empty() or int(projectile.run_id) != run_id or status != "running":
		return
	var refund := projectile.duplicate(true)
	projectile.clear() # Clear first, so repeat invalidations cannot refund twice.
	var color := str(refund.color)
	inventory[color] = int(inventory[color]) + 1
	spent_counts[color] = int(spent_counts[color]) - 1
	refunded_counts[color] = int(refunded_counts[color]) + 1
	refund["reason"] = reason
	_emit("projectile_refunded", refund)

func _hit_projectile() -> void:
	if projectile.is_empty() or status != "running":
		return
	if int(projectile.run_id) != run_id:
		# Stale events never spend, refund, damage or terminate a newer run.
		projectile.clear()
		return
	var segment := get_segment(str(projectile.target_segment_id))
	if segment.is_empty() or int(segment.hp) <= 0 or not alive_segment_ids.has(str(projectile.target_segment_id)):
		_refund_projectile("target_no_longer_alive")
		return
	var hit := projectile.duplicate(true)
	projectile.clear()
	hit_counts[hit.color] = int(hit_counts[hit.color]) + 1
	_apply_segment_hit(str(hit.target_segment_id), "projectile", hit)

func apply_external_hit(segment_id: String, event_run_id: int) -> Dictionary:
	# Narrow extension/test hook. No current tool or presentation invokes this.
	# It cannot apply old-run, paused, terminal, duplicate or unknown hits.
	if event_run_id != run_id or paused or status != "running":
		return {"ok": false, "reason": "stale_or_frozen_event"}
	var segment := get_segment(segment_id)
	if segment.is_empty() or not alive_segment_ids.has(segment_id) or int(segment.hp) <= 0:
		return {"ok": false, "reason": "segment_not_alive"}
	return _apply_segment_hit(segment_id, "external", {})

func _apply_segment_hit(segment_id: String, source: String, context: Dictionary) -> Dictionary:
	var segment := get_segment(segment_id)
	var old_rank := alive_segment_ids.find(segment_id)
	if old_rank < 0 or segment.is_empty() or int(segment.hp) <= 0:
		return {"ok": false, "reason": "segment_not_alive"}
	segment.hp = int(segment.hp) - 1
	var payload := context.duplicate(true)
	payload.merge({"segment_id": segment_id, "target_segment_id": segment_id, "color": str(segment.color), "hp": int(segment.hp), "max_hp": int(segment.max_hp), "kind": str(segment.kind), "source": source, "head_s": head_s(), "target_s": head_s() - (old_rank + 1) * float(level.serpent.pitch), "projectile_id": int(context.get("id", -1)), "former_rank": old_rank}, true)
	_emit("segment_hit", payload)
	if int(segment.hp) == 0:
		alive_segment_ids.remove_at(old_rank)
		payload["alive_segment_ids"] = alive_segment_ids.duplicate()
		payload["alive_count"] = alive_segment_ids.size()
		_emit("segment_removed", payload)
	# An external hit can invalidate the stable target, never retarget by index.
	if int(segment.hp) == 0 and not projectile.is_empty() and str(projectile.target_segment_id) == segment_id:
		_refund_projectile("target_no_longer_alive")
	if alive_segment_ids.is_empty():
		_finish("victory", "final_segment_hit")
	return {"ok": true, "segment_id": segment_id, "hp": int(segment.hp)}

func head_s() -> float:
	if level.is_empty() or status in ["unloaded", "load_error"] or not level.get("serpent") is Dictionary:
		return 0.0
	if status == "ready":
		return _dragon_anchor_position
	return minf(float(level.serpent.goal_s), _dragon_anchor_position + float(time_us - _dragon_anchor_us) / TIMEBASE * float(level.serpent.speed_units_sec))

func dragon_position() -> float:
	# Compatibility alias: absolute head progress on the finite route, not HP.
	return head_s()

func segment_positions() -> Dictionary:
	var result: Dictionary = {}
	for rank in range(alive_segment_ids.size()):
		result[str(alive_segment_ids[rank])] = head_s() - (rank + 1) * float(level.serpent.pitch)
	return result

func _recompute_contact() -> void:
	var remaining: float = float(level.serpent.goal_s) - _dragon_anchor_position
	_contact_us = _dragon_anchor_us + int(ceil(remaining / float(level.serpent.speed_units_sec) * TIMEBASE - 0.000001))

func _finish(result: String, reason: String) -> void:
	if status != "running":
		return
	status = result
	terminal_time_us = time_us
	terminal_reason = reason
	_emit(result, {"reason": reason, "alive_segment_ids": alive_segment_ids.duplicate(), "alive_count": alive_segment_ids.size(), "head_s": head_s(), "dragon_position": head_s()})

func _transport_error(reason: String, task: Dictionary) -> void:
	_recoverable_error = true
	paused = true
	speed_multiplier = 1
	_emit("recoverable_error", {"reason": reason, "task_id": task.get("id", -1), "recovery": "retry_or_restart"})

func accepts_callback(callback_run_id: int) -> bool:
	# Presentation callbacks never settle rules; this guard prevents stale effects.
	return callback_run_id == run_id and status in ["ready", "running"] and not paused

func tool_states() -> Array:
	return [] # Queue-slot tools are not part of the click-one core.

func request_tool(_tool_id: String, _payload: Dictionary = {}) -> Dictionary:
	return {"ok": false, "reason": "tool_unavailable", "consumed": false}

func replay_state() -> Dictionary:
	# Capture every script variable, including cached routes, event queues, integer
	# deadlines, RNG-free counters and fractional time. No public restore API.
	var result: Dictionary = {}
	for property in get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value: Variant = get(property.name)
			result[property.name] = value.duplicate(true) if value is Dictionary or value is Array else value
	return result

func duplicate_for_replay():
	var copy = get_script().new()
	var state := replay_state()
	for field in state:
		copy.set(field, state[field])
	return copy

func _task_event(task: Dictionary) -> Dictionary:
	return task.duplicate(true)

func _emit(type: String, payload: Dictionary = {}) -> void:
	_event_sequence += 1
	var event := payload.duplicate(true)
	event["type"] = type
	event["time_us"] = time_us
	event["time_sec"] = float(time_us) / TIMEBASE
	event["run_id"] = run_id
	event["sequence"] = _event_sequence
	_events.append(event)

func drain_events() -> Array:
	var result := _events
	_events = []
	return result

func conservation_errors() -> Array[String]:
	var errors: Array[String] = []
	for color in initial_counts:
		var on_board := 0
		var returning := 0
		var outbound := 0
		for bead in board.values():
			if bead.color == color:
				on_board += 1
		for task in tasks.values():
			if task.color == color:
				if task.stage in ["returning", "unloading"]:
					returning += 1
				elif task.stage == "outbound":
					outbound += 1
		if int(initial_counts[color]) != on_board + returning + int(delivered_counts[color]):
			errors.append("board/returning/delivered: " + str(color))
		if int(delivered_counts[color]) != int(inventory[color]) + int(spent_counts[color]):
			errors.append("inventory/spent: " + str(color))
		if int(dispatched_counts[color]) != outbound + returning + int(delivered_counts[color]):
			errors.append("dispatched/tasks/delivered: " + str(color))
		var in_projectile := 1 if not projectile.is_empty() and str(projectile.color) == str(color) else 0
		if int(spent_counts[color]) != int(hit_counts[color]) + in_projectile:
			errors.append("spent/hit/projectile: " + str(color))
		if int(shot_counts[color]) != int(spent_counts[color]) + int(refunded_counts[color]):
			errors.append("shots/spent/refunded: " + str(color))
		if int(inventory[color]) < 0:
			errors.append("negative resource: " + str(color))
	for cell_id in reservations:
		if not board.has(cell_id) or not tasks.has(reservations[cell_id]):
			errors.append("invalid reservation: " + str(cell_id))
		elif int(tasks[reservations[cell_id]].cell_id) != int(cell_id) or str(tasks[reservations[cell_id]].stage) != "outbound":
			errors.append("reservation/task mismatch: " + str(cell_id))
	for task in tasks.values():
		if int(task.run_id) != run_id:
			errors.append("stale transport task: " + str(task.id))
		if task.stage == "outbound" and int(reservations.get(task.cell_id, -1)) != int(task.id):
			errors.append("outbound task missing exclusive reservation: " + str(task.id))
	if tasks.size() > CARRIER_LIMIT:
		errors.append("transport capacity exceeded")
	return errors

func snapshot() -> Dictionary:
	var states := color_states()
	var clickable: Dictionary = {}
	var reserved: Dictionary = {}
	for color in states:
		clickable[color] = int(states[color].clickable_count)
		reserved[color] = int(states[color].reserved_count)
	return {"api_version": API_VERSION, "run_id": run_id, "level_id": level.get("level_id", ""), "time_us": time_us, "time_sec": float(time_us) / TIMEBASE, "status": status, "paused": paused, "speed_multiplier": speed_multiplier, "board": board.duplicate(true), "reservations": reservations.duplicate(true), "tasks": tasks.duplicate(true), "available_counts": available_counts(), "clickable_counts": clickable, "reserved_counts": reserved, "color_states": states, "carrier_count": tasks.size(), "carrier_limit": CARRIER_LIMIT, "capacity_full": tasks.size() >= CARRIER_LIMIT, "inventory": inventory.duplicate(true), "initial_counts": initial_counts.duplicate(), "delivered_counts": delivered_counts.duplicate(), "spent_counts": spent_counts.duplicate(), "dispatched_counts": dispatched_counts.duplicate(), "shot_counts": shot_counts.duplicate(), "hit_counts": hit_counts.duplicate(), "refunded_counts": refunded_counts.duplicate(), "segments": segments.duplicate(true), "alive_segment_ids": alive_segment_ids.duplicate(), "alive_count": alive_segment_ids.size(), "segment_s": segment_positions(), "segment_pitch": float(level.get("serpent", {}).get("pitch", 0)), "head_s": head_s(), "goal_s": float(level.get("serpent", {}).get("goal_s", 0)), "head_start_s": float(level.get("serpent", {}).get("head_start_s", 0)), "projectile": projectile.duplicate(true), "cooldown_until_us": cooldown_until_us, "dragon_position": head_s(), "dragon_contact_us": _contact_us, "terminal_time_us": terminal_time_us, "terminal_reason": terminal_reason, "tools": [], "validation_errors": validation_errors.duplicate()}
