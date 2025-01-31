extends Node

signal surface_updated

var _base_positions
var _bt_density
var _height_map
var _params
var _prev_params
var _satellite_bt_sources_positions
var _surface

enum SurfaceType { MOUNTAINS, SAND }

const _globals = preload("res://globals.gd")
const _perlin_noise = preload("res://perlin_noise.gd")


func get_satellite_bt_sources():
	return _make_satellite_bt_sources()


func set_betirium_density(bt_density):
	_bt_density = bt_density

	if _params != null and bt_density.size() != _params.map_size:
		_params = null


func set_params(params):
	if _should_invalidate_satellite_bt_sources_positions(params):
		_satellite_bt_sources_positions = null

	if _params == null:
		_prev_params = null
	else:
		_prev_params = _params.duplicate(true)

	_params = params

	var warnings = []
	
	if _satellite_bt_sources_positions == null:
		var result = _pick_satellite_bt_sources_positions()
		_satellite_bt_sources_positions = result.positions
		warnings.append_array(result.warnings)

	return {warnings = warnings}


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
				radius = _globals.CELL_SIDE_KMS / 2.0,
			},
		)

	return bt_sources


func _is_mountain(params, height_map, p: Vector2i):
	var idx = p.y * params.map_size + p.x
	return height_map[idx] > params.mountains.height_threshold


func pick_base_positions(params, height_map):
	var map_center = Vector2.ONE * params.map_size / 2.0

	var available = []
	var warnings = []

	for x in params.map_size:
		for y in params.map_size:
			var p = Vector2(x + 0.5, y + 0.5)

			var d = p.distance_to(map_center) * _globals.CELL_SIDE_KMS
			if d < params.base_placement.central_dead_zone_radius:
				continue

			var off_edge = [
				Vector2(p.x, -0.5),
				Vector2(p.x, params.map_size+0.5),
				Vector2(-0.5, p.y),
				Vector2(params.map_size+0.5, p.y),
			]

			var is_too_close = off_edge.any(
				func(off_edge_pos):
					d = p.distance_to(off_edge_pos) * _globals.CELL_SIDE_KMS
					return d < params.base_placement.min_dist_to_map_edge
			)

			if is_too_close:
				continue

			if _is_mountain(params, height_map, Vector2i(p)):
				continue

			available.append(Vector2(x, y))

	available.shuffle()

	var base_positions = []
	for i in params.players_qty:
		if available.size() == 0:
			warnings.append("No cells available to place a base\n")
			break

		var p = available.pop_back()

		base_positions.append(p)

		available = available.filter(
			func(a): 
				var d = a.distance_to(p) * _globals.CELL_SIDE_KMS
				return d > params.base_placement.min_dist_to_other_bases
		)

	return {positions = base_positions, warnings = warnings}


func set_base_positions(base_positions):
	_base_positions = base_positions
	_satellite_bt_sources_positions = null


func get_base_positions():
	return _base_positions


func _pick_satellite_bt_sources_positions():
	var satellite_bt_radius = \
		_params.betirium.satellite_sources.distance_to_base / _globals.CELL_SIDE_KMS

	var positions = []
	var warnings = []

	for base_pos in _base_positions:
		var available_positions = {}

		for a in 360:
			var p = (
				Vector2.from_angle(a / 360.0 * TAU) * satellite_bt_radius \
					+ base_pos + Vector2.ONE / 2.0
			).floor()

			if p.x < 0 or p.y < 0 or p.x >= _params.map_size or p.y >= _params.map_size:
				continue

			available_positions[p] = true

		if available_positions.size() < 1:
			warnings.append(
				"Nowhere to put satellite Bt source around base at %d,%d\n" % [
					base_pos.x, base_pos.y
				]
			)
			continue

		positions.append(_pick_random_key(available_positions))

	return {positions = positions, warnings = warnings}


func _pick_random_key(dict):
	var keys = dict.keys()
	keys.shuffle()
	return keys[0]


func _should_invalidate_satellite_bt_sources_positions(new_params):
	if _prev_params == null:
		return true

	if _prev_params.map_size != new_params.map_size:
		return true

	if _prev_params.betirium.satellite_sources.distance_to_base != \
		new_params.betirium.satellite_sources.distance_to_base:
		return true

	return false
