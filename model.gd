extends Node

var _surface

enum SurfaceType { MOUNTAINS, SAND }


func setup_surface(params, height_map):
	_surface = Array()
	_surface.resize(params.map_size)

	for x in params.map_size:
		_surface[x] = Array()
		_surface[x].resize(params.map_size)

		for y in params.map_size:
			var cell = {}
			if _is_mountain(params, height_map, Vector2i(x, y)):
				cell = { type = SurfaceType.MOUNTAINS }
			else:
				cell = { type = SurfaceType.SAND }

			_surface[x][y] = cell


func _is_mountain(params, height_map, p: Vector2i):
	var idx = p.y * params.map_size + p.x
	return height_map[idx] > params.mountains.height_threshold
