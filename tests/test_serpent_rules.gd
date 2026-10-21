extends SceneTree
const Rules = preload("res://scripts/rescue_rules.gd")
var failures: Array[String] = []
var assertions := 0
var test_names: Array[String] = []
var level_reports: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures.append(message)
		push_error(message)

func fixture(grid: Array, segment_specs: Array = [], transport: Dictionary = {}, params: Dictionary = {}, serpent: Dictionary = {}) -> Dictionary:
	var palette := {"R": "red", "B": "blue", "G": "green"}
	var counts: Dictionary = {}
	for row in grid:
		for symbol in str(row):
			if symbol != ".":
				counts[palette[symbol]] = int(counts.get(palette[symbol], 0)) + 1
	if segment_specs.is_empty():
		for color in counts:
			segment_specs.append({"color": color, "kind": "normal", "hp": 1})
	var segments: Array = []
	for i in range(segment_specs.size()):
		var spec: Dictionary = segment_specs[i].duplicate()
		spec["id"] = "s" + str(i)
		segments.append(spec)
	var route := {"head_start_s": float(segments.size()), "goal_s": float(segments.size() + 100), "speed_units_sec": 1.0, "pitch": 1.0}
	route.merge(serpent, true)
	var parameters := {"max_inflight_ants": 4, "cannon_cooldown_sec": 0.5, "projectile_flight_sec": 1.0}
	parameters.merge(params, true)
	var moving := {"carrier_type": "worker", "outbound_speed_cells_sec": 1.0, "returning_speed_cells_sec": 1.0, "pickup_pause_sec": 0.3, "unload_pause_sec": 0.2}
	moving.merge(transport, true)
	return {"schema_version": 3, "level_id": "single-click-fixture", "level_number": 1, "width": str(grid[0]).length(), "height": grid.size(), "grid": grid, "palette": palette, "segments": segments, "parameters": parameters, "transport": moving, "serpent": route, "tools": []}

func normal(color: String) -> Dictionary:
	return {"color": color, "kind": "normal", "hp": 1}

func armored(color: String) -> Dictionary:
	return {"color": color, "kind": "armored", "hp": 2}

func new_rules(config: Dictionary):
	var r = Rules.new()
	check(r.load_level(config), "config validates: " + str(r.validation_errors))
	return r

func events_of(events: Array, type: String) -> Array:
	return events.filter(func(event: Dictionary) -> bool: return str(event.type) == type)

func conserved(r, label: String) -> void:
	check(r.conservation_errors().is_empty(), label + ": " + str(r.conservation_errors()))

func test_schema() -> void:
	test_names.append("single_click_schema_surplus_worker_and_segment_hp")
	var c := fixture(["RRR"], [armored("red")])
	check(Rules.validate_level(c).is_empty(), "supply exceeds HP without teams or quota equality")
	c.segments[0].hp = 1
	check(not Rules.validate_level(c).is_empty(), "initial armored segment must have HP2")
	c = fixture(["R"], [armored("red")])
	check(not Rules.validate_level(c).is_empty(), "same-color supply below HP rejected")
	c = fixture(["R"])
	c.parameters.max_inflight_ants = 5
	check(not Rules.validate_level(c).is_empty(), "slice capacity is exactly four")
	c = fixture(["R"])
	c.schema_version = 2
	check(not Rules.validate_level(c).is_empty(), "superseded automatic-team schema cannot silently load")
	c = fixture(["R"])
	c.serpent.head_start_s = 0
	check(not Rules.validate_level(c).is_empty(), "initial finite body must fit")
	check(not Rules.validate_level({}).is_empty(), "malformed config safely rejected")

func test_click_lifecycle() -> void:
	test_names.append("one_click_one_ant_pickup_count_unload_capacity_and_one_ammo")
	var r = new_rules(fixture(["R"]))
	r.update_us(9000000)
	check(r.time_us == 0 and r.status == "ready", "waiting does not start threat")
	check(not r.click_color("unknown").ok and r.status == "ready", "invalid color does not start threat")
	check(not r.select_team("red-20").ok and r.tasks.is_empty(), "old team dispatch is disabled, not a default path")
	check(r.click_color("red").ok and r.tasks.size() == 1 and r.status == "running", "successful click starts exactly one ant and threat")
	check(r.available_counts().red == 1 and r.reservations.size() == 1 and r.inventory.red == 0, "reserved bead still counted and no inventory debit/credit")
	var state: Dictionary = r.snapshot()
	check(r.click_color("red").reason == "color_all_reserved" and r.snapshot() == state, "repeat with no unreserved bead has no queue or resource change")
	r.update_us(1000000)
	check(r.available_counts().red == 0 and r.tasks[1].stage == "returning" and r.tasks.size() == 1, "pickup opens cell and decrements display count, retaining carrier")
	check(r.color_states().red.state == "collected" and r.click_color("red").reason == "color_collected", "collected distinguished from reserved")
	r.update_us(1300000)
	check(r.tasks[1].stage == "unloading" and r.tasks.size() == 1 and r.inventory.red == 0, "arrival begins unload without releasing capacity or ammo")
	r.update_us(199999)
	check(r.tasks.size() == 1 and r.inventory.red == 0, "unload cannot settle early")
	r.update_us(1)
	check(r.tasks.is_empty() and r.delivered_counts.red == 1 and r.spent_counts.red == 1 and r.projectile.amount == 1, "unload complete releases place; one bead fires once")
	check(r.projectile.flight_us == 1000000 and r.get_segment("s0").hp == 1, "projectile deadline explicit and no early damage")
	r.update_us(1000000)
	check(r.status == "victory" and r.terminal_time_us == 3500000 and r.terminal_reason == "final_segment_hit", "actual final hit alone wins")
	var events: Array = r.drain_events()
	check(events_of(events, "color_clicked").size() == 1 and events_of(events, "ant_dispatched").size() == 1 and events_of(events, "bead_unloading").size() == 1, "one input/task/unload event lifecycle")
	var hit: Dictionary = events_of(events, "segment_hit")[0]
	check(hit.projectile_id == 1 and is_equal_approx(hit.target_s, 3.5) and hit.kind == "normal", "hit retains stable projectile and pre-deletion position")
	state = r.snapshot()
	r.update_us(99999999)
	check(r.snapshot() == state and not r.click_color("red").ok and not r.apply_external_hit("s0", r.run_id).ok, "terminal state guards every entry")
	conserved(r, "single-click terminal accounting")

func test_capacity_no_queue() -> void:
	test_names.append("four_carriers_reject_fifth_no_hidden_queue_or_automatic_repeat")
	var specs: Array = []
	for i in range(5):
		specs.append(normal("red"))
	var r = new_rules(fixture(["RRRRR"], specs))
	for i in range(4):
		check(r.click_color("red").ok, "four independent clicks each accepted")
	var state: Dictionary = r.snapshot()
	var denied: Dictionary = r.click_color("red")
	check(not denied.ok and denied.reason == "carrier_limit" and not denied.queued and r.snapshot() == state, "fifth click is pure rejection")
	check(r.available_counts().red == 5 and r.reservations.size() == 4, "display includes all four reserved beads plus remaining bead")
	var cells: Array = []
	for task in r.tasks.values():
		check(not cells.has(task.cell_id), "accepted clicks uniquely reserve beads")
		cells.append(task.cell_id)
	r.update_us(15000000)
	check(r.dispatched_counts.red == 4 and r.board.size() == 1 and r.tasks.is_empty() and r.status == "running", "time never dispatches rejected fifth click or repeats an accepted click")
	check(r.click_color("red").ok, "capacity released after unload allows a new explicit click")
	r.update_us(15000000)
	check(r.status == "victory" and r.shot_counts.red == 5, "five successful clicks produce exactly five shots")
	conserved(r, "capacity accounting")

func test_reachability_and_counts() -> void:
	test_names.append("four_direction_reachability_and_blocked_reserved_collected")
	var r = new_rules(fixture([".R.", "RBR", ".R."]))
	check(r.reachable_cell_ids("red") == [1, 3, 5, 7] and r.reachable_cell_ids("blue").is_empty(), "four exterior directions work; diagonal corners do not bypass red")
	var state: Dictionary = r.snapshot()
	check(r.click_color("blue").reason == "color_blocked" and r.snapshot() == state and r.status == "ready", "blocked click does not start threat, deduct or cache intent")
	check(r.available_counts().blue == 1 and r.color_states().blue.state == "blocked", "blocked color still displays remaining bead")
	r.click_color("red")
	r.update_us(1000000)
	check(not r.board.has(7) and r.reachable_cell_ids("blue") == [4], "pickup opens an orthogonal path")
	check(r.dispatched_counts.blue == 0, "blocked old click never triggers automatically when path opens")
	check(r.click_color("blue").ok and r.available_counts().blue == 1, "new explicit click reserves blue without decrementing count")
	conserved(r, "reachability accounting")

func test_armor_and_targets() -> void:
	test_names.append("normal_hp1_armored_hp2_stable_target_all_stock_colors")
	var r = new_rules(fixture(["RRB"], [normal("blue"), armored("red")], {"outbound_speed_cells_sec": 100.0, "returning_speed_cells_sec": 100.0, "pickup_pause_sec": 0.0, "unload_pause_sec": 0.0}))
	r.click_color("red")
	r.click_color("red")
	r.update_us(40000)
	check(r.projectile.target_segment_id == "s1" and r.inventory.red == 1, "red stock bypasses blue front and fires only one projectile")
	var before: float = r.head_s()
	r.update_us(1000000)
	check(r.get_segment("s1").hp == 1 and r.get_segment("s1").kind == "armored" and r.alive_segment_ids == ["s0", "s1"], "first armored hit preserves armored kind and alive ID")
	check(r.projectile.target_segment_id == "s1" and is_equal_approx(r.head_s(), before + 1.0), "second shot targets same armored ID; ordinary hit has no head retreat or advance")
	var events: Array = r.drain_events()
	check(events_of(events, "segment_hit").size() == 1 and events_of(events, "segment_removed").is_empty(), "first armored hit is not removal")
	r.update_us(1000000)
	check(r.get_segment("s1").hp == 0 and r.alive_segment_ids == ["s0"] and r.hit_counts.red == 2, "second armored hit removes exactly once")
	conserved(r, "two-hit accounting")
	var p = new_rules(fixture(["RB"], [normal("red"), normal("blue")]))
	p.inventory.red = 1
	p.inventory.blue = 1
	check(p.next_fire_target().id == "s0", "all positive stock colors choose frontmost eligible candidate")
	p.inventory.red = 0
	check(p.next_fire_target().id == "s1", "unsupplied front color cannot block supplied rear color")

func test_stable_refund_and_surplus() -> void:
	test_names.append("stable_ids_external_invalidation_refund_once_surplus_win")
	var fast := {"outbound_speed_cells_sec": 100.0, "returning_speed_cells_sec": 100.0, "pickup_pause_sec": 0.0, "unload_pause_sec": 0.0}
	var r = new_rules(fixture(["RRB"], [normal("blue"), normal("red")], fast))
	r.click_color("red")
	r.update_us(40000)
	check(r.projectile.target_segment_id == "s1", "rear target created")
	r.apply_external_hit("s0", r.run_id)
	check(r.projectile.target_segment_id == "s1" and r.refunded_counts.red == 0, "removing earlier rank never remaps original target")
	r.update_us(1000000)
	check(r.status == "victory" and r.board.size() == 2, "all segments gone wins with untouched board surplus")
	conserved(r, "surplus win accounting")
	r = new_rules(fixture(["RRB"], [normal("red"), normal("blue")], fast))
	r.click_color("red")
	r.update_us(40000)
	r.apply_external_hit("s0", r.run_id)
	check(r.projectile.is_empty() and r.inventory.red == 1 and r.spent_counts.red == 0 and r.refunded_counts.red == 1, "invalidated exact target ends shot and refunds same color once")
	check(not r.apply_external_hit("s0", r.run_id).ok, "duplicate invalidation rejected")
	r.update_us(2000000)
	check(r.refunded_counts.red == 1 and r.get_segment("s1").hp == 1, "old target deadline neither refunds twice nor hits next ID")
	conserved(r, "refund accounting")
	r = new_rules(fixture(["RR"], [armored("red")], fast))
	r.click_color("red")
	r.update_us(40000)
	r.apply_external_hit("s0", r.run_id)
	check(not r.projectile.is_empty() and r.get_segment("s0").hp == 1 and r.refunded_counts.red == 0, "nonlethal external armored hit does not invalidate live target")
	r.update_us(1000000)
	check(r.status == "victory" and r.hit_counts.red == 1, "in-flight shot still hits surviving stable armored target")

func test_contact_and_clock() -> void:
	test_names.append("exact_hit_contact_order_old_run_pause_x2_partition")
	for offset in [0, -1]:
		var r = new_rules(fixture(["R"], [], {}, {}, {"goal_s": 4.5 + float(offset) / 1000000.0}))
		r.click_color("red")
		r.update_us(10000000)
		check((r.status == "victory" and r.terminal_time_us == 3500000) if offset == 0 else (r.status == "defeat" and r.terminal_time_us == 3499999 and r.get_segment("s0").hp == 1), "same-time hit wins; earlier contact wins within same render update")
		conserved(r, "contact accounting")
	var r = new_rules(fixture(["RR"], [normal("red"), normal("red")]))
	r.click_color("red")
	var old: int = r.run_id
	r.restart()
	var before: Dictionary = r.snapshot()
	check(not r.apply_external_hit("s0", old).ok and r.snapshot() == before, "old-run event cannot modify restarted round")
	r.click_color("red")
	r.click_color("red")
	r.set_speed(2)
	r.update_us(100000)
	check(r.time_us == 200000, "x2 multiplies simulation time")
	r.set_paused(true)
	before = r.snapshot()
	r.update_us(10000000)
	check(r.snapshot() == before and r.speed_multiplier == 1 and not r.click_color("red").ok, "pause freezes transport and input, resetting x2")
	r.set_paused(false)
	var copy = r.duplicate_for_replay()
	r.update_us(10000000)
	for i in range(10):
		copy.update_us(1000000)
	check(r.snapshot() == copy.snapshot(), "chunked and single update settle identical terminal state")
	conserved(r, "clock accounting")

func test_authored_replays() -> void:
	test_names.append("three_current_12_16_16_click_no_tool_core_replays")
	for index in range(1, 4):
		var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-%02d.json" % index))
		var r = new_rules(config)
		var events: Array = r.drain_events()
		var max_carriers := 0
		var min_path := 999
		var max_path := 0
		var min_trip := 999999999
		var max_trip := 0
		var previous := -2200000
		for input in config.solution.inputs:
			var at_us := Rules.seconds_to_us(float(input.at_sec))
			check(at_us - previous >= 750000, "authored clicks have readable nonzero gaps")
			previous = at_us
			r.update_us(at_us - int(r.time_us))
			var result: Dictionary = r.click_color(str(input.color))
			check(result.ok, "authored one-ant click accepted without retry: " + str(config.level_id) + " @" + str(input.at_sec))
			if not result.ok:
				break
			var task: Dictionary = r.tasks[result.task_id]
			max_carriers = maxi(max_carriers, r.tasks.size())
			min_path = mini(min_path, int(task.distance_cells))
			max_path = maxi(max_path, int(task.distance_cells))
			min_trip = mini(min_trip, int(task.delivery_us) - int(task.depart_us))
			max_trip = maxi(max_trip, int(task.delivery_us) - int(task.depart_us))
			events.append_array(r.drain_events())
		r.update_us(60000000)
		events.append_array(r.drain_events())
		check(r.status == "victory" and r.terminal_reason == "final_segment_hit", "current authored click replay wins: " + str(config.level_id))
		check(max_carriers <= 4 and events_of(events, "ant_dispatched").size() == config.solution.inputs.size(), "one task per authored click; never above four")
		check(events_of(events, "cannon_fired").size() == config.solution.inputs.size() and events_of(events, "segment_hit").size() == config.solution.inputs.size(), "every required click yields one shot and one damage, including armor")
		check(r.board.size() > 0 and events_of(events, "victory").size() == 1 and int(r.snapshot().dragon_contact_us) == 60000000, "surplus victory is once within real 60s finite route")
		conserved(r, "whole-level accounting")
		level_reports.append({"level_id": config.level_id, "board_beads": r.initial_counts, "necessary_clicks": config.solution.inputs.size(), "segment_count": config.segments.size(), "result": r.status, "terminal_time_us": r.terminal_time_us, "contact_deadline_us": r.snapshot().dragon_contact_us, "time_margin_us": int(r.snapshot().dragon_contact_us) - int(r.terminal_time_us), "minimum_input_gap_sec": config.solution.minimum_input_gap_sec, "max_carriers": max_carriers, "path_cells_range": [min_path, max_path], "complete_trip_us_range": [min_trip, max_trip], "board_beads_remaining": r.board.size(), "remaining_by_color": r.available_counts(), "tool_uses": 0, "conservation_errors": r.conservation_errors(), "verification": "automated single-click deterministic core replay, not human acceptance"})

func run() -> void:
	test_schema()
	test_click_lifecycle()
	test_capacity_no_queue()
	test_reachability_and_counts()
	test_armor_and_targets()
	test_stable_refund_and_surplus()
	test_contact_and_clock()
	test_authored_replays()
	var report := {"api_version": Rules.API_VERSION, "schema_version": 3, "engine": Engine.get_version_info().string, "scope": "current single-click core only; old 724 automatic-team assertions and replays are superseded, not current acceptance", "test_groups": test_names, "assertions": assertions, "passed": failures.is_empty(), "failures": failures, "authored_levels": level_reports}
	var file := FileAccess.open("res://reports/rules/serpent-core-tests.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
