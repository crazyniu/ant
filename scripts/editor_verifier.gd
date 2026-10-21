extends "res://scripts/rescue_tool_solver.gd"
## Thin authoring adapter. All choice, timing and final-hit proof remain in Solver.
const Rules = preload("res://scripts/rescue_rules.gd")

func verify_level(config: Dictionary, inputs: Variant, budget: int = DEFAULT_BUDGET) -> Dictionary:
	return _run(config, inputs, budget, false)

func solve_level(config: Dictionary, budget: int = DEFAULT_BUDGET) -> Dictionary:
	return _run(config, [], budget, true)

func _run(config: Dictionary, inputs: Variant, budget: int, search: bool) -> Dictionary:
	if not search:
		if not inputs is Array:
			return {"ok": false, "reason": "invalid_replay"}
		for input in inputs:
			if not input is Dictionary or input.get("action", "select_front") != "select_front":
				return {"ok": false, "reason": "non_selection_action_forbidden"}
	var sim = Rules.new()
	if not sim.load_level(config):
		return {"ok": false, "reason": "invalid_configuration", "errors": sim.validation_errors}
	_steps_left = clampi(budget, 0, MAX_BUDGET)
	_steps_used = 0
	if _steps_left == 0:
		return {"ok": false, "reason": "search_budget_exhausted", "search_steps": 0}
	var plan: Dictionary = {"ok": true, "inputs": inputs}
	if search:
		plan = _find_plan(sim.duplicate_for_replay())
	if not plan.ok:
		return {"ok": false, "reason": "search_budget_exhausted" if _steps_left <= 0 else "no_verified_winning_replay", "search_steps": _steps_used}
	# No request_tool() call and no candidate permutation: this proves this document.
	var proof: Dictionary = _verify_replay(sim, plan.inputs)
	if not proof.ok:
		return {"ok": false, "reason": "search_budget_exhausted" if _steps_left <= 0 else "invalid_or_nonwinning_replay", "search_steps": _steps_used}
	proof["search_steps"] = _steps_used
	proof["terminal_reason"] = sim.terminal_reason
	proof["conservation_errors"] = sim.conservation_errors()
	proof["final_hit_margin_us"] = int(sim.snapshot().dragon_contact_us) - sim.terminal_time_us
	proof["rules_api_version"] = Rules.API_VERSION
	return proof

func probe_boundaries(config: Dictionary, inputs: Array, final_time_us: int, margin_us: int) -> Dictionary:
	# These are altered-route test copies, never edits to the authored level.
	# A shorter route may also expose an earlier loss, which is reported honestly.
	var result: Dictionary = {}
	var tie_route := float(config.dragon.route_length) - float(margin_us) * float(config.dragon.speed_units_sec) / 1000000.0
	for offset in [0, -1]:
		var copy: Dictionary = config.duplicate(true)
		copy.dragon.route_length = tie_route + float(offset) * float(config.dragon.speed_units_sec) / 1000000.0
		var sim = Rules.new()
		var name := "exact_final_hit_tie" if offset == 0 else "contact_1us_earlier"
		if not sim.load_level(copy):
			result[name] = {"status": "NOT_APPLICABLE", "reason": "Shortened route is outside the legal initial-position range"}
			continue
		_steps_left = DEFAULT_BUDGET
		_steps_used = 0
		_verify_replay(sim, inputs)
		var expected := "victory" if offset == 0 else "defeat"
		result[name] = {"status": "PASS" if sim.status == expected and sim.terminal_time_us == final_time_us + offset else "REVIEW_REQUIRED", "route_length": copy.dragon.route_length, "outcome": sim.status, "time_us": sim.terminal_time_us, "expected_outcome": expected, "expected_time_us": final_time_us + offset, "budget_exhausted": _steps_left <= 0, "conservation_errors": sim.conservation_errors()}
	return result
