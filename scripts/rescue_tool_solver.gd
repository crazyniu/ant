extends RefCounted
## Bounded, deterministic, fail-closed shuffle search. Search success is not proof:
## a separate replay from the exact frozen state must reach the final armor hit.
const CLICK_INTERVAL_US := 750000
const DEFAULT_BUDGET := 16000
const MAX_BUDGET := 50000
const MAX_CANDIDATES := 12
var _steps_left: int = 0
var _steps_used: int = 0

func find_verified_shuffle(source, options: Dictionary = {}) -> Dictionary:
	if options.has("search_budget") and (not source._is_integer(options.search_budget) or int(options.search_budget) < 0):
		return {"ok": false, "reason": "invalid_search_budget"}
	_steps_left = mini(MAX_BUDGET, int(options.get("search_budget", DEFAULT_BUDGET)))
	_steps_used = 0
	if _steps_left == 0:
		return {"ok": false, "reason": "search_budget_exhausted"}
	var waiting: Array = []
	for column in source.columns:
		waiting.append_array(column.teams)
	if waiting.size() < 2:
		return {"ok": false, "reason": "no_changed_arrangement"}
	var orders: Array = []
	if options.has("candidate_order"):
		var parsed := _parse_order(waiting, options.candidate_order)
		if not parsed.ok:
			return parsed
		orders.append(parsed.teams)
	else:
		# Preserve all team objects and per-column lengths. No randomized mutation.
		for offset in range(1, mini(waiting.size(), MAX_CANDIDATES)):
			var order: Array = []
			for i in range(waiting.size()):
				order.append(waiting[(i + offset) % waiting.size()])
			orders.append(order)
		var reversed := waiting.duplicate(true)
		reversed.reverse()
		orders.append(reversed)
	var changed_candidates := 0
	for order in orders:
		if not _meaningfully_changed(waiting, order):
			continue
		changed_candidates += 1
		var candidate_columns: Array = source.columns.duplicate(true)
		var index := 0
		for column in candidate_columns:
			for i in range(column.teams.size()):
				column.teams[i] = order[index].duplicate(true)
				index += 1
		var plan: Dictionary
		if options.has("replay"):
			plan = {"ok": true, "inputs": options.replay}
		else:
			plan = _find_plan(_candidate_copy(source, candidate_columns))
		if not plan.ok:
			if _steps_left <= 0:
				return {"ok": false, "reason": "search_budget_exhausted", "search_steps": _steps_used}
			continue
		var proof := _verify_replay(_candidate_copy(source, candidate_columns), plan.inputs)
		if proof.ok:
			proof["run_id"] = source.run_id
			proof["start_time_us"] = source.time_us
			proof["start_contact_us"] = source.snapshot().dragon_contact_us
			proof["start_cooldown_until_us"] = source.cooldown_until_us
			proof["start_inventory"] = source.inventory.duplicate(true)
			proof["start_tasks"] = source.tasks.duplicate(true)
			proof["start_projectile"] = source.projectile.duplicate(true)
			proof["search_steps"] = _steps_used
			return {"ok": true, "columns": candidate_columns, "proof": proof}
		if _steps_left <= 0:
			return {"ok": false, "reason": "search_budget_exhausted", "search_steps": _steps_used}
	return {"ok": false, "reason": "no_changed_arrangement" if changed_candidates == 0 else "no_verified_winning_replay", "search_steps": _steps_used}

func _parse_order(waiting: Array, ids: Variant) -> Dictionary:
	if not ids is Array or ids.size() != waiting.size():
		return {"ok": false, "reason": "invalid_candidate_order"}
	var by_id: Dictionary = {}
	for team in waiting:
		by_id[str(team.id)] = team
	var result: Array = []
	for team_id in ids:
		if not team_id is String or not by_id.has(team_id):
			return {"ok": false, "reason": "invalid_candidate_order"}
		result.append(by_id[team_id])
		by_id.erase(team_id)
	return {"ok": true, "teams": result}

func _meaningfully_changed(before: Array, after: Array) -> bool:
	for i in range(before.size()):
		# Swapping otherwise identical teams is not a useful rearrangement.
		if str(before[i].color) != str(after[i].color) or int(before[i].remaining) != int(after[i].remaining):
			return true
	return false

func _candidate_copy(source, candidate_columns: Array):
	var copy = source.duplicate_for_replay()
	copy.columns = candidate_columns.duplicate(true)
	# Replay in simulation time, never by rewinding the dragon or transport clocks.
	copy.paused = false
	copy.speed_multiplier = 1
	copy.drain_events()
	return copy

func _spend_step() -> bool:
	if _steps_left <= 0:
		return false
	_steps_left -= 1
	_steps_used += 1
	return true

func _choose_front(sim) -> Dictionary:
	if sim.slots.find(null) < 0:
		return {}
	for column in sim.columns:
		if not column.teams.is_empty() and not sim.best_target(str(column.teams[0].color)).is_empty():
			return {"column_id": column.id, "team_id": column.teams[0].id}
	for column in sim.columns:
		for i in range(1, column.teams.size()):
			if not sim.best_target(str(column.teams[i].color)).is_empty():
				return {"column_id": column.id, "team_id": column.teams[0].id}
	return {}

func _find_plan(sim) -> Dictionary:
	var inputs: Array = []
	var next_click_us: int = sim.time_us if sim.status == "ready" else sim.time_us + CLICK_INTERVAL_US
	while sim.status in ["ready", "running"] and not sim.paused:
		if not _spend_step():
			return {"ok": false}
		if not sim.conservation_errors().is_empty():
			return {"ok": false}
		if sim.time_us >= next_click_us:
			var choice := _choose_front(sim)
			if not choice.is_empty():
				choice["time_us"] = sim.time_us
				if not sim.select_front(choice.column_id, choice.team_id).ok:
					return {"ok": false}
				inputs.append(choice)
			next_click_us = sim.time_us + CLICK_INTERVAL_US
		if sim.status == "ready":
			return {"ok": false}
		if sim.status != "running":
			break
		var next_time: int = mini(sim._next_event_time(), next_click_us)
		if next_time < sim.time_us or next_time == sim.NEVER:
			return {"ok": false}
		sim._advance_to(next_time)
		sim.drain_events()
	return {"ok": sim.status == "victory" and sim.terminal_reason == "final_armor_hit" and sim.conservation_errors().is_empty(), "inputs": inputs}

func _verify_replay(sim, inputs: Variant) -> Dictionary:
	if not inputs is Array:
		return {"ok": false}
	var previous_time: int = -1
	for input in inputs:
		if not input is Dictionary or not sim._is_integer(input.get("time_us")) or not input.get("column_id") is String or not input.get("team_id") is String:
			return {"ok": false}
		var input_time := int(input.time_us)
		if input_time < sim.time_us or (previous_time >= 0 and input_time - previous_time < CLICK_INTERVAL_US):
			return {"ok": false}
		# A running game keeps moving while the next intentional click is made.
		if previous_time < 0 and sim.status == "running" and input_time < sim.time_us + CLICK_INTERVAL_US:
			return {"ok": false}
		if not _advance_checked(sim, input_time) or sim.time_us != input_time:
			return {"ok": false}
		if not _spend_step() or not sim.select_front(input.column_id, input.team_id).ok:
			return {"ok": false}
		previous_time = input_time
	while sim.status == "running" and not sim.paused:
		if not _spend_step() or not sim.conservation_errors().is_empty():
			return {"ok": false}
		var next_time: int = sim._next_event_time()
		if next_time < sim.time_us or next_time == sim.NEVER:
			return {"ok": false}
		sim._advance_to(next_time)
		sim.drain_events()
	if sim.status != "victory" or sim.terminal_reason != "final_armor_hit" or not sim.conservation_errors().is_empty():
		return {"ok": false}
	return {"ok": true, "kind": "complete_timed_victory_replay", "terminal_time_us": sim.terminal_time_us, "inputs": inputs.duplicate(true), "click_interval_us": CLICK_INTERVAL_US}

func _advance_checked(sim, target_us: int) -> bool:
	while sim.time_us < target_us:
		if sim.status != "running" or sim.paused or not _spend_step() or not sim.conservation_errors().is_empty():
			return false
		var next_time: int = mini(target_us, sim._next_event_time())
		if next_time < sim.time_us:
			return false
		sim._advance_to(next_time)
		sim.drain_events()
	return true
