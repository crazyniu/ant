extends Control
## Orthographic authoring surface. Uses the current production bead atlas.
signal cell_action(x: int, y: int, erase: bool)
const Bead = preload("res://scripts/bead.gd")
var document
var show_exposure := true
var preview_mode := false
var textures: Dictionary = {}
var _last_cell := Vector2i(-1, -1)
var _dragging := false
var _erase := false
var exposure: Array = []
var _revision := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(520, 480)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var regions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/fusion/bead-regions.json"))
	var atlas = load("res://assets/ui/fusion/beads.png")
	for color in regions:
		var rect: Array = regions[color]
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(rect[0], rect[1], rect[2], rect[3])
		texture.filter_clip = true
		textures[color] = texture

func refresh() -> void:
	if document != null:
		if preview_mode and document.preview != null:
			exposure = document.preview.reachable_cell_ids()
		elif _revision != document.revision:
			exposure = document.exposed_cells()
			_revision = document.revision
	queue_redraw()

func board_rect() -> Rect2:
	if document == null:
		return Rect2()
	var cell := minf((size.x - 40) / float(document.config.width), (size.y - 40) / float(document.config.height))
	var extent := Vector2(document.config.width, document.config.height) * cell
	return Rect2((size - extent) / 2, extent)

func cell_from_point(point: Vector2) -> Vector2i:
	var rect := board_rect()
	if not rect.has_point(point):
		return Vector2i(-1, -1)
	var cell: float = rect.size.x / float(document.config.width)
	return Vector2i(floori((point.x - rect.position.x) / cell), floori((point.y - rect.position.y) / cell))

func _gui_input(event: InputEvent) -> void:
	if document == null or preview_mode:
		return
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		_dragging = event.pressed
		_erase = event.button_index == MOUSE_BUTTON_RIGHT
		_last_cell = Vector2i(-1, -1)
		if event.pressed:
			_emit_cell(event.position)
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_emit_cell(event.position)
		accept_event()

func _emit_cell(point: Vector2) -> void:
	var cell := cell_from_point(point)
	if cell.x >= 0 and cell != _last_cell:
		_last_cell = cell
		cell_action.emit(cell.x, cell.y, _erase)

func _draw() -> void:
	draw_style_box(_panel(), Rect2(Vector2.ZERO, size))
	if document == null:
		return
	var rect := board_rect()
	var cell: float = rect.size.x / float(document.config.width)
	var board: Dictionary = {}
	var sim = document.preview if preview_mode else null
	if sim != null:
		board = sim.board
	for y in range(int(document.config.height)):
		for x in range(int(document.config.width)):
			var tile := Rect2(rect.position + Vector2(x, y) * cell, Vector2.ONE * cell)
			var id: int = y * int(document.config.width) + x
			draw_rect(tile.grow(-0.8), Color("e5d7b6"))
			var color := ""
			if sim != null:
				if board.has(id):
					color = str(board[id].color)
			else:
				var symbol: String = document.config.grid[y].substr(x, 1)
				color = str(document.config.palette.get(symbol, ""))
			if textures.has(color):
				draw_texture_rect(textures[color], tile, false)
			if show_exposure and id in exposure:
				draw_rect(tile.grow(-2.0), Color("31a497"), false, 2.2)
			if sim != null and sim.reservations.has(id):
				draw_circle(tile.get_center(), maxf(2, cell * 0.10), Color("172d45"))
	if sim != null:
		for task in sim.tasks.values():
			var points := PackedVector2Array()
			for point in task.path:
				points.append(rect.position + (Vector2(point[0], point[1]) + Vector2.ONE * 0.5) * cell)
			if points.size() > 1:
				draw_polyline(points, Color(0.13, 0.25, 0.32, 0.17), 1.0)

func _panel() -> StyleBoxFlat:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("f4ead1")
	panel.border_color = Color("b79955")
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(12)
	return panel
