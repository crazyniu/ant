extends RefCounted
## Editable authoring state, deliberately separate from runtime and progress saves.
const Rules = preload("res://scripts/rescue_rules.gd")
const Verifier = preload("res://scripts/editor_verifier.gd")
const COLORS := ["red", "blue", "yellow", "green", "purple", "white"]
const PALETTE := {"R": "red", "B": "blue", "Y": "yellow", "G": "green", "P": "purple", "W": "white"}
const MAX_SIDE := 48
var config: Dictionary = {}
var validation: Dictionary = {}
var solution: Array = []
var preview = null
var recording: Array = []
var revision := 0
var dirty := false
var _undo: Array = []
var _redo: Array = []

func _init() -> void:
	new_document()

func new_document(width: int = 16, height: int = 16, seed_value: int = 20261021) -> void:
	config = {"schema_version": 1, "level_id": "untitled", "pattern_name": "Untitled pattern", "objective": "Rescue the princess by breaking every armor.", "content_version": "authoring-1", "content_kind": "authoring_draft", "production_level_number": null, "seed": seed_value, "width": clampi(width, 1, MAX_SIDE), "height": clampi(height, 1, MAX_SIDE), "palette": PALETTE.duplicate(), "grid": [], "columns": [{"id": "column-1", "teams": []}], "armors": [], "dragon": {"initial_position": 0.0, "route_length": 60.0, "speed_units_sec": 1.0, "knockback_distance": 1.0, "max_knockback_distance": 1.0}, "parameters": {"dispatch_interval_sec": 0.12, "transport_speed_cells_sec": 14.0, "transport_min_leg_sec": 0.55, "pickup_pause_sec": 0.16, "max_inflight_ants": 28, "cannon_cooldown_sec": 2.4, "projectile_flight_sec": 0.85}, "tools": Rules.DEFAULT_TOOLS.duplicate(true), "author_notes": {"failure_boundary_cases": [], "playtest_conclusion": "Not run"}}
	for y in range(int(config.height)):
		config.grid.append(".".repeat(int(config.width)))
	_undo.clear()
	_redo.clear()
	_changed()

func _changed() -> void:
	revision += 1
	dirty = true
	preview = null
	recording.clear()
	solution.clear()
	validation = {"status": "UNVERIFIED", "reason": "content_changed", "human_playtest": "NOT_RUN", "production_eligible": false}

func _checkpoint() -> void:
	_undo.append(config.duplicate(true))
	if _undo.size() > 40:
		_undo.pop_front()
	_redo.clear()

func undo() -> bool:
	if _undo.is_empty():
		return false
	_redo.append(config.duplicate(true))
	config = _undo.pop_back()
	_changed()
	return true

func redo() -> bool:
	if _redo.is_empty():
		return false
	_undo.append(config.duplicate(true))
	config = _redo.pop_back()
	_changed()
	return true

func set_field(key: String, value: Variant) -> void:
	if key in ["validation", "production_level_number", "content_kind", "grid", "width", "height", "schema_version", "initial_color_counts", "thumbnail"]:
		return
	if config.get(key) == value:
		return
	_checkpoint()
	config[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	_changed()

func resize_grid(width: int, height: int) -> bool:
	if width < 1 or width > MAX_SIDE or height < 1 or height > MAX_SIDE:
		return false
	if width == int(config.width) and height == int(config.height):
		return true
	_checkpoint()
	var rows: Array = []
	for y in range(height):
		var old: String = config.grid[y] if y < config.grid.size() else ""
		rows.append(old.substr(0, width) + ".".repeat(maxi(0, width - old.length())))
	config.grid = rows
	config.width = width
	config.height = height
	_changed()
	return true

func paint(x: int, y: int, symbol: String, fill: bool = false) -> bool:
	if x < 0 or y < 0 or x >= int(config.width) or y >= int(config.height) or (symbol != "." and not config.palette.has(symbol)):
		return false
	var old: String = config.grid[y].substr(x, 1)
	if old == symbol:
		return false
	_checkpoint()
	var pending: Array[Vector2i] = [Vector2i(x, y)]
	while not pending.is_empty():
		var point: Vector2i = pending.pop_back()
		if point.x < 0 or point.y < 0 or point.x >= int(config.width) or point.y >= int(config.height):
			continue
		var row: String = config.grid[point.y]
		if row.substr(point.x, 1) != old:
			continue
		config.grid[point.y] = row.substr(0, point.x) + symbol + row.substr(point.x + 1)
		if fill:
			for direction in Rules.DIRECTIONS:
				pending.append(point + direction)
	_changed()
	return true

func import_json(text: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary:
		return {"ok": false, "reason": "Invalid JSON object at line %d: %s" % [parser.get_error_line(), parser.get_error_message()]}
	var candidate: Dictionary = parser.data
	var shape := _shape_errors(candidate)
	if not shape.is_empty():
		return {"ok": false, "reason": "; ".join(shape)}
	_checkpoint()
	config = candidate.duplicate(true)
	config.erase("validation")
	config.erase("initial_color_counts")
	config.erase("thumbnail")
	config["production_level_number"] = null
	config["content_kind"] = "authoring_draft"
	if not config.has("author_notes"):
		config["author_notes"] = {"failure_boundary_cases": [], "playtest_conclusion": "Not run"}
	_changed()
	# Import claims are untrusted. Keep the sequence only as an unverified candidate.
	var imported: Variant = candidate.get("validation", {})
	if imported is Dictionary and imported.get("no_tool_solution") is Array:
		solution = imported.no_tool_solution.duplicate(true)
	validation.reason = "import_requires_replay"
	return {"ok": true, "errors": structural_errors()}

func _shape_errors(candidate: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for key in ["schema_version", "width", "height", "seed"]:
		if not Rules._is_integer(candidate.get(key)):
			errors.append(key + " must be an integer")
	for key in ["level_id", "pattern_name", "content_version"]:
		if not candidate.get(key) is String or str(candidate.get(key, "")).strip_edges().is_empty():
			errors.append(key + " must be nonempty text")
	for key in ["grid", "columns", "armors"]:
		if not candidate.get(key) is Array:
			errors.append(key + " must be an array")
	for key in ["palette", "dragon", "parameters"]:
		if not candidate.get(key) is Dictionary:
			errors.append(key + " must be an object")
	if not errors.is_empty():
		return errors
	if int(candidate.width) < 1 or int(candidate.width) > MAX_SIDE or int(candidate.height) < 1 or int(candidate.height) > MAX_SIDE or candidate.grid.size() != int(candidate.height):
		errors.append("Grid dimensions must be 1–48 and match its rows")
	for symbol in candidate.palette:
		if not symbol is String or str(symbol).length() != 1 or symbol == "." or candidate.palette[symbol] not in COLORS:
			errors.append("Palette maps single non-dot symbols to the six supported bead colors")
	for row in candidate.grid:
		if not row is String or row.length() != int(candidate.width):
			errors.append("Grid row width/type mismatch")
			continue
		for symbol in row:
			if symbol != "." and not candidate.palette.has(symbol):
				errors.append("Unknown grid symbol " + symbol)
	for column in candidate.columns:
		if not column is Dictionary or not column.get("teams") is Array or not column.get("id") is String:
			errors.append("Columns require objects with teams arrays")
			continue
		for team in column.teams:
			if not team is Dictionary or not team.get("id") is String or not Rules._is_integer(team.get("quota")) or team.get("color") not in COLORS:
				errors.append("Teams require a supported color and integer quota")
	for armor in candidate.armors:
		if not armor is Dictionary or not armor.get("id") is String or not Rules._is_integer(armor.get("demand")) or armor.get("color") not in COLORS:
			errors.append("Armors require a supported color and integer demand")
	for key in ["dispatch_interval_sec", "transport_speed_cells_sec", "projectile_flight_sec", "cannon_cooldown_sec", "max_inflight_ants"]:
		if not Rules._is_number(candidate.parameters.get(key)):
			errors.append("Parameter must be numeric: " + key)
	for key in ["transport_min_leg_sec", "pickup_pause_sec"]:
		if candidate.parameters.has(key) and not Rules._is_number(candidate.parameters[key]):
			errors.append("Optional parameter must be numeric and finite: " + key)
	for key in ["initial_position", "route_length", "speed_units_sec", "knockback_distance", "max_knockback_distance"]:
		if not Rules._is_number(candidate.dragon.get(key)):
			errors.append("Dragon parameter must be numeric: " + key)
	if candidate.has("tools"):
		if not candidate.tools is Array:
			errors.append("Tools must be an array")
		else:
			for tool in candidate.tools:
				if not tool is Dictionary or tool.get("id") not in ["extra_slot", "shuffle", "recall", "scout"] or not Rules._is_integer(tool.get("unlock_level")) or not Rules._is_integer(tool.get("uses_per_level")):
					errors.append("Malformed tool definition")
	return errors

func structural_errors() -> Array[String]:
	var errors := _shape_errors(config)
	if not errors.is_empty():
		return errors
	errors.append_array(Rules.validate_level(config))
	return errors

func color_report() -> Array:
	var counts: Dictionary = {}
	for color in COLORS:
		counts[color] = {"color": color, "board": 0, "quota": 0, "armor": 0}
	for row in config.grid:
		for symbol in row:
			if symbol != "." and config.palette.has(symbol):
				counts[config.palette[symbol]].board += 1
	for column in config.columns:
		for team in column.teams:
			if counts.has(team.get("color")):
				counts[team.color].quota += int(team.get("quota", 0))
	for armor in config.armors:
		if counts.has(armor.get("color")):
			counts[armor.color].armor += int(armor.get("demand", 0))
	var result: Array = []
	for color in COLORS:
		var row: Dictionary = counts[color]
		row["balanced"] = row.board == row.quota and row.board == row.armor
		result.append(row)
	return result

func fingerprint() -> String:
	var content := config.duplicate(true)
	for key in ["validation", "thumbnail", "initial_color_counts", "author_notes"]:
		content.erase(key)
	return JSON.stringify(content, "", true, false).sha256_text()

func exposed_cells() -> Array:
	# Draft queues may be unbalanced while painting. A throwaway conservation scaffold
	# lets Rules calculate routes on the exact unchanged grid, not a second flood fill.
	var draft: Dictionary = config.duplicate(true)
	draft.columns = []
	draft.armors = []
	for row in color_report():
		if row.board > 0:
			draft.columns.append({"id": row.color, "teams": [{"id": row.color, "color": row.color, "quota": row.board}]})
			draft.armors.append({"id": row.color, "color": row.color, "demand": row.board})
	# Authoring exposure is geometric and must still work with unfinished timing fields.
	var defaults = get_script().new()
	draft.parameters = defaults.config.parameters
	draft.dragon = defaults.config.dragon
	draft.tools = []
	var sim = Rules.new()
	if not sim.load_level(draft):
		return []
	return sim.reachable_cell_ids()

func generate_balanced_queues(column_count: int = 5, quota_limit: int = 18) -> void:
	_checkpoint()
	var generated: Array = []
	for index in range(clampi(column_count, 1, 8)):
		generated.append({"id": "column-%d" % (index + 1), "teams": []})
	var armor_list: Array = []
	var color_index := 0
	for row in color_report():
		var remaining: int = row.board
		if remaining == 0:
			continue
		var team_number := 0
		while remaining > 0:
			team_number += 1
			var quota := mini(maxi(1, quota_limit), remaining)
			generated[color_index % generated.size()].teams.append({"id": "%s-%02d" % [row.color, team_number], "color": row.color, "quota": quota})
			remaining -= quota
		armor_list.append({"id": "armor-" + row.color, "color": row.color, "demand": row.board})
		color_index += 1
	config.columns = generated
	config.armors = armor_list
	_changed()

func start_preview() -> Dictionary:
	var errors := structural_errors()
	if not errors.is_empty():
		return {"ok": false, "errors": errors, "reason": "Fix the configuration before previewing"}
	preview = Rules.new()
	preview.load_level(config)
	preview.drain_events()
	recording.clear()
	return {"ok": true}

func select_front(column_id: String, team_id: String) -> Dictionary:
	if preview == null:
		return {"ok": false, "reason": "preview_not_started"}
	if not recording.is_empty() and preview.time_us - int(recording[-1].time_us) < Verifier.CLICK_INTERVAL_US:
		return {"ok": false, "reason": "Wait 0.75 simulation seconds between recorded selections"}
	var input := {"action": "select_front", "time_us": preview.time_us, "column_id": column_id, "team_id": team_id}
	var result: Dictionary = preview.select_front(column_id, team_id)
	if result.ok:
		recording.append(input)
	return result

func step_preview(microseconds: int = 250000) -> Array:
	if preview == null:
		return []
	preview.update_us(clampi(microseconds, 0, 1000000))
	return preview.drain_events()

func validate_solution(inputs: Variant = null, budget: int = Verifier.DEFAULT_BUDGET) -> Dictionary:
	var errors := structural_errors()
	if not errors.is_empty():
		validation = {"status": "INVALID", "reason": "invalid_configuration", "errors": errors, "human_playtest": "NOT_RUN", "production_eligible": false}
		return validation
	var engine = Verifier.new()
	var result: Dictionary
	if inputs == null:
		result = engine.solve_level(config, budget)
	else:
		result = engine.verify_level(config, inputs, budget)
	validation = result.duplicate(true)
	validation["status"] = "TIMED_REPLAY_VERIFIED" if result.ok else "UNVERIFIED"
	validation["human_playtest"] = "NOT_RUN"
	validation["production_eligible"] = false
	validation["content_sha256"] = fingerprint()
	validation["verified_at_utc"] = Time.get_datetime_string_from_system(true) + "Z" if result.ok else ""
	if result.ok:
		validation["boundary_replays"] = engine.probe_boundaries(config, result.inputs, result.terminal_time_us, result.final_hit_margin_us)
		solution = result.inputs.duplicate(true)
		dirty = true
	return validation

func exported_config() -> Dictionary:
	var result := config.duplicate(true)
	result["content_kind"] = "authoring_draft"
	result["production_level_number"] = null
	result["initial_color_counts"] = {}
	for row in color_report():
		result.initial_color_counts[row.color] = row.board
	var report: Dictionary = validation.duplicate(true)
	if report.get("content_sha256", "") != fingerprint() and report.get("status") == "TIMED_REPLAY_VERIFIED":
		report = {"status": "UNVERIFIED", "reason": "content_hash_mismatch"}
	report["human_playtest"] = "NOT_RUN"
	report["production_eligible"] = false
	report["no_tool_solution"] = solution.duplicate(true)
	report["color_conservation"] = color_report()
	report["structural_errors"] = structural_errors()
	result["validation"] = report
	return result

func export_json(path: String) -> Dictionary:
	# Never replace the three fixtures or silently publish to a production directory.
	var absolute := ProjectSettings.globalize_path(path).simplify_path()
	var production := ProjectSettings.globalize_path("res://data/levels").simplify_path()
	if absolute.begins_with(production + "/") or absolute == production:
		return {"ok": false, "reason": "Export to an authoring folder, not data/levels. Promotion is a separate reviewed step."}
	if path.get_extension().to_lower() != "json":
		return {"ok": false, "reason": "Choose a .json filename"}
	var thumbnail_path := path.get_basename() + "-thumbnail.png"
	var thumbnail_error := thumbnail_image().save_png(thumbnail_path)
	if thumbnail_error != OK:
		return {"ok": false, "reason": "Thumbnail export failed: " + error_string(thumbnail_error)}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "reason": "Cannot open output: " + error_string(FileAccess.get_open_error())}
	var exported := exported_config()
	exported["thumbnail"] = thumbnail_path.get_file()
	file.store_string(JSON.stringify(exported, "  ", true, false) + "\n")
	file.flush()
	var ok := file.get_error() == OK
	file.close()
	if ok:
		dirty = false
	return {"ok": ok, "reason": "Draft JSON and companion PNG exported. Human playtest and production review are still required." if ok else "Write failed"}

func thumbnail_image(cell_size: int = 24) -> Image:
	var side := clampi(cell_size, 8, 64)
	var result := Image.create(int(config.width) * side + 24, int(config.height) * side + 24, false, Image.FORMAT_RGBA8)
	result.fill(Color("f2e8ce"))
	var atlas: Image = load("res://assets/ui/fusion/beads.png").get_image()
	var regions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/fusion/bead-regions.json"))
	var sprites: Dictionary = {}
	for color in COLORS:
		var rect: Array = regions[color]
		var sprite := atlas.get_region(Rect2i(rect[0], rect[1], rect[2], rect[3]))
		sprite.convert(Image.FORMAT_RGBA8)
		sprite.resize(side, side, Image.INTERPOLATE_LANCZOS)
		sprites[color] = sprite
	for y in range(int(config.height)):
		for x in range(int(config.width)):
			var symbol: String = config.grid[y].substr(x, 1)
			if symbol != ".":
				result.blend_rect(sprites[config.palette[symbol]], Rect2i(0, 0, side, side), Vector2i(12 + x * side, 12 + y * side))
	return result
