class_name RescueRules
extends RefCounted
## Deterministic simulation and conserving tools. No Nodes, callbacks, RNG or save I/O.
## Time is integer microseconds. Only update/update_us advances it; views consume events.
const API_VERSION := "1.2.0"
const ToolSolver = preload("res://scripts/rescue_tool_solver.gd")
const DEFAULT_TOOLS := [
	{"id": "extra_slot", "unlock_level": 3, "uses_per_level": 1},
	{"id": "shuffle", "unlock_level": 6, "uses_per_level": 1},
	{"id": "recall", "unlock_level": 9, "uses_per_level": 1},
	{"id": "scout", "unlock_level": 16, "uses_per_level": 1}
]
const TIMEBASE := 1000000
const INITIAL_SLOTS := 5
const NEVER := 9223372036854775807
const DIRECTIONS := [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]

var run_id: int = 0
var time_us: int = 0
var status: String = "unloaded"
var paused: bool = false
var speed_multiplier: int = 1
var level: Dictionary = {}
var board: Dictionary = {}
var reservations: Dictionary = {}
var columns: Array = []
var slots: Array = []
var tasks: Dictionary = {}
var inventory: Dictionary = {}
var initial_counts: Dictionary = {}
var delivered_counts: Dictionary = {}
var spent_counts: Dictionary = {}
var dispatched_counts: Dictionary = {}
var armors: Array = []
var armor_index: int = 0
var projectile: Dictionary = {}
var cooldown_until_us: int = 0
var terminal_time_us: int = -1
var terminal_reason: String = ""
var validation_errors: Array[String] = []
var _events: Array = []
var _event_sequence: int = 0
var _task_sequence: int = 0
var _projectile_sequence: int = 0
var _round_robin_slot: int = 0
var _next_dispatch_us: int = NEVER
var _dispatch_ready_us: int = 0
var _fractional_us: float = 0.0
var _dragon_anchor_us: int = 0
var _dragon_anchor_position: float = 0.0
var _contact_us: int = NEVER
var _routes: Dictionary = {}
var _routes_dirty: bool = true
var _blocked: bool = false
var tool_uses: Dictionary = {}
var _tool_selection: Dictionary = {}
var _tool_selection_sequence: int = 0
var _recoverable_error: bool = false

static func seconds_to_us(seconds: float) -> int:
	return int(round(seconds * TIMEBASE))

static func _is_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))

static func _is_integer(value: Variant) -> bool:
	return _is_number(value) and float(value) == floor(float(value))

static func validate_level(config: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	# Reject malformed JSON structure before typed reads or nested field access.
	for field in ["palette", "parameters", "dragon"]:
		if not config.get(field) is Dictionary:
			errors.append(field + " must be an object")
	for field in ["grid", "columns", "armors"]:
		if not config.get(field) is Array:
			errors.append(field + " must be an array")
	for field in ["schema_version", "width", "height"]:
		if not _is_integer(config.get(field)):
			errors.append(field + " must be an integer")
	if not errors.is_empty():
		return errors
	for field in ["dispatch_interval_sec", "transport_speed_cells_sec", "projectile_flight_sec", "cannon_cooldown_sec", "max_inflight_ants"]:
		if not _is_number(config.parameters.get(field)):
			errors.append("parameter must be numeric: " + field)
	for field in ["transport_min_leg_sec", "pickup_pause_sec"]:
		if config.parameters.has(field) and not _is_number(config.parameters[field]):
			errors.append("optional parameter must be numeric and finite: " + field)
	for field in ["route_length", "speed_units_sec", "knockback_distance", "max_knockback_distance"]:
		if not _is_number(config.dragon.get(field)):
			errors.append("dragon parameter must be numeric: " + field)
	if config.dragon.has("initial_position") and not _is_number(config.dragon.initial_position):
		errors.append("dragon initial_position must be numeric")
	if not errors.is_empty():
		return errors
	if int(config.get("schema_version", 0)) != 1:
		errors.append("schema_version must be 1")
	var width := int(config.get("width", 0))
	var height := int(config.get("height", 0))
	var grid: Array = config.get("grid", [])
	var palette: Dictionary = config.get("palette", {})
	if width < 1 or height < 1 or grid.size() != height:
		errors.append("grid dimensions are invalid")
	var counts: Dictionary = {}
	for row_value in grid:
		if not row_value is String:
			errors.append("grid rows must be strings")
			continue
		var row := str(row_value)
		if row.length() != width:
			errors.append("grid row width mismatch")
		for symbol in row:
			if symbol == ".":
				continue
			if not palette.has(symbol) or not palette[symbol] is String or str(palette[symbol]).is_empty():
				errors.append("unknown board symbol: " + symbol)
				continue
			var color := str(palette[symbol])
			counts[color] = int(counts.get(color, 0)) + 1
	if counts.is_empty():
		errors.append("board must contain beads")
	var team_counts: Dictionary = {}
	var team_ids: Dictionary = {}
	var column_ids: Dictionary = {}
	for column in config.get("columns", []):
		if not column is Dictionary or not column.get("teams") is Array:
			errors.append("column must be an object with a teams array")
			continue
		var column_id := str(column.get("id", ""))
		if column_id.is_empty() or column_ids.has(column_id):
			errors.append("column IDs must be nonempty and unique")
		column_ids[column_id] = true
		for team in column.get("teams", []):
			if not team is Dictionary or not _is_integer(team.get("quota")):
				errors.append("team must be an object with an integer quota")
				continue
			var team_id := str(team.get("id", ""))
			var color := str(team.get("color", ""))
			var quota := int(team.get("quota", 0))
			if team_id.is_empty() or team_ids.has(team_id):
				errors.append("team IDs must be nonempty and unique")
			if quota < 1:
				errors.append("team quota must be positive: " + team_id)
			team_ids[team_id] = true
			team_counts[color] = int(team_counts.get(color, 0)) + quota
	var armor_counts: Dictionary = {}
	var armor_ids: Dictionary = {}
	for armor in config.get("armors", []):
		if not armor is Dictionary or not _is_integer(armor.get("demand")):
			errors.append("armor must be an object with an integer demand")
			continue
		var armor_id := str(armor.get("id", ""))
		var color := str(armor.get("color", ""))
		var demand := int(armor.get("demand", 0))
		if armor_id.is_empty() or armor_ids.has(armor_id):
			errors.append("armor IDs must be nonempty and unique")
		if demand < 1:
			errors.append("armor demand must be positive: " + armor_id)
		armor_ids[armor_id] = true
		armor_counts[color] = int(armor_counts.get(color, 0)) + demand
	var all_colors: Dictionary = counts.duplicate()
	all_colors.merge(team_counts, false)
	all_colors.merge(armor_counts, false)
	for color in all_colors:
		if int(counts.get(color, 0)) != int(team_counts.get(color, 0)) or int(counts.get(color, 0)) != int(armor_counts.get(color, 0)):
			errors.append("color conservation mismatch: " + str(color))
	var params: Dictionary = config.get("parameters", {})
	for key in ["dispatch_interval_sec", "transport_speed_cells_sec", "projectile_flight_sec"]:
		var value := float(params.get(key, 0.0))
		if not is_finite(value) or value <= 0.0 or (key != "transport_speed_cells_sec" and seconds_to_us(value) < 1):
			errors.append(key + " must be finite and positive")
	for key in ["transport_min_leg_sec", "pickup_pause_sec"]:
		if float(params.get(key, 0.0)) < 0.0:
			errors.append(key + " must be finite and nonnegative")
	var cooldown := float(params.get("cannon_cooldown_sec", -1.0))
	if not is_finite(cooldown) or cooldown < 0.0:
		errors.append("cannon_cooldown_sec must be finite and nonnegative")
	if not _is_integer(params.get("max_inflight_ants")) or int(params.get("max_inflight_ants", 0)) < 1:
		errors.append("max_inflight_ants must be positive")
	var dragon: Dictionary = config.get("dragon", {})
	for key in ["route_length", "speed_units_sec"]:
		if not is_finite(float(dragon.get(key, 0))) or float(dragon.get(key, 0)) <= 0.0:
			errors.append("dragon " + key + " must be finite and positive")
	for key in ["knockback_distance", "max_knockback_distance"]:
		if not is_finite(float(dragon.get(key, -1))) or float(dragon.get(key, -1)) < 0.0:
			errors.append("dragon " + key + " must be finite and nonnegative")
	var initial_position := float(dragon.get("initial_position", 0.0))
	if not is_finite(initial_position) or initial_position < 0.0 or initial_position >= float(dragon.get("route_length", 0)):
		errors.append("dragon initial_position must lie before the princess")
	if config.has("tools") and not config.tools is Array:
		errors.append("tools must be an array")
	elif config.has("tools"):
		var seen_tools: Dictionary = {}
		for tool in config.tools:
			if not tool is Dictionary:
				errors.append("tool must be an object")
				continue
			var tool_id := str(tool.get("id", ""))
			if tool_id not in ["extra_slot", "shuffle", "recall", "scout"] or seen_tools.has(tool_id):
				errors.append("tool IDs must be known and unique")
			seen_tools[tool_id] = true
			if not _is_integer(tool.get("unlock_level")) or int(tool.get("unlock_level", 0)) < 1:
				errors.append("tool unlock_level must be a positive integer")
			if not _is_integer(tool.get("uses_per_level")) or int(tool.get("uses_per_level", 0)) != 1:
				errors.append("tools must have exactly one use per level")
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
	level = config.duplicate(true)
	board.clear()
	reservations.clear()
	columns.clear()
	slots.clear()
	slots.resize(INITIAL_SLOTS)
	tasks.clear()
	inventory.clear()
	initial_counts.clear()
	delivered_counts.clear()
	spent_counts.clear()
	dispatched_counts.clear()
	armors.clear()
	armor_index = 0
	projectile.clear()
	cooldown_until_us = 0
	terminal_time_us = -1
	terminal_reason = ""
	_events.clear()
	_event_sequence = 0
	_task_sequence = 0
	_projectile_sequence = 0
	_round_robin_slot = 0
	_next_dispatch_us = NEVER
	_dispatch_ready_us = 0
	_fractional_us = 0.0
	_dragon_anchor_us = 0
	_dragon_anchor_position = 0.0
	_contact_us = NEVER
	_routes.clear()
	_routes_dirty = true
	_blocked = false
	tool_uses.clear()
	_tool_selection.clear()
	_tool_selection_sequence = 0
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
	for source in level.columns:
		var column := {"id": str(source.id), "teams": []}
		for original_team in source.teams:
			var team: Dictionary = original_team.duplicate(true)
			team["remaining"] = int(team.quota)
			team["source_column"] = column.id
			team["work_state"] = "candidate"
			column.teams.append(team)
		columns.append(column)
	armors = level.armors.duplicate(true)
	_dragon_anchor_position = float(level.dragon.get("initial_position", 0.0))
	status = "ready"
	_emit("level_loaded", {"level_id": level.get("level_id", ""), "api_version": API_VERSION})
	return true

func restart() -> bool:
	return load_level(level.duplicate(true))

func select_front(column_id: Variant, expected_team_id: String = "") -> Dictionary:
	if paused or status not in ["ready", "running"]:
		return {"ok": false, "reason": "simulation_frozen"}
	var column_index := -1
	if column_id is int:
		column_index = int(column_id)
	else:
		for i in range(columns.size()):
			if str(columns[i].id) == str(column_id):
				column_index = i
				break
	if column_index < 0 or column_index >= columns.size():
		return {"ok": false, "reason": "unknown_column"}
	var column: Dictionary = columns[column_index]
	if column.teams.is_empty():
		return {"ok": false, "reason": "empty_column"}
	if not expected_team_id.is_empty() and str(column.teams[0].id) != expected_team_id:
		return {"ok": false, "reason": "not_front_or_stale_input"}
	var free_slot := slots.find(null)
	if free_slot < 0:
		return {"ok": false, "reason": "slots_full"}
	var team: Dictionary = column.teams.pop_front()
	# After a shuffle, origin means the actual column this dispatch came from.
	team.source_column = column.id
	team.work_state = "working"
	slots[free_slot] = team
	_emit("team_selected", {"team_id": team.id, "color": team.color, "remaining": team.remaining, "slot": free_slot, "column_id": column.id})
	if status == "ready":
		status = "running"
		_dragon_anchor_us = time_us
		_recompute_contact()
		_emit("dragon_started")
	if _next_dispatch_us == NEVER:
		_next_dispatch_us = maxi(time_us, _dispatch_ready_us)
	_process_current_time()
	return {"ok": true, "team_id": team.id, "slot": free_slot, "run_id": run_id}

func set_paused(value: bool) -> void:
	if status not in ["ready", "running"] or paused == value:
		return
	paused = value
	_tool_selection.clear()
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
	var due: int = mini(_next_dispatch_us, _contact_us)
	if not projectile.is_empty():
		due = mini(due, int(projectile.hit_us))
	for task in tasks.values():
		due = mini(due, int(task.pickup_us if task.stage == "outbound" else task.delivery_us))
	if projectile.is_empty() and armor_index < armors.size():
		var armor: Dictionary = armors[armor_index]
		if int(inventory.get(armor.color, 0)) >= int(armor.demand):
			due = mini(due, maxi(time_us, cooldown_until_us))
	return due

func _process_current_time() -> void:
	if status != "running" or paused:
		return
	# Exact-time priority: scheduled hit, contact, pickup/delivery, dispatch, fire.
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
		if task.stage == "returning" and int(task.delivery_us) <= time_us:
			inventory[task.color] = int(inventory[task.color]) + 1
			delivered_counts[task.color] = int(delivered_counts[task.color]) + 1
			tasks.erase(task_id)
			_emit("bead_delivered", _task_event(task))
	if _next_dispatch_us <= time_us:
		_dispatch_tick()
	_check_fire()
	_refresh_waiting_and_blockage()

func _dispatch_tick() -> void:
	_dispatch_ready_us = time_us + seconds_to_us(float(level.parameters.dispatch_interval_sec))
	_next_dispatch_us = _dispatch_ready_us
	if tasks.size() >= int(level.parameters.max_inflight_ants):
		return
	for offset in range(slots.size()):
		var slot_index := (_round_robin_slot + offset) % slots.size()
		if slots[slot_index] == null:
			continue
		var team: Dictionary = slots[slot_index]
		var target := best_target(str(team.color))
		if target.is_empty():
			continue
		_task_sequence += 1
		# Authored readability is simulation time, never delayed animation settlement.
		# Omitted optional values preserve legacy fixture timing.
		var travel_sec := maxf(float(target.distance) / float(level.parameters.transport_speed_cells_sec), float(level.parameters.get("transport_min_leg_sec", 0.0)))
		var travel_us: int = maxi(1, int(ceil(travel_sec * TIMEBASE)))
		var pickup_pause_us := seconds_to_us(float(level.parameters.get("pickup_pause_sec", 0.0)))
		var task := {"id": _task_sequence, "run_id": run_id, "team_id": team.id, "source_column": team.source_column, "slot": slot_index, "color": str(team.color), "cell_id": int(target.cell_id), "path": target.path.duplicate(true), "depart_us": time_us, "pickup_us": time_us + travel_us, "return_depart_us": time_us + travel_us + pickup_pause_us, "leg_duration_us": travel_us, "delivery_us": time_us + travel_us * 2 + pickup_pause_us, "stage": "outbound"}
		# Quota debit and exclusive reservation are one atomic transition.
		reservations[task.cell_id] = task.id
		team.remaining = int(team.remaining) - 1
		dispatched_counts[team.color] = int(dispatched_counts[team.color]) + 1
		tasks[task.id] = task
		_round_robin_slot = (slot_index + 1) % slots.size()
		_emit("target_reserved", _task_event(task))
		var payload := _task_event(task)
		payload["team_remaining"] = team.remaining
		_emit("ant_dispatched", payload)
		if int(team.remaining) == 0:
			slots[slot_index] = null
			_emit("slot_released", {"slot": slot_index, "team_id": team.id, "color": team.color})
		break
	if slots.all(func(value: Variant) -> bool: return value == null):
		_next_dispatch_us = NEVER

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
	var origin := Vector2i(width / 2, height)
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

func _refresh_waiting_and_blockage() -> void:
	var any_dispatchable := false
	for slot_index in range(slots.size()):
		if slots[slot_index] == null:
			continue
		var team: Dictionary = slots[slot_index]
		var available := not best_target(str(team.color)).is_empty()
		any_dispatchable = any_dispatchable or available
		var new_state := "working" if available else "waiting_target"
		if available and tasks.size() >= int(level.parameters.max_inflight_ants):
			new_state = "waiting_capacity"
		if team.work_state != new_state:
			team.work_state = new_state
			_emit("team_work_state", {"team_id": team.id, "slot": slot_index, "state": new_state})
	var can_fire := false
	if armor_index < armors.size():
		var current: Dictionary = armors[armor_index]
		can_fire = int(inventory.get(current.color, 0)) >= int(current.demand)
	var full := slots.find(null) < 0
	var truly_blocked := full and not any_dispatchable and tasks.is_empty() and projectile.is_empty() and not can_fire
	if truly_blocked != _blocked:
		_blocked = truly_blocked
		_emit("blocked_changed", {"blocked": _blocked, "reason": "no_progress_with_full_slots" if _blocked else "progress_possible"})

func _check_fire() -> void:
	if status != "running" or armor_index >= armors.size() or not projectile.is_empty() or time_us < cooldown_until_us:
		return
	var armor: Dictionary = armors[armor_index]
	if int(inventory[armor.color]) < int(armor.demand):
		return
	inventory[armor.color] = int(inventory[armor.color]) - int(armor.demand)
	spent_counts[armor.color] = int(spent_counts[armor.color]) + int(armor.demand)
	cooldown_until_us = time_us + seconds_to_us(float(level.parameters.cannon_cooldown_sec))
	_projectile_sequence += 1
	projectile = {"id": _projectile_sequence, "run_id": run_id, "armor_id": str(armor.id), "color": str(armor.color), "amount": int(armor.demand), "fire_us": time_us, "hit_us": time_us + seconds_to_us(float(level.parameters.projectile_flight_sec))}
	_emit("cannon_fired", projectile.duplicate(true))

func _hit_projectile() -> void:
	if int(projectile.run_id) != run_id or armor_index >= armors.size() or str(projectile.armor_id) != str(armors[armor_index].id):
		_transport_error("projectile armor/run mismatch", projectile)
		return
	var hit := projectile.duplicate(true)
	projectile.clear()
	var before := dragon_position()
	var knockback: float = minf(float(level.dragon.knockback_distance), float(level.dragon.max_knockback_distance))
	_dragon_anchor_position = maxf(0.0, before - knockback)
	_dragon_anchor_us = time_us
	armor_index += 1
	hit["dragon_before"] = before
	hit["dragon_after"] = _dragon_anchor_position
	hit["applied_knockback"] = before - _dragon_anchor_position
	_emit("armor_broken", hit)
	if armor_index >= armors.size():
		_finish("victory", "final_armor_hit")
		return
	_recompute_contact()
	_emit("armor_changed", {"armor_index": armor_index, "armor": armors[armor_index].duplicate(true)})

func dragon_position() -> float:
	if level.is_empty() or status in ["unloaded", "load_error"] or not level.get("dragon") is Dictionary:
		return 0.0
	if status == "ready":
		return _dragon_anchor_position
	return minf(float(level.dragon.route_length), _dragon_anchor_position + float(time_us - _dragon_anchor_us) / TIMEBASE * float(level.dragon.speed_units_sec))

func _recompute_contact() -> void:
	var remaining: float = float(level.dragon.route_length) - _dragon_anchor_position
	_contact_us = _dragon_anchor_us + int(ceil(remaining / float(level.dragon.speed_units_sec) * TIMEBASE - 0.000001))

func _finish(result: String, reason: String) -> void:
	if status != "running":
		return
	status = result
	terminal_time_us = time_us
	terminal_reason = reason
	_emit(result, {"reason": reason, "armor_index": armor_index, "dragon_position": dragon_position()})

func _transport_error(reason: String, task: Dictionary) -> void:
	_recoverable_error = true
	_tool_selection.clear()
	paused = true
	speed_multiplier = 1
	_emit("recoverable_error", {"reason": reason, "task_id": task.get("id", -1), "recovery": "retry_or_restart"})

func accepts_callback(callback_run_id: int) -> bool:
	# Presentation callbacks never settle rules; this guard prevents stale effects.
	return callback_run_id == run_id and status in ["ready", "running"] and not paused

func tool_states() -> Array:
	if status in ["unloaded", "load_error"]:
		return []
	var level_number := 1
	if _is_integer(level.get("production_level_number")):
		level_number = int(level.production_level_number)
	elif _is_integer(level.get("level_number")):
		level_number = int(level.level_number)
	var result: Array = []
	for config in level.get("tools", DEFAULT_TOOLS):
		var tool: Dictionary = config.duplicate(true)
		tool["implementation"] = "RULES_IMPLEMENTED"
		tool["unlocked"] = level_number >= int(tool.unlock_level)
		tool["used"] = int(tool_uses.get(tool.id, 0))
		tool["remaining"] = 1 - int(tool.used)
		result.append(tool)
	return result

func _tool_precondition(tool_id: String) -> String:
	if status not in ["ready", "running"] or _recoverable_error:
		return "simulation_frozen"
	for tool in tool_states():
		if tool.id == tool_id:
			if not tool.unlocked:
				return "tool_locked"
			return "tool_already_used" if int(tool.remaining) == 0 else ""
	return "unknown_tool"

func begin_tool_selection(tool_id: String) -> Dictionary:
	# Caller deliberately opens the modal and pauses first. This API never pauses,
	# resumes or advances time, and cannot authorize a technical-error pause.
	var reason := _tool_precondition(tool_id)
	if not reason.is_empty():
		return {"ok": false, "reason": reason, "consumed": false}
	if tool_id != "recall" or not paused:
		return {"ok": false, "reason": "recall_requires_paused_selection", "consumed": false}
	_tool_selection_sequence += 1
	var token := str(run_id) + ":" + str(_tool_selection_sequence)
	_tool_selection = {"tool_id": tool_id, "token": token, "run_id": run_id}
	return {"ok": true, "token": token, "run_id": run_id, "consumed": false}

func cancel_tool_selection(token: String) -> bool:
	if str(_tool_selection.get("token", "")) != token or token.is_empty():
		return false
	_tool_selection.clear()
	return true

func request_tool(tool_id: String, payload: Dictionary = {}) -> Dictionary:
	var reason := _tool_precondition(tool_id)
	if not reason.is_empty():
		return {"ok": false, "reason": reason, "consumed": false}
	if paused and (tool_id != "recall" or _tool_selection.is_empty() or str(payload.get("selection_token", "")) != str(_tool_selection.token)):
		return {"ok": false, "reason": "simulation_frozen", "consumed": false}
	var result: Dictionary
	match tool_id:
		"extra_slot":
			if slots.size() != INITIAL_SLOTS:
				return {"ok": false, "reason": "slot_already_added", "consumed": false}
			slots.append(null)
			_refresh_waiting_and_blockage()
			result = {"ok": true, "slot": INITIAL_SLOTS, "slot_count": slots.size()}
		"recall":
			result = _recall_team(payload)
		"scout":
			result = _scout_hint()
		"shuffle":
			result = ToolSolver.new().find_verified_shuffle(self, payload)
			if result.ok:
				# Search used independent copies only. Commit just the candidate layout.
				columns = result.columns.duplicate(true)
				result.erase("columns")
		_:
			result = {"ok": false, "reason": "unknown_tool"}
	result["consumed"] = bool(result.ok)
	if result.ok:
		tool_uses[tool_id] = 1
		if tool_id == "recall":
			_tool_selection.clear()
		_emit("tool_used", {"tool_id": tool_id, "remaining": 0, "result": result.duplicate(true)})
	return result

func _recall_team(payload: Dictionary) -> Dictionary:
	if not _is_integer(payload.get("slot")):
		return {"ok": false, "reason": "invalid_slot"}
	var slot_index := int(payload.slot)
	if slot_index < 0 or slot_index >= slots.size() or slots[slot_index] == null:
		return {"ok": false, "reason": "invalid_slot"}
	var team: Dictionary = slots[slot_index]
	if int(team.remaining) <= 0:
		return {"ok": false, "reason": "no_remaining_quota"}
	if payload.has("expected_team_id") and str(payload.expected_team_id) != str(team.id):
		return {"ok": false, "reason": "stale_team_selection"}
	for column in columns:
		if str(column.id) != str(team.source_column):
			continue
		var reveal_column: bool = column.teams.is_empty()
		team.work_state = "candidate"
		column.teams.push_front(team)
		slots[slot_index] = null
		if slots.all(func(value: Variant) -> bool: return value == null):
			_next_dispatch_us = NEVER
		_emit("slot_released", {"slot": slot_index, "team_id": team.id, "color": team.color, "reason": "recall"})
		_refresh_waiting_and_blockage()
		return {"ok": true, "slot": slot_index, "team_id": team.id, "remaining_quota": team.remaining, "column_id": column.id, "reveal_column": reveal_column}
	return {"ok": false, "reason": "missing_source_column"}

func _scout_hint() -> Dictionary:
	if slots.find(null) < 0:
		return {"ok": false, "reason": "slots_full"}
	# Keep even route-cache writes off the live state until a suggestion is accepted.
	var probe = duplicate_for_replay()
	for column in probe.columns:
		if column.teams.is_empty():
			continue
		var team: Dictionary = column.teams[0]
		var cells: Array = probe.reachable_cell_ids(str(team.color))
		if cells.is_empty():
			continue
		var armor: Dictionary = armors[armor_index].duplicate(true) if armor_index < armors.size() else {}
		var armor_stock := int(inventory.get(armor.get("color", ""), 0))
		var demand := int(armor.get("demand", 0))
		return {"ok": true, "column_id": column.id, "team_id": team.id, "color": team.color, "remaining_quota": team.remaining, "exposed_cell_ids": cells, "suggested_at_us": time_us, "run_id": run_id, "current_armor": armor, "armor_inventory": armor_stock, "armor_shortfall": maxi(0, demand - armor_stock), "armor_shot_in_flight": not projectile.is_empty(), "cooldown_remaining_us": maxi(0, cooldown_until_us - time_us), "selection_matches_armor": team.color == armor.get("color", ""), "guaranteed_solution": false}
	return {"ok": false, "reason": "no_exposed_front_target"}

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
		var remaining_quota := 0
		for bead in board.values():
			if bead.color == color:
				on_board += 1
		for task in tasks.values():
			if task.color == color and task.stage == "returning":
				returning += 1
		for column in columns:
			for team in column.teams:
				if team.color == color:
					remaining_quota += int(team.remaining)
		for team in slots:
			if team != null and team.color == color:
				remaining_quota += int(team.remaining)
		if int(initial_counts[color]) != on_board + returning + int(delivered_counts[color]):
			errors.append("board/returning/delivered: " + str(color))
		if int(delivered_counts[color]) != int(inventory[color]) + int(spent_counts[color]):
			errors.append("inventory/spent: " + str(color))
		if int(initial_counts[color]) != remaining_quota + int(dispatched_counts[color]):
			errors.append("quota/dispatched: " + str(color))
	for cell_id in reservations:
		if not board.has(cell_id) or not tasks.has(reservations[cell_id]):
			errors.append("invalid reservation: " + str(cell_id))
	return errors

func snapshot() -> Dictionary:
	var tool_config: Array = tool_states()
	return {"api_version": API_VERSION, "run_id": run_id, "level_id": level.get("level_id", ""), "time_us": time_us, "time_sec": float(time_us) / TIMEBASE, "status": status, "paused": paused, "speed_multiplier": speed_multiplier, "board": board.duplicate(true), "reservations": reservations.duplicate(true), "columns": columns.duplicate(true), "slots": slots.duplicate(true), "tasks": tasks.duplicate(true), "inventory": inventory.duplicate(true), "initial_counts": initial_counts.duplicate(), "delivered_counts": delivered_counts.duplicate(), "spent_counts": spent_counts.duplicate(), "dispatched_counts": dispatched_counts.duplicate(), "armors": armors.duplicate(true), "armor_index": armor_index, "projectile": projectile.duplicate(true), "cooldown_until_us": cooldown_until_us, "dragon_position": dragon_position(), "dragon_contact_us": _contact_us, "terminal_time_us": terminal_time_us, "terminal_reason": terminal_reason, "blocked": _blocked, "tools": tool_config.duplicate(true), "validation_errors": validation_errors.duplicate()}
