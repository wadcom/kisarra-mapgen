extends Control

const EditorV2Constants = preload("res://editor_v2/constants.gd")
const EditorDocument = preload("res://editor_v2/document.gd")

## The document to visualize. Must be set before the view can render.
var document: EditorDocument:
	set(value):
		# Disconnect from old document if any
		if document:
			document.dimensions.changed.disconnect(_on_dimensions_changed)

		document = value

		# Connect to new document
		if document:
			document.dimensions.changed.connect(_on_dimensions_changed)
			_update_size()
			queue_redraw()


func _ready():
	_update_size()


func _draw():
	if not document:
		return

	var cell_size := EditorV2Constants.CELL_SIZE_PX
	var grid_size := document.dimensions.size
	var total_size := grid_size * cell_size

	# Draw background
	draw_rect(
		Rect2(Vector2.ZERO, Vector2(total_size, total_size)),
		EditorV2Constants.GRID_BACKGROUND_COLOR
	)

	# Draw vertical grid lines
	for x in range(grid_size + 1):
		var x_pos := x * cell_size
		draw_line(
			Vector2(x_pos, 0),
			Vector2(x_pos, total_size),
			EditorV2Constants.GRID_LINE_COLOR
		)

	# Draw horizontal grid lines
	for y in range(grid_size + 1):
		var y_pos := y * cell_size
		draw_line(
			Vector2(0, y_pos),
			Vector2(total_size, y_pos),
			EditorV2Constants.GRID_LINE_COLOR
		)


func _update_size():
	if not document:
		custom_minimum_size = Vector2.ZERO
		return

	var total := document.dimensions.size * EditorV2Constants.CELL_SIZE_PX
	custom_minimum_size = Vector2(total, total)


func _on_dimensions_changed():
	_update_size()
	queue_redraw()
