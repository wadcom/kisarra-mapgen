extends ColorRect

@export var base_cell_prefab: PackedScene
@export var mountain_cell_prefab: PackedScene
@export var round_area_prefab: PackedScene
@export var sand_cell_prefab: PackedScene
@export var extra_source_prefab: PackedScene

var _export_data

const _globals = preload("res://globals.gd")

const MAPGEN_URL = "https://github.com/wadcom/kisarra-mapgen"


func update_parameters(params):
	custom_minimum_size = Vector2.ONE * _globals.PIXELS_PER_CELL_SIDE * params.map_size

	%DiagnosticsText.clear()

	Model.make_height_map(params)

	var result = Model.pick_base_positions(params)
	_display_warnings(result.warnings)

	Model.set_base_positions(result.positions)

	update_betirium(params)

	_setup_bases(params)
 
	_prepare_export_data(params)


func update_mountains_height_threshold(params):
	%DiagnosticsText.clear()

	Model.setup_surface(params)

	_setup_ground_cells(params)
 
	var result = Model.pick_base_positions(params)
	_display_warnings(result.warnings)
	Model.set_base_positions(result.positions)

	update_betirium(params)

	_setup_bases(params)

	_prepare_export_data(params)


func update_betirium(params):
	var warnings = Model.set_params(params)
	_display_warnings(warnings)

	_setup_ground_cells(params)

	_prepare_export_data(params)


func export_map():
	return _export_data


func _prepare_export_data(params):
	var terrain = _format_terrain(params, Model.get_base_positions())

	_export_data = {
		betirium = _format_bt(Model.get_betirium_density()),
		id = _generate_id(params),
		size = params.map_size,
		terrain = terrain,
		version = 1,
	}

	_export_data[MAPGEN_URL] = {
		bt_stats = Model.calculate_bt_stats(),
		params = params
	}


func _generate_id(params):
	const alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"

	var id = ""
	for i in 10:
		id += alphabet[randi() % alphabet.length()]

	return "%s/map-ids/%d/%s" % [MAPGEN_URL, params.players_qty, id]


func _format_terrain(params, base_positions):
	var terrain = Array()
	terrain.resize(params.map_size)

	for y in params.map_size:
		var t = ""
		for x in params.map_size:
			if _is_mountain(params, Vector2i(x, y)):
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


func _is_mountain(params, p: Vector2i):
	var idx = p.y * params.map_size + p.x
	return Model.get_height_map()[idx] > params.mountains.height_threshold


func _setup_ground_cells(params):
	var bt_density = Model.get_betirium_density()

	for c in $GroundCells.get_children():
		$GroundCells.remove_child(c)
		c.queue_free()

	for y in params.map_size:
		for x in params.map_size:

			var cell
			if _is_mountain(params, Vector2i(x, y)):
				cell = mountain_cell_prefab.instantiate()
			else:
				cell = sand_cell_prefab.instantiate()
				cell.set_bt_density(bt_density[x][y])

			cell.position = Vector2(x, y) * _globals.PIXELS_PER_CELL_SIDE
			$GroundCells.add_child(cell)

	# Controls should be on top of the ground cells
	for y in params.map_size:
		for x in params.map_size:
			var bt_source = Model.get_bt_source(Vector2i(x, y))
			if bt_source != null and bt_source.type == Model.BTSourceType.EXTRA:
				var extra_source = extra_source_prefab.instantiate()
				extra_source.setup(Vector2i(x, y), Model.is_bt_source_locked(Vector2i(x, y)))
				extra_source.locked.connect(Model.lock_bt_source)
				extra_source.unlocked.connect(Model.unlock_bt_source)
				$GroundCells.add_child(extra_source)


func _setup_bases(params):
	var base_positions = Model.get_base_positions()

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


func _display_warnings(warnings):
	for w in warnings:
		%DiagnosticsText.add_text(w)
