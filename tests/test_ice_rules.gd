extends SceneTree
## Bounded acceptance for serpent-05 only. Never runs a generator or other levels.
## No save writes, growth, advertising, chain elimination, tools, or external hits.
const Rules = preload("res://scripts/rescue_rules.gd")
const COLORS := ["red", "blue", "green", "yellow"]
const EXPECTED_PATHS := [3, 4, 4, 4, 4, 3, 4, 5, 4, 3, 6, 5, 5, 5, 6, 5]
const OLD_LEVEL_SHA256 := "3c3359aff7a523e878c84d2df535eb2a1e058f01806ca29f14e4126cb63dad07"
const RULES_SHA256 := "14a5b20efdf237fbf271ea8749b35580d012485aee8a529a30e53487852c7c23"
var failures: Array[String] = []
var assertions := 0
var opening_reports: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures.append(label)
		push_error(label)

func loaded(c: Dictionary):
	var r = Rules.new()
	check(r.load_level(c), "serpent-05 validates: " + str(r.validation_errors))
	return r

func event_count(events: Array, kind: String) -> int:
	return events.filter(func(event: Dictionary) -> bool: return str(event.type) == kind).size()

func test_contract(c: Dictionary) -> void:
	check(c.schema_version == 3 and c.level_number == 5 and c.level_id == "serpent-05", "new schema-3 level 05 identity")
	check(c.region_id == "ice_valley" and c.boss_profile == "armored_serpent", "ice-valley armored guardian")
	check(c.defense_target == {"id": "winter_camp", "display_name": "Winter Camp", "fixed": true}, "fixed winter-camp target")
	check(c.scene_layout == "res://data/scenes/ice-camp.json", "separate ice scene configuration")
	check(c.width == 10 and c.height == 8 and int(c.transport.entrance_cell[0]) == 6 and int(c.transport.entrance_cell[1]) == 8, "10 by 8 mosaic with right-offset entrance")
	check(c.tools.is_empty() and not str(c.content_version).is_empty(), "no tools; explicit content version")
	check(c.palette.size() == 4 and c.palette.Y == "yellow", "four existing RGBY colors only")
	check(c.transport.carrier_type == "worker" and c.transport.outbound_speed_cells_sec == 2.5 and c.transport.returning_speed_cells_sec == 2.0, "unchanged basic worker movement")
	check(c.transport.pickup_pause_sec == 0.3 and c.transport.unload_pause_sec == 0.2, "unchanged pickup and unload pauses")
	check(c.parameters.max_inflight_ants == 4 and c.parameters.projectile_flight_sec == 0.45 and c.parameters.cannon_cooldown_sec == 0.65, "unchanged four-carrier and cannon parameters")
	var r = loaded(c)
	check(r.board.size() == 24 and c.segments.size() == 12, "24 beads and 12 initial segments")
	var hp := {"red": 0, "blue": 0, "green": 0, "yellow": 0}
	var armored := 0
	var normal := 0
	for segment in c.segments:
		hp[segment.color] += int(segment.hp)
		if segment.kind == "armored":
			armored += 1
		else:
			normal += 1
		check(int(segment.hp) == (2 if segment.kind == "armored" else 1), "HP matches visible segment kind: " + str(segment.id))
	check(armored == 4 and normal == 8, "eight normal plus four armored segments")
	for color in COLORS:
		check(r.initial_counts[color] == 6 and hp[color] == 4, "six supply, four required damage, two surplus: " + color)
	check(float(c.serpent.head_start_s) >= c.segments.size() * float(c.serpent.pitch), "complete initial body fits finite route")
	check(is_equal_approx(float(c.serpent.head_start_s) - c.segments.size() * float(c.serpent.pitch), 6.0), "initial tail stays six route units after the start")
	check(is_equal_approx((float(c.serpent.goal_s) - float(c.serpent.head_start_s)) / float(c.serpent.speed_units_sec), 66.0), "66-second candidate contact budget")
	check(c.rewards.fast_seconds == 28.0 and c.rewards.normal_seconds == 42.0, "ice-specific reward thresholds are configuration only, never applied here")
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-04.json"))
	check(c.grid != old.grid and c.solution.inputs != old.solution.inputs and c.segments != old.segments and c.serpent != old.serpent, "ice differs in topology, input sequence, body order, and finite-route parameters")
	check(FileAccess.get_sha256("res://data/serpent-levels/serpent-04.json") == OLD_LEVEL_SHA256, "old 04 configuration byte-for-byte unchanged")
	check(FileAccess.get_sha256("res://scripts/rescue_rules.gd") == RULES_SHA256, "authoritative rules byte-for-byte unchanged")

func test_openings(c: Dictionary) -> void:
	var r = loaded(c)
	check(r.color_states().yellow.state == "blocked" and r.available_counts().yellow == 6 and r.reachable_cell_ids("yellow").is_empty(), "all six staircase-core yellow beads initially enclosed")
	var before: Dictionary = r.snapshot()
	var denied: Dictionary = r.click_color("yellow")
	check(not denied.ok and denied.reason == "color_blocked" and not denied.queued and r.snapshot() == before, "blocked yellow click neither mutates nor queues a task")
	r.update_us(2000000)
	check(r.time_us == 0 and r.status == "ready" and r.threat_started_us == -1, "blocked input cannot start threat or time")
	var choices := [
		{"color": "red", "cell_id": 56, "distance": 3, "pickup_us": 1200000, "yellow_ids": [46, 57], "yellow_distance": 4, "role": "near central fork: opens two core cells"},
		{"color": "green", "cell_id": 68, "distance": 4, "pickup_us": 1600000, "yellow_ids": [58], "yellow_distance": 5, "role": "far right mouth: opens one core cell"},
		{"color": "blue", "cell_id": 64, "distance": 4, "pickup_us": 1600000, "yellow_ids": [], "yellow_distance": -1, "role": "outer supply: provides ammo without opening the core"}
	]
	for choice in choices:
		r = loaded(c)
		var target: Dictionary = r.best_target(choice.color)
		check(int(target.cell_id) == int(choice.cell_id) and int(target.distance) == int(choice.distance), "initial choice uses actual shortest outer route: " + str(choice.color))
		var accepted: Dictionary = r.click_color(choice.color)
		check(accepted.ok and not accepted.queued and r.tasks.size() == 1 and r.board.size() == 24, "opening click reserves but does not collect: " + str(choice.color))
		r.update_us(int(choice.pickup_us) - 1)
		check(r.board.has(choice.cell_id) and r.reachable_cell_ids("yellow").is_empty(), "reservation and travel do not open core: " + str(choice.color))
		r.update_us(1)
		check(not r.board.has(choice.cell_id) and r.reachable_cell_ids("yellow") == choice.yellow_ids, "only actual pickup changes core reachability: " + str(choice.color))
		check(r.inventory[choice.color] == 0 and r.delivered_counts[choice.color] == 0, "pickup opens road but does not grant ammo early")
		if not choice.yellow_ids.is_empty():
			check(r.best_target("yellow").distance == choice.yellow_distance, "near and far openings create different yellow travel costs")
			var yellow_click: Dictionary = r.click_color("yellow")
			check(yellow_click.ok and r.tasks.size() == 2 and r.dispatched_counts.yellow == 1, "fresh explicit yellow click is required after opening")
		else:
			check(not r.click_color("yellow").ok, "blue outer collection still leaves yellow blocked")
		check(r.conservation_errors().is_empty(), "opening path preserves conservation")
		opening_reports.append(choice)

func can_dispatch(r) -> bool:
	return r.status in ["ready", "running"] and not r.paused and r.tasks.size() < 4 and not r.reachable_cell_ids().is_empty()

func observe_wait(r, tracker: Dictionary) -> void:
	var blocked: bool = r.status == "running" and not can_dispatch(r)
	if blocked and int(tracker.start_us) < 0:
		tracker.start_us = int(r.time_us)
	elif not blocked and int(tracker.start_us) >= 0:
		var duration := int(r.time_us) - int(tracker.start_us)
		if duration > 0:
			tracker.windows.append({"start_us": int(tracker.start_us), "end_us": int(r.time_us), "duration_us": duration})
			tracker.longest_us = maxi(int(tracker.longest_us), duration)
		tracker.start_us = -1

func advance_tracked(r, target_us: int, tracker: Dictionary, chunk_us: int) -> void:
	while r.status == "running" and int(r.time_us) < target_us:
		observe_wait(r, tracker)
		# Actual rule deadlines, not rounded frame sampling, determine wait boundaries.
		var next_us := mini(target_us, int(r._next_event_time()))
		if chunk_us > 0:
			next_us = mini(next_us, int(r.time_us) + chunk_us)
		check(next_us > r.time_us, "next real event advances simulation time")
		if next_us <= r.time_us:
			break
		r.update_us(next_us - int(r.time_us))
		check(r.conservation_errors().is_empty(), "conservation holds at each real event boundary")
		observe_wait(r, tracker)

func test_path(r, task: Dictionary, entrance: Array) -> void:
	var path: Array = task.path
	check(int(path[0][0]) == int(entrance[0]) and int(path[0][1]) == int(entrance[1]) and path.size() == int(task.distance_cells) + 1, "actual transport route begins at configured entrance")
	for i in range(1, path.size()):
		var previous: Array = path[i - 1]
		var cell: Array = path[i]
		check(absi(int(cell[0]) - int(previous[0])) + absi(int(cell[1]) - int(previous[1])) == 1, "transport path uses orthogonal adjacent cells")
		if i < path.size() - 1 and int(cell[0]) >= 0 and int(cell[0]) < 10 and int(cell[1]) >= 0 and int(cell[1]) < 8:
			check(not r.board.has(int(cell[1]) * 10 + int(cell[0])), "route cannot walk through a bead before pickup")
	var last: Array = path.back()
	check(int(last[1]) * 10 + int(last[0]) == int(task.cell_id), "route reaches exactly the reserved bead")
	check(int(task.pickup_us) - int(task.depart_us) == int(task.distance_cells) * 400000, "outbound time is exact path length / 2.5")
	check(int(task.delivery_us) - int(task.depart_us) == int(task.distance_cells) * 900000 + 500000, "complete trip is outbound plus pickup plus loaded return plus unload")

func replay(c: Dictionary, chunk_us: int = 0) -> Dictionary:
	var r = loaded(c)
	var events: Array = r.drain_events()
	var routes: Array = []
	var paths: Array = []
	var peak := 0
	var previous_us := -1400000
	var waits := {"start_us": -1, "longest_us": 0, "windows": []}
	for input in c.solution.inputs:
		var at_us := Rules.seconds_to_us(float(input.at_sec))
		check(at_us - previous_us >= 1400000, "every authored independent click has at least 1.4 seconds of input spacing")
		previous_us = at_us
		advance_tracked(r, at_us, waits, chunk_us)
		check(r.time_us == at_us, "input occurs at authored simulation time without retry")
		observe_wait(r, waits)
		var old_tasks: int = r.tasks.size()
		var old_reservations: int = r.reservations.size()
		var old_beads: int = r.board.size()
		var result: Dictionary = r.click_color(str(input.color))
		check(result.ok and not result.queued, "authored %s click accepted at %.1f seconds" % [input.color, input.at_sec])
		if not result.ok:
			break
		check(r.tasks.size() == old_tasks + 1 and r.reservations.size() == old_reservations + 1 and r.board.size() == old_beads, "one input creates one reservation and one ant, not an early pickup")
		var task: Dictionary = r.tasks[result.task_id].duplicate(true)
		check(task.carrier_type == "worker" and task.speed_multiplier == 1.0 and r.ant_loadout.level == 1 and r.speed_multiplier == 1, "unupgraded basic worker at normal simulation speed")
		test_path(r, task, c.transport.entrance_cell)
		routes.append(task)
		paths.append(int(task.distance_cells))
		peak = maxi(peak, int(r.tasks.size()))
		check(peak <= 4 and r.conservation_errors().is_empty(), "accepted input preserves four-carrier limit and all resource ledgers")
		observe_wait(r, waits)
		events.append_array(r.drain_events())
	advance_tracked(r, 75000000, waits, chunk_us)
	events.append_array(r.drain_events())
	check(r.status == "victory" and r.terminal_reason == "final_segment_hit", "victory comes from an actual final segment hit")
	check(r.terminal_time_us == 26900000 and r.snapshot().dragon_contact_us == 66000000, "actual terminal hit at 26.90 seconds precedes 66-second contact")
	check(c.solution.inputs.size() == 16 and peak == 4 and r.board.size() == 8, "sixteen clicks, peak four carriers, eight surplus beads")
	check(paths == EXPECTED_PATHS, "fourteen 3–5-cell routes and only two 6-cell routes")
	check(waits.longest_us == 1700000, "longest wait until a fresh legal dispatch opportunity is 1.70 seconds")
	for kind in ["color_clicked", "target_reserved", "ant_dispatched", "bead_picked_up", "bead_delivered", "cannon_fired", "segment_hit"]:
		check(event_count(events, kind) == 16, "exactly sixteen authoritative events: " + kind)
	check(event_count(events, "segment_removed") == 12 and event_count(events, "victory") == 1, "all twelve real segments removed and one victory emitted")
	check(event_count(events, "projectile_refunded") == 0 and event_count(events, "defeat") == 0 and event_count(events, "recoverable_error") == 0, "no refunds, defeat, recovery cheats, or fallback supplies")
	var picked_ids: Dictionary = {}
	var crack_count := 0
	for event in events:
		if event.type == "bead_picked_up":
			check(not picked_ids.has(event.cell_id), "each collected bead has a unique cell ID")
			picked_ids[event.cell_id] = true
		if event.type == "segment_hit":
			check(event.source == "projectile", "every damage point comes from a delivered bead and actual projectile")
			if event.kind == "armored" and int(event.hp) == 1:
				crack_count += 1
	check(crack_count == 4, "all four armor segments survive their first hit")
	for color in COLORS:
		check(r.dispatched_counts[color] == 4 and r.delivered_counts[color] == 4 and r.spent_counts[color] == 4 and r.hit_counts[color] == 4 and r.available_counts()[color] == 2, "reachable base supply, delivered ammo, real hits, and surplus match per color: " + color)
	check(r.tasks.is_empty() and r.projectile.is_empty() and r.alive_segment_ids.is_empty() and r.conservation_errors().is_empty(), "terminal state has no pending transport or shot and conserved resources")
	check(events.back().type == "victory" and events[-2].type == "segment_removed" and events[-3].type == "segment_hit" and events[-3].time_us == r.terminal_time_us, "terminal event order is real hit, removal, then victory at the same timestamp")
	return {"rules": r, "events": events, "routes": routes, "paths": paths, "peak": peak, "waits": waits}

func longest_merged_capacity_span(windows: Array) -> int:
	var longest := 0
	var start_us := -1
	var end_us := -1
	for window in windows:
		if int(window.start_us) != end_us:
			start_us = int(window.start_us)
		end_us = int(window.end_us)
		longest = maxi(longest, end_us - start_us)
	return longest

func run() -> void:
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-05.json"))
	test_contract(c)
	test_openings(c)
	var actual := replay(c)
	var frame := replay(c, 100000)
	check(actual.rules.snapshot() == frame.rules.snapshot() and actual.events == frame.events and actual.waits == frame.waits, "100-ms frame stepping matches exact-event replay including wait windows")
	var merged_capacity_span := longest_merged_capacity_span(actual.waits.windows)
	check(merged_capacity_span == 2200000, "measured full-capacity span includes the instantaneous legal handoff at 19.9 seconds")
	check(float(c.rewards.fast_seconds) > actual.rules.terminal_time_us / 1000000.0 and c.rewards.normal_seconds > c.rewards.fast_seconds and c.rewards.normal_seconds < 66.0, "provisional reward thresholds bracket this measured solution below contact")
	var report := {
		"suite": "one_ice_level_bounded_acceptance", "engine": Engine.get_version_info().string,
		"assertions": assertions, "passed": failures.is_empty(), "failures": failures,
		"scope": "serpent-05 only; base worker level 1, no tools, rewards, growth, ads, chain elimination, mechanism supplies, or external hits. No generator, 707-case batch, 30-level batch, or old-level replay.",
		"level_id": c.level_id, "level_sha256": FileAccess.get_sha256("res://data/serpent-levels/serpent-05.json"), "grid": c.grid, "entrance_cell": c.transport.entrance_cell,
		"budget": {"beads_per_color": 6, "required_damage_per_color": 4, "normal_segments": 8, "armored_segments": 4, "total_damage": 16, "surplus_per_color": 2},
		"opening_choices": opening_reports,
		"terminal_time_us": actual.rules.terminal_time_us, "deadline_us": actual.rules.snapshot().dragon_contact_us,
		"safety_margin_us": actual.rules.snapshot().dragon_contact_us - actual.rules.terminal_time_us,
		"accepted_clicks": c.solution.inputs.size(), "minimum_input_gap_sec": 1.4, "max_carriers": actual.peak,
		"path_cells": actual.paths, "ordinary_3_to_5_cell_trips": 14, "six_cell_trips": 2,
		"timed_inputs": c.solution.inputs, "transport_tasks": actual.routes,
		"longest_no_dispatch_opportunity_us": actual.waits.longest_us, "no_dispatch_windows": actual.waits.windows,
		"wait_definition": "All color buttons unable to accept a new dispatch in the authored replay. Windows end when a legal opportunity opens, including an immediate accepted input at 19.9 seconds. Voluntary thinking gaps and final delivery/shot latency are not mislabeled as forced inactivity.",
		"full_capacity_span_including_instant_handoff_us": merged_capacity_span,
		"full_capacity_span_note": "18.2 to 20.4 seconds, with one available slot and a legal new dispatch exactly at 19.9; reported separately from the longest wait to an opportunity.",
		"last_authored_input_to_victory_us": actual.rules.terminal_time_us - Rules.seconds_to_us(float(c.solution.inputs.back().at_sec)),
		"reward_thresholds": {"fast_seconds": c.rewards.fast_seconds, "normal_seconds": c.rewards.normal_seconds, "basis": "26.90-second actual base-worker replay; provisional fast threshold adds 1.10 seconds, normal threshold adds 15.10 seconds. Rewards are not applied or required."},
		"terminal_events": actual.events.slice(actual.events.size() - 3),
		"surplus_beads": actual.rules.board.size(), "hit_counts": actual.rules.hit_counts,
		"preserved_files": {"serpent-04.json": FileAccess.get_sha256("res://data/serpent-levels/serpent-04.json"), "rescue_rules.gd": FileAccess.get_sha256("res://scripts/rescue_rules.gd")},
		"acceptance_limit": "Automated configuration, reachability, accounting, transport, and true-event solution evidence only. Not human playability, visual, audio, performance, or economy-balance acceptance."
	}
	var output := FileAccess.open("res://reports/rules/ice-rules.json", FileAccess.WRITE)
	if output:
		output.store_string(JSON.stringify(report, "\t") + "\n")
	else:
		push_error("Cannot write reports/rules/ice-rules.json")
		quit(2)
		return
	var event_log_path := OS.get_environment("ICE_RULES_EVENT_LOG")
	if not event_log_path.is_empty():
		var event_log := FileAccess.open(event_log_path, FileAccess.WRITE)
		if event_log:
			event_log.store_string(JSON.stringify(actual.events, "\t") + "\n")
		else:
			push_error("Cannot write requested external evidence log")
			quit(2)
			return
	print(JSON.stringify({"suite": report.suite, "engine": report.engine, "assertions": assertions, "passed": report.passed, "failures": failures, "terminal_time_us": report.terminal_time_us, "longest_no_dispatch_opportunity_us": report.longest_no_dispatch_opportunity_us, "report": "reports/rules/ice-rules.json"}))
	quit(0 if failures.is_empty() else 1)
