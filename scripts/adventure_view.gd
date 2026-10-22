extends Control
## Full-screen adventure navigation. This presentation module never writes a save,
## spends points, starts combat, or declares content outside the supplied catalog.
## The parent owns progression/equipment persistence and handles the signals.

signal choose_level(number: int)
signal begin_level(number: int, carrier_type: String)
signal back_requested
signal shop_requested
signal settings_requested

const SceneLayout = preload("res://scripts/scene_layout.gd")
const Catalog = preload("res://scripts/level_catalog.gd")
const UiSkin = preload("res://scripts/ui_skin.gd")
const Icon = preload("res://scripts/ui_icon.gd")
const Bead = preload("res://scripts/bead.gd")
const ApprovedBall = preload("res://scripts/first_level_bead.gd")
const FirstPreview = preload("res://scripts/first_level_preview.gd")
const BoardPlane = preload("res://scripts/board_plane.gd")
const Serpent = preload("res://scripts/serpent_view.gd")
const Carrier = preload("res://scripts/directional_carrier.gd")
const INK := Color("653513")
const CREAM := Color("fff3cf")
const LOGICAL_SIZE := Vector2(940, 1672)


var font: Font
var skin: RefCounted
var level_definitions: Array = []
var progress: Dictionary = {}
var economy: Dictionary = {}
## Optional alpha title sprites, supplied by the parent after production assets load.
var title_textures: Dictionary = {}
var selected_level := 1
var selected_type := "worker"
var screen := "map"
var map_scroll := -1
var map_region := "woodland"
var _shell: Control
var _page: Control
var _scroll: ScrollContainer
var _begin_pending := false
var _ready_to_draw := false
var _scroll_has_restored:=false
var _page_revision:=0

class MapTrail extends Control:
	var points := PackedVector2Array()
	func _draw() -> void:
		if points.size() < 2: return
		draw_polyline(points, Color("80532e"), 34.0, true)
		draw_polyline(points, Color("d5a55d"), 27.0, true)
		draw_polyline(points, Color("f9d88a"), 18.0, true)
		for i in range(points.size() - 1):
			var distance := points[i].distance_to(points[i + 1])
			for step in range(0, int(distance), 26):
				var p := points[i].lerp(points[i + 1], float(step) / maxf(1.0, distance))
				draw_circle(p, 3.5, Color("ba8744"))

class Emblem extends Control:
	var kind := "coin"
	var ink := Color("ffe4a0")
	func _ready() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var c := size * .5
		var r := minf(size.x, size.y) * .36
		match kind:
			"coin":
				draw_circle(c + Vector2(0, 3), r, Color("925218"))
				draw_circle(c, r, Color("e5a529"))
				draw_arc(c, r - 2, 0, TAU, 40, Color("fff2b2"), 3, true)
				draw_circle(c, r * .69, Color("ffcb4f"))
				for y in [-.37, 0.0, .37]: draw_circle(c + Vector2(0, y * r), r * .15, Color("9a531c"))
				for y in [-.1, .23]:
					for x in [-1, 1]: draw_line(c + Vector2(0, y * r), c + Vector2(x * r * .38, (y + .13) * r), Color("9a531c"), 2.5, true)
			"settings":
				for i in 8:
					var a := float(i) * TAU / 8.0
					draw_line(c + Vector2.from_angle(a) * r * .50, c + Vector2.from_angle(a) * r, ink, r * .36, true)
				draw_circle(c, r * .75, ink)
				draw_circle(c, r * .33, Color("714625"))
			"shop":
				draw_style_box(_box(Color("8c5428"), 3), Rect2(c + Vector2(-r * .8, -r * .05), Vector2(r * 1.6, r * .95)))
				for i in 4:
					var left := c.x - r + float(i) * r * .5
					var points := PackedVector2Array([Vector2(left + r * .09, c.y - r * .8), Vector2(left + r * .41, c.y - r * .8), Vector2(left + r * .5, c.y), Vector2(left, c.y)])
					draw_colored_polygon(points, ink if i % 2 == 0 else Color("cf7833"))
					draw_circle(Vector2(left + r * .25, c.y), r * .25, ink if i % 2 == 0 else Color("cf7833"))
				draw_rect(Rect2(c + Vector2(-r * .19, r * .2), Vector2(r * .38, r * .65)), ink)
			"speed":
				var points := PackedVector2Array([c + Vector2(r * .1, -r), c + Vector2(-r * .7, r * .12), c + Vector2(-r * .05, r * .12), c + Vector2(-r * .23, r), c + Vector2(r * .78, -r * .25), c + Vector2(r * .14, -r * .25)])
				draw_colored_polygon(points, ink)
				points.append(points[0]); draw_polyline(points, Color("a56520"), 2, true)
	static func _box(color: Color, radius: int) -> StyleBoxFlat:
		var style := StyleBoxFlat.new(); style.bg_color = color; style.set_corner_radius_all(radius); return style

func _ready() -> void:
	name = "AdventureView"; size = LOGICAL_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	if font == null: font = load("res://assets/fonts/Title.ttf")
	if skin == null: skin = UiSkin.new()
	_ready_to_draw = true
	_build_shell()
	_render_page()

## Supply the actual loaded catalog, the authoritative save view, and optional
## economy view. Definitions may be raw configs or {number, config} entries.
func set_data(definitions: Array, progress_state: Dictionary, economy_state: Dictionary = {}) -> void:
	_capture_scroll()
	level_definitions.clear()
	for definition in definitions:
		if definition is Dictionary:
			var config: Dictionary = definition.get("config", definition).duplicate(true)
			if not config.is_empty():
				config["level_number"] = int(definition.get("number", config.get("level_number", level_definitions.size() + 1)))
				if not Catalog.runtime_config_allowed(config,int(config.level_number)):continue
				level_definitions.append(config)
	progress = progress_state.duplicate(true)
	economy = economy_state.duplicate(true)
	if economy.is_empty(): economy = progress.duplicate(true)
	if _definition(selected_level).is_empty() and not level_definitions.is_empty(): selected_level = int(level_definitions[0].level_number)
	var equipped := str(economy.get("equipped_type", economy.get("carrier_type", "worker")))
	if not _owned(selected_type): selected_type = "worker"
	if equipped in ["worker", "swift"] and _owned(equipped): selected_type = equipped
	_begin_pending = false
	if _ready_to_draw:
		_build_shell()
		_render_page()

func show_map() -> void:
	_capture_scroll()
	screen = "map"; _begin_pending = false
	if _ready_to_draw: _render_page()
	show()

func show_preparation(number: int) -> bool:
	if _definition(number).is_empty() or not _is_unlocked(number): return false
	_capture_scroll()
	selected_level = number; screen = "preparation"; _begin_pending = false
	map_region=str(_definition(number).get("region_id","forest"))
	if _ready_to_draw: _render_page()
	show()
	return true

func get_navigation_state() -> Dictionary:
	_capture_scroll()
	return {"screen": screen, "region_id": map_region, "scroll_y": map_scroll, "selected_level": selected_level, "selected_type": selected_type}

func restore_navigation_state(state: Dictionary) -> void:
	if not Catalog.runtime_level_allowed(int(state.get("selected_level",1))):
		state={"selected_level":1,"screen":"map","region_id":str(_definition(1).get("region_id","forest")),"scroll_y":-1}
	var saved_region:=str(state.get("region_id", state.get("region", "")))
	map_region = saved_region if not saved_region.is_empty() else str(_definition(selected_level).get("region_id","forest"))
	map_scroll = -1 if saved_region.is_empty() else int(state.get("scroll_y", state.get("scroll", -1)))
	var number := int(state.get("selected_level", selected_level))
	if not _definition(number).is_empty(): selected_level = number
	var carrier_type := str(state.get("selected_type", selected_type))
	selected_type = carrier_type if _owned(carrier_type) else "worker"
	screen = "preparation" if state.get("screen", "map") == "preparation" and _is_unlocked(selected_level) else "map"
	_begin_pending = false
	if _ready_to_draw: _render_page()

## Useful when the parent refuses launch because a save could not be persisted.
func release_begin_lock() -> void:
	_begin_pending = false
	var button := get_node_or_null("AdventurePage/BeginLevel") as Button
	if button != null: button.disabled = false

func level_summary(number: int) -> Dictionary:
	var config := _definition(number)
	if config.is_empty(): return {}
	var normal := 0; var armored := 0; var hp := 0; var beads := 0
	var needs: Dictionary = {}; var supplies: Dictionary = {}
	for segment in config.get("segments", []):
		var health := maxi(0, int(segment.get("hp", 1)))
		if str(segment.get("kind", "normal")) == "armored": armored += 1
		else: normal += 1
		hp += health
		var color := str(segment.get("color", "")); needs[color] = int(needs.get(color, 0)) + health
	var palette: Dictionary = config.get("palette", {})
	for row in config.get("grid", []):
		for letter in str(row):
			if palette.has(letter):
				beads += 1
				var color := str(palette[letter]); supplies[color] = int(supplies.get(color, 0)) + 1
	var serpent: Dictionary = config.get("serpent", {})
	var speed := float(serpent.get("speed_units_sec", 0.0))
	var time_budget := (float(serpent.get("goal_s", 0)) - float(serpent.get("head_start_s", 0))) / speed if speed > 0 else 0.0
	return {"normal": normal, "armored": armored, "hp": hp, "beads": beads, "needs": needs, "supplies": supplies, "time_budget": time_budget, "target": _target_label(config)}

func _definition(number: int) -> Dictionary:
	for config in level_definitions:
		if int(config.get("level_number", 0)) == number: return config
	return {}

func _is_unlocked(number: int) -> bool:
	if not Catalog.runtime_level_allowed(number):return false
	if not bool(progress.get("ready", true)): return false
	for entry in progress.get("levels", []):
		if int(entry.get("number", 0)) == number: return bool(entry.get("unlocked", false))
	return number <= int(progress.get("available_unlocked", progress.get("highest_unlocked", 1)))

func _is_completed(number: int) -> bool:
	for entry in progress.get("levels", []):
		if int(entry.get("number", 0)) == number: return bool(entry.get("completed", false))
	var completed: Variant = progress.get("completed_levels", {})
	var id := str(_definition(number).get("level_id", ""))
	return completed.has(id)

func _owned(carrier_type: String) -> bool:
	if carrier_type == "worker": return true
	if carrier_type != "swift": return false
	var owned: Variant = economy.get("owned_types", economy.get("unlocked_types", ["worker"]))
	if owned is Dictionary: return bool(owned.get(carrier_type, false))
	return owned is Array and owned.has(carrier_type)

func _multiplier(carrier_type: String) -> float:
	var types: Dictionary = economy.get("type_multipliers", {"worker": 1.0, "swift": 1.2})
	var level := clampi(int(economy.get("carry_level", 1)), 1, 4)
	var training := float(economy.get("level_multiplier", [1.0, 1.05, 1.10, 1.15][level - 1]))
	return minf(1.5, float(types.get(carrier_type, 1.0)) * training)

func _target_label(config: Dictionary) -> String:
	var target: Variant = config.get("defense_target", "princess")
	if target is Dictionary: return str(target.get("display_name", target.get("label", target.get("kind", "Princess")))).capitalize()
	return str(target).replace("_", " ").capitalize()

func _capture_scroll() -> void:
	if screen == "map" and is_instance_valid(_scroll) and _scroll_has_restored: map_scroll = _scroll.scroll_vertical

func _clear_page() -> void:
	_page_revision += 1
	if is_instance_valid(_page): remove_child(_page); _page.queue_free()
	_scroll = null
	_scroll_has_restored=false
	_page = _group("AdventurePage", self)
	_page.size = LOGICAL_SIZE

func _build_shell() -> void:
	if is_instance_valid(_shell): remove_child(_shell); _shell.queue_free()
	_shell = _group("AdventureShell", self)
	move_child(_shell, 0)
	_texture(load("res://assets/serpent/environment.png"), Rect2(Vector2.ZERO, LOGICAL_SIZE), "ForestEnvironment", _shell)

func _render_page() -> void:
	_clear_page()
	var layout_result:=SceneLayout.load_for(_definition(selected_level))
	if layout_result.ok:
		var background:=_shell.get_node_or_null("ForestEnvironment") as TextureRect
		if background!=null:background.texture=load(str(layout_result.data.background))
	if screen == "preparation": _build_preparation()
	else: _build_map()
	_build_header()

func _build_header() -> void:
	_button("BackButton", Rect2(24, 20, 116, 120), "", func(): back_requested.emit(), false, _page)
	var back := _icon("arrow", Rect2(53, 51, 58, 58), _page, INK)
	back.pivot_offset = Vector2(29, 29); back.rotation = PI
	var title_key := "ADVENTURE" if screen == "map" else "READY"
	if title_textures.get(title_key) is Texture2D:
		var title_art := _texture(title_textures[title_key], Rect2(150, 20, 470, 108), "PageTitleArt", _page)
		title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else: _label("ADVENTURE" if screen == "map" else "PREPARE", Rect2(150, 29, 470, 80), 43, "PageTitle", _page, CREAM, true)
	_panel("game/row", Rect2(650, 43, 244, 78), "PointBalanceFrame", _page, 24)
	_emblem("coin", Rect2(659, 49, 65, 65), _page)
	_label(str(int(economy.get("points", economy.get("balance", 0)))), Rect2(722, 47, 145, 66), 32, "PointBalance", _page)
	_button("SettingsButton", Rect2(790, 132, 116, 116), "", func(): settings_requested.emit(), false, _page)
	_emblem("settings", Rect2(821.5, 164.5, 53, 51), _page, INK)

func _build_map() -> void:
	_label("ADVENTURE TRAIL", Rect2(180, 139, 580, 56), 38, "RegionTitle", _page, CREAM, true)
	_scroll = ScrollContainer.new(); _scroll.name = "MapScroll"
	_scroll.position = Vector2(16, 226); _scroll.size = Vector2(908, 1174)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.follow_focus = true; _scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_page.add_child(_scroll)
	var canvas := Control.new(); canvas.name = "MapCanvas"
	# With only the real first level enabled, there is no long trail to scroll.
	# Keep its complete destination and scene preview in the initial safe viewport.
	var compact_first := _has_only_first_level()
	var height := _scroll.size.y if compact_first else maxf(1480.0, 370.0 + level_definitions.size() * 390.0)
	canvas.custom_minimum_size = Vector2(884, height); canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	_scroll.add_child(canvas)
	var centers: Array[Vector2] = []
	for i in level_definitions.size(): centers.append(Vector2(154, 600) if compact_first else Vector2(226 if i % 2 == 0 else 654, height - 230 - i * 390))
	var trail := MapTrail.new(); trail.name = "ConnectedTrail"; trail.size = canvas.custom_minimum_size; trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(centers.size() - 1):
		var from := centers[i]; var to := centers[i + 1]
		var curve := Curve2D.new()
		curve.add_point(from, Vector2.ZERO, Vector2(0, -150))
		curve.add_point(to, Vector2(0, 150), Vector2.ZERO)
		trail.points.append_array(curve.tessellate(4, 5))
	canvas.add_child(trail)
	for i in level_definitions.size():
		_map_node(level_definitions[i], centers[i], canvas, compact_first)
		if i==0 or str(level_definitions[i].get("region_id","forest"))!=str(level_definitions[i-1].get("region_id","forest")):
			var layout:=SceneLayout.load_for(level_definitions[i])
			if layout.ok:
				var region_bounds:=Rect2(24,738,260,100) if compact_first else Rect2(centers[i].x-195,centers[i].y+130,390,42)
				_label(str(layout.data.region_label),region_bounds,32 if compact_first else 25,"Region_%d"%i,canvas,CREAM,true)
	var complete := 0
	for config in level_definitions:
		if _is_completed(int(config.level_number)): complete += 1
	_label("%d / %d COMPLETE" % [complete, level_definitions.size()], Rect2(225, 38, 434, 53), 38, "CompletionProgress", canvas, INK, true)
	if level_definitions.is_empty(): _label("No levels available", Rect2(170, 510, 560, 80), 36, "EmptyCatalog", canvas)
	_button("ShopButton", Rect2(350, 1480, 240, 120), "", func():
		_capture_scroll(); shop_requested.emit(), true, _page)
	_emblem("shop", Rect2(425, 1495, 90, 90), _page)
	call_deferred("_restore_scroll", _scroll, _page_revision)

func _has_only_first_level() -> bool:
	return level_definitions.size()==1 and int(level_definitions[0].level_number)==1

func _restore_scroll(target: ScrollContainer, revision: int) -> void:
	# Container scrollbar limits are established by the layout pass, not _ready.
	# A page may be rebuilt several times in the same frame; ignore stale restores.
	if not is_inside_tree(): return
	await get_tree().process_frame
	if not is_inside_tree() or revision != _page_revision or not is_instance_valid(target) or target != _scroll or screen != "map": return
	if _has_only_first_level():
		# Legacy saved zero or large offsets cannot hide the only destination.
		map_scroll=0
	elif map_scroll < 0:
		var index := 0
		for i in level_definitions.size():
			if int(level_definitions[i].level_number) == selected_level: index = i
		var content_height: float = _scroll.get_child(0).custom_minimum_size.y
		map_scroll = maxi(0, int(content_height - 230 - index * 390 - _scroll.size.y * .62))
	_scroll.scroll_vertical = map_scroll
	map_scroll = _scroll.scroll_vertical
	_scroll_has_restored=true

func _map_node(config: Dictionary, center: Vector2, parent: Control, compact_first: bool=false) -> void:
	var number := int(config.level_number)
	var unlocked := _is_unlocked(number); var completed := _is_completed(number)
	var node := _group("LevelNode%d" % number, parent)
	node.position = center - Vector2(92, 92); node.size = Vector2(184, 184)
	node.set_meta("level_number", number); node.set_meta("state", "completed" if completed else ("playable" if unlocked else "locked"))
	var ring := _panel("game/primary" if unlocked else "game/secondary", Rect2(-5, 18, 194, 148), "LevelMedallion", node, 34)
	if not unlocked: ring.modulate = Color("b8b1a0")
	if number == selected_level:
		_icon("star", Rect2(65, -41, 54, 54), node, Color("ffcf48"))
	_label(str(number), Rect2(25, 26, 134, 96), 60, "LevelNumber", node, CREAM if unlocked else Color("7f7865"), true)
	_icon("check" if completed else ("play" if unlocked else "lock"), Rect2(72, 116, 40, 36), node, CREAM if unlocked else INK)
	var hit := _hit("ChooseLevel%d" % number, Rect2(0, 0, 184, 184), node)
	hit.tooltip_text = "Open level %d" % number if unlocked else "Complete level %d first" % (number - 1)
	hit.disabled = not unlocked
	hit.pressed.connect(func(): _choose_map_level(number))
	var left := center.x > 450
	var sign_x := center.x - 490 if left else center.x + 128
	var sign := _group("SceneSign%d" % number, parent)
	if compact_first:
		sign.position=Vector2(310,128);sign.size=Vector2(500,1016)
		_panel("game/panel",Rect2(Vector2.ZERO,sign.size),"CarvedSign",sign,40)
		_label(str(config.get("title","Level 1")),Rect2(24,20,452,110),38,"SceneTitle",sign)
		FirstPreview.build(config,Rect2(26,142,448,797),sign,"ScenePreview")
		_label("CLEARED" if completed else "READY",Rect2(28,944,444,48),38,"LevelState",sign,Color("347b28"))
		var preview_hit:=_hit("ChooseLevelPreview%d"%number,Rect2(Vector2.ZERO,sign.size),sign)
		preview_hit.disabled=not unlocked;preview_hit.tooltip_text=hit.tooltip_text
		preview_hit.pressed.connect(func(): _choose_map_level(number))
		return
	sign.position = Vector2(sign_x, center.y - 120)
	_panel("game/panel", Rect2(0, 0, 330, 239), "CarvedSign", sign, 30)
	_label(str(config.get("title", "Level %d" % number)), Rect2(22, 17, 286, 72), 23, "SceneTitle", sign)
	_mosaic(config, Rect2(81, 92, 168, 105), sign, false)
	_label("CLEARED" if completed else ("READY" if unlocked else "LOCKED"), Rect2(29, 197, 272, 29), 18, "LevelState", sign, Color("347b28") if unlocked else INK)

func _choose_map_level(number: int) -> void:
	if not _is_unlocked(number): return
	_capture_scroll();selected_level=number;choose_level.emit(number)

func _build_preparation() -> void:
	var config := _definition(selected_level)
	if config.is_empty():
		screen = "map"; _build_map(); return
	var scene_check:=SceneLayout.load_for(config)
	if not scene_check.ok:
		_label("SCENE UNAVAILABLE",Rect2(150,650,640,90),34,"SceneUnavailable",_page,CREAM,true)
		return
	var summary := level_summary(selected_level)
	_label("LEVEL %02d" % selected_level, Rect2(210, 151, 520, 58), 38, "LevelHeading", _page, CREAM, true)
	_panel("game/panel", Rect2(42, 280, 856, 700), "PreviewStoneFrame", _page, 40)
	if not _build_scene_preview(config, Rect2(65, 305, 503, 642), _page):
		_label("SCENE UNAVAILABLE",Rect2(130,500,680,90),34,"SceneUnavailable",_page,CREAM,true);return
	var preview:Control=_page.get_node("ScenePreview/ActualLevelScene/PreviewSerpent")
	preview.add_head_portrait(_page,Rect2(630,322,170,155))
	var metadata:Dictionary=preview.manifest
	var body_region:Array=metadata.body.region
	var normal_icon:=_atlas(preview.atlas,Rect2(body_region[0],body_region[1],body_region[2],body_region[3]),Rect2(629,526,74,74),"NormalSegmentIcon",_page)
	normal_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_label(str(summary.normal),Rect2(723,526,102,74),42,"NormalCount",_page)
	if int(summary.armored)>0:
		var armor:Dictionary=metadata.armor.intact;var region:Array=armor.region
		var armored_icon:=_atlas(load(str(armor.path)),Rect2(region[0],region[1],region[2],region[3]),Rect2(625,633,82,82),"ArmoredSegmentIcon",_page)
		armored_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_label(str(summary.armored),Rect2(723,637,102,74),42,"ArmoredCount",_page)
	_page.set_meta("level_summary",summary)
	var layout_result:=SceneLayout.load_for(config)
	var target:=_texture(SceneLayout.target_texture(layout_result.data),Rect2(619,746,110,104),"DefenseTargetIcon",_page)
	target.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon("shield",Rect2(735,772,53,58),_page,Color("ffe3a0"))
	var index := 0
	for color in summary.needs:
		if config.get("level_id","")=="serpent-01":
			# Twenty ordinary segments is already the prominent true total. Keep
			# the actual five-color palette, not five tiny repeated "4" labels.
			var color_icon:=_bead(str(color),Vector2(617+index*46,900),34,_page)
			color_icon.name="RequiredColor_%s"%color
			index+=1;continue
		var x := 601 + index * 84
		var y := 918
		if summary.needs.size()>4:
			x=601+(index%3)*84;y=866+(index/3)*52
		elif summary.needs.size()>3:
			x=631+(index%2)*126;y=866+(index/2)*52
		_bead(str(color), Vector2(x, y), 24, _page)
		_label(str(int(summary.needs[color])), Rect2(x + 27, y-4, 46, 31), 22, "Need_%s" % color, _page)
		index += 1
	var detail:=Control.new();detail.name="BossDetails";detail.position=Vector2(584,315);detail.size=Vector2(287,625)
	detail.tooltip_text="%d normal segments (1 hit each).\nProtect %s."%[summary.normal,summary.target]
	if summary.armored>0:detail.tooltip_text+="\n%d armored segments (2 hits each)."%summary.armored
	detail.mouse_filter=Control.MOUSE_FILTER_STOP;_page.add_child(detail)
	_ant_choice("worker", Rect2(50, 1000, 407, 367))
	_ant_choice("swift", Rect2(483, 1000, 407, 367))
	var carry_level := int(economy.get("carry_level", 1))
	_emblem("speed",Rect2(316,1385,36,36),_page,CREAM)
	_label("Lv.%d   +%d%%" % [carry_level,roundi((_multiplier(selected_type)-1.)*100.)], Rect2(366, 1377, 292, 56), 38, "LoadoutSummary", _page, CREAM, true)
	_button("BeginLevel", Rect2(190, 1444, 560, 127), "", _request_begin, true, _page)
	_icon("play", Rect2(428, 1465, 85, 85), _page)

func _build_scene_preview(config: Dictionary, bounds: Rect2, parent: Control) -> bool:
	if config.get("level_id","")=="serpent-01":
		return FirstPreview.build(config,bounds,parent)!=null
	var viewport := _group("ScenePreview", parent); viewport.position = bounds.position; viewport.size = bounds.size; viewport.clip_contents = true
	var scene := _group("ActualLevelScene", viewport)
	var factor := bounds.size.x / 940.0; scene.scale = Vector2.ONE * factor
	var layout_result:=SceneLayout.load_for(config)
	if not layout_result.ok:return false
	var layout:Dictionary=layout_result.data
	_texture(load(str(layout.background)), Rect2(Vector2.ZERO, LOGICAL_SIZE), "Forest", scene)
	var serpent := Serpent.new(); serpent.name = "PreviewSerpent"; scene.add_child(serpent)
	var serpent_config: Dictionary = config.get("serpent", {})
	if serpent_config.has("goal_s") and serpent.configure(serpent_config, SceneLayout.knots(layout)):
		var ids: Array = []; var positions: Dictionary = {}
		var segments: Array = config.get("segments", []).duplicate(true)
		for i in segments.size():
			var id := str(segments[i].get("id", "preview-%d" % i))
			segments[i]["id"] = id; ids.append(id)
			positions[id] = float(serpent_config.head_start_s) - float(i + 1) * float(serpent_config.pitch)
		serpent.sync_snapshot({"paused": true, "speed_multiplier": 1, "status": "ready", "head_s": float(serpent_config.head_start_s), "alive_segment_ids": ids, "segments": segments, "segment_s": positions})
		# Guardian is an independent asset from the same level scene contract.
		SceneLayout.add_target(scene,layout)
	_mosaic(config, Rect2(), scene, true)
	SceneLayout.add_nest(scene,layout)
	_atlas(load("res://assets/characters-atlas.png"), Rect2(48, 654, 412, 337), SceneLayout.rect(layout.cannon.rect), "PreviewCannon", scene)
	var foot:=SceneLayout.point(layout.nest.position)
	_carrier(foot+Vector2(-95,4), 66, "blue", "PreviewWorker", scene)
	_carrier(foot+Vector2(95,4), 66, "green", "PreviewWorker2", scene)
	return true

func _mosaic(config: Dictionary, bounds: Rect2, parent: Control, actual: bool) -> void:
	var grid: Array = config.get("grid", []); var palette: Dictionary = config.get("palette", {})
	var width := maxi(1, int(config.get("width", 1))); var height := maxi(1, int(config.get("height", grid.size())))
	var layout_result:=SceneLayout.load_for(config)
	var plane := BoardPlane.new(width, height,layout_result.get("data",{}),config.get("transport",{}).get("entrance_cell",[]))
	var edge := minf(bounds.size.x / width, bounds.size.y / height) if not actual else 0.0
	var min_y := height; var max_y := 0; var min_x := width; var max_x := 0
	if not actual:
		for y in grid.size():
			for x in str(grid[y]).length():
				if palette.has(str(grid[y])[x]): min_y = mini(min_y, y); max_y = maxi(max_y, y); min_x = mini(min_x, x); max_x = maxi(max_x, x)
		edge = minf(bounds.size.x / maxi(1, max_x - min_x + 1), bounds.size.y / maxi(1, max_y - min_y + 1))
	for y in grid.size():
		var row := str(grid[y])
		for x in row.length():
			if not palette.has(row[x]): continue
			var bead: Control
			if actual:
				var span: Vector2 = plane.footprint(x, y) * .98
				bead = _bead(str(palette[row[x]]), plane.center(x, y) - Vector2(span.x * .5, span.y * .57), span.x, parent)
				bead.footprint_height = span.y * 1.07; bead.size.y = span.y * 1.07
			else:
				var origin := bounds.position + (bounds.size - Vector2(max_x - min_x + 1, max_y - min_y + 1) * edge) * .5
				bead = _bead(str(palette[row[x]]), origin + Vector2(x - min_x, y - min_y) * edge, edge * .94, parent)
			bead.name = "Mosaic_%d_%d" % [x, y]; bead.set_meta("cell", Vector2i(x, y)); bead.set_meta("color_id", palette[row[x]])

func _ant_choice(carrier_type: String, bounds: Rect2) -> void:
	var owned := _owned(carrier_type); var selected := selected_type == carrier_type and owned
	var card := _group("AntChoice_" + carrier_type, _page); card.position = bounds.position; card.size = bounds.size
	_panel("game/panel", Rect2(Vector2.ZERO, bounds.size), "StonePlinth", card, 30)
	var name_art:=_texture(load("res://assets/meta-ui/"+carrier_type+".png"),Rect2(60,10,287,65),"TypeName",card);name_art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_carrier(Vector2(101, 192), 123, "blue", "AntPortrait", card)
	if carrier_type == "swift": _emblem("speed", Rect2(337, 79, 46, 49), card)
	_bead("blue",Vector2(213,111),34,card)
	_label("1", Rect2(252,103,127,52), 38, "Capacity", card)
	_emblem("speed",Rect2(213,164,31,35),card,Color("b77c24"))
	_label("+%d%%" % roundi((_multiplier(carrier_type)-1.)*100.), Rect2(252,156,127,52), 38, "MovementSpeed", card)
	card.set_meta("owned",owned)
	var caption := ""
	_button("Equip_" + carrier_type, Rect2(28, 222, 351, 120), caption, func():
		if not _owned(carrier_type): shop_requested.emit(); return
		selected_type = carrier_type; _begin_pending = false; _render_page(), selected, card, 23)
	_icon("check" if selected else ("arrow" if owned else "lock"), Rect2(181, 261.5, 45, 41), card, CREAM if selected else INK)

func _request_begin() -> void:
	if _begin_pending or not _is_unlocked(selected_level) or not _owned(selected_type): return
	_begin_pending = true
	var button := _page.get_node_or_null("BeginLevel") as Button
	if button != null: button.disabled = true
	begin_level.emit(selected_level, selected_type)

func _group(id: String, parent: Node) -> Control:
	var node := Control.new(); node.name = id; node.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(node); return node

func _label(value: String, bounds: Rect2, px: int, id: String, parent: Node, color: Color = INK, outline: bool = false) -> Label:
	var label := Label.new(); label.name = id; label.text = value; label.position = bounds.position; label.size = bounds.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", font); label.add_theme_font_size_override("font_size", px); label.add_theme_color_override("font_color", color)
	if outline:
		label.add_theme_color_override("font_outline_color", Color("623918") if color == CREAM else CREAM); label.add_theme_constant_override("outline_size", 5 if color == CREAM else 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(label); return label

func _panel(key: String, bounds: Rect2, id: String, parent: Node, corner: float) -> Panel:
	return skin.panel(key, bounds, parent, id, corner)

func _button(id: String, bounds: Rect2, caption: String, callback: Callable, primary: bool, parent: Node, px: int = 32) -> Button:
	_panel("game/primary" if primary else "game/secondary", bounds, id + "Art", parent, minf(bounds.size.y * .40, 46.0))
	if not caption.is_empty(): _label(caption, Rect2(bounds.position + Vector2(48, 0), bounds.size - Vector2(64, 0)), px, id + "Label", parent, CREAM if primary else INK, primary)
	var button := _hit(id, bounds, parent); button.pressed.connect(callback); return button

func _hit(id: String, bounds: Rect2, parent: Node) -> Button:
	var button := Button.new(); button.name = id; button.position = bounds.position; button.size = bounds.size; button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled"]: button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var focus := StyleBoxFlat.new(); focus.bg_color = Color(0, 0, 0, 0); focus.border_color = Color("fff0b3"); focus.set_border_width_all(3); focus.set_corner_radius_all(18)
	button.add_theme_stylebox_override("focus", focus)
	parent.add_child(button); return button

func _icon(kind: String, bounds: Rect2, parent: Node, color: Color = CREAM) -> Control:
	var icon := Icon.new(); icon.kind = kind; icon.position = bounds.position; icon.size = bounds.size; icon.ink = color; parent.add_child(icon); return icon

func _emblem(kind: String, bounds: Rect2, parent: Node, color: Color = CREAM) -> Control:
	var emblem := Emblem.new(); emblem.kind = kind; emblem.position = bounds.position; emblem.size = bounds.size; emblem.ink = color; parent.add_child(emblem); return emblem

func _texture(texture: Texture2D, bounds: Rect2, id: String, parent: Node) -> TextureRect:
	return UiSkin.place_texture(texture,bounds,parent,id)

func _atlas(texture: Texture2D, region: Rect2, bounds: Rect2, id: String, parent: Node) -> TextureRect:
	var atlas := AtlasTexture.new(); atlas.atlas = texture; atlas.region = region; atlas.filter_clip = true
	return _texture(atlas, bounds, id, parent)

func _bead(color: String, at: Vector2, edge: float, parent: Node) -> Control:
	var bead := ApprovedBall.new(); bead.color_id = color; bead.edge = edge; bead.footprint_height=edge; bead.position = at; bead.size = Vector2(edge, edge); parent.add_child(bead); return bead

func _carrier(foot: Vector2, diameter: float, color: String, id: String, parent: Node) -> Control:
	var actor := _group(id, parent); actor.position = foot
	var sprite := TextureRect.new(); sprite.name = "Ant"; sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE; actor.add_child(sprite)
	Carrier.prepare(actor, color, diameter)
	Carrier.apply(actor, {"time": 0.0, "moving": false, "direction": Vector2(1, 1), "stage": "outbound", "color_id": color, "diameter": diameter})
	return actor
