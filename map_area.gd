extends ColorRect

@export var base_cell_prefab: PackedScene
@export var sand_cell_prefab: PackedScene


const _globals = preload("res://globals.gd")


func update_parameters(params):
	custom_minimum_size = Vector2.ONE * _globals.PIXELS_PER_CELL_SIDE * params.map_size

	_setup_ground_cells(params)
	_setup_bases(params)



func _setup_ground_cells(params):
	for c in $GroundCells.get_children():
		$GroundCells.remove_child(c)
		c.queue_free()

	for x in params.map_size:
		for y in params.map_size:
			var cell = sand_cell_prefab.instantiate()

			cell.position = Vector2(x, y) * _globals.PIXELS_PER_CELL_SIDE
			$GroundCells.add_child(cell)


func _setup_bases(params):
	for b in $Bases.get_children():
		$Bases.remove_child(b)
		b.queue_free()

	var available = []
	for x in params.map_size:
		for y in params.map_size:
			available.append(Vector2(x, y))

	available.shuffle()

	for i in params.players_qty:
		var p = available.pop_back()

		var base = base_cell_prefab.instantiate()
		base.position = p * _globals.PIXELS_PER_CELL_SIDE
		$Bases.add_child(base)

		available = available.filter(
			func(a): 
				var d = a.distance_to(p) * _globals.CELL_SIDE_KMS
				return d > params.base_placement.min_dist_to_other_bases
		)

