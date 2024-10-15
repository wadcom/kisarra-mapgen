extends Node

signal surface_updated

var _height_map
var _params
var _surface

enum SurfaceType { MOUNTAINS, SAND }


func setup_surface(params, height_map):
	_height_map = height_map
	_params = params
	_surface = make_surface(params, height_map)
	surface_updated.emit()


func get_height_map():
	return _height_map


func get_params():
	return _params.duplicate(true)


func get_surface():
	return _surface


func _is_mountain(params, height_map, p: Vector2i):
	var idx = p.y * params.map_size + p.x
	return height_map[idx] > params.mountains.height_threshold


func make_surface(params, height_map):
	var surface = Array()
	surface.resize(params.map_size)

	for x in params.map_size:
		surface[x] = Array()
		surface[x].resize(params.map_size)

		for y in params.map_size:
			var cell = {}
			if _is_mountain(params, height_map, Vector2i(x, y)):
				cell = { type = SurfaceType.MOUNTAINS }
			else:
				cell = { type = SurfaceType.SAND }

			surface[x][y] = cell

	return surface
