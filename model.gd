extends Node

signal surface_updated

var _bt_density
var _height_map
var _params
var _satellite_bt_sources_positions
var _surface

enum SurfaceType { MOUNTAINS, SAND }


func set_betirium_density(bt_density):
	_bt_density = bt_density

	if _params != null and bt_density.size() != _params.map_size:
		_params = null


func set_params(params):
	_params = params


func set_satellite_bt_sources_positions(satellite_bt_sources_positions):
	_satellite_bt_sources_positions = satellite_bt_sources_positions


func setup_surface(params, height_map):
	_height_map = height_map
	_params = params

	if _bt_density != null and _bt_density.size() != params.map_size:
		_bt_density = null

	_surface = make_surface(params, height_map)

	surface_updated.emit()


func get_betirium_density():
	return _bt_density


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
