extends Control

const EditorV2Constants = preload("res://editor/constants.gd")
const EditorDocument = preload("res://editor/document.gd")
const MountainsLayer = preload("res://editor/layers/mountains.gd")

var _document: EditorDocument
var _show_base_constraints := false


func set_document(doc: EditorDocument) -> void:
	assert(_document == null, "Document already set")
	assert(doc != null, "Document cannot be null")
	_document = doc
	_document.changed.connect(_on_document_changed)
	_document.mountains.changed.connect(queue_redraw)
	_document.bases.changed.connect(queue_redraw)
	_document.betirium_density.changed.connect(queue_redraw)
	_document.betirium_sources.changed.connect(queue_redraw)
	_update_size()
	queue_redraw()


func _ready():
	_update_size()


func set_show_base_constraints(value: bool) -> void:
	_show_base_constraints = value
	queue_redraw()


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

	# Draw constraint visualizations (on top of terrain, under bases)
	if _show_base_constraints:
		_draw_edge_buffer(cell_size, total_size)
		_draw_dead_zone(cell_size)

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

	if _show_base_constraints:
		_draw_inter_base_circles(cell_size)

	_draw_home_deposit_sources(cell_size)
	_draw_extra_sources(cell_size)
	_draw_bases(cell_size)


func _draw_terrain(cell_size: int) -> void:
	for x in _document.size:
		for y in _document.size:
			var terrain_type := _document.mountains.get_terrain_at(x, y)
			var color: Color
			if terrain_type == MountainsLayer.TerrainType.MOUNTAIN:
				color = EditorV2Constants.TERRAIN_COLOR_MOUNTAIN
			else:
				# Sand cells: lerp toward betirium color based on density
				var density := _document.betirium_density.get_density_at(x, y)
				var lerp_factor := density / 100.0
				color = EditorV2Constants.TERRAIN_COLOR_SAND.lerp(
					EditorV2Constants.BETIRIUM_DENSITY_COLOR, lerp_factor,
				)

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


## Draws the edge buffer border showing the exclusion zone around map edges.
func _draw_edge_buffer(cell_size: int, total_size: int) -> void:
	var params := _document.bases.get_constraint_params(_document.size)
	var edge_buffer_px: float = params.edge_buffer * cell_size
	var color := EditorV2Constants.CONSTRAINT_EDGE_BUFFER_COLOR

	# Top edge
	draw_rect(Rect2(0, 0, total_size, edge_buffer_px), color)
	# Bottom edge
	draw_rect(Rect2(0, total_size - edge_buffer_px, total_size, edge_buffer_px), color)
	# Left edge (excluding corners already covered)
	draw_rect(Rect2(0, edge_buffer_px, edge_buffer_px, total_size - 2 * edge_buffer_px), color)
	# Right edge (excluding corners already covered)
	draw_rect(
		Rect2(
			total_size - edge_buffer_px, 
			edge_buffer_px, 
			edge_buffer_px, 
			total_size - 2 * edge_buffer_px,
		), 
		color,
	)


## Draws the dead zone circle at map center.
func _draw_dead_zone(cell_size: int) -> void:
	var params := _document.bases.get_constraint_params(_document.size)
	var dead_zone_px: float = params.dead_zone_radius * cell_size
	var center := Vector2(_document.size / 2.0, _document.size / 2.0) * cell_size
	draw_circle(center, dead_zone_px, EditorV2Constants.CONSTRAINT_DEAD_ZONE_COLOR)


## Draws inter-base distance circles around each base.
func _draw_inter_base_circles(cell_size: int) -> void:
	var params := _document.bases.get_constraint_params(_document.size)
	var inter_base_px: float = params.inter_base_radius * cell_size

	for pos in _document.bases.get_positions():
		var center := Vector2(pos.x + 0.5, pos.y + 0.5) * cell_size
		draw_circle(center, inter_base_px, EditorV2Constants.CONSTRAINT_INTER_BASE_COLOR)


## Draws home deposit source markers as small diamonds.
func _draw_home_deposit_sources(cell_size: int) -> void:
	for pos in _document.betirium_sources.get_home_deposit_positions():
		var center := Vector2(pos.x + 0.5, pos.y + 0.5) * cell_size
		var half_size := (cell_size - 2) / 2.0
		# Draw diamond shape (rotated square)
		var points := PackedVector2Array([
			center + Vector2(0, -half_size),  # Top
			center + Vector2(half_size, 0),   # Right
			center + Vector2(0, half_size),   # Bottom
			center + Vector2(-half_size, 0),  # Left
		])
		draw_colored_polygon(points, EditorV2Constants.BETIRIUM_HOME_DEPOSIT_COLOR)


## Draws extra source markers as larger diamonds (richer than home deposits).
func _draw_extra_sources(cell_size: int) -> void:
	for pos in _document.betirium_sources.get_extra_positions():
		var center := Vector2(pos.x + 0.5, pos.y + 0.5) * cell_size
		# Larger diamond for extras (extends beyond cell)
		var half_size := cell_size / 2.0 + 1
		var points := PackedVector2Array([
			center + Vector2(0, -half_size),  # Top
			center + Vector2(half_size, 0),   # Right
			center + Vector2(0, half_size),   # Bottom
			center + Vector2(-half_size, 0),  # Left
		])
		draw_colored_polygon(points, EditorV2Constants.BETIRIUM_EXTRA_COLOR)


## Draws base markers as blue rectangles.
func _draw_bases(cell_size: int) -> void:
	for pos in _document.bases.get_positions():
		# Draw rectangle slightly smaller than cell (cell size minus 1 pixel on each side)
		var rect := Rect2(
			Vector2(pos.x * cell_size + 1, pos.y * cell_size + 1),
			Vector2(cell_size - 2, cell_size - 2)
		)
		draw_rect(rect, EditorV2Constants.BASE_COLOR)
