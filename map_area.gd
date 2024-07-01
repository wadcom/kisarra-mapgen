extends ColorRect

const PIXELS_PER_CELL_SIDE = 10

func update_parameters(params):
	custom_minimum_size = Vector2.ONE * PIXELS_PER_CELL_SIDE * params.map_size
