extends Node

signal surface_updated

var _bt_density
var _height_map
var _params
var _satellite_bt_sources_positions
var _surface

enum SurfaceType { MOUNTAINS, SAND }

const _perlin_noise = preload("res://perlin_noise.gd")


func get_satellite_bt_sources():
	return _make_satellite_bt_sources()


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


# TODO: unexport
func make_height_map(params):
	var octaves = []

	var total_weight = 0.0

	for o_params in params.mountains.octaves:
		if o_params.enabled:
			octaves.append(_perlin_noise.make_octave(o_params.size))
			total_weight += o_params.weight
		else:
			octaves.append(null)

	var height = []
	for y in params.map_size:
		for x in params.map_size:
			var p = Vector2(x + 0.5, y + 0.5)

			var h = 0.0
			for i in octaves.size():
				if octaves[i] == null:
					continue

				var o_h = _perlin_noise.get_height(octaves[i], params.map_size, p)
				h += o_h * params.mountains.octaves[i].weight / total_weight

			height.append(h)

	return height


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


func _make_satellite_bt_sources():
	var bt_sources = []
	for p in _satellite_bt_sources_positions:
		bt_sources.append(
			{
				decay_factor = _params.betirium.satellite_sources.decay,
				position = p,
				peak_density = _params.betirium.satellite_sources.peak_density,
			},
		)

	return bt_sources


func _is_mountain(params, height_map, p: Vector2i):
	var idx = p.y * params.map_size + p.x
	return height_map[idx] > params.mountains.height_threshold
