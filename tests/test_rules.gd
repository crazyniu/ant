extends SceneTree
const Rules = preload("res://scripts/rescue_rules.gd")
var failures: Array[String] = []
var assertions: int = 0
var test_names: Array[String] = []
var level_reports: Array = []
var all_recorded_events: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures.append(message)
		push_error(message)

func fixture(grid: Array, columns: Array = [], armors: Array = [], params: Dictionary = {}, dragon: Dictionary = {}) -> Dictionary:
	var palette := {"R": "red", "B": "blue", "W": "white", "G": "green", "Y": "yellow", "P": "purple"}
	var counts: Dictionary = {}
	for row in grid:
		for symbol in str(row):
			if symbol != ".":
				var color: String = palette[symbol]
				counts[color] = int(counts.get(color, 0)) + 1
	if columns.is_empty():
		for color in counts:
			columns.append({"id": color, "teams": [{"id": color + "-1", "color": color, "quota": counts[color]}]})
	if armors.is_empty():
		for color in counts:
			armors.append({"id": "armor-" + color, "color": color, "demand": counts[color]})
	var parameters := {"dispatch_interval_sec": 0.1, "transport_speed_cells_sec": 1.0, "max_inflight_ants": 20, "cannon_cooldown_sec": 0.5, "projectile_flight_sec": 1.0}
	parameters.merge(params, true)
	var dragon_config := {"route_length": 100.0, "speed_units_sec": 1.0, "initial_position": 0.0, "knockback_distance": 0.0, "max_knockback_distance": 0.0}
	dragon_config.merge(dragon, true)
	return {"schema_version": 1, "level_id": "test-fixture", "width": str(grid[0]).length(), "height": grid.size(), "grid": grid, "palette": palette, "columns": columns, "armors": armors, "parameters": parameters, "dragon": dragon_config}

func new_rules(config: Dictionary):
	var rules = Rules.new()
	check(rules.load_level(config), "fixture/config must validate: " + str(rules.validation_errors))
	return rules

func event_filter(events: Array, type: String) -> Array:
	return events.filter(func(event: Dictionary) -> bool: return event.type == type)

func test_lifecycle() -> void:
	test_names.append("reservation_pickup_delivery_fire_final_hit_are_distinct")
	var r = new_rules(fixture(["R"]))
	r.update_us(100000000)
	check(r.time_us == 0 and is_equal_approx(r.dragon_position(), 0.0), "opening observation must not count threat time")
	check(r.select_front("red", "red-1").ok, "front team accepted")
	check(r.tasks.size() == 1 and r.reservations.size() == 1 and r.board.size() == 1, "reservation must leave the bead on board")
	check(r.slots.all(func(v: Variant) -> bool: return v == null), "quota zero frees the slot before pickup")
	check(r.dispatched_counts.red == 1 and r.inventory.red == 0, "dispatch decrements quota, not board or inventory")
	r.update_us(999999)
	check(r.board.size() == 1, "reservation remains an obstacle until pickup")
	r.update_us(1)
	check(r.board.is_empty() and r.tasks[1].stage == "returning" and r.inventory.red == 0 and r.status == "running", "pickup clears board but cannot deliver or win")
	check(r.conservation_errors().is_empty(), "conservation at pickup")
	r.update_us(1000000)
	check(r.tasks.is_empty() and r.delivered_counts.red == 1 and r.spent_counts.red == 1 and r.inventory.red == 0, "delivery enters inventory and fire debits exactly once")
	check(r.status == "running" and not r.projectile.is_empty(), "last delivery and fire are not victory")
	r.update_us(999999)
	check(r.status == "running", "flight cannot win early")
	r.update_us(1)
	check(r.status == "victory" and r.terminal_time_us == 3000000, "only final hit wins")
	var terminal: Dictionary = r.snapshot()
	r.update_us(100000000)
	check(r.snapshot() == terminal, "terminal state must freeze all simulation")
	var old_run: int = r.run_id
	check(not r.accepts_callback(old_run), "terminal callback rejected")
	r.restart()
	check(r.run_id == old_run + 1 and not r.accepts_callback(old_run) and r.accepts_callback(r.run_id), "restart invalidates old callback run IDs")
	check(r.speed_multiplier == 1 and r.time_us == 0, "restart returns to x1 and zero simulation time")

func test_inputs_and_same_color() -> void:
	test_names.append("front_only_five_slots_same_color_and_global_dispatch_pacing")
	var cols := [{"id": "a", "teams": [{"id": "a1", "color": "red", "quota": 1}, {"id": "a2", "color": "red", "quota": 1}]}, {"id": "b", "teams": [{"id": "b1", "color": "red", "quota": 1}]}]
	var r = new_rules(fixture(["RRR"], cols))
	check(not r.select_front("a", "a2").ok and r.status == "ready", "back-row request must not start dragon")
	r.select_front("a", "a1")
	check(not r.select_front("a", "a1").ok, "stale double-click must not select a different team")
	r.select_front("a", "a2")
	r.select_front("b", "b1")
	check(r.tasks.size() == 1, "rapid clicks cannot bypass global dispatch interval")
	r.update_us(200000)
	check(r.tasks.size() == 3 and r.reservations.size() == 3, "same-color squads reserve distinct cells")
	var events: Array = r.drain_events()
	var dispatches := event_filter(events, "ant_dispatched")
	check(dispatches.size() == 3 and dispatches[0].time_us == 0 and dispatches[1].time_us == 100000 and dispatches[2].time_us == 200000, "dispatch pace is explicit and stable")
	check(dispatches[0].cell_id == 1 and dispatches[1].cell_id == 0 and dispatches[2].cell_id == 2, "shortest route then stable cell ID chooses targets")
	check(dispatches[0].slot == 0 and dispatches[1].slot == 1 and dispatches[2].slot == 0, "stable slot round robin survives immediate slot reuse")
	cols = []
	for i in range(6):
		cols.append({"id": str(i), "teams": [{"id": "team-" + str(i), "color": "red", "quota": 2}]})
	r = new_rules(fixture(["RRRRRRRRRRRR"], cols))
	for i in range(5):
		check(r.select_front(i).ok, "five starting work slots accept five teams")
	check(not r.select_front(5).ok and r.slots.size() == 5, "sixth team cannot enter full slots")
	r.update_us(500000)
	check(r.tasks.size() == 6 and r.slots.find(null) >= 0 and r.status == "running", "quota exhaustion releases slot while transports continue; full slots alone never fail")
	check(r.conservation_errors().is_empty(), "same-color and slot reuse conservation")
	check(not r.snapshot().blocked, "full slots with active transport must not be reported stalled")
	cols = []
	for i in range(5):
		cols.append({"id": str(i), "teams": [{"id": "blue-" + str(i), "color": "blue", "quota": 1}]})
	cols.append({"id": "red", "teams": [{"id": "red-1", "color": "red", "quota": 14}]})
	r = new_rules(fixture(["RRRRR", "RBBBR", "RB.BR", "RRRRR"], cols))
	for i in range(5):
		r.select_front(i)
	check(r.snapshot().blocked and r.status == "running", "true full-slot no-progress state prompts blockage rather than immediate failure")
	r.update_us(500000)
	check(r.status == "running", "only dragon contact can lose a blocked run")


func test_exterior_and_waiting() -> void:
	test_names.append("four_neighbor_exterior_sealed_holes_top_edge_and_waiting_recovery")
	var r = new_rules(fixture(["RRRRR", "R...R", "R.B.R", "R...R", "RRRRR"]))
	check(r.reachable_cell_ids("blue").is_empty(), "sealed cavity is not exterior air")
	check(r.reachable_cell_ids("red").has(0) and r.reachable_cell_ids("red").has(2), "top edge is reachable from full exterior ring")
	r = new_rules(fixture([".RR", "RBR", "RRR"]))
	check(r.reachable_cell_ids("blue").is_empty(), "diagonal contact alone is not reachable")
	var columns := [{"id": "b", "teams": [{"id": "b1", "color": "blue", "quota": 1}]}, {"id": "r", "teams": [{"id": "r1", "color": "red", "quota": 8}]}]
	var armors := [{"id": "blue", "color": "blue", "demand": 1}, {"id": "red", "color": "red", "demand": 8}]
	r = new_rules(fixture(["RRR", "RBR", "RRR"], columns, armors, {"transport_speed_cells_sec": 10.0}))
	r.select_front("b")
	check(r.slots[0].work_state == "waiting_target" and r.dispatched_counts.blue == 0, "hidden same-color team occupies slot without consuming quota")
	r.select_front("r")
	var non_current_stock_seen := false
	var all_events: Array = r.drain_events()
	for _i in range(200):
		r.update_us(25000)
		all_events.append_array(r.drain_events())
		if r.armor_index == 0 and r.inventory.red > 0:
			non_current_stock_seen = true
		check(r.conservation_errors().is_empty(), "waiting recovery must conserve all colors")
		if r.status != "running":
			break
	check(non_current_stock_seen, "non-current-color inventory accumulates and is retained")
	check(r.status == "victory" and r.dispatched_counts.blue == 1, "waiting team resumes without reselection after outer bead pickup")
	var blue_dispatches: Array = event_filter(all_events, "ant_dispatched").filter(func(event: Dictionary) -> bool: return event.color == "blue")
	check(blue_dispatches.size() == 1 and blue_dispatches[0].time_us > 0, "waiting recovery produces one eventual blue reservation")
	validate_paths(fixture(["RRR", "RBR", "RRR"], columns, armors), all_events)

func test_stock_and_cooldown() -> void:
	test_names.append("unbounded_inventory_surplus_same_color_armor_one_inflight_and_cooldown_from_fire")
	var armors := [{"id": "r1", "color": "red", "demand": 1}, {"id": "r2", "color": "red", "demand": 2}]
	var r = new_rules(fixture(["RRR"], [], armors, {"transport_speed_cells_sec": 10.0, "projectile_flight_sec": 0.5, "cannon_cooldown_sec": 2.0}))
	r.select_front("red")
	r.update_us(1000000)
	check(r.armor_index == 1 and r.inventory.red == 2 and r.spent_counts.red == 1, "surplus stock survives first armor and cooldown")
	r.update_us(1200000)
	check(r.spent_counts.red == 3 and r.inventory.red == 0 and not r.projectile.is_empty(), "second shot spends only its demand after fire-based cooldown")
	r.update_us(500000)
	var events: Array = r.drain_events()
	var fires := event_filter(events, "cannon_fired")
	check(fires.size() == 2 and fires[0].time_us == 200000 and fires[1].time_us == 2200000, "cooldown is measured from fire rather than hit")
	check(event_filter(events, "armor_broken").size() == 2 and r.status == "victory", "one projectile per armor ID and one hit per projectile")

func test_pause_cap_and_knockback() -> void:
	test_names.append("pause_freezes_all_cap_preserves_quota_and_knockback_is_finite_clamped")
	var r = new_rules(fixture(["RRRRRRRR"], [], [], {"max_inflight_ants": 2}))
	r.select_front("red")
	r.set_speed(2)
	r.update_us(50000)
	check(r.tasks.size() == 2 and r.dispatched_counts.red == 2, "inflight cap reached")
	r.update_us(500000)
	check(r.tasks.size() == 2 and r.dispatched_counts.red == 2, "capacity waits do not consume extra quota")
	check(r.slots[0].work_state == "waiting_capacity", "capacity waiting is distinct from color obstruction")
	r.set_paused(true)
	var paused_snapshot: Dictionary = r.snapshot()
	r.update(15.0)
	r.update_us(10000000)
	check(r.snapshot() == paused_snapshot and r.speed_multiplier == 1, "pause freezes every clock and resets speed")
	check(not r.select_front("red").ok and not r.set_speed(2), "paused gameplay inputs are rejected")
	r.set_paused(false)
	r.update_us(100000)
	check(r.time_us == paused_snapshot.time_us + 100000, "resume advances at x1")
	check(not r.request_tool("recall").ok and not r.request_tool("recall").consumed, "locked recall rejects without consuming or fabricating effects")
	r = new_rules(fixture(["R"], [], [], {"transport_speed_cells_sec": 1000.0, "projectile_flight_sec": 0.001}, {"knockback_distance": 100.0, "max_knockback_distance": 0.5}))
	r.select_front("red")
	r.update_us(100000)
	var hit: Dictionary = event_filter(r.drain_events(), "armor_broken")[0]
	check(hit.applied_knockback <= 0.5 and hit.dragon_after == 0.0 and r.dragon_position() == 0.0, "knockback capped and clamped at route origin")

func test_terminal_ordering() -> void:
	test_names.append("exact_hit_contact_tie_and_strict_earlier_contact_within_one_render_update")
	var r = new_rules(fixture(["R"], [], [], {}, {"route_length": 3.0}))
	r.select_front("red")
	r.update_us(10000000)
	check(r.status == "victory" and r.terminal_time_us == 3000000, "exact same-time final hit wins before contact")
	r = new_rules(fixture(["R"], [], [], {}, {"route_length": 2.999999}))
	r.select_front("red")
	r.update_us(10000000)
	check(r.status == "defeat" and r.terminal_time_us == 2999999, "contact one microsecond earlier wins even within same render update")
	var events: Array = r.drain_events()
	check(event_filter(events, "armor_broken").is_empty() and event_filter(events, "victory").is_empty(), "later hit cannot undo failure")
	r = new_rules(fixture(["R"], [], [], {}, {"route_length": 2.0}))
	r.select_front("red")
	r.update_us(10000000)
	check(r.status == "defeat" and r.delivered_counts.red == 0 and r.spent_counts.red == 0, "same-time delivery or new fire cannot stop contact")
	var armors := [{"id": "r1", "color": "red", "demand": 1}, {"id": "r2", "color": "red", "demand": 1}]
	r = new_rules(fixture(["RR"], [], armors, {}, {"route_length": 3.0, "knockback_distance": 1.0, "max_knockback_distance": 1.0}))
	r.select_front("red")
	r.update_us(3000000)
	check(r.status == "running" and r.armor_index == 1 and r.dragon_position() == 2.0, "same-time nonfinal hit applies knockback before contact")
	r.update_us(1000000)
	check(r.status == "defeat" and r.terminal_time_us == 4000000, "finite knockback does not permanently stall dragon")
	r = new_rules(fixture(["RR"], [], armors, {}, {"route_length": 3.0}))
	r.select_front("red")
	r.update_us(3000000)
	check(r.status == "defeat" and r.armor_index == 1 and r.terminal_time_us == 3000000, "zero-knockback nonfinal hit still allows contact at same time")

func test_validation_and_errors() -> void:
	test_names.append("invalid_color_accounting_and_recoverable_transport_failure")
	var config := fixture(["RW"])
	config.columns.pop_back()
	var r = Rules.new()
	check(not r.load_level(config) and r.status == "load_error", "missing white quota must reject level")
	config = fixture(["R"])
	config.parameters.dispatch_interval_sec = 0
	check(not r.load_level(config), "zero-time unlimited dispatch must reject level")
	r = new_rules(fixture(["R"]))
	r.select_front("red")
	r.board.erase(0) # Deliberate test fault: not a production API.
	r.update_us(1000000)
	check(r.paused and r.status == "running" and r.delivered_counts.red == 0 and r.inventory.red == 0, "technical transport failure pauses instead of inventing ammo")
	check(event_filter(r.drain_events(), "recoverable_error").size() == 1, "recoverable transport failure is explicit")
	check(r.restart() and r.board.size() == 1 and not r.paused, "restart recovers intact configuration after technical error")
	for malformed in [null, "bad", 123, [], {}]:
		for field in ["grid", "palette", "parameters", "dragon", "columns", "armors"]:
			config = fixture(["R"])
			config[field] = malformed
			check(not r.load_level(config), "malformed config must be rejected without a runtime crash: " + field)
			check(r.snapshot().status == "load_error", "invalid level still exposes a safe error snapshot")
	config = fixture(["R"])
	config.columns[0].teams[0].quota = 1.5
	check(not r.load_level(config), "fractional quota must not silently truncate")
	config = fixture(["R"])
	config.parameters.max_inflight_ants = 1.5
	check(not r.load_level(config), "fractional ant cap must be rejected")
	config = fixture(["R"])
	config.dragon.route_length = "three"
	check(not r.load_level(config), "nonnumeric dragon parameters must fail cleanly")
	config = fixture(["R"])
	config.tools = null
	check(not r.load_level(config) and r.snapshot().tools == [], "corrupt tool data rejects but remains displayable")


func validate_paths(config: Dictionary, events: Array) -> void:
	var occupied: Dictionary = {}
	var width := int(config.width)
	var height := int(config.height)
	for y in range(height):
		for x in range(width):
			if str(config.grid[y]).substr(x, 1) != ".":
				occupied[y * width + x] = true
	var reserved: Dictionary = {}
	for event in events:
		if event.type == "target_reserved":
			check(not reserved.has(event.cell_id) and occupied.has(event.cell_id), "each target is reserved once while still on board")
			reserved[event.cell_id] = event.id
		if event.type == "bead_picked_up":
			check(occupied.has(event.cell_id) and reserved.has(event.cell_id), "pickup requires an occupied reserved target")
			occupied.erase(event.cell_id)
			reserved.erase(event.cell_id)
		if event.type != "ant_dispatched":
			continue
		var path: Array = event.path
		for i in range(path.size()):
			var point: Array = path[i]
			var x := int(point[0])
			var y := int(point[1])
			check(x >= -1 and x <= width and y >= -1 and y <= height, "path remains within board plus exterior ring")
			if i > 0:
				check(absi(x - int(path[i - 1][0])) + absi(y - int(path[i - 1][1])) == 1, "transport path never uses diagonal movement")
			if i < path.size() - 1 and x >= 0 and x < width and y >= 0 and y < height:
				check(not occupied.has(y * width + x), "transport path never crosses occupied or reserved beads")

func select_solution_front(r, level_id: String) -> Dictionary:
	if r.slots.find(null) < 0:
		return {}
	# The waiting validation deliberately begins with the hidden blue team.
	if r.status == "ready":
		return {"column": str(r.columns[0].id), "team": str(r.columns[0].teams[0].id)}
	for column in r.columns:
		if not column.teams.is_empty() and not r.best_target(str(column.teams[0].color)).is_empty():
			return {"column": str(column.id), "team": str(column.teams[0].id)}
	# A waiting front may be selected to expose an already reachable team behind it.
	# This is an authored replay aid, not an implementation of the P3 scout tool.
	for column in r.columns:
		if column.teams.size() < 2:
			continue
		for i in range(1, column.teams.size()):
			if not r.best_target(str(column.teams[i].color)).is_empty():
				return {"column": str(column.id), "team": str(column.teams[0].id)}
	return {}

func record_solution(config: Dictionary) -> Dictionary:
	var r = new_rules(config)
	var solution: Array = []
	var events: Array = r.drain_events()
	var next_click_us := 0
	var non_current_inventory := false
	var waiting_blue := false
	var maximum_inflight := 0
	while r.status in ["ready", "running"] and r.time_us < 240000000:
		if r.time_us >= next_click_us:
			var selection := select_solution_front(r, str(config.level_id))
			if not selection.is_empty():
				var input_time: int = r.time_us
				var result: Dictionary = r.select_front(selection.column, selection.team)
				check(result.ok, "recorded no-tool input must be legal: " + str(config.level_id))
				solution.append({"time_us": input_time, "time_sec": float(input_time) / 1000000, "action": "select_front", "column_id": selection.column, "team_id": selection.team})
			next_click_us += 750000
		events.append_array(r.drain_events())
		check(r.conservation_errors().is_empty(), "per-color conservation throughout " + str(config.level_id))
		maximum_inflight = maxi(maximum_inflight, r.tasks.size())
		if r.armor_index < r.armors.size():
			for color in r.inventory:
				if color != r.armors[r.armor_index].color and r.inventory[color] > 0:
					non_current_inventory = true
		for team in r.slots:
			if team != null and team.color == "blue" and team.work_state == "waiting_target":
				waiting_blue = true
		if r.status == "ready":
			check(false, "solver failed to start level " + str(config.level_id))
			break
		r.update_us(25000)
	events.append_array(r.drain_events())
	check(r.status == "victory", "timed no-tool solution must naturally win: " + str(config.level_id) + ", got " + str(r.status) + " at " + str(r.time_us))
	check(r.board.is_empty() and r.tasks.is_empty() and r.reservations.is_empty(), "natural victory must have completed all transport")
	check(maximum_inflight <= int(config.parameters.max_inflight_ants), "configured ant cap holds during entire replay")
	validate_paths(config, events)
	for i in range(1, solution.size()):
		check(int(solution[i].time_us) - int(solution[i - 1].time_us) >= 750000, "no instantaneous all-click replay")
	if str(config.level_id) == "validation-02":
		check(waiting_blue and non_current_inventory, "waiting level must demonstrate waiting blue and noncurrent stock")
	var pickups := event_filter(events, "bead_picked_up")
	var deliveries := event_filter(events, "bead_delivered")
	var fires := event_filter(events, "cannon_fired")
	var last_pickup := int(pickups[-1].time_us) if not pickups.is_empty() else -1
	var last_delivery := int(deliveries[-1].time_us) if not deliveries.is_empty() else -1
	var last_fire := int(fires[-1].time_us) if not fires.is_empty() else -1
	check(last_pickup < last_delivery and last_delivery <= last_fire and last_fire < r.terminal_time_us, "tail pickup, delivery, fire and final hit must be distinct ordered phases")
	var report := {"level_id": config.level_id, "pattern_name": config.pattern_name, "board_count": r.initial_counts.values().reduce(func(a: int, b: Variant) -> int: return a + int(b), 0), "color_counts": r.initial_counts, "teams": solution.size(), "armors": r.armors.size(), "outcome": r.status, "final_hit_us": r.terminal_time_us, "final_hit_sec": float(r.terminal_time_us) / 1000000, "last_pickup_us": last_pickup, "last_delivery_us": last_delivery, "last_fire_us": last_fire, "final_hit_margin_sec": float(r.snapshot().dragon_contact_us - r.terminal_time_us) / 1000000, "maximum_inflight": maximum_inflight, "non_current_inventory_observed": non_current_inventory, "blue_waiting_observed": waiting_blue, "human_playtest": "NOT_RUN", "visual_acceptance": "NOT_RUN", "solution": solution}
	all_recorded_events[config.level_id] = events
	return {"report": report, "snapshot": r.snapshot(), "events": events}

func replay(config: Dictionary, solution: Array, speed: int, chunk_us: int = 17000, use_float_update: bool = false) -> Dictionary:
	var r = new_rules(config)
	r.set_speed(speed)
	var events: Array = r.drain_events()
	for input in solution:
		while r.time_us < int(input.time_us) and r.status == "running":
			var remaining: int = int(input.time_us) - r.time_us
			var wall_us: int = mini(chunk_us, remaining / speed)
			if use_float_update:
				r.update(float(wall_us) / 1000000.0)
			else:
				r.update_us(wall_us)
			events.append_array(r.drain_events())
		check(r.time_us == int(input.time_us), "replay input lands at exact simulation time")
		check(r.select_front(str(input.column_id), str(input.team_id)).ok, "timed replay input remains legal")
		events.append_array(r.drain_events())
	while r.status == "running" and r.time_us < 240000000:
		if use_float_update:
			r.update(float(chunk_us) / 1000000.0)
		else:
			r.update_us(chunk_us)
		events.append_array(r.drain_events())
	var state: Dictionary = r.snapshot()
	state.erase("speed_multiplier")
	var normalized: Array = []
	for event in events:
		if event.type == "speed_changed":
			continue
		var clean: Dictionary = event.duplicate(true)
		clean.erase("sequence")
		normalized.append(clean)
	return {"state": state, "events": normalized}

func run() -> void:
	test_lifecycle()
	test_inputs_and_same_color()
	test_exterior_and_waiting()
	test_stock_and_cooldown()
	test_pause_cap_and_knockback()
	test_terminal_ordering()
	test_validation_and_errors()
	for level_id in ["validation-01", "validation-02", "validation-03"]:
		var path: String = "res://data/levels/" + level_id + ".json"
		var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var result := record_solution(config)
		var report: Dictionary = result.report
		var normal := replay(config, report.solution, 1, 17000)
		var double_speed := replay(config, report.solution, 2, 11500)
		var coarse := replay(config, report.solution, 1, 730000)
		var float_step := replay(config, report.solution, 2, 8333, true)
		check(normal.state == double_speed.state and normal.events == double_speed.events, "1x/2x same-simulation-time replay is identical: " + level_id)
		check(normal.state == coarse.state and normal.events == coarse.events, "coarse/fine render updates produce identical events: " + level_id)
		check(normal.state == float_step.state and normal.events == float_step.events, "update(float seconds) matches microsecond stepping: " + level_id)
		report["speed_and_chunk_invariance"] = normal.state == double_speed.state and normal.events == double_speed.events and normal.events == coarse.events and normal.events == float_step.events
		var final_hit: Dictionary = event_filter(result.events, "armor_broken")[-1]
		var tie_config: Dictionary = config.duplicate(true)
		tie_config.dragon.route_length = final_hit.dragon_before
		var tie_replay := replay(tie_config, report.solution, 1, 5000000)
		check(tie_replay.state.status == "victory" and tie_replay.state.terminal_time_us == report.final_hit_us, "full-level exact tie must win: " + level_id)
		var earlier_config: Dictionary = tie_config.duplicate(true)
		earlier_config.dragon.route_length = float(final_hit.dragon_before) - float(config.dragon.speed_units_sec) / 1000000.0
		var earlier_replay := replay(earlier_config, report.solution, 1, 5000000)
		check(earlier_replay.state.status == "defeat" and earlier_replay.state.terminal_time_us == report.final_hit_us - 1, "full-level contact 1us before final hit must lose: " + level_id)
		report["boundary_replays"] = {"exact_tie": {"route_length": tie_config.dragon.route_length, "outcome": tie_replay.state.status, "time_us": tie_replay.state.terminal_time_us}, "contact_1us_earlier": {"route_length": earlier_config.dragon.route_length, "outcome": earlier_replay.state.status, "time_us": earlier_replay.state.terminal_time_us}}
		level_reports.append(report)
		if failures.is_empty():
			config.validation.status = "HEADLESS_TIMED_REPLAY_PASS"
			config.validation.no_tool_solution = report.solution
			config.validation["measured_final_hit_sec"] = report.final_hit_sec
			config.validation["final_hit_margin_sec"] = report.final_hit_margin_sec
			config.validation["boundary_replays"] = report.boundary_replays
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_string(JSON.stringify(config, "  ") + "\n")
		var event_file := FileAccess.open("res://reports/rules/" + level_id + "-events.json", FileAccess.WRITE)
		event_file.store_string(JSON.stringify(result.events, "  ") + "\n")
	var summary := {"api_version": Rules.API_VERSION, "engine": Engine.get_version_info().string, "pass": failures.is_empty(), "assertions": assertions, "failures": failures, "test_groups": test_names, "levels": level_reports, "scope": "P2 pure rule simulation and 3 timed no-tool headless replays. Not UI integration, human playtest, P3 tools, audio, persistence, 30 levels, Mac, or mobile acceptance."}
	var output := FileAccess.open("res://reports/rules/test-report.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(summary, "  ") + "\n")
	print(JSON.stringify(summary, "  "))
	quit(0 if failures.is_empty() else 1)
