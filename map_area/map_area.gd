extends ColorRect

@export var base_cell_prefab: PackedScene
@export var mountain_cell_prefab: PackedScene
@export var round_area_prefab: PackedScene
@export var sand_cell_prefab: PackedScene

var _export_data
var _base_positions
var _height_map

const _globals = preload("res://globals.gd")
const _perlin_noise = preload("res://perlin_noise.gd")


func update_parameters(params):
	custom_minimum_size = Vector2.ONE * _globals.PIXELS_PER_CELL_SIDE * params.map_size

	%DiagnosticsText.clear()

	_height_map = _make_height_map(params)
	_base_positions = _pick_base_positions(params, _height_map)

	update_betirium(params)

	_setup_bases(params, _base_positions)
 
	_prepare_export_data(params)


func update_mountains_height_threshold(params):
	%DiagnosticsText.clear()

	_setup_ground_cells(params, _height_map)
 
	_base_positions = _pick_base_positions(params, _height_map)

	update_betirium(params)

	_setup_bases(params, _base_positions)

	_prepare_export_data(params)


func update_betirium(params):
	var satellite_bt_sources_positions = _pick_satellite_bt_sources_positions(
		params, _base_positions,
	)
	var satellite_bt_sources = _pick_satellite_bt_sources(params, satellite_bt_sources_positions)

	var extra_bt_sources = _pick_extra_bt_sources(params, _base_positions)

	var bt_density = _calculate_bt_density(params, satellite_bt_sources + extra_bt_sources)
	Model.set_betirium_density(bt_density)

	_setup_ground_cells(params, _height_map)


func _make_height_map(params):
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


func export_map():
	return _export_data


func _prepare_export_data(params):
	var terrain = _format_terrain(params, _base_positions)

	_export_data = {
		betirium = _format_bt(Model.get_betirium_density()),
		size = params.map_size,
		terrain = terrain,
		version = 1,
	}

	_export_data["https://github.com/wadcom/kisarra-mapgen"] = {
		params = params
	}


func _format_terrain(params, base_positions):
	var terrain = Array()
	terrain.resize(params.map_size)

	for y in params.map_size:
		var t = ""
		for x in params.map_size:
			if _is_mountain(params, _height_map, Vector2i(x, y)):
				t += "m"
			else:
				t += "s"

		terrain[y] = t

	for bp in base_positions:
		terrain[bp.y][bp.x] = "b"

	return terrain


func _format_bt(bt_density):
	assert(bt_density.size() == bt_density[0].size())

	var map_size = bt_density.size()

	var result = []
	for y in map_size:
		for x in map_size:
			result.append(bt_density[x][y])

	return result


func _calculate_bt_density(params, bt_sources):
	var bt = Array()
	bt.resize(params.map_size)

	for x in params.map_size:
		bt[x] = Array()
		bt[x].resize(params.map_size)

		for y in params.map_size:
			var p = Vector2(x, y)
			
			var t = 0.0
			for s in bt_sources:
				var d = s.position.distance_to(p)
				t += s.peak_density * pow(s.decay_factor, d)

			bt[x][y] = int(t)
	
	return bt


func _is_mountain(params, height_map, p: Vector2i):
	var idx = p.y * params.map_size + p.x
	return height_map[idx] > params.mountains.height_threshold


func _setup_ground_cells(params, height_map):
	Model.setup_surface(params, height_map)

	var bt_density = Model.get_betirium_density()

	for c in $GroundCells.get_children():
		$GroundCells.remove_child(c)
		c.queue_free()

	for y in params.map_size:
		for x in params.map_size:

			var cell
			if _is_mountain(params, height_map, Vector2i(x, y)):
				cell = mountain_cell_prefab.instantiate()
			else:
				cell = sand_cell_prefab.instantiate()
				cell.set_bt_density(bt_density[x][y])

			cell.position = Vector2(x, y) * _globals.PIXELS_PER_CELL_SIDE
			$GroundCells.add_child(cell)


func _setup_bases(params, base_positions):
	for b in $Bases.get_children():
		$Bases.remove_child(b)
		b.queue_free()

	for c in $Constraints.get_children():
		$Constraints.remove_child(c)
		c.queue_free()

	for p in base_positions:
		var base = base_cell_prefab.instantiate()
		base.position = p * _globals.PIXELS_PER_CELL_SIDE
		$Bases.add_child(base)

		var exclusion_area = round_area_prefab.instantiate()
		exclusion_area.position = \
			p * _globals.PIXELS_PER_CELL_SIDE + Vector2.ONE * (_globals.PIXELS_PER_CELL_SIDE / 2.0)
		exclusion_area.set_radius(params.base_placement.min_dist_to_other_bases)
		exclusion_area.modulate = Color(Color.BLACK, 0.05)
		$Constraints.add_child(exclusion_area)


func _pick_extra_bt_sources(params, base_positions):
	var bt_sources = []

	var available_cxys = {}
	for x in params.map_size:
		for y in params.map_size:
			var p = Vector2(x, y)

			var too_close = false
			for base_pos in base_positions:
				var d = p.distance_to(base_pos) * _globals.CELL_SIDE_KMS
				if d < params.betirium.extra_sources.distance_to_any_base:
					too_close = true
					break

			if too_close:
				continue

			var cxy = p.x * 1000 + p.y
			available_cxys[cxy] = true

	for i in params.betirium.extra_sources.count:
		if available_cxys.size() < 1:
			%DiagnosticsText.add_text("Nowhere to put extra Bt source\n")
			break

		var cxys = available_cxys.keys()
		cxys.shuffle()

		bt_sources.append(
			{
				decay_factor = params.betirium.extra_sources.decay,
				position = Vector2(int(cxys[0] / 1000.0), int(cxys[0]) % 1000),
				peak_density = params.betirium.extra_sources.peak_density,
			},
		)

		available_cxys.erase(cxys[0])

	return bt_sources


func _pick_satellite_bt_sources_positions(params, base_positions):
	var satellite_bt_radius = \
		params.betirium.satellite_sources.distance_to_base / _globals.CELL_SIDE_KMS

	var positions = []

	for base_pos in base_positions:
		var available_cxys = {}
		for a in 360:
			var p = (
				Vector2.from_angle(a / 360.0 * TAU) * satellite_bt_radius \
					+ base_pos + Vector2.ONE / 2.0
			).floor()

			if p.x < 0 or p.y < 0 or p.x >= params.map_size or p.y >= params.map_size:
				continue

			var cxy = p.x * 1000 + p.y
			available_cxys[cxy] = true

		if available_cxys.size() < 1:
			%DiagnosticsText.add_text(
				"Nowhere to put satellite Bt source around base at %d,%d\n" % [
					base_pos.x, base_pos.y
				]
			)
			continue

		var cxys = available_cxys.keys()
		cxys.shuffle()

		positions.append(Vector2(int(cxys[0] / 1000.0), int(cxys[0]) % 1000))

	return positions


func _pick_satellite_bt_sources(params, sources_positions):
	var bt_sources = []
	for p in sources_positions:
		bt_sources.append(
			{
				decay_factor = params.betirium.satellite_sources.decay,
				position = p,
				peak_density = params.betirium.satellite_sources.peak_density,
			},
		)

	return bt_sources


func _pick_base_positions(params, height_map):
	var map_center = Vector2.ONE * params.map_size / 2.0

	var available = []
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
			%DiagnosticsText.add_text("No cells available to place a base\n")
			break

		var p = available.pop_back()

		base_positions.append(p)

		available = available.filter(
			func(a): 
				var d = a.distance_to(p) * _globals.CELL_SIDE_KMS
				return d > params.base_placement.min_dist_to_other_bases
		)

	return base_positions
