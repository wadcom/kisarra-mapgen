extends ColorRect

@export var base_cell_prefab: PackedScene
@export var sand_cell_prefab: PackedScene


const _globals = preload("res://globals.gd")


func update_parameters(params):
	custom_minimum_size = Vector2.ONE * _globals.PIXELS_PER_CELL_SIDE * params.map_size

	for c in $Cells.get_children():
		$Cells.remove_child(c)
		c.queue_free()

	for x in params.map_size:
		for y in params.map_size:
			var cell = sand_cell_prefab.instantiate()

			cell.position = Vector2(x, y) * _globals.PIXELS_PER_CELL_SIDE
			$Cells.add_child(cell)

	for i in params.players_qty:
		var base = base_cell_prefab.instantiate()
		base.position = Vector2(i, 0) * _globals.PIXELS_PER_CELL_SIDE
		$Bases.add_child(base)
