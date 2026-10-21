extends Control
## Standalone authoring application. Does not load or write the player's save.
const Document = preload("res://scripts/editor_document.gd")
const Grid = preload("res://scripts/editor_grid.gd")
const LOGICAL_SIZE := Vector2i(1440, 1000)
var document = Document.new()
var grid
var mode := "paint"
var symbol := "R"
var playing := false
var replay_inputs: Array = []
var replay_index := 0
var replaying := false
var tabs: TabContainer
var report_label: Label
var status_label: Label
var preview_label: Label
var front_row: HFlowContainer
var route: ProgressBar
var route_label: Label
var export_dialog: FileDialog
var import_dialog: FileDialog
var thumbnail_dialog: FileDialog
var discard_dialog: ConfirmationDialog
var _pending_action: Callable
var _elapsed_refresh := 0.0
var _selected_column := 0
var _selected_team := 0
var _selected_armor := 0
var _rebuilding := false
var _queued_rebuild := false
var palette_bar: HBoxContainer

func _ready() -> void:
	# A separate desktop studio canvas; the production portrait scene is unchanged.
	var window := get_tree().root
	window.content_scale_size = LOGICAL_SIZE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	if DisplayServer.get_name() != "headless":
		var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
		window.mode = Window.MODE_WINDOWED
		window.size = fitted_window_size(usable.size)
		window.position = usable.position + (usable.size - window.size) / 2
		if window.size != LOGICAL_SIZE:
			window.mode = Window.MODE_MAXIMIZED
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = _theme()
	_build_shell()
	document.import_json(FileAccess.get_file_as_string("res://data/levels/validation-01.json"))
	document.dirty = false
	_refresh_all()
	get_tree().auto_accept_quit = false

static func fitted_window_size(usable_size: Vector2i) -> Vector2i:
	# Reserve decoration/work-area clearance for the restored window, even when
	# launching maximized. Input coordinates are transformed by Godot, not manually.
	var available := Vector2(maxi(1, usable_size.x - 32), maxi(1, usable_size.y - 64))
	var scale := minf(1.0, minf(available.x / float(LOGICAL_SIZE.x), available.y / float(LOGICAL_SIZE.y)))
	return Vector2i(maxi(1, floori(LOGICAL_SIZE.x * scale)), maxi(1, floori(LOGICAL_SIZE.y * scale)))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(discard_dialog):
		_guard(func(): get_tree().quit())

func _theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 19
	result.set_color("font_color", "Label", Color("213449"))
	result.set_color("font_color", "Button", Color("213449"))
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("ead7a5") if state != "pressed" else Color("c7a15a")
		box.border_color = Color("b19359")
		box.set_border_width_all(1)
		box.set_corner_radius_all(7)
		box.content_margin_left = 12
		box.content_margin_right = 12
		box.content_margin_top = 8
		box.content_margin_bottom = 8
		result.set_stylebox(state, "Button", box)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("f2e8d2")
	panel.border_color = Color("b19359")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(8)
	panel.content_margin_left = 12
	panel.content_margin_right = 12
	panel.content_margin_top = 12
	panel.content_margin_bottom = 12
	result.set_stylebox("panel", "TabContainer", panel)
	for state in ["tab_selected", "tab_unselected", "tab_hovered"]:
		var tab := StyleBoxFlat.new()
		tab.bg_color = Color("ead7a5") if state == "tab_selected" else Color("e1d5bd")
		tab.content_margin_left = 14
		tab.content_margin_right = 14
		tab.content_margin_top = 8
		tab.content_margin_bottom = 8
		result.set_stylebox(state, "TabContainer", tab)
	for state in ["font_selected_color", "font_unselected_color", "font_hovered_color"]:
		result.set_color(state, "TabContainer", Color("213449"))
	for control in ["LineEdit", "TextEdit", "ItemList"]:
		var input := panel.duplicate()
		input.bg_color = Color("fffaf0")
		result.set_stylebox("panel" if control == "ItemList" else "normal", control, input)
		result.set_color("font_color", control, Color("213449"))
		result.set_color("caret_color", control, Color("213449"))
		result.set_color("font_selected_color", control, Color("213449"))
		result.set_color("selection_color", control, Color("dfc68c"))
	var selected := panel.duplicate()
	selected.bg_color = Color("dfc68c")
	result.set_stylebox("selected", "ItemList", selected)
	result.set_stylebox("selected_focus", "ItemList", selected)
	return result

func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("f9f3e6")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := _label("ANT RESCUE  /  LEVEL STUDIO", header)
	title.add_theme_font_size_override("font_size", 27)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label("AUTHORING ONLY · NO PRODUCTION PROMOTION", header).add_theme_font_size_override("font_size", 15)
	var toolbar := HBoxContainer.new()
	layout.add_child(toolbar)
	_button("New", toolbar, func(): _guard(func(): document.new_document(); _refresh_all()))
	_button("Import JSON", toolbar, func(): _guard(func(): import_dialog.popup_centered(Vector2i(960, 650))))
	_button("Export draft + PNG", toolbar, func(): export_dialog.current_file = str(document.config.level_id) + ".json"; export_dialog.popup_centered(Vector2i(960, 650)))
	_button("Export thumbnail", toolbar, func(): thumbnail_dialog.current_file = str(document.config.level_id) + ".png"; thumbnail_dialog.popup_centered(Vector2i(960, 650)))
	_button("Undo", toolbar, func(): document.undo(); _refresh_all())
	_button("Redo", toolbar, func(): document.redo(); _refresh_all())
	var fixtures := OptionButton.new()
	fixtures.add_item("Open validation fixture…")
	for i in range(1, 4):
		fixtures.add_item("Validation %d" % i)
	fixtures.item_selected.connect(func(index: int):
		if index > 0:
			_guard(func(): _import_path("res://data/levels/validation-%02d.json" % index))
		fixtures.select(0))
	toolbar.add_child(fixtures)
	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.split_offset = 860
	layout.add_child(body)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 730
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	var tools := HBoxContainer.new()
	left.add_child(tools)
	for tool_mode in ["paint", "erase", "fill"]:
		_button(tool_mode.capitalize(), tools, func(): mode = tool_mode; _status("Mode: " + mode + ". Right-click always erases."))
	var exposure := CheckButton.new()
	exposure.text = "External exposure"
	exposure.button_pressed = true
	exposure.toggled.connect(func(value: bool): grid.show_exposure = value; grid.refresh())
	tools.add_child(exposure)
	palette_bar = HBoxContainer.new()
	left.add_child(palette_bar)
	grid = Grid.new()
	grid.document = document
	grid.cell_action.connect(_paint)
	left.add_child(grid)
	var preview_controls := HBoxContainer.new()
	left.add_child(preview_controls)
	_button("Start / reset preview", preview_controls, _start_preview)
	_button("Step 0.25s", preview_controls, func(): playing = false; _advance(250000))
	_button("Play / pause", preview_controls, func():
		if document.preview == null:
			_start_preview()
		playing = not playing if document.preview != null else false)
	_button("Edit pattern", preview_controls, func(): playing = false; replaying = false; grid.preview_mode = false; grid.refresh())
	front_row = HFlowContainer.new()
	left.add_child(front_row)
	preview_label = _label("", left)
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route_label = _label("", left)
	route = ProgressBar.new()
	route.show_percentage = false
	route.custom_minimum_size.y = 16
	left.add_child(route)
	tabs = TabContainer.new()
	tabs.custom_minimum_size.x = 480
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(tabs)
	status_label = _label("", layout)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 30
	import_dialog = _file_dialog(FileDialog.FILE_MODE_OPEN_FILE, "*.json ; Level JSON")
	import_dialog.file_selected.connect(_import_path)
	export_dialog = _file_dialog(FileDialog.FILE_MODE_SAVE_FILE, "*.json ; Draft level JSON")
	export_dialog.file_selected.connect(func(path: String): var result: Dictionary = document.export_json(path); _status(result.reason))
	thumbnail_dialog = _file_dialog(FileDialog.FILE_MODE_SAVE_FILE, "*.png ; PNG thumbnail")
	thumbnail_dialog.file_selected.connect(func(path: String):
		var error: int = document.thumbnail_image().save_png(path)
		_status("Thumbnail exported: " + path if error == OK else "Thumbnail failed: " + error_string(error)))
	discard_dialog = ConfirmationDialog.new()
	discard_dialog.dialog_text = "Discard unsaved authoring changes? The source fixtures and player save are not changed."
	discard_dialog.confirmed.connect(func(): _pending_action.call())
	add_child(discard_dialog)

func _file_dialog(file_mode: FileDialog.FileMode, filter: String) -> FileDialog:
	var dialog := FileDialog.new()
	dialog.file_mode = file_mode
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray([filter])
	dialog.current_dir = ProjectSettings.globalize_path("user://")
	add_child(dialog)
	return dialog

func _guard(action: Callable) -> void:
	playing = false
	if document.dirty:
		_pending_action = action
		discard_dialog.popup_centered()
	else:
		action.call()

func _import_path(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_status("Cannot read " + path)
		return
	var result: Dictionary = document.import_json(file.get_as_text())
	if result.ok:
		document.dirty = false
		_selected_column = 0
		_refresh_all()
		_status("Imported as an unverified authoring draft. Replay is required, even for imported success claims.")
	else:
		_status(result.reason)

func _paint(x: int, y: int, erase: bool) -> void:
	if document.paint(x, y, "." if erase or mode == "erase" else symbol, mode == "fill" and not erase):
		playing = false
		grid.refresh()
		_refresh_report()
		_status("Pattern edited. Previous replay proof invalidated.")

func _refresh_palette() -> void:
	for child in palette_bar.get_children():
		palette_bar.remove_child(child); child.queue_free()
	var tokens: Array = document.config.palette.keys()
	tokens.append(".")
	if symbol not in tokens:
		symbol = str(tokens[0])
	for token in tokens:
		var color: String = "Blank" if token == "." else str(document.config.palette[token]).capitalize()
		_button(color, palette_bar, func(): symbol = token; _status("Palette: " + color))

func _refresh_all() -> void:
	playing = false
	replaying = false
	grid.preview_mode = false
	grid.refresh()
	_refresh_palette()
	_rebuild_tabs()
	_refresh_preview()
	_status("Draft: " + str(document.config.pattern_name) + ". Imported or edited content is not automatically production-ready.")

func _schedule_tabs() -> void:
	if not _queued_rebuild:
		_queued_rebuild = true
		call_deferred("_rebuild_tabs")

func _rebuild_tabs() -> void:
	_queued_rebuild = false
	_rebuilding = true
	var selected := tabs.current_tab
	for child in tabs.get_children():
		tabs.remove_child(child)
		child.queue_free()
	_rebuilding = true
	_build_config_tab(_tab("Pattern"))
	_build_queues_tab(_tab("Queues"))
	_build_dragon_tab(_tab("Dragon"))
	_build_validation_tab(_tab("Verify"))
	tabs.current_tab = clampi(selected, 0, 3)
	_rebuilding = false
	_refresh_report()

func _tab(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 9)
	scroll.add_child(box)
	return box

func _build_config_tab(box: VBoxContainer) -> void:
	_label("Identity and reproducibility", box)
	for field in ["level_id", "pattern_name", "content_version", "objective"]:
		_text_field(field.replace("_", " ").capitalize(), str(document.config.get(field, "")), box, func(value: String): document.set_field(field, value); _refresh_report())
	_number("Seed", float(document.config.seed), 0, 2147483647, 1, box, func(value: float): document.set_field("seed", int(value)); _refresh_report())
	var dimensions := HBoxContainer.new()
	box.add_child(dimensions)
	var width := _spin(float(document.config.width), 1, 48, 1)
	var height := _spin(float(document.config.height), 1, 48, 1)
	dimensions.add_child(width)
	_label("×", dimensions)
	dimensions.add_child(height)
	_button("Resize grid", dimensions, func(): document.resize_grid(int(width.value), int(height.value)); grid.refresh(); _refresh_report())
	_label("Resize crops right/bottom edges. Undo restores them.", box).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label("Palette symbols", box)
	var palette_text := TextEdit.new()
	palette_text.text = JSON.stringify(document.config.palette, "  ")
	palette_text.custom_minimum_size.y = 150
	box.add_child(palette_text)
	_button("Apply palette JSON", box, func():
		var value: Variant = JSON.parse_string(palette_text.text)
		if not value is Dictionary:
			_status("Palette must be a JSON object.")
			return
		var candidate: Dictionary = document.config.duplicate(true)
		candidate.palette = value
		var errors: Array = document._shape_errors(candidate)
		if errors.is_empty():
			document.set_field("palette", value); _refresh_palette(); grid.refresh(); _refresh_report()
		else:
			_status("; ".join(errors)))
	_label("Original artwork is hand-painted here. The helper below only builds balanced queues and armor; it does not prove solvability.", box).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var count := _spin(5, 1, 8, 1)
	var quota := _spin(18, 1, 999, 1)
	_label("Candidate columns / maximum team quota", box)
	var options := HBoxContainer.new(); box.add_child(options); options.add_child(count); options.add_child(quota)
	_button("Build balanced queue + armor draft", box, func(): document.generate_balanced_queues(int(count.value), int(quota.value)); _schedule_tabs(); _refresh_report())

func _build_queues_tab(box: VBoxContainer) -> void:
	_label("Columns and front-to-back team order", box)
	var selector := OptionButton.new()
	for column in document.config.columns:
		selector.add_item(str(column.id))
	_selected_column = clampi(_selected_column, 0, maxi(0, document.config.columns.size() - 1))
	selector.select(_selected_column)
	box.add_child(selector)
	selector.item_selected.connect(func(index: int): _selected_column = index; _selected_team = 0; _schedule_tabs())
	var column_controls := HBoxContainer.new(); box.add_child(column_controls)
	_button("Add column", column_controls, func():
		var columns: Array = document.config.columns.duplicate(true)
		columns.append({"id": _unique_id("column", columns), "teams": []})
		document.set_field("columns", columns); _selected_column = columns.size() - 1; _schedule_tabs())
	_button("Delete column", column_controls, func():
		var columns: Array = document.config.columns.duplicate(true)
		if not columns.is_empty():
			columns.remove_at(_selected_column); document.set_field("columns", columns); _schedule_tabs())
	if document.config.columns.is_empty():
		return
	var column: Dictionary = document.config.columns[_selected_column]
	_text_field("Column ID", str(column.id), box, func(value: String):
		var columns: Array = document.config.columns.duplicate(true); columns[_selected_column].id = value; document.set_field("columns", columns); _refresh_report())
	var list := ItemList.new()
	list.custom_minimum_size.y = 220
	for team in column.teams:
		list.add_item("%s  ·  %s × %d" % [team.id, team.color, team.quota])
	_selected_team = clampi(_selected_team, 0, maxi(0, column.teams.size() - 1))
	if not column.teams.is_empty():
		list.select(_selected_team)
		list.call_deferred("ensure_current_is_visible")
	box.add_child(list)
	list.item_selected.connect(func(index: int): _selected_team = index; _schedule_tabs())
	var actions := HBoxContainer.new(); box.add_child(actions)
	_button("Add team", actions, func(): _edit_teams("add"))
	_button("Remove", actions, func(): _edit_teams("remove"))
	_button("↑", actions, func(): _edit_teams("up"))
	_button("↓", actions, func(): _edit_teams("down"))
	if not column.teams.is_empty():
		var team: Dictionary = column.teams[_selected_team]
		_text_field("Team ID", str(team.id), box, func(value: String): _team_value("id", value))
		_color_field(str(team.color), box, func(value: String): _team_value("color", value))
		_number("Quota", float(team.quota), 1, 2304, 1, box, func(value: float): _team_value("quota", int(value)))

func _unique_id(prefix: String, values: Array) -> String:
	var ids: Array = values.map(func(value): return str(value.id))
	var index := 1
	while "%s-%d" % [prefix, index] in ids:
		index += 1
	return "%s-%d" % [prefix, index]

func _team_value(key: String, value: Variant) -> void:
	var columns: Array = document.config.columns.duplicate(true)
	columns[_selected_column].teams[_selected_team][key] = value
	document.set_field("columns", columns)
	_refresh_report()

func _edit_teams(action: String) -> void:
	var columns: Array = document.config.columns.duplicate(true)
	var teams: Array = columns[_selected_column].teams
	if action == "add":
		var all: Array = []
		for column in columns:
			all.append_array(column.teams)
		teams.append({"id": _unique_id("team", all), "color": "red", "quota": 1})
		_selected_team = teams.size() - 1
	elif not teams.is_empty():
		if action == "remove":
			teams.remove_at(_selected_team)
		else:
			var target := clampi(_selected_team + (-1 if action == "up" else 1), 0, teams.size() - 1)
			var team: Dictionary = teams.pop_at(_selected_team)
			teams.insert(target, team)
			_selected_team = target
	document.set_field("columns", columns)
	_schedule_tabs()

func _build_dragon_tab(box: VBoxContainer) -> void:
	_label("Ordered armor demands", box)
	var list := ItemList.new(); list.custom_minimum_size.y = 150
	for armor in document.config.armors:
		list.add_item("%s  ·  %s × %d" % [armor.id, armor.color, armor.demand])
	_selected_armor = clampi(_selected_armor, 0, maxi(0, document.config.armors.size() - 1))
	if not document.config.armors.is_empty():
		list.select(_selected_armor)
		list.call_deferred("ensure_current_is_visible")
	box.add_child(list)
	list.item_selected.connect(func(index: int): _selected_armor = index; _schedule_tabs())
	var actions := HBoxContainer.new(); box.add_child(actions)
	for action in ["add", "remove", "up", "down"]:
		_button(action.capitalize(), actions, func(): _edit_armor(action))
	if not document.config.armors.is_empty():
		var armor: Dictionary = document.config.armors[_selected_armor]
		_text_field("Armor ID", str(armor.id), box, func(value: String): _armor_value("id", value))
		_color_field(str(armor.color), box, func(value: String): _armor_value("color", value))
		_number("Demand", float(armor.demand), 1, 2304, 1, box, func(value: float): _armor_value("demand", int(value)))
	for group in ["dragon", "parameters"]:
		_label(group.capitalize(), box)
		for key in document.config[group]:
			_number(key.replace("_", " "), float(document.config[group][key]), 0, 10000, 1 if key == "max_inflight_ants" else 0.01, box, func(value: float):
				var values: Dictionary = document.config[group].duplicate(true)
				values[key] = int(value) if key == "max_inflight_ants" else value
				document.set_field(group, values); _refresh_report())
	_label("Available tools (once per level; validation never uses them)", box).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for definition in Document.Rules.DEFAULT_TOOLS:
		var row := HBoxContainer.new(); box.add_child(row)
		var toggle := CheckBox.new(); toggle.text = definition.id; row.add_child(toggle)
		var matches: Array = document.config.get("tools", []).filter(func(item): return item.id == definition.id)
		toggle.button_pressed = not matches.is_empty()
		var unlock := _spin(matches[0].unlock_level if not matches.is_empty() else definition.unlock_level, 1, 30, 1); row.add_child(unlock)
		var update := func():
			var items: Array = document.config.get("tools", []).filter(func(item): return item.id != definition.id)
			if toggle.button_pressed:
				items.append({"id": definition.id, "unlock_level": int(unlock.value), "uses_per_level": 1})
			document.set_field("tools", items); _refresh_report()
		toggle.toggled.connect(func(_value: bool): update.call())
		unlock.value_changed.connect(func(_value: float): update.call())

func _armor_value(key: String, value: Variant) -> void:
	var armors: Array = document.config.armors.duplicate(true)
	armors[_selected_armor][key] = value
	document.set_field("armors", armors); _refresh_report()

func _edit_armor(action: String) -> void:
	var armors: Array = document.config.armors.duplicate(true)
	if action == "add":
		armors.append({"id": _unique_id("armor", armors), "color": "red", "demand": 1})
		_selected_armor = armors.size() - 1
	elif not armors.is_empty():
		if action == "remove":
			armors.remove_at(_selected_armor)
		else:
			var target := clampi(_selected_armor + (-1 if action == "up" else 1), 0, armors.size() - 1)
			var armor: Dictionary = armors.pop_at(_selected_armor); armors.insert(target, armor); _selected_armor = target
	document.set_field("armors", armors); _schedule_tabs()

func _build_validation_tab(box: VBoxContainer) -> void:
	_label("Proof requires the final armor hit, not an empty board.", box).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button("Find and verify no-tool solution", box, func(): playing = false; _status("Checking a bounded timed replay…"); call_deferred("_verify", null))
	_button("Verify imported / saved sequence", box, func(): playing = false; _verify(document.solution))
	_button("Verify recorded preview inputs", box, func(): playing = false; _verify(document.recording))
	_button("Watch verified replay", box, _watch_replay)
	report_label = _label("", box)
	report_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	report_label.add_theme_font_size_override("font_size", 18)
	_label("Author notes (not automated playtest evidence)", box)
	var notes := TextEdit.new()
	notes.custom_minimum_size.y = 180
	notes.text = JSON.stringify(document.config.get("author_notes", {}), "  ")
	box.add_child(notes)
	_button("Save author notes JSON", box, func():
		var value: Variant = JSON.parse_string(notes.text)
		if value is Dictionary:
			document.set_field("author_notes", value); _refresh_report()
		else:
			_status("Author notes must be a JSON object."))

func _verify(inputs: Variant) -> void:
	var result: Dictionary = document.validate_solution(inputs)
	_refresh_report()
	_status("Timed no-tool replay verified. Human playtesting is NOT RUN; this remains a draft." if result.status == "TIMED_REPLAY_VERIFIED" else "Unverified: " + str(result.get("reason", "unknown")))

func _watch_replay() -> void:
	if document.validation.get("status") != "TIMED_REPLAY_VERIFIED" or document.validation.get("content_sha256") != document.fingerprint():
		_status("Verify this exact content before watching its accepted replay.")
		return
	var inputs: Array = document.solution.duplicate(true)
	_start_preview()
	if document.preview == null:
		return
	replay_inputs = inputs
	replay_index = 0
	replaying = true
	playing = true
	_advance(0)

func _refresh_report() -> void:
	if not is_instance_valid(report_label):
		return
	var lines: Array[String] = ["STATE: " + str(document.validation.get("status", "UNVERIFIED")), "Human playtest: NOT RUN", "Production: not eligible", "", "COLOR     BOARD / QUOTA / ARMOR"]
	for row in document.color_report():
		lines.append("%s: %d / %d / %d   %s" % [row.color.capitalize(), row.board, row.quota, row.armor, "OK" if row.balanced else "MISMATCH"])
	var errors: Array = document.structural_errors()
	lines.append("")
	lines.append("Structure: valid (not proof of a solution)" if errors.is_empty() else "Errors:\n" + "\n".join(errors))
	if document.validation.get("status") == "TIMED_REPLAY_VERIFIED":
		lines.append("Final hit: %.3fs · %d inputs\nMargin: %.3fs\nVerified: %s\nSHA256: %s" % [float(document.validation.terminal_time_us) / 1000000, document.solution.size(), float(document.validation.final_hit_margin_us) / 1000000, document.validation.verified_at_utc, str(document.validation.content_sha256).substr(0, 16)])
		for boundary in document.validation.get("boundary_replays", {}):
			lines.append(boundary.replace("_", " ") + ": " + str(document.validation.boundary_replays[boundary].status))
	else:
		lines.append("Reason: " + str(document.validation.get("reason", "not_checked")))
	report_label.text = "\n".join(lines)
	if document.preview == null:
		playing = false
		replaying = false
		grid.preview_mode = false
		grid.refresh()
		_refresh_preview()

func _start_preview() -> void:
	playing = false
	replaying = false
	var result: Dictionary = document.start_preview()
	if not result.ok:
		_status(result.reason + ": " + "; ".join(result.errors))
		return
	grid.preview_mode = true
	grid.refresh()
	_refresh_preview()
	_status("Preview records accepted front selections at ≥0.75s simulation intervals. No tools are used.")

func _process(delta: float) -> void:
	if playing and document.preview != null:
		_advance(int(minf(delta, 0.25) * 1000000))
	_elapsed_refresh += delta
	if _elapsed_refresh > 0.12 and document.preview != null:
		_elapsed_refresh = 0
		grid.refresh()
		_refresh_preview()

func _advance(delta_us: int) -> void:
	if document.preview == null:
		_start_preview()
		if document.preview == null:
			return
	var sim = document.preview
	if replaying:
		var target: int = sim.time_us + delta_us
		while replay_index < replay_inputs.size() and int(replay_inputs[replay_index].time_us) <= target:
			var input: Dictionary = replay_inputs[replay_index]
			document.step_preview(int(input.time_us) - sim.time_us)
			var response: Dictionary = document.select_front(input.column_id, input.team_id)
			if not response.ok:
				playing = false; replaying = false; _status("Replay stopped: " + str(response.reason)); return
			replay_index += 1
		document.step_preview(maxi(0, target - sim.time_us))
	else:
		document.step_preview(delta_us)
	if sim.status in ["victory", "defeat"] or sim.paused:
		playing = false
	grid.refresh()
	_refresh_preview()

func _refresh_preview() -> void:
	for child in front_row.get_children():
		front_row.remove_child(child); child.queue_free()
	if document.preview == null:
		preview_label.text = "Paint the pattern, configure queues, then start preview. Right-click erases."
		route_label.text = "Dragon route and current armor appear during preview."
		route.value = 0
		return
	var sim = document.preview
	for column in sim.columns:
		if column.teams.is_empty():
			continue
		var team: Dictionary = column.teams[0]
		var button := _button("%s\n%s × %d" % [column.id, team.color.capitalize(), team.remaining], front_row, func():
			var result: Dictionary = document.select_front(column.id, team.id)
			if not result.ok:
				_status(str(result.reason))
			_refresh_preview(); grid.refresh())
		button.disabled = replaying or sim.status not in ["ready", "running"]
		button.add_theme_font_size_override("font_size", 16)
	var slots: Array[String] = []
	for slot in sim.slots:
		slots.append("empty" if slot == null else "%s %d (%s)" % [slot.color, slot.remaining, slot.work_state])
	var stock: Array[String] = []
	for color in sim.inventory:
		stock.append("%s %d" % [color, sim.inventory[color]])
	preview_label.text = "%.2fs · %s · %d recorded inputs · %d ants in flight\nSlots: %s\nInventory: %s" % [float(sim.time_us) / 1000000, sim.status.to_upper(), document.recording.size(), sim.tasks.size(), " | ".join(slots), " · ".join(stock)]
	route.max_value = float(document.config.dragon.route_length)
	route.value = sim.dragon_position()
	var armor_text := "All armor broken" if sim.armor_index >= sim.armors.size() else "Armor %d/%d: %s × %d" % [sim.armor_index + 1, sim.armors.size(), sim.armors[sim.armor_index].color, sim.armors[sim.armor_index].demand]
	route_label.text = "Dragon %.2f → Princess %.2f · %s" % [sim.dragon_position(), document.config.dragon.route_length, armor_text]

func _label(value: String, parent: Node) -> Label:
	var label := Label.new(); label.text = value; parent.add_child(label); return label

func _button(value: String, parent: Node, callback: Callable) -> Button:
	var button := Button.new(); button.text = value; button.pressed.connect(callback); parent.add_child(button); return button

func _text_field(title: String, value: String, parent: Node, callback: Callable) -> void:
	_label(title, parent)
	var edit := LineEdit.new(); edit.text = value; parent.add_child(edit)
	edit.text_submitted.connect(callback)
	edit.focus_exited.connect(func():
		if not _rebuilding and edit.text != value:
			callback.call(edit.text))

func _spin(value: float, minimum: float, maximum: float, step: float) -> SpinBox:
	var spin := SpinBox.new(); spin.min_value = minimum; spin.max_value = maximum; spin.step = step; spin.value = value; spin.custom_minimum_size.x = 120; return spin

func _number(title: String, value: float, minimum: float, maximum: float, step: float, parent: Node, callback: Callable) -> void:
	var row := HBoxContainer.new(); parent.add_child(row)
	_label(title, row).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var spin := _spin(value, minimum, maximum, step)
	if title == "Seed":
		spin.custom_minimum_size.x = 190
	row.add_child(spin); spin.value_changed.connect(callback)

func _color_field(value: String, parent: Node, callback: Callable) -> void:
	var selector := OptionButton.new()
	for color in Document.COLORS:
		selector.add_item(color.capitalize())
	selector.select(Document.COLORS.find(value))
	parent.add_child(selector)
	selector.item_selected.connect(func(index: int): callback.call(Document.COLORS[index]))

func _status(text: String) -> void:
	status_label.text = text
