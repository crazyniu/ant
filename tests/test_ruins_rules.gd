extends SceneTree
## Bounded acceptance for one new region and the three existing production replays.
## No batch generator, progression writes, reward application, tools, or external hits.
const Rules = preload("res://scripts/rescue_rules.gd")
const COLORS := ["red", "blue", "green", "yellow"]
const EXPECTED_OLD_TERMINAL_US := [19950000, 26450000, 27350000]
var failures: Array[String] = []
var assertions := 0
var reports: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures.append(label)
		push_error(label)

func config(number: int) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-%02d.json" % number))

func loaded(c: Dictionary):
	var r = Rules.new()
	check(r.load_level(c), "%s validates: %s" % [c.level_id, r.validation_errors])
	return r

func event_count(events: Array, kind: String) -> int:
	return events.filter(func(event: Dictionary) -> bool: return str(event.type) == kind).size()

func total(values: Dictionary) -> int:
	var value := 0
	for item in values.values():
		value += int(item)
	return value

func advance_to(r, target_us: int, chunk_us: int = 0) -> void:
	if chunk_us <= 0:
		r.update_us(target_us - int(r.time_us))
		return
	while r.status == "running" and int(r.time_us) < target_us:
		r.update_us(mini(chunk_us, target_us - int(r.time_us)))

func test_contract_and_supply(c: Dictionary) -> void:
	check(c.schema_version == 3 and c.level_number == 4 and c.level_id == "serpent-04", "new level identity is schema 3 / level 4")
	check(c.region_id == "ruins" and c.boss_profile == "armored_serpent", "new ruins guardian contract")
	check(c.defense_target.id == "supply_cart" and c.defense_target.fixed == true, "supply cart stays fixed")
	check(c.scene_layout == "res://data/scenes/ruins-cart.json", "separate ruins scene selected")
	check(c.width == 10 and c.height == 8 and Vector2i(int(c.transport.entrance_cell[0]), int(c.transport.entrance_cell[1])) == Vector2i(3, 8), "ruins grid and distinct entrance")
	check(c.tools.is_empty() and not str(c.content_version).is_empty(), "no tools and explicit content version")
	check(c.rewards.fast_seconds == 30.0 and c.rewards.normal_seconds == 45.0, "explicit reward thresholds, not applied by this test")
	check(c.palette.size() == 4 and c.palette.Y == "yellow", "four-color RGBY palette")
	check(c.transport.outbound_speed_cells_sec == 2.5 and c.transport.returning_speed_cells_sec == 2.0, "normal base-worker travel speeds")
	check(c.transport.pickup_pause_sec == 0.3 and c.transport.unload_pause_sec == 0.2, "normal pickup and unload delays")
	check(c.parameters.cannon_cooldown_sec == 0.65 and c.parameters.projectile_flight_sec == 0.45 and c.parameters.max_inflight_ants == 4, "normal cannon and carrier parameters")
	var r = loaded(c)
	check(r.board.size() == 24 and c.segments.size() == 12, "24 beads and 12 body segments")
	var hp := {"red": 0, "blue": 0, "green": 0, "yellow": 0}
	var armor := 0
	for segment in c.segments:
		hp[segment.color] += int(segment.hp)
		check(int(segment.hp) == (2 if segment.kind == "armored" else 1), "normal HP1 / armored HP2: " + str(segment.id))
		if segment.kind == "armored":
			armor += 1
	check(armor == 4 and total(hp) == 16, "four armored segments and 16 required damage")
	for color in COLORS:
		check(r.initial_counts[color] == 6 and hp[color] == 4, "six supply / four HP / two surplus: " + color)
	for number in range(1, 4):
		check(c.grid != config(number).grid, "ruins mosaic differs from forest level " + str(number))
	var deadline := (float(c.serpent.goal_s) - float(c.serpent.head_start_s)) / float(c.serpent.speed_units_sec)
	check(is_equal_approx(deadline, 66.0) and deadline >= 60.0 and deadline <= 75.0, "candidate deadline is 66 seconds")
	for invalid_entrance in [[3, 7], [11, 8], [3.5, 8], [3], "3,8"]:
		var malformed := c.duplicate(true)
		malformed.transport.entrance_cell = invalid_entrance
		check(not Rules.validate_level(malformed).is_empty(), "malformed entrance rejected: " + str(invalid_entrance))

func test_blocked_opening(c: Dictionary) -> void:
	var r = loaded(c)
	check(r.color_states().yellow.state == "blocked" and r.available_counts().yellow == 6 and r.reachable_cell_ids("yellow").is_empty(), "all six yellow core beads initially inaccessible")
	for color in ["red", "blue", "green"]:
		var target: Dictionary = r.best_target(color)
		check(int(target.distance) >= 3 and int(target.distance) <= 5 and target.path[0] == [3, 8], "RGB first carrier starts at ruins entrance with 3–5 cell path: " + color)
	var before: Dictionary = r.snapshot()
	var denied: Dictionary = r.click_color("yellow")
	check(not denied.ok and denied.reason == "color_blocked" and not denied.queued and r.snapshot() == before, "initial yellow rejection changes nothing and queues nothing")
	denied = r.click_color("purple")
	check(not denied.ok and denied.reason == "unknown_color" and not denied.queued and r.snapshot() == before, "unknown color is also pure rejection")
	r.update_us(2000000)
	check(r.status == "ready" and r.time_us == 0 and r.threat_started_us == -1, "forbidden opening inputs never start the threat")
	var accepted: Dictionary = r.click_color("red")
	check(accepted.ok and accepted.cell_id == 53 and r.tasks.size() == 1 and r.reservations.size() == 1, "matching red shell click reserves exactly one gate bead")
	r.update_us(1199999)
	check(r.board.has(53) and r.reachable_cell_ids("yellow").is_empty(), "reservation and travel cannot prematurely open yellow")
	r.update_us(1)
	check(not r.board.has(53) and r.reachable_cell_ids("yellow") == [43], "actual shell pickup opens one orthogonal yellow entry")
	check(r.dispatched_counts.yellow == 0 and r.available_counts().yellow == 6 and r.tasks.size() == 1, "old forbidden yellow input never becomes queued work")
	accepted = r.click_color("yellow")
	check(accepted.ok and accepted.cell_id == 43 and not accepted.queued and r.tasks.size() == 2, "new explicit yellow click dispatches only after opening")
	check(r.conservation_errors().is_empty(), "opening preserves bead/ammo conservation")

func test_strict_capacity(c: Dictionary) -> void:
	var r = loaded(c)
	for color in ["red", "blue", "green", "red"]:
		var count: int = r.tasks.size()
		var result: Dictionary = r.click_color(color)
		check(result.ok and not result.queued and r.tasks.size() == count + 1, "one accepted click means one ant at capacity boundary")
	check(r.tasks.size() == 4 and r.reservations.size() == 4 and r.board.size() == 24, "four slots reserve four distinct uncollected beads")
	var before: Dictionary = r.snapshot()
	var denied: Dictionary = r.click_color("blue")
	check(not denied.ok and denied.reason == "carrier_limit" and not denied.queued and r.snapshot() == before, "fifth click is rejected without mutation or hidden queue")
	r.update_us(15000000)
	check(total(r.dispatched_counts) == 4 and total(r.delivered_counts) == 4 and r.tasks.is_empty() and r.board.size() == 20, "elapsed time cannot repeat accepted clicks or execute rejected fifth click")
	check(event_count(r.drain_events(), "ant_dispatched") == 4, "exactly four dispatch events before new explicit input")
	check(r.click_color("yellow").ok and total(r.dispatched_counts) == 5, "released capacity requires a fresh explicit click")
	r.set_paused(true)
	before = r.snapshot()
	denied = r.click_color("red")
	check(not denied.ok and denied.reason == "simulation_frozen" and not denied.queued and r.snapshot() == before, "paused input is pure rejection")
	check(r.conservation_errors().is_empty(), "capacity and rejected-input accounting conserved")

func replay(c: Dictionary, chunk_us: int = 0) -> Dictionary:
	var r = loaded(c)
	var paths: Array = []
	var trips: Array = []
	var events: Array = r.drain_events()
	var peak := 0
	var previous := -1400000
	for input in c.solution.inputs:
		var at_us := Rules.seconds_to_us(float(input.at_sec))
		check(at_us - previous >= 1400000, str(c.level_id) + " scheduled input gap is at least 1.4 seconds")
		previous = at_us
		advance_to(r, at_us, chunk_us)
		check(r.time_us == at_us, str(c.level_id) + " input occurs at authored simulation time")
		var count: int = r.tasks.size()
		var reserved: int = r.reservations.size()
		var beads: int = r.board.size()
		var result: Dictionary = r.click_color(str(input.color))
		check(result.ok and not result.queued, "%s accepts authored click at %.1f without retry" % [c.level_id, input.at_sec])
		if not result.ok:
			break
		check(r.tasks.size() == count + 1 and r.reservations.size() == reserved + 1 and r.board.size() == beads, "one click reserves one bead, dispatches one ant, does not collect early")
		var task: Dictionary = r.tasks[result.task_id]
		check(task.carrier_type == "worker" and task.speed_multiplier == 1.0 and r.ant_loadout.level == 1 and r.speed_multiplier == 1, "replay uses unupgraded level-one worker at normal simulation speed")
		var origin: Array = c.transport.get("entrance_cell", [5, 8])
		check(Vector2i(int(task.path[0][0]), int(task.path[0][1])) == Vector2i(int(origin[0]), int(origin[1])) and task.path.size() == int(task.distance_cells) + 1, "carrier follows exact configured entrance route")
		var distance := int(task.distance_cells)
		var expected_trip := distance * 900000 + 500000
		check(int(task.delivery_us) - int(task.depart_us) == expected_trip, "transport time derives from distance plus pickup/unload")
		paths.append(distance)
		trips.append(expected_trip)
		peak = maxi(peak, int(r.tasks.size()))
		check(peak <= 4 and r.conservation_errors().is_empty(), "authored replay never exceeds four or violates conservation")
		events.append_array(r.drain_events())
	advance_to(r, 75000000, chunk_us)
	events.append_array(r.drain_events())
	check(r.status == "victory" and r.terminal_reason == "final_segment_hit", str(c.level_id) + " wins on actual final hit")
	check(event_count(events, "ant_dispatched") == c.solution.inputs.size() and event_count(events, "cannon_fired") == c.solution.inputs.size() and event_count(events, "segment_hit") == c.solution.inputs.size(), "accepted click count equals carrier, shot, and damage counts")
	check(event_count(events, "victory") == 1 and r.board.size() > 0 and r.conservation_errors().is_empty(), "victory occurs once with uncleared surplus board and conserved accounting")
	return {"rules": r, "paths": paths, "trips": trips, "peak": peak, "events": events}

func test_authored_replays(c: Dictionary) -> void:
	var actual := replay(c)
	var r = actual.rules
	check(r.terminal_time_us == 27350000 and r.snapshot().dragon_contact_us == 66000000, "ruins baseline wins at 27.35 s before 66 s contact")
	check(r.board.size() == 8 and actual.peak == 4 and c.solution.inputs.size() == 16, "ruins uses exactly 16 inputs and leaves eight surplus beads")
	var short_paths := 0
	var long_paths := 0
	for distance in actual.paths:
		if int(distance) >= 3 and int(distance) <= 5:
			short_paths += 1
		elif int(distance) == 6:
			long_paths += 1
	check(short_paths == 13 and long_paths == 3, "13 ordinary 3–5 cell trips, only three sparse 6-cell trips")
	for color in COLORS:
		check(r.dispatched_counts[color] == 4 and r.hit_counts[color] == 4 and r.available_counts()[color] == 2, "four explicit hits with two surplus beads: " + color)
	var frame_replay := replay(c, 100000)
	check(frame_replay.rules.snapshot() == r.snapshot() and frame_replay.events == actual.events, "100 ms frame stepping exactly matches direct event replay")
	reports.append({"level_id": c.level_id, "terminal_time_us": r.terminal_time_us, "deadline_us": r.snapshot().dragon_contact_us, "accepted_clicks": c.solution.inputs.size(), "minimum_input_gap_sec": 1.4, "max_carriers": actual.peak, "path_cells": actual.paths, "complete_trip_us": actual.trips, "surplus_beads": r.board.size(), "worker_level": 1, "tool_uses": 0, "rewards_applied": 0})
	for number in range(1, 4):
		var old := config(number)
		check(not old.transport.has("entrance_cell"), "forest default entrance remains unchanged")
		var old_result := replay(old)
		var old_rules = old_result.rules
		check(old_rules.terminal_time_us == EXPECTED_OLD_TERMINAL_US[number - 1] and old_rules.snapshot().dragon_contact_us == 60000000, "old level %d terminal timing and 60 s contact unchanged" % number)
		reports.append({"level_id": old.level_id, "terminal_time_us": old_rules.terminal_time_us, "deadline_us": old_rules.snapshot().dragon_contact_us, "regression": "unchanged"})

func run() -> void:
	var c := config(4)
	test_contract_and_supply(c)
	test_blocked_opening(c)
	test_strict_capacity(c)
	test_authored_replays(c)
	print(JSON.stringify({"suite": "one_ruins_level_bounded_acceptance", "engine": Engine.get_version_info().string, "assertions": assertions, "passed": failures.is_empty(), "failures": failures, "levels": reports, "scope": "one new region/guardian candidate plus three existing production replays only; automated rules verification, not human visual acceptance"}))
	quit(0 if failures.is_empty() else 1)
