extends Node

signal surface_updated

var _base_positions
var _bt_density
var _bt_sources
var _height_map
var _locked_extra_bt_sources = {}
var _params
var _prev_params
var _satellite_bt_sources_positions
var _surface

enum SurfaceType { MOUNTAINS, SAND }
enum BTSourceType { SATELLITE, EXTRA }

const _globals = preload("res://globals.gd")
const _perlin_noise = preload("res://perlin_noise.gd")

const SATELLITE_BT_SOURCE_RADIUS = _globals.CELL_SIDE_KMS / 2.0


func _set_betirium_density(bt_density):
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

	var _bt_sources_warnings = _make_bt_sources()
	warnings.append_array(_bt_sources_warnings)

	var bt_density = _calculate_bt_density()
	_set_betirium_density(bt_density)

	setup_surface(_params)

	return warnings


func setup_surface(params):
	_params = params

	if _bt_density != null and _bt_density.size() != params.map_size:
		_bt_density = null

	_surface = make_surface(params)

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

	_height_map = height


func make_surface(params):
	var surface = Array()
	surface.resize(params.map_size)

	for x in params.map_size:
		surface[x] = Array()
		surface[x].resize(params.map_size)

		for y in params.map_size:
			var cell = {}
			if _is_mountain(params, Vector2i(x, y)):
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
				radius = SATELLITE_BT_SOURCE_RADIUS,
				type = BTSourceType.SATELLITE,
			},
		)

	return bt_sources


func _is_mountain(params, p: Vector2i):
	var idx = p.y * params.map_size + p.x
	return _height_map[idx] > params.mountains.height_threshold


func pick_base_positions(params):
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

			if _is_mountain(params, Vector2i(p)):
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


func calculate_bt_stats():
	var bt_density = get_betirium_density()
	var surface = get_surface()

	assert(bt_density.size() == surface.size())

	var cells = 0
	var total = 0

	for x in bt_density.size():
		for y in bt_density[x].size():
			cells += 1

			if surface[x][y].type == SurfaceType.SAND:
				total += bt_density[x][y]

	return {total = total, per_cell = total / cells}


func _pick_satellite_bt_sources_positions():
	var satellite_bt_radius = \
		_params.betirium.satellite_sources.distance_to_base / _globals.CELL_SIDE_KMS

	var positions = []
	var warnings = []

	for base_pos in _base_positions:
		var available_positions = {}

		for a in 360:
			var p = Vector2i(
				(Vector2.from_angle(a / 360.0 * TAU) * satellite_bt_radius \
					+ base_pos + Vector2.ONE / 2.0
			).floor())

			if not _is_good_satellite_bt_source_position(p):
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


func _is_good_satellite_bt_source_position(potential_pos: Vector2i):
	if _is_outside_map(potential_pos):
		return false

	var vicinity_radius = 1 + SATELLITE_BT_SOURCE_RADIUS / _globals.CELL_SIDE_KMS

	var min_x = potential_pos.x - int(vicinity_radius)
	var max_x = potential_pos.x + int(vicinity_radius)
	var min_y = potential_pos.y - int(vicinity_radius)
	var max_y = potential_pos.y + int(vicinity_radius)

	# If any part of vicinity is outside map, position is not good
	if min_x < 0 or min_y < 0 or max_x >= _params.map_size or max_y >= _params.map_size:
		return false

	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var c = Vector2i(x, y)
			if _is_mountain(_params, c):
				return false

	return true


func _is_outside_map(p):
	return p.x < 0 or p.y < 0 or p.x >= _params.map_size or p.y >= _params.map_size


func _make_extra_bt_sources():
	var bt_sources = []
	var warnings = []

	var available_cxys = {}
	for x in _params.map_size:
		for y in _params.map_size:
			var p = Vector2i(x, y)

			var too_close = false
			for base_pos in _base_positions:
				var d = p.distance_to(base_pos) * _globals.CELL_SIDE_KMS
				if d < _params.betirium.extra_sources.distance_to_any_base:
					too_close = true
					break

			if too_close:
				continue

			if _is_mountain(_params, p):
				continue

			available_cxys[p] = true

	for i in _params.betirium.extra_sources.count:
		if available_cxys.size() < 1:
			warnings.append("Nowhere to put extra Bt source\n")
			break

		var positions = available_cxys.keys()
		positions.shuffle()

		bt_sources.append(
			{
				decay_factor = _params.betirium.extra_sources.decay,
				position = positions[0],
				peak_density = _params.betirium.extra_sources.peak_density,
				radius = _globals.CELL_SIDE_KMS,
				type = BTSourceType.EXTRA,
			},
		)

		available_cxys.erase(positions[0])

	return { sources = bt_sources, warnings = warnings }


func get_bt_sources():
	return _bt_sources


func get_bt_source(p: Vector2i):
	for s in _bt_sources:
		if s.position == p:
			return s

	return null


func _make_bt_sources():
	var satellite_bt_sources = _make_satellite_bt_sources()
	var extra_bt_sources = _make_extra_bt_sources()

	_bt_sources = satellite_bt_sources + extra_bt_sources.sources
	return extra_bt_sources.warnings


func _calculate_bt_density():
	var bt = Array()
	bt.resize(_params.map_size)

	for x in _params.map_size:
		bt[x] = Array()
		bt[x].resize(_params.map_size)

		for y in _params.map_size:
			var p = Vector2(x, y)
			
			var t = 0.0
			for s in _bt_sources:
				t += _bt_density_from_source(s, p)

			bt[x][y] = int(t)
	
	return bt


func _bt_density_from_source(bt_source, p: Vector2i):
	var d = bt_source.position.distance_to(p) * _globals.CELL_SIDE_KMS

	var f = 1.0
	if d > bt_source.radius:
		f = pow(bt_source.decay_factor, (d - bt_source.radius) / _globals.CELL_SIDE_KMS)

	return bt_source.peak_density * f


func lock_bt_source(p: Vector2i):
	_locked_extra_bt_sources[p] = true


func unlock_bt_source(p: Vector2i):
	_locked_extra_bt_sources.erase(p)
