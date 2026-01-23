extends Control

const EditorV2Constants = preload("res://editor_v2/constants.gd")
const EditorDocument = preload("res://editor_v2/document.gd")
const MountainsLayer = preload("res://editor_v2/layers/mountains.gd")

var _document: EditorDocument


func set_document(doc: EditorDocument) -> void:
	assert(_document == null, "Document already set")
	assert(doc != null, "Document cannot be null")
	_document = doc
	_document.changed.connect(_on_document_changed)
	_document.mountains.changed.connect(_on_mountains_changed)
	_update_size()
	queue_redraw()


func _ready():
	_update_size()


func _draw():
	if not _document:
		return

	var cell_size := EditorV2Constants.CELL_SIZE_PX
	var total_size := _document.size * cell_size

	# Draw terrain cells if mountains layer has data, otherwise draw background
	if _document.mountains.has_terrain():
		_draw_terrain(cell_size)
	else:
		draw_rect(
			Rect2(Vector2.ZERO, Vector2(total_size, total_size)),
			EditorV2Constants.GRID_BACKGROUND_COLOR
		)

	# Draw vertical grid lines (on top of terrain)
	for x in range(_document.size + 1):
		var x_pos := x * cell_size
		draw_line(
			Vector2(x_pos, 0),
			Vector2(x_pos, total_size),
			EditorV2Constants.GRID_LINE_COLOR
		)

	# Draw horizontal grid lines (on top of terrain)
	for y in range(_document.size + 1):
		var y_pos := y * cell_size
		draw_line(
			Vector2(0, y_pos),
			Vector2(total_size, y_pos),
			EditorV2Constants.GRID_LINE_COLOR
		)


func _draw_terrain(cell_size: int) -> void:
	for x in _document.size:
		for y in _document.size:
			var terrain_type := _document.mountains.get_terrain_at(x, y)
			var color: Color
			if terrain_type == MountainsLayer.TerrainType.MOUNTAIN:
				color = EditorV2Constants.TERRAIN_COLOR_MOUNTAIN
			else:
				color = EditorV2Constants.TERRAIN_COLOR_SAND

			var rect := Rect2(
				Vector2(x * cell_size, y * cell_size),
				Vector2(cell_size, cell_size)
			)
			draw_rect(rect, color)


func _update_size():
	if not _document:
		custom_minimum_size = Vector2.ZERO
		return

	var total := _document.size * EditorV2Constants.CELL_SIZE_PX
	custom_minimum_size = Vector2(total, total)


func _on_document_changed():
	_update_size()
	queue_redraw()


func _on_mountains_changed():
	queue_redraw()
