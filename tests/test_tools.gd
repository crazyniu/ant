extends SceneTree
const Rules = preload("res://scripts/rescue_rules.gd")
var failures: Array[String] = []
var assertions: int = 0
var groups: Array[String] = []
var proofs: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures.append(message)
		push_error(message)

func fixture(grid: Array, columns: Array = [], armors: Array = [], parameters: Dictionary = {}, dragon: Dictionary = {}) -> Dictionary:
	var palette := {"R": "red", "B": "blue", "G": "green"}
	var counts: Dictionary = {}
	for row in grid:
		for symbol in str(row):
			if symbol != ".":
				counts[palette[symbol]] = int(counts.get(palette[symbol], 0)) + 1
	if columns.is_empty():
		for color in counts:
			columns.append({"id": color, "teams": [{"id": color + "-1", "color": color, "quota": counts[color]}]})
	if armors.is_empty():
		for color in counts:
			armors.append({"id": "armor-" + color, "color": color, "demand": counts[color]})
	var params := {"dispatch_interval_sec": 0.1, "transport_speed_cells_sec": 10.0, "max_inflight_ants": 20, "cannon_cooldown_sec": 0.5, "projectile_flight_sec": 1.0}
	params.merge(parameters, true)
	var route := {"route_length": 100.0, "speed_units_sec": 1.0, "initial_position": 0.0, "knockback_distance": 0.0, "max_knockback_distance": 0.0}
	route.merge(dragon, true)
	return {"schema_version": 1, "level_id": "tools-fixture", "production_level_number": 16, "width": str(grid[0]).length(), "height": grid.size(), "grid": grid, "palette": palette, "columns": columns, "armors": armors, "parameters": params, "dragon": route}

func make(config: Dictionary):
	var rules = Rules.new()
	check(rules.load_level(config), "fixture validates: " + str(rules.validation_errors))
	return rules

func events_of(rules, type: String) -> Array:
	return rules.drain_events().filter(func(event: Dictionary) -> bool: return event.type == type)

func unchanged_request(rules, id: String, payload: Dictionary, reason: String) -> Dictionary:
	var before: Dictionary = rules.replay_state()
	var result: Dictionary = rules.request_tool(id, payload)
	check(not result.ok and not result.consumed and result.reason == reason, id + " fails explicitly with " + reason + ": " + str(result))
	check(rules.replay_state() == before, id + " failure preserves exact state, cached routes, events, quotas, counters and clocks")
	return result

func test_unlocks_and_extra_slot() -> void:
	groups.append("unlock_configuration_one_use_retry_and_extra_slot")
	for level_number in [1, 3, 6, 9, 16]:
		var config := fixture(["R"])
		config.production_level_number = level_number
		var r = make(config)
		for i in range(4):
			check(bool(r.tool_states()[i].unlocked) == (level_number >= [3, 6, 9, 16][i]), "draft tool unlocks follow explicit level number")
		if level_number == 1:
			unchanged_request(r, "extra_slot", {}, "tool_locked")
	var r = make(fixture(["R"]))
	var original: Dictionary = r.snapshot()
	var result: Dictionary = r.request_tool("extra_slot")
	check(result.ok and result.consumed and r.slots.size() == 6 and r.slots[5] == null, "extra slot adds exactly the sixth slot")
	check(r.time_us == 0 and r.status == "ready", "extra slot does not start threat or advance time")
	check(r.board == original.board and r.inventory == original.inventory and r.columns == original.columns, "extra slot changes no quota or beads")
	check(events_of(r, "tool_used").size() == 1, "one successful tool_used event")
	unchanged_request(r, "extra_slot", {}, "tool_already_used")
	check(r.restart() and r.slots.size() == 5 and r.tool_uses.is_empty(), "retry resets slots and all tool uses")
	check(r.request_tool("extra_slot").ok, "extra slot can be reused after retry")
	unchanged_request(r, "nonexistent", {}, "unknown_tool")
	r = make(fixture(["R"]))
	r.slots.append(null)
	unchanged_request(r, "extra_slot", {}, "slot_already_added")
	var config := fixture(["R"])
	config.tools = [{"id": "recall", "unlock_level": 1, "uses_per_level": 1}]
	config.production_level_number = 1
	r = make(config)
	check(r.tool_states().size() == 1 and r.tool_states()[0].unlocked, "explicit tool unlock configuration overrides draft values")
	unchanged_request(r, "extra_slot", {}, "unknown_tool")
	for broken in [[{"id": "recall", "unlock_level": 1, "uses_per_level": 2}], [{"id": "oops", "unlock_level": 1, "uses_per_level": 1}], [null], [{"id": "recall", "unlock_level": "soon", "uses_per_level": 1}]]:
		config.tools = broken
		check(not Rules.new().load_level(config), "malformed tool configuration rejects")

func test_blocked_tools() -> void:
	groups.append("extra_slot_and_recall_unblock_without_losing_waiting_quotas")
	var columns: Array = []
	for i in range(5):
		columns.append({"id": "blue-" + str(i), "teams": [{"id": "blue-team-" + str(i), "color": "blue", "quota": 1}]})
	columns.append({"id": "red", "teams": [{"id": "red-team", "color": "red", "quota": 14}]})
	var config := fixture(["RRRRR", "RBBBR", "RB.BR", "RRRRR"], columns)
	var r = make(config)
	for i in range(5):
		r.select_front(i)
	check(r.snapshot().blocked and r.tasks.is_empty(), "five hidden blue teams are genuinely blocked")
	unchanged_request(r, "scout", {}, "slots_full")
	check(r.request_tool("extra_slot").ok and not r.snapshot().blocked, "sixth slot clears capacity blockage without fake movement")
	var hint: Dictionary = r.request_tool("scout")
	check(hint.ok and hint.team_id == "red-team", "scout identifies usable exposed front after adding slot")
	r.select_front("red")
	r.update_us(10000000)
	check(r.status == "victory" and r.conservation_errors().is_empty(), "extra slot opens a real conserving winning rescue")
	r = make(config)
	for i in range(5):
		r.select_front(i)
	check(r.request_tool("recall", {"slot": 0}).ok and not r.snapshot().blocked and r.columns[0].teams[0].remaining == 1, "recall releases a blocked slot and restores hidden source front")
	unchanged_request(r, "recall", {"slot": 1}, "tool_already_used")
	r.select_front("red")
	r.update_us(5000000)
	r.select_front("blue-0")
	r.update_us(5000000)
	check(r.status == "victory" and r.conservation_errors().is_empty(), "recalled waiting quota remains required and later completes the win")

func test_recall_reservations_and_origin() -> void:
	groups.append("recall_remaining_only_source_front_independent_outbound_returning_tasks")
	var cols := [{"id": "source", "teams": [{"id": "first", "color": "red", "quota": 3}, {"id": "second", "color": "red", "quota": 1}]}]
	var r = make(fixture(["RRRR"], cols, [], {"transport_speed_cells_sec": 1.0}))
	r.select_front("source")
	var old_tasks: Dictionary = r.tasks.duplicate(true)
	var old_reservations: Dictionary = r.reservations.duplicate(true)
	unchanged_request(r, "recall", {"slot": 0, "expected_team_id": "second"}, "stale_team_selection")
	unchanged_request(r, "recall", {}, "invalid_slot")
	var result: Dictionary = r.request_tool("recall", {"slot": 0, "expected_team_id": "first"})
	check(result.ok and result.consumed and result.remaining_quota == 2 and not result.reveal_column, "only undispatched remaining quota returns")
	check(r.columns[0].teams[0].id == "first" and r.columns[0].teams[1].id == "second" and r.slots[0] == null, "recall returns to source front and releases selected slot")
	check(r.tasks == old_tasks and r.reservations == old_reservations and r.dispatched_counts.red == 1, "recall never cancels or duplicates outbound reservation")
	check(r.conservation_errors().is_empty(), "recall conserves both ledgers")
	r.select_front("source", "first")
	r.update_us(10000000)
	r.select_front("source", "second")
	r.update_us(10000000)
	check(r.status == "victory" and r.delivered_counts.red == 4 and r.dispatched_counts.red == 4, "recalled team reselection and old task finish exactly once")
	unchanged_request(r, "recall", {"slot": 0}, "simulation_frozen")
	# One team hides its source column; the in-flight task is already returning.
	r = make(fixture(["RRR"], [], [], {"dispatch_interval_sec": 10.0, "transport_speed_cells_sec": 1.0}))
	r.select_front("red")
	r.update_us(1000000)
	check(r.tasks[1].stage == "returning", "recall returning-task fixture")
	old_tasks = r.tasks.duplicate(true)
	result = r.request_tool("recall", {"slot": 0})
	check(result.ok and result.reveal_column and r.columns[0].teams[0].remaining == 2, "recall reveals exhausted source column with only remaining two")
	check(r.tasks == old_tasks and r.reservations.is_empty(), "returning ant remains an independent task")
	r.update_us(1000000)
	check(r.delivered_counts.red == 1 and r.inventory.red == 1 and r.conservation_errors().is_empty(), "recalled returning ant delivers once, cannot debit returned team")
	# Empty/zero-remaining selection cannot consume a use.
	r = make(fixture(["R"]))
	r.select_front("red")
	unchanged_request(r, "recall", {"slot": 0}, "invalid_slot")

func test_recall_modal_pause() -> void:
	groups.append("intentional_paused_recall_selection_cancel_stale_token_no_clock_resume")
	var r = make(fixture(["RRR"], [], [], {"dispatch_interval_sec": 10.0}))
	r.select_front("red")
	check(not r.begin_tool_selection("recall").ok, "caller must pause before entering recall selection")
	r.set_speed(2)
	r.set_paused(true)
	var before: Dictionary = r.snapshot()
	unchanged_request(r, "recall", {"slot": 0}, "simulation_frozen")
	var selection: Dictionary = r.begin_tool_selection("recall")
	check(selection.ok and not selection.consumed, "explicit paused selection produces token without consumption")
	check(r.cancel_tool_selection(selection.token), "cancel valid selection token")
	check(r.snapshot() == before and r.paused, "cancel preserves gameplay state and caller-owned pause")
	unchanged_request(r, "recall", {"slot": 0, "selection_token": selection.token}, "simulation_frozen")
	selection = r.begin_tool_selection("recall")
	r.update_us(100000000)
	var result: Dictionary = r.request_tool("recall", {"slot": 0, "selection_token": selection.token})
	check(result.ok and r.paused and r.time_us == before.time_us and r.speed_multiplier == 1, "intentional paused recall works without advancing/resuming any clock")
	r.update_us(100000000)
	check(r.time_us == before.time_us, "pause remains after recall commit until caller resumes")
	r.set_paused(false)
	r.update_us(200000)
	check(r.time_us == before.time_us + 200000, "caller can explicitly resume at x1")
	r.restart()
	r.select_front("red")
	r.set_paused(true)
	unchanged_request(r, "recall", {"slot": 0, "selection_token": selection.token}, "simulation_frozen")
	unchanged_request(r, "extra_slot", {}, "simulation_frozen")
	# An internal transport failure is not an authorized selection pause.
	r.set_paused(false)
	r.reservations.clear()
	r.update_us(1000000)
	check(r.paused and not r.begin_tool_selection("recall").ok, "error pause cannot be used to authorize a tool")

func test_scout() -> void:
	groups.append("atomic_scout_valid_front_exposed_targets_armor_stock_without_removing_beads")
	var armors := [{"id": "first-blue", "color": "blue", "demand": 1}, {"id": "next-red", "color": "red", "demand": 8}]
	var r = make(fixture(["RRR", "RBR", "RRR"], [], armors))
	var before: Dictionary = r.snapshot()
	var result: Dictionary = r.request_tool("scout")
	check(result.ok and result.consumed and result.color == "red" and not result.selection_matches_armor, "scout can recommend exposed red while blue armor is current")
	check(result.exposed_cell_ids.size() == 8 and not result.exposed_cell_ids.has(4), "highlight only currently exposed legal same-color targets")
	check(result.current_armor.id == "first-blue" and result.armor_inventory == 0 and result.armor_shortfall == 1 and not result.guaranteed_solution, "scout explains current armor and stock without promising a whole solution")
	check(r.board == before.board and r.columns == before.columns and r.slots == before.slots and r.reservations == before.reservations and r.time_us == 0 and r.status == "ready", "hint is atomic information, never selects a team/removes a bead/starts threat")
	check(events_of(r, "tool_used").size() == 1, "hint emits only one successful tool consumption")
	unchanged_request(r, "scout", {}, "tool_already_used")
	var cols := [{"id": "hidden", "teams": [{"id": "blue", "color": "blue", "quota": 1}, {"id": "red", "color": "red", "quota": 8}]}]
	r = make(fixture(["RRR", "RBR", "RRR"], cols))
	unchanged_request(r, "scout", {}, "no_exposed_front_target")
	# Already reserved targets are not highlighted, and a running hint doesn't pause.
	r = make(fixture(["RRB"]))
	r.select_front("red")
	result = r.request_tool("scout")
	check(result.ok and result.color == "blue" and not r.paused and r.status == "running", "running hint leaves simulation unpaused")
	for cell_id in result.exposed_cell_ids:
		check(not r.reservations.has(cell_id), "hint excludes reserved cells")
	# Full slots are not a valid front suggestion.
	r = make(fixture(["R"]))
	for i in range(5):
		r.slots[i] = {"id": str(i)}
	unchanged_request(r, "scout", {}, "slots_full")

func replay_proof(r, proof: Dictionary) -> void:
	var copy = r.duplicate_for_replay()
	copy.speed_multiplier = 1
	for input in proof.inputs:
		copy.update_us(int(input.time_us) - copy.time_us)
		check(copy.time_us == int(input.time_us) and copy.select_front(input.column_id, input.team_id).ok, "shuffle certificate input is a real legal timed selection")
		check(copy.conservation_errors().is_empty(), "proof conserves at every input")
	copy.update_us(1000000000)
	check(copy.status == "victory" and copy.terminal_time_us == int(proof.terminal_time_us), "independent replay reaches the certified final hit, not merely a clear board")
	check(copy.conservation_errors().is_empty(), "proof conserves through terminal hit")

func test_shuffle_basic_and_atomic_failures() -> void:
	groups.append("shuffle_waiting_only_real_change_full_timed_replay_and_failure_atomicity")
	var r = make(fixture(["RB"]))
	var result: Dictionary = r.request_tool("shuffle")
	check(result.ok and result.consumed and result.proof.kind == "complete_timed_victory_replay", "shuffle requires complete winning timed replay")
	if result.ok:
		check(r.columns[0].teams[0].color == "blue" and r.columns[1].teams[0].color == "red", "shuffle commits only changed waiting layout")
		check(r.time_us == 0 and r.status == "ready" and r.tasks.is_empty(), "search never starts or advances real run")
		replay_proof(r, result.proof)
		proofs.append(result.proof)
	unchanged_request(r, "shuffle", {}, "tool_already_used")
	r = make(fixture(["RB"]))
	unchanged_request(r, "shuffle", {"search_budget": 0}, "search_budget_exhausted")
	unchanged_request(r, "shuffle", {"search_budget": 1}, "search_budget_exhausted")
	unchanged_request(r, "shuffle", {"candidate_order": ["red-1", "red-1"]}, "invalid_candidate_order")
	unchanged_request(r, "shuffle", {"candidate_order": ["red-1", "blue-1"]}, "no_changed_arrangement")
	unchanged_request(r, "shuffle", {"candidate_order": ["blue-1", "red-1"], "replay": []}, "no_verified_winning_replay")
	unchanged_request(r, "shuffle", {"candidate_order": ["blue-1", "red-1"], "replay": [null]}, "no_verified_winning_replay")
	var too_fast := [{"time_us": 0, "column_id": "red", "team_id": "blue-1"}, {"time_us": 0, "column_id": "blue", "team_id": "red-1"}]
	unchanged_request(r, "shuffle", {"candidate_order": ["blue-1", "red-1"], "replay": too_fast}, "no_verified_winning_replay")
	r = make(fixture(["RR"], [{"id": "a", "teams": [{"id": "one", "color": "red", "quota": 1}, {"id": "two", "color": "red", "quota": 1}]}]))
	unchanged_request(r, "shuffle", {}, "no_changed_arrangement")
	r = make(fixture(["RB"], [], [], {}, {"route_length": 0.5}))
	unchanged_request(r, "shuffle", {}, "no_verified_winning_replay")
	check(r.tool_uses.is_empty(), "structurally balanced but too slow shuffle does not consume")

func test_shuffle_frozen_midgame() -> void:
	groups.append("shuffle_frozen_inventory_returning_outbound_projectile_cooldown_dragon_deadline")
	var cols := [{"id": "r", "teams": [{"id": "red-work", "color": "red", "quota": 5}]}, {"id": "b", "teams": [{"id": "blue-wait", "color": "blue", "quota": 1}]}, {"id": "g", "teams": [{"id": "green-wait", "color": "green", "quota": 1}]}]
	var armor := [{"id": "red-now", "color": "red", "demand": 1}, {"id": "red-later", "color": "red", "demand": 4}, {"id": "blue-last", "color": "blue", "demand": 1}, {"id": "green-last", "color": "green", "demand": 1}]
	var config := fixture(["RRRRRBG"], cols, armor, {"cannon_cooldown_sec": 4.0, "projectile_flight_sec": 2.0, "dispatch_interval_sec": 0.3, "transport_speed_cells_sec": 2.0})
	var r = make(config)
	r.select_front("r")
	r.update_us(1100000)
	check(not r.projectile.is_empty() and not r.tasks.is_empty() and r.slots[0] != null, "midgame fixture includes projectile, ant tasks, work slot and cooldown")
	var original: Dictionary = r.snapshot()
	var exact: Dictionary = r.replay_state()
	var clone = r.duplicate_for_replay()
	check(clone.replay_state() == exact, "clone includes exact event queue, counters, fractional carry and all clocks")
	clone.update_us(100000)
	check(r.replay_state() == exact, "clone cannot alias mutable source state")
	var result: Dictionary = r.request_tool("shuffle")
	check(result.ok, "midgame shuffle can verify a win from the actual frozen state")
	if result.ok:
		check(r.time_us == original.time_us and r.tasks == original.tasks and r.projectile == original.projectile and r.cooldown_until_us == original.cooldown_until_us and r.inventory == original.inventory and r.slots == original.slots and r.board == original.board and r.reservations == original.reservations, "shuffle touches no current work, stock, board, projectile, cooldown or task")
		check(result.proof.start_contact_us == original.dragon_contact_us and result.proof.start_tasks == original.tasks and result.proof.start_projectile == original.projectile, "proof is anchored to remaining dragon contact and existing work")
		replay_proof(r, result.proof)
		proofs.append(result.proof)
	# The same structurally solvable waiting layout must fail when the frozen
	# remaining time is insufficient, despite starting level being generous.
	r = make(config)
	r.select_front("r")
	r.update_us(1100000)
	r._dragon_anchor_position = 99.9
	r._dragon_anchor_us = r.time_us
	r._recompute_contact()
	unchanged_request(r, "shuffle", {}, "no_verified_winning_replay")
	# Preserve fractional time and current x2 speed in live state during search.
	r = make(fixture(["RBG"]))
	r.select_front("red")
	r.set_speed(2)
	r.update(0.00000025)
	var fraction: float = r._fractional_us
	result = r.request_tool("shuffle")
	check(result.ok and r.speed_multiplier == 2 and r._fractional_us == fraction, "shuffle proof uses simulation time without changing live x2 or fractional remainder")

func test_shuffle_terminal_boundaries_and_stock() -> void:
	groups.append("shuffle_full_last_hit_boundary_noncurrent_stock_and_recalled_origin")
	var r = make(fixture(["RB"]))
	var result: Dictionary = r.request_tool("shuffle")
	check(result.ok, "timed baseline for shuffle contact boundary")
	if result.ok:
		var end_sec: float = float(result.proof.terminal_time_us) / Rules.TIMEBASE
		var config := fixture(["RB"], [], [], {}, {"route_length": end_sec})
		var tie = make(config)
		var tie_result: Dictionary = tie.request_tool("shuffle")
		check(tie_result.ok and tie_result.proof.terminal_time_us == result.proof.terminal_time_us, "shuffle accepts a proof whose final hit exactly ties dragon contact")
		if tie_result.ok:
			replay_proof(tie, tie_result.proof)
		config.dragon.route_length = end_sec - 0.000001
		var earlier = make(config)
		unchanged_request(earlier, "shuffle", {}, "no_verified_winning_replay")
	var armors := [{"id": "red-now", "color": "red", "demand": 2}, {"id": "blue-later", "color": "blue", "demand": 2}, {"id": "green-last", "color": "green", "demand": 2}]
	r = make(fixture(["BBRRGG"], [], armors))
	r.select_front("blue")
	r.update_us(1000000)
	check(r.inventory.blue == 2 and r.armor_index == 0, "noncurrent stock exists before frozen shuffle")
	var stock: Dictionary = r.inventory.duplicate(true)
	result = r.request_tool("shuffle")
	check(result.ok and r.inventory == stock and result.proof.start_inventory == stock, "shuffle proof retains and uses noncurrent inventory, never starts inventory empty")
	if result.ok:
		replay_proof(r, result.proof)
		proofs.append(result.proof)
	# Shuffled team returns to the column from which it was actually selected,
	# not its old pre-shuffle location. Existing outbound task still owns its ID.
	r = make(fixture(["RRBB"], [], [], {"dispatch_interval_sec": 10.0}))
	result = r.request_tool("shuffle")
	check(result.ok, "recall-origin shuffle fixture verified")
	if result.ok:
		r.select_front("red", "blue-1")
		var tasks_before: Dictionary = r.tasks.duplicate(true)
		var recall: Dictionary = r.request_tool("recall", {"slot": 0, "expected_team_id": "blue-1"})
		check(recall.ok and recall.column_id == "red" and r.columns[0].teams[0].id == "blue-1" and r.tasks == tasks_before, "shuffled team recall origin is its actual dispatch column")
		check(r.conservation_errors().is_empty(), "shuffle followed by recall conserves quota")

func test_real_validation_shuffles() -> void:
	groups.append("three_authored_levels_finite_shuffle_search_fail_closed_or_verified_win")
	for level_id in ["validation-01", "validation-02", "validation-03"]:
		var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/" + level_id + ".json"))
		# This is test-only tool access, not shipped progression or changing content.
		config.production_level_number = 16
		var r = make(config)
		var before: Dictionary = r.replay_state()
		var result: Dictionary = r.request_tool("shuffle")
		check(r.time_us == 0 and r.status == "ready" and r.conservation_errors().is_empty(), "authored-level search never mutates live simulation: " + level_id)
		if result.ok:
			replay_proof(r, result.proof)
			var proof: Dictionary = result.proof.duplicate(true)
			proof["validation_level"] = level_id
			proofs.append(proof)
		else:
			check(not result.consumed and r.replay_state() == before, "unproved authored-level shuffle fails closed exactly: " + level_id)
			check(result.reason in ["search_budget_exhausted", "no_verified_winning_replay", "no_changed_arrangement"], "finite search reports honest nonproof reason: " + level_id)
			proofs.append({"validation_level": level_id, "result": result})

func run() -> void:
	test_unlocks_and_extra_slot()
	test_blocked_tools()
	test_recall_reservations_and_origin()
	test_recall_modal_pause()
	test_scout()
	test_shuffle_basic_and_atomic_failures()
	test_shuffle_frozen_midgame()
	test_shuffle_terminal_boundaries_and_stock()
	test_real_validation_shuffles()
	var report := {"api_version": Rules.API_VERSION, "pass": failures.is_empty(), "assertions": assertions, "failures": failures, "groups": groups, "proofs": proofs, "scope": "P3 pure four-tool rules and full frozen-state shuffle replay. Not UI, saves, editor, human playtest, audio or 30-level acceptance."}
	DirAccess.make_dir_recursive_absolute("res://reports/tools")
	var file := FileAccess.open("res://reports/tools/test-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	print(JSON.stringify(report, "  "))
	quit(0 if failures.is_empty() else 1)
