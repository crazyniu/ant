extends SceneTree
## Isolated presentation regression. No production profiles or rules are changed.
const Adventure = preload("res://scripts/adventure_view.gd")
var failures: Array[String] = []
var checks := 0
var view: Control
var chosen: Array[int] = []
var launches: Array = []
var shops := 0

func _initialize() -> void: call_deferred("run")
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures.append(message); push_error(message)

func run() -> void:
	var configs: Array = []
	for number in range(1, 4): configs.append(JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-%02d.json" % number)))
	var state := {"ready": true, "available_unlocked": 1, "completed_levels": {}}
	var economy := {"points": 127, "owned_types": ["worker"], "equipped_type": "worker", "carry_level": 1}
	view = Adventure.new(); view.set_data(configs, state, economy)
	view.restore_navigation_state({"region_id":"","scroll_y":0,"selected_level":1})
	view.choose_level.connect(func(number: int): chosen.append(number))
	view.begin_level.connect(func(number: int, carrier_type: String): launches.append([number, carrier_type]))
	view.shop_requested.connect(func(): shops += 1)
	root.add_child(view)
	await process_frame; await process_frame; await process_frame
	check(view.get_node("AdventurePage/MapScroll").scroll_vertical > 0 and view.get_navigation_state().region_id == "forest", "Fresh map frames the first playable level and persists a real region after container layout")
	check(view.size == Vector2(940, 1672), "Logical canvas matches existing 2K parent scale")
	check(view.get_node("AdventurePage/PointBalance").text == "127", "Points come from economy view")
	var canvas: Control = view.get_node("AdventurePage/MapScroll/MapCanvas")
	check(canvas.get_node_or_null("LevelNode1") != null and canvas.get_node_or_null("LevelNode3") != null, "Three real map nodes are present")
	check(canvas.get_node_or_null("LevelNode4") == null and canvas.get_node_or_null("LevelNode30") == null, "Map never fabricates 30 completed/authored levels")
	check(canvas.get_node("LevelNode1").get_meta("state") == "playable", "First level is available")
	check(canvas.get_node("LevelNode2").get_meta("state") == "locked", "Locked level status uses save state")
	check(canvas.get_node("LevelNode2/ChooseLevel2").disabled, "Locked node is disabled")
	canvas.get_node("LevelNode2/ChooseLevel2").pressed.emit()
	check(chosen.is_empty(), "Even a stale locked-node signal cannot choose a level")
	canvas.get_node("LevelNode1/ChooseLevel1").pressed.emit()
	check(chosen == [1], "Available node emits exact level number")
	check(not view.show_preparation(2), "Locked preparation navigation is rejected")
	check(not view.show_preparation(30), "Missing definition navigation is rejected")
	view.get_node("AdventurePage/MapScroll").scroll_vertical = 200
	var before: Dictionary = view.get_navigation_state()
	check(view.show_preparation(1), "Unlocked preparation navigation succeeds")
	await process_frame
	check(view.get_node("AdventurePage").get_meta("level_summary").hp == 12, "Level 1 preview uses twelve required hits")
	check(view.get_node("AdventurePage/NormalCount").text == "12" and view.get_node_or_null("AdventurePage/ArmoredCount")==null, "Level 1 segment mix is authoritative")
	check(view.get_node("AdventurePage").get_meta("level_summary").beads == 18, "Level 1 shows actual sparse mosaic count")
	var scene: Control = view.get_node("AdventurePage/ScenePreview/ActualLevelScene")
	var bead_count := 0
	for child in scene.get_children():
		if child.has_meta("cell"): bead_count += 1
	check(bead_count == 18, "Preview has one real node per configured bead")
	check(scene.get_node("PreviewSerpent").bodies.size() == 12, "Preview has one real body node per configured segment")
	check(scene.get_node_or_null("Princess") != null, "Preview matches the current gameplay guardian rather than inventing a camp")
	check(not view.get_node("AdventurePage/AntChoice_swift").get_meta("owned"), "Locked Swift is not falsely marked owned")
	view.get_node("AdventurePage/AntChoice_swift/Equip_swift").pressed.emit()
	check(shops == 1 and view.selected_type == "worker", "Locked Swift requests shop and never equips")
	view.get_node("AdventurePage/BeginLevel").pressed.emit()
	view.get_node("AdventurePage/BeginLevel").pressed.emit()
	check(launches == [[1, "worker"]], "Repeated start is idempotent until parent resolves launch")
	view.release_begin_lock(); view.get_node("AdventurePage/BeginLevel").pressed.emit()
	check(launches.size() == 2, "Parent may explicitly release start after save failure")
	view.show_map(); await process_frame; await process_frame; await process_frame
	var after: Dictionary = view.get_navigation_state()
	check(after.scroll_y == before.scroll_y and after.selected_level == 1, "Map return retains scroll and selection")
	state = {"ready": true, "available_unlocked": 3, "completed_levels": {"serpent-01": {}, "serpent-02": {}}}
	economy = {"points": 506, "owned_types": ["worker", "swift"], "equipped_type": "swift", "carry_level": 4}
	view.set_data(configs, state, economy); view.show_preparation(2); await process_frame
	check(view.get_node("AdventurePage").get_meta("level_summary").hp == 16, "Level 2 derives sixteen HP, not twelve segments")
	check(view.get_node("AdventurePage/NormalCount").text == "8" and view.get_node("AdventurePage/ArmoredCount").text == "4", "Level 2 displays correct normal/armor mix")
	check(view.selected_type == "swift", "Owned equipped type is restored from economy")
	check(is_equal_approx(view._multiplier("swift"), 1.38), "Type and shared training multiply without compounding upgrades")
	check(view.get_node("AdventurePage/AntChoice_swift").get_meta("owned"), "Owned Swift is accurately marked")
	var armor_count := 0
	for body in view.get_node("AdventurePage/ScenePreview/ActualLevelScene/PreviewSerpent").bodies.values():
		if body.node.get_node_or_null("ArmorOverlay") != null: armor_count += 1
	check(armor_count == 4, "Armored preview uses four actual independent overlay sprites")
	view.get_node("AdventurePage/AntChoice_worker/Equip_worker").pressed.emit()
	check(view.selected_type == "worker", "Owned Worker can be selected")
	view.show_preparation(3); await process_frame
	check(view.get_node("AdventurePage").get_meta("level_summary").hp == 16, "Level 3 derives sixteen HP")
	check(view.get_node("AdventurePage/NormalCount").text == "6" and view.get_node("AdventurePage/ArmoredCount").text == "5", "Level 3 differs from Level 2 rather than reusing counts")
	check(view.level_summary(1).needs == {"red": 4, "blue": 4, "green": 4}, "Per-color damage requirements are exact")
	check(view.level_summary(2).needs == {"red": 5, "blue": 5, "green": 6}, "Armored per-color damage requirements count twice")
	check(is_equal_approx(view.level_summary(1).time_budget, 60.0), "Finite-route threat budget is computed from config")
	view.restore_navigation_state({"screen": "map", "region_id": "woodland", "scroll_y": 140, "selected_level": 2, "selected_type": "swift"})
	await process_frame; await process_frame; await process_frame
	var restored: Dictionary = view.get_navigation_state()
	check(restored.region_id == "woodland" and restored.scroll_y == 140 and restored.selected_level == 2, "Persistable navigation contract restores all map fields")
	check(view.get_node("AdventurePage/MapScroll/MapCanvas/LevelNode1").get_meta("state") == "completed", "Completed nodes reflect refreshed progression")
	check(view.get_node("AdventurePage/PointBalance").text == "506", "Balance refresh does not keep stale text")
	var before_data := JSON.stringify(configs)
	view.level_definitions[0]["title"] = "Presentation copy"
	check(JSON.stringify(configs) == before_data, "Display module never mutates parent definitions")
	view.set_data(configs, {"ready": false, "available_unlocked": 3}, economy)
	check(not view.show_preparation(1), "Save-not-ready cannot launch even when a stale unlocked count exists")
	view.queue_free(); await process_frame; await process_frame
	print("ADVENTURE_VIEW_TEST ", JSON.stringify({"ok": failures.is_empty(), "checks": checks, "failures": failures, "visual_acceptance": false, "production_save_writes": false}))
	quit(0 if failures.is_empty() else 1)
