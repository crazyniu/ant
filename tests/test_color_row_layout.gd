extends SceneTree
## Bounded production-Control regression for the color-row presentation only.
## Signal-driven handlers are not native pointer input or human visual acceptance.

const REPORT_PATH := "res://reports/ui/color-row-layout.json"
const Play = preload("res://scripts/play.gd")
const LOGICAL_CANVAS := Vector2(940, 1672)
const PHONE_WIDTH := 375.0
const MIN_TARGET_POINTS := 44.0
const EPSILON := 0.01

var checks := 0
var failures: Array[String] = []
var observations: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, note: String) -> void:
	checks += 1
	if not value:
		failures.append(note)
		push_error(note)

func rectangle_data(rect: Rect2) -> Dictionary:
	return {"x": rect.position.x, "y": rect.position.y, "width": rect.size.x, "height": rect.size.y}

func same_rectangle(a: Rect2, b: Rect2) -> bool:
	return a.position.distance_to(b.position) < EPSILON and a.size.distance_to(b.size) < EPSILON

func inspect_static_layout() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	check(Play.color_control_layout(0).is_empty(), "layout helper: zero colors yields no controls")
	# Geometry only. Do not fabricate a five/six-color level or gameplay claim.
	for count in range(1, 7):
		var rects: Array[Rect2] = Play.color_control_layout(count)
		check(rects.size() == count, "layout helper: %d colors returns exactly %d rectangles" % [count, count])
		if rects.is_empty():
			continue
		var rows: Array[Dictionary] = []
		var union_rect := rects[0]
		for index in rects.size():
			var rect := rects[index]
			var points := rect.size * PHONE_WIDTH / LOGICAL_CANVAS.x
			check(absf(rect.position.y - 1282.0) < EPSILON and rect.size.distance_to(rects[0].size) < EPSILON, "layout helper: %d colors, entry %d is single-row and equal-sized" % [count, index])
			check(points.x >= MIN_TARGET_POINTS and points.y >= MIN_TARGET_POINTS, "layout helper: %d colors, entry %d retains minimum target dimensions" % [count, index])
			check(Rect2(Vector2.ZERO, LOGICAL_CANVAS).encloses(rect), "layout helper: %d colors, entry %d remains inside canvas" % [count, index])
			if index > 0:
				check(absf(rect.position.x - rects[index - 1].end.x - 20.0) < EPSILON and not rect.intersects(rects[index - 1]), "layout helper: %d colors, entry %d retains 20-pixel gap without overlap" % [count, index])
			union_rect = union_rect.merge(rect)
			rows.append(rectangle_data(rect))
		check(absf(union_rect.get_center().x - LOGICAL_CANVAS.x * 0.5) < EPSILON, "layout helper: %d-color row remains centered" % count)
		results.append({"color_count": count, "rectangles": rows})
	return results

func inspect_row(scene: Control, level: int, expected_colors: int) -> Dictionary:
	var prefix := "level %d: " % level
	var colors: Array = scene.color_buttons.keys()
	check(colors.size() == expected_colors, prefix + "actual authored color count")
	var rows: Array[Dictionary] = []
	if colors.is_empty():
		return {"level": level, "controls": rows}
	var first: Button = scene.color_buttons[colors[0]]
	var union_rect: Rect2 = first.get_rect()
	var previous_rect: Rect2 = first.get_rect()
	var expected_gap := -1.0
	var helper_rects: Array[Rect2] = Play.color_control_layout(colors.size())
	for index in colors.size():
		var color := str(colors[index])
		var button: Button = scene.color_buttons[color]
		var rect := button.get_rect()
		var target_points := rect.size * PHONE_WIDTH / LOGICAL_CANVAS.x
		check(button.is_inside_tree() and button.is_visible_in_tree(), prefix + color + " is a real visible Button")
		check(absf(rect.position.y - first.position.y) < EPSILON, prefix + color + " stays in one row")
		check(rect.size.distance_to(first.size) < EPSILON, prefix + color + " has equal dimensions")
		check(same_rectangle(rect, helper_rects[index]), prefix + color + " actual post-tree rectangle matches dynamic layout")
		check(target_points.x >= MIN_TARGET_POINTS and target_points.y >= MIN_TARGET_POINTS, prefix + color + " meets 44-point equivalent target in both axes")
		check(Rect2(Vector2.ZERO, LOGICAL_CANVAS).encloses(rect), prefix + color + " stays inside logical canvas")
		check(button.mouse_filter != Control.MOUSE_FILTER_IGNORE and not button.disabled, prefix + color + " accepts handler input")
		var plate: Control = scene.get_node("CandidateQueues/ColorPlate_" + color)
		var count: Label = scene.get_node("CandidateQueues/Remaining_" + color)
		var indicator: Control = scene.get_node("CandidateQueues/ColorState_" + color)
		check(same_rectangle(plate.get_rect(), rect), prefix + color + " plate matches hit target")
		check(rect.grow(EPSILON).encloses(count.get_rect()), prefix + color + " count fits inside its target")
		check(rect.grow(EPSILON).encloses(indicator.get_rect()), prefix + color + " state icon fits inside its target")
		check(count.text == str(scene.rules.available_counts().get(color, 0)), prefix + color + " displays actual uncollected count")
		if index > 0:
			var gap := rect.position.x - previous_rect.end.x
			check(gap > 0.0, prefix + color + " follows the previous target without overlap")
			if expected_gap < 0.0:
				expected_gap = gap
			else:
				check(absf(gap - expected_gap) < EPSILON, prefix + color + " has equal spacing")
		for earlier_index in index:
			var earlier: Button = scene.color_buttons[colors[earlier_index]]
			check(not rect.intersects(earlier.get_rect()), prefix + color + " has no overlapping hit target with " + str(colors[earlier_index]))
		rows.append({"color": color, "button": rectangle_data(rect), "target_points_at_375_width": {"width": target_points.x, "height": target_points.y}, "count": count.text, "state": scene.view_snapshot.color_states[color].state, "indicator": indicator.kind, "indicator_visible": indicator.visible, "tooltip": button.tooltip_text})
		union_rect = union_rect.merge(rect)
		previous_rect = rect
	check(absf(union_rect.get_center().x - LOGICAL_CANVAS.x * 0.5) < EPSILON, prefix + "row is horizontally centered")
	return {"level": level, "level_id": scene.level_config.level_id, "controls": rows, "row_bounds": rectangle_data(union_rect), "gap": expected_gap}

func inspect_blocked_clicks(scene: Control) -> Dictionary:
	var before: Dictionary = scene.rules.snapshot()
	var yellow: Button = scene.color_buttons.yellow
	var indicator: Control = scene.get_node("CandidateQueues/ColorState_yellow")
	var count: Label = scene.get_node("CandidateQueues/Remaining_yellow")
	var original_count := count.text
	check(before.color_states.yellow.state == "blocked", "level 4: authored yellow starts blocked, not locked")
	check(int(before.color_states.yellow.available_count) > 0 and int(before.color_states.yellow.clickable_count) == 0, "level 4: yellow exists but has no reachable bead")
	check(indicator.visible and indicator.kind == "barrier", "level 4: blocked yellow shows barrier, never a padlock")
	check(yellow.tooltip_text == "No reachable bead", "level 4: blocked tooltip is No reachable bead")
	check(not yellow.disabled, "level 4: blocked yellow still accepts explanatory clicks")
	for press in 3:
		yellow.emit_signal("pressed")
		check(scene.rules.snapshot() == before, "level 4: blocked click %d creates no task, reservation, count deduction or gameplay mutation" % (press + 1))
		check(count.text == original_count, "level 4: blocked click %d keeps displayed yellow count" % (press + 1))
	check(scene.has_node("ClickFeedback") and str(scene.get_node("ClickFeedback").text) == "NO REACHABLE BEAD", "level 4: blocked handler supplies exact NO REACHABLE BEAD feedback")
	scene.sync_view()
	check(indicator.visible and indicator.kind == "barrier" and yellow.tooltip_text == "No reachable bead", "level 4: blocked presentation survives repeated presses and view sync")
	check(scene.rules.conservation_errors().is_empty(), "level 4: blocked presses conserve resources")
	return {"repeated_presses": 3, "remaining_yellow_before": original_count, "remaining_yellow_after": count.text, "tasks_after": scene.rules.tasks.size(), "reservations_after": scene.rules.reservations.size(), "feedback": scene.get_node("ClickFeedback").text}

func inspect_ready_and_modal_clicks(scene: Control, level: int) -> void:
	var prefix := "level %d: " % level
	var before: Dictionary = scene.rules.snapshot()
	check(before.color_states.red.state == "ready", prefix + "authored red is reachable")
	scene.color_buttons.red.emit_signal("pressed")
	check(scene.rules.tasks.size() == 1 and scene.rules.reservations.size() == 1, prefix + "one ready pressed signal creates exactly one task and reservation")
	check(scene.rules.available_counts() == before.available_counts, prefix + "dispatch does not prematurely deduct any bead count")
	check(scene.get_node("WorkSlots/CarrierCount").text == "1 / 4", prefix + "carrier count reflects exactly one dispatch")
	scene.show_pause()
	var paused: Dictionary = scene.rules.snapshot()
	scene.color_buttons.red.emit_signal("pressed")
	check(scene.rules.snapshot() == paused, prefix + "modal blocks color handler without gameplay mutation")
	check(scene.rules.conservation_errors().is_empty(), prefix + "focused click regression conserves resources")

func run() -> void:
	var helper_geometry := inspect_static_layout()
	for level in [4, 1]:
		var scene: Control = load("res://scenes/play.tscn").instantiate()
		# Production auto-replay initialization creates an isolated /tmp profile and
		# admits only this authored level. Disable simulation before any frame runs.
		scene.auto_replay = true
		scene.use_command_line_catalog = false
		scene.use_command_line_level = false
		scene.level_index = level
		root.add_child(scene)
		current_scene = scene
		scene.set_process(false)
		scene.auto_replay = false
		await process_frame
		check(scene.ready_to_simulate, "level %d: production play scene initializes" % level)
		check(scene.profile_directory.begins_with("/tmp/ant-rescue-replay-"), "level %d: test uses an isolated replay profile" % level)
		if scene.ready_to_simulate:
			check(scene.rules.status == "ready" and scene.rules.time_us == 0 and scene.rules.tasks.is_empty(), "level %d: no replay or simulation advanced before inspection" % level)
			var observation := inspect_row(scene, level, 4 if level == 4 else 3)
			if level == 4:
				observation["blocked_clicks"] = inspect_blocked_clicks(scene)
			inspect_ready_and_modal_clicks(scene, level)
			observations.append(observation)
		scene.queue_free()
		await process_frame
		await process_frame
	var report := {"checks": checks, "failures": failures, "engine_version": Engine.get_version_info().string, "levels": observations, "static_layout_geometry": helper_geometry, "scope": "Bounded headless actual production Controls at authored levels 4 and 1: single-row geometry, 44-point-equivalent targets, blocked barrier/tooltip, repeated rejection, one-click dispatch and modal guard. Pure layout-helper geometry for 1..6 colors, not synthetic levels. No full campaign replay, native pointer input, rendering acceptance or human playtest."}
	var report_file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if report_file == null:
		check(false, "cannot write color-row layout report: %s" % FileAccess.get_open_error())
	else:
		report_file.store_string(JSON.stringify(report, "\t") + "\n")
		report_file.close()
	print("COLOR_ROW_LAYOUT ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
