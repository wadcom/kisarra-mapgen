extends ColorRect

@export var base_cell_prefab: PackedScene
@export var round_area_prefab: PackedScene
@export var sand_cell_prefab: PackedScene


const _globals = preload("res://globals.gd")


func update_parameters(params):
	custom_minimum_size = Vector2.ONE * _globals.PIXELS_PER_CELL_SIDE * params.map_size

	%DiagnosticsText.clear()

	var base_positions = _pick_base_positions(params)
	var satellite_bt_sources = _pick_satellite_bt_sources(params, base_positions)

	var bt_density = _calculate_bt_density(params, satellite_bt_sources)

	_setup_bases(params, base_positions)
	_setup_ground_cells(params, bt_density)


func _calculate_bt_density(params, bt_sources):
	var total_bt = []
	for x in params.map_size:
		for y in params.map_size:
			var p = Vector2(x, y)
			
			var t = 0.0
			for s in bt_sources:
				var d = s.position.distance_to(p)
				t += s.peak_density * pow(s.decay_factor, d)

			total_bt.append(int(t))

	return total_bt


func _setup_ground_cells(params, bt_density):
	for c in $GroundCells.get_children():
		$GroundCells.remove_child(c)
		c.queue_free()

	for x in params.map_size:
		for y in params.map_size:

			var cell = sand_cell_prefab.instantiate()
			cell.set_bt_density(bt_density.pop_front())

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


func _pick_satellite_bt_sources(params, base_positions):
	var satellite_bt_radius = \
		params.betirium.satellite_sources.distance_to_base / _globals.CELL_SIDE_KMS

	var bt_sources = []

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

		bt_sources.append(
			{
				decay_factor = params.betirium.satellite_sources.decay,
				position = Vector2(int(cxys[0] / 1000.0), int(cxys[0]) % 1000),
				peak_density = params.betirium.satellite_sources.peak_density,
			},
		)

	return bt_sources


func _pick_base_positions(params):
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
