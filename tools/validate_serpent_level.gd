extends SceneTree
## One current-schema level, real Worker Lv.1 rules, no save mutation or auto-solver.
## Run after resource import: --script tools/validate_serpent_level.gd -- --level=res://... [--report=/tmp/check.json] [--events]
const Rules = preload("res://scripts/rescue_rules.gd")
const SceneLayout = preload("res://scripts/scene_layout.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var input_path := ""
	var output_path := ""
	var include_events := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="): input_path = arg.trim_prefix("--level=")
		elif arg.begins_with("--report="): output_path = arg.trim_prefix("--report=")
		elif arg == "--events": include_events = true
		else:
			printerr("Unknown argument: ", arg); quit(2); return
	if input_path.is_empty() or not FileAccess.file_exists(input_path):
		printerr("Provide one existing --level=path; no implicit batch or generated solution."); quit(2); return
	if not output_path.is_empty() and ProjectSettings.globalize_path(input_path).simplify_path() == ProjectSettings.globalize_path(output_path).simplify_path():
		printerr("Report must not overwrite level input."); quit(2); return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(input_path)) != OK or not parser.data is Dictionary:
		printerr("Level must be a JSON object: ", parser.get_error_message()); quit(2); return
	var report := inspect(parser.data, include_events)
	report["level_sha256"] = FileAccess.get_sha256(input_path)
	var serialized := JSON.stringify(report, "\t") + "\n"
	if not output_path.is_empty():
		var file := FileAccess.open(output_path, FileAccess.WRITE)
		if file == null: printerr("Cannot write requested report."); quit(2); return
		file.store_string(serialized); file.close()
	print(serialized)
	quit(0 if report.ok else 1)

static func inspect(config: Dictionary, include_events: bool = false) -> Dictionary:
	var errors: Array = []
	var report := {"ok": false, "level_id": config.get("level_id", ""), "rules_api": Rules.API_VERSION,
		"loadout": {"ant_type": "worker", "level": 1, "speed_multiplier": 1.0}, "errors": errors,
		"scope": "One authored level and timed solution. Not a solver, editor, GL/ground-support check, human balance or device acceptance."}
	errors.append_array(Rules.validate_level(config))
	for key in ["level_id", "content_version", "region_id", "boss_profile"]:
		if not config.get(key) is String or str(config[key]).strip_edges().is_empty(): errors.append("Missing string identity: " + key)
	var target: Variant = config.get("defense_target")
	if not target is Dictionary or target.get("fixed") != true or str(target.get("id", "")).is_empty(): errors.append("A named fixed defense_target is required")
	var rewards: Variant = config.get("rewards")
	if not rewards is Dictionary or not finite_number(rewards.get("fast_seconds")) or not finite_number(rewards.get("normal_seconds")):
		errors.append("Numeric reward thresholds required")
	elif float(rewards.fast_seconds) < 0 or float(rewards.normal_seconds) <= float(rewards.fast_seconds): errors.append("Reward thresholds must satisfy 0 <= fast < normal")
	var solution: Variant = config.get("solution")
	if not solution is Dictionary or not solution.get("inputs") is Array or solution.inputs.is_empty(): errors.append("Nonempty authored solution.inputs required")
	if not errors.is_empty(): return report
	var previous := -1
	for index in range(solution.inputs.size()):
		var item: Variant = solution.inputs[index]
		if not item is Dictionary or not finite_number(item.get("at_sec")) or float(item.at_sec) < 0 or not item.get("color") is String:
			errors.append("Malformed solution input " + str(index)); continue
		var at_us := Rules.seconds_to_us(float(item.at_sec))
		if at_us <= previous or (index == 0 and at_us != 0): errors.append("Inputs must start at 0 and increase strictly: " + str(index))
		previous = at_us
	if not errors.is_empty(): return report
	var layout := SceneLayout.load_for(config)
	if not layout.ok: errors.append("Scene: " + str(layout.reason)); return report
	var rules := Rules.new()
	if not rules.load_level(config): errors.append_array(rules.validation_errors); return report
	var required := {}
	for segment in config.segments: required[segment.color] = int(required.get(segment.color, 0)) + int(segment.hp)
	report["supply_by_color"] = rules.initial_counts.duplicate()
	report["required_damage_by_color"] = required
	report["scene_id"] = layout.data.id
	report["guardian_id"] = layout.data.defense_target.id
	var state := {"events": rules.drain_events(), "wait_start": -1, "waits": [], "peak": 0, "paths": [], "steps": 0}
	for index in range(solution.inputs.size()):
		var input: Dictionary = solution.inputs[index]
		var at_us := Rules.seconds_to_us(float(input.at_sec))
		advance(rules, at_us, state, errors)
		if not errors.is_empty(): break
		if rules.status not in ["ready", "running"] or int(rules.time_us) != at_us:
			errors.append("Terminal state before input " + str(index)); break
		track_wait(rules, state)
		var accepted: Dictionary = rules.click_color(input.color)
		if not accepted.ok:
			errors.append("Rejected input %d at %.6fs: %s" % [index, input.at_sec, accepted.reason]); break
		var task: Dictionary = rules.tasks[accepted.task_id]
		check_path(rules, task, errors)
		state.paths.append(int(task.distance_cells)); state.peak = maxi(state.peak, rules.tasks.size())
		state.events.append_array(rules.drain_events()); track_wait(rules, state)
		errors.append_array(rules.conservation_errors())
	if errors.is_empty(): advance(rules, int(rules.snapshot().dragon_contact_us), state, errors)
	if rules.status != "victory": errors.append("Authored solution did not win: " + rules.status)
	if rules.terminal_reason != "final_segment_hit": errors.append("Expected final actual segment hit")
	errors.append_array(rules.conservation_errors())
	if state.peak > Rules.CARRIER_LIMIT: errors.append("Carrier limit exceeded")
	var longest := 0
	for window in state.waits: longest = maxi(longest, int(window.duration_us))
	report.merge({"ok": errors.is_empty(), "status": rules.status, "terminal_time_us": rules.terminal_time_us,
		"contact_time_us": rules.snapshot().dragon_contact_us, "remaining_beads": rules.board.size(), "maximum_carriers": state.peak,
		"accepted_inputs": state.paths.size(), "path_cells": state.paths, "no_dispatch_windows": state.waits,
		"longest_no_dispatch_opportunity_us": longest, "event_count": state.events.size(),
		"event_sequence_sha256": JSON.stringify(state.events).sha256_text(), "hit_counts": rules.hit_counts.duplicate()}, true)
	if include_events: report["events"] = state.events
	return report

static func finite_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func track_wait(rules, state: Dictionary) -> void:
	var blocked: bool = rules.status == "running" and (rules.tasks.size() >= Rules.CARRIER_LIMIT or rules.reachable_cell_ids().is_empty())
	if blocked and int(state.wait_start) < 0: state.wait_start = int(rules.time_us)
	elif not blocked and int(state.wait_start) >= 0:
		var duration := int(rules.time_us) - int(state.wait_start)
		if duration > 0: state.waits.append({"start_us": state.wait_start, "end_us": rules.time_us, "duration_us": duration})
		state.wait_start = -1

static func advance(rules, target_us: int, state: Dictionary, errors: Array) -> void:
	while rules.status == "running" and int(rules.time_us) < target_us:
		track_wait(rules, state)
		var next_us := mini(target_us, int(rules._next_event_time()))
		state.steps += 1
		if next_us <= rules.time_us or state.steps > 100000:
			errors.append("Invalid or excessive event progression"); return
		rules.update_us(next_us - int(rules.time_us))
		state.events.append_array(rules.drain_events())
		errors.append_array(rules.conservation_errors()); track_wait(rules, state)
		if not errors.is_empty(): return

static func check_path(rules, task: Dictionary, errors: Array) -> void:
	var width := int(rules.level.width)
	var height := int(rules.level.height)
	var path: Array = task.path
	var entrance: Array = rules.level.transport.get("entrance_cell", [int(width / 2), height])
	if path.is_empty() or int(path[0][0]) != int(entrance[0]) or int(path[0][1]) != int(entrance[1]) or path.size() != int(task.distance_cells) + 1:
		errors.append("Transport path/source/length mismatch"); return
	for index in range(1, path.size()):
		var cell: Array = path[index]
		var before: Array = path[index - 1]
		if absi(int(cell[0]) - int(before[0])) + absi(int(cell[1]) - int(before[1])) != 1: errors.append("Non-orthogonal transport edge")
		if index < path.size()-1 and int(cell[0]) >= 0 and int(cell[0]) < width and int(cell[1]) >= 0 and int(cell[1]) < height and rules.board.has(int(cell[1])*width+int(cell[0])): errors.append("Transport crossed an uncollected bead")
	if int(path.back()[1])*width+int(path.back()[0]) != int(task.cell_id): errors.append("Transport target differs from reserved bead")
