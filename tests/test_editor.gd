extends SceneTree
const Document = preload("res://scripts/editor_document.gd")
const Studio = preload("res://scenes/editor.tscn")
var failures: Array[String] = []
var assertions := 0
var results: Array = []
var output_dir := ProjectSettings.globalize_path("user://editor-evidence")

func _initialize() -> void:
	var override := OS.get_environment("ANT_RESCUE_EVIDENCE_DIR").strip_edges()
	if not override.is_empty():
		output_dir = ProjectSettings.globalize_path(override)
	call_deferred("run")

func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures.append(message)
		push_error(message)

func load_fixture(index: int):
	var document = Document.new()
	var result: Dictionary = document.import_json(FileAccess.get_file_as_string("res://data/levels/validation-%02d.json" % index))
	check(result.ok, "Fixture %d imports" % index)
	return document

func small():
	var document = Document.new()
	document.new_document(3, 3, 17)
	for y in range(3):
		for x in range(3):
			document.paint(x, y, "R")
	document.generate_balanced_queues(1, 9)
	return document

func test_authoring() -> void:
	var document = Document.new()
	document.new_document(3, 3, 17)
	check(document.config.grid == ["...", "...", "..."], "New grid consists of blanks")
	check(document.structural_errors().size() > 0, "Empty board is explicitly incomplete")
	check(document.paint(1, 1, "R"), "Paint writes a cell")
	check(document.config.grid[1] == ".R.", "Paint exact cell")
	check(not document.paint(-1, 1, "B") and not document.paint(1, 1, "?"), "Reject invalid positions and palette symbols")
	check(document.paint(0, 0, "B", true), "Flood fill accepts blanks")
	check(document.config.grid == ["BBB", "BRB", "BBB"], "Four-neighbor flood fill preserves other colors")
	check(document.paint(1, 1, "."), "Erase restores a blank")
	check(document.undo() and document.config.grid[1] == "BRB", "Undo restores prior artwork")
	check(document.redo() and document.config.grid[1] == "B.B", "Redo reapplies artwork")
	check(document.resize_grid(4, 2) and document.config.grid == ["BBB.", "B.B."], "Resize preserves existing cells and fills new cells with blanks")
	check(document.undo() and document.config.height == 3, "Undo restores cropped content")
	check(not document.resize_grid(100, 3), "Grid size safety bound")
	document.generate_balanced_queues(3, 3)
	check(document.structural_errors().is_empty(), "Generated queues and armor conserve all colors")
	check(document.color_report().all(func(row): return row.balanced), "Per-color ledger reports balance")
	check(document.validation.status == "UNVERIFIED", "Balanced structure alone never verifies content")
	var copy: Dictionary = document.config.duplicate(true)
	var changed: Array = copy.columns.duplicate(true)
	changed[0].teams[0].quota += 1
	document.set_field("columns", changed)
	check(not document.structural_errors().is_empty(), "Quota mismatch is visible")
	check(not document.start_preview().ok, "Invalid content cannot start preview")
	check(document.validate_solution().status == "INVALID", "Invalid content cannot receive proof")

func test_exposure() -> void:
	var document = small()
	check(document.exposed_cells().size() == 8 and 4 not in document.exposed_cells(), "Rules exposes every board edge, not enclosed center")
	document.paint(1, 1, ".")
	check(document.exposed_cells().size() == 8, "Closed hole does not create extra targets")
	document.paint(1, 0, ".")
	check(3 in document.exposed_cells() and 5 in document.exposed_cells() and 7 in document.exposed_cells(), "Exterior-connected hole opens neighbors through Rules")
	check(document.exposed_cells().size() == 7, "Exposure works while quotas are temporarily unbalanced")

func test_import_export() -> void:
	var document = load_fixture(1)
	check(document.validation.status == "UNVERIFIED" and document.validation.reason == "import_requires_replay", "Imported success metadata is not trusted")
	check(document.config.production_level_number == null and document.config.content_kind == "authoring_draft", "Imports cannot promote production content")
	var before: Dictionary = document.config.duplicate(true)
	for malformed in ["{", "[]", "null", '{"width":2}', JSON.stringify({"width": {}, "seed": true})]:
		check(not document.import_json(malformed).ok, "Malformed import rejects")
		check(document.config == before, "Failed import preserves current content")
	for mutation in [{"columns": [{}]}, {"armors": [{}]}, {"parameters": {"max_inflight_ants": {}}}, {"palette": {"R": "orange"}}, {"tools": "invalid"}]:
		var candidate: Dictionary = before.duplicate(true)
		candidate.merge(mutation, true)
		check(not document.import_json(JSON.stringify(candidate)).ok, "Unsafe nested shape rejects without crashing")
		check(document.config == before, "Nested malformed import preserves document")
	check(not document.export_json("res://data/levels/editor-must-not-exist.json").ok, "Production fixture directory cannot be overwritten")
	check(not document.export_json("/tmp/not-a-json.png").ok, "JSON extension required")
	check(document.export_json(output_dir + "/roundtrip.json").ok, "Draft JSON writes")
	var exported: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(output_dir + "/roundtrip.json"))
	check(exported.thumbnail == "roundtrip-thumbnail.png" and FileAccess.file_exists(output_dir + "/" + exported.thumbnail), "Draft JSON links its automatically exported portable PNG companion")
	var reopened = Document.new()
	check(reopened.import_json(FileAccess.get_file_as_string(output_dir + "/roundtrip.json")).ok, "Exported JSON reimports")
	check(reopened.fingerprint() == document.fingerprint(), "Canonical content hash survives JSON number roundtrip")
	check(reopened.config.seed == document.config.seed and reopened.config.content_version == document.config.content_version, "Seed and content version preserved")
	var thumb: Image = document.thumbnail_image(20)
	check(thumb.get_width() == 344 and thumb.get_height() == 344, "Thumbnail dimensions follow the grid")
	check(thumb.save_png(output_dir + "/validation-01-thumbnail.png") == OK, "Current bead-art thumbnail exports")
	check(Image.load_from_file(output_dir + "/validation-01-thumbnail.png").get_size() == thumb.get_size(), "Thumbnail file roundtrip")

func test_replay() -> void:
	for index in range(1, 4):
		var document = load_fixture(index)
		var imported: Array = document.solution.duplicate(true)
		var result: Dictionary = document.validate_solution(imported)
		check(result.status == "TIMED_REPLAY_VERIFIED" and result.terminal_reason == "final_armor_hit", "Fixture %d independently replays to final hit" % index)
		check(result.human_playtest == "NOT_RUN" and not result.production_eligible, "Replay does not assert human playtest or production acceptance")
		check(result.conservation_errors.is_empty(), "Replay uses conserving authoritative rules")
		check(result.boundary_replays.exact_final_hit_tie.status == "PASS", "Full-level final-hit tie boundary wins")
		check(result.boundary_replays.contact_1us_earlier.status == "PASS", "Full-level one-microsecond-earlier contact loses")
		check(result.inputs.size() == imported.size(), "Timestamped sequence retained")
		check(result.verified_at_utc.ends_with("Z") and result.content_sha256.length() == 64, "Replay has UTC timestamp and exact-content hash")
		results.append({"level_id": document.config.level_id, "terminal_time_us": result.terminal_time_us, "margin_us": result.final_hit_margin_us, "inputs": imported.size(), "status": result.status})
		check(document.export_json(output_dir + "/verified-validation-%02d.json" % index).ok, "Verified draft exports, not production")
		var tampered: Array = imported.duplicate(true)
		tampered[0].team_id = "missing-team"
		check(document.validate_solution(tampered).status == "UNVERIFIED", "Illegal selection cannot verify")
		check(document.validate_solution(imported, 0).reason == "search_budget_exhausted", "Timeout/budget exhaustion remains unverified")
		check(document.exported_config().validation.status == "UNVERIFIED", "Failed proof replaces earlier success")
		check(document.validate_solution([]).status == "UNVERIFIED", "Empty solution cannot verify")
		check(document.validate_solution([{"action": "shuffle"}]).reason == "non_selection_action_forbidden", "Tools cannot masquerade as no-tool inputs")
		document.validate_solution(imported)
		document.paint(0, 0, "." if document.config.grid[0][0] != "." else "R")
		check(document.validation.status == "UNVERIFIED" and document.solution.is_empty(), "Any content edit invalidates proof and stale solution")
		check(document.preview == null, "Any content edit discards stale preview")
	var document = small()
	var result: Dictionary = document.validate_solution()
	check(result.status == "TIMED_REPLAY_VERIFIED", "Bounded solver constructs and independently verifies a no-tool plan")
	var config_before: Dictionary = document.config.duplicate(true)
	document.validate_solution(null, 0)
	check(document.config == config_before, "Failed search does not mutate grid, queue, dragon or parameters")

func test_preview_recording() -> void:
	var document = small()
	check(document.start_preview().ok, "Valid document starts a real Rules preview")
	check(document.preview.status == "ready" and document.preview.time_us == 0, "Observation does not start threat")
	var team: Dictionary = document.preview.columns[0].teams[0]
	check(document.select_front("column-1", team.id).ok, "Preview front team selection uses Rules")
	check(document.recording.size() == 1 and document.recording[0].time_us == 0, "Accepted input records exact simulation microseconds")
	check(not document.select_front("column-1", team.id).ok, "Double clicks rejected without a duplicate record")
	for i in range(120):
		document.step_preview(250000)
		if document.preview.status in ["victory", "defeat"]:
			break
	check(document.preview.status == "victory", "Finite manual step preview reaches final-hit victory")
	check(document.validate_solution(document.recording).status == "TIMED_REPLAY_VERIFIED", "Recorded run independently re-verifies")
	check(document.start_preview().ok and document.recording.is_empty() and document.preview.time_us == 0, "Restart clears input log and simulation")

func find_button(node: Node, text: String):
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var match_node = find_button(child, text)
		if match_node != null:
			return match_node
	return null

func test_scene() -> void:
	var studio = Studio.instantiate()
	root.add_child(studio)
	await process_frame
	await process_frame
	check(root.content_scale_size == Vector2i(1440, 1000), "Editor retains its 1440 by 1000 logical canvas")
	check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_VIEWPORT and root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP, "Editor uses uniform viewport scaling with Godot-transformed input")
	var fitted: Vector2i = studio.fitted_window_size(Vector2i(1364, 1024))
	check(fitted.x <= 1332 and fitted.y <= 960 and fitted.x > 0 and fitted.y > 0, "Restored editor window fits the actual small screen with decoration clearance")
	check(absf(float(fitted.x) / float(fitted.y) - 1.44) < 0.002, "Small-screen fit preserves the authoring canvas aspect ratio")
	check(studio.fitted_window_size(Vector2i(1920, 1200)) == Vector2i(1440, 1000), "Large screen retains native authoring size")
	check(studio.tabs.get_tab_count() == 4, "Real editor scene exposes four authoring panels")
	check(find_button(studio, "Add team") != null and find_button(studio, "Down") != null, "Queue and armor forms finish constructing their action controls")
	check(studio.grid.textures.size() == 6, "Grid renders six current production bead textures")
	var rect: Rect2 = studio.grid.board_rect()
	var width: int = studio.document.config.width
	var center := rect.position + Vector2.ONE * (rect.size.x / width / 2)
	check(studio.grid.cell_from_point(center) == Vector2i(0, 0), "Canvas maps rendered pointer coordinates to cells")
	check(studio.grid.cell_from_point(Vector2(-20, -20)) == Vector2i(-1, -1), "Outside canvas pointer rejected")
	studio.symbol = "P"
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = center
	studio.grid._gui_input(event)
	check(studio.document.config.grid[0][0] == "P", "Canvas mouse handler paints actual document")
	find_button(studio, "Undo").pressed.emit()
	await process_frame
	check(studio.document.validation.status == "UNVERIFIED", "Undo invalidates imported replay proof")
	studio._import_path("res://data/levels/validation-01.json")
	studio.tabs.current_tab = 1
	var original_teams: int = studio.document.config.columns[0].teams.size()
	studio._edit_teams("add")
	await process_frame
	check(studio.document.config.columns[0].teams.size() == original_teams + 1, "Queue control adds a real team")
	studio._team_value("quota", 2)
	studio._team_value("color", "blue")
	check(studio.document.config.columns[0].teams[-1].quota == 2 and studio.document.config.columns[0].teams[-1].color == "blue", "Team controls edit quota and color")
	var team_id: String = studio.document.config.columns[0].teams[-1].id
	studio._edit_teams("up")
	await process_frame
	check(studio.document.config.columns[0].teams[-2].id == team_id, "Queue reorder changes actual front-to-back order")
	studio.tabs.current_tab = 2
	var original_armors: int = studio.document.config.armors.size()
	studio._edit_armor("add")
	await process_frame
	studio._armor_value("demand", 3)
	check(studio.document.config.armors.size() == original_armors + 1 and studio.document.config.armors[-1].demand == 3, "Armor controls edit actual ordered demands")
	studio._edit_armor("up")
	await process_frame
	check(studio.document.config.armors[-2].demand == 3, "Armor order control changes configuration")
	studio._import_path("res://data/levels/validation-01.json")
	find_button(studio, "Start / reset preview").pressed.emit()
	check(studio.document.preview != null and studio.grid.preview_mode, "Actual preview control loads Rules")
	check(studio.front_row.get_child_count() == 5, "Real front-team buttons mirror candidate columns")
	studio.front_row.get_child(0).pressed.emit()
	find_button(studio, "Step 0.25s").pressed.emit()
	check(studio.document.preview.time_us == 250000, "Step control advances exact simulation interval")
	check(studio.document.recording.size() == 1, "UI selection creates one timestamped recording")
	await capture("editor-live-preview.png")
	find_button(studio, "Edit pattern").pressed.emit()
	check(not studio.grid.preview_mode and not studio.playing, "Edit control exits preview without runtime side effects")
	studio._import_path("res://data/levels/validation-01.json")
	studio.tabs.current_tab = 3
	studio._verify(studio.document.solution)
	check(studio.document.validation.status == "TIMED_REPLAY_VERIFIED", "Verify control accepts the imported sequence only after real replay")
	studio._watch_replay()
	check(studio.replaying and studio.document.recording.size() == 1, "Watch control starts replay from its exact time-zero input")
	studio.playing = false
	for i in range(600):
		studio._advance(250000)
		if studio.document.preview.status in ["victory", "defeat"]:
			break
	check(studio.document.preview.status == "victory", "Visual replay controller preserves exact timestamp ordering through final hit")
	studio._import_path("res://data/levels/validation-01.json")
	studio._verify(studio.document.solution)
	studio.tabs.current_tab = 3
	await process_frame
	await process_frame
	for tab in range(4):
		studio.tabs.current_tab = tab
		await process_frame
		await capture(["editor-pattern.png", "editor-queues.png", "editor-dragon.png", "editor-studio.png"][tab])
	studio.queue_free()
	await process_frame

func capture(filename: String) -> void:
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		var screenshot := root.get_texture().get_image()
		check(screenshot.save_png(output_dir + "/" + filename) == OK, "Actual Godot viewport capture saves " + filename)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	test_authoring()
	test_exposure()
	test_import_export()
	test_replay()
	test_preview_recording()
	await test_scene()
	var report := {"suite": "editor", "assertions": assertions, "failures": failures, "ok": failures.is_empty(), "fixtures": results, "human_playtest": "NOT_RUN", "render_backend": DisplayServer.get_name(), "utc": Time.get_datetime_string_from_system(true) + "Z"}
	var file := FileAccess.open(output_dir + "/test-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print(JSON.stringify(report, "  "))
	quit(0 if failures.is_empty() else 1)
