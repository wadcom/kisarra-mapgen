extends VBoxContainer

signal betirium_parameters_changed(params)
signal export_requested
signal height_threshold_changed(height_threshold)
signal parameters_changed(params: Variant)

var _params = {
	base_placement = {
		central_dead_zone_radius = 100,
		min_dist_to_map_edge = 60,
		min_dist_to_other_bases = 175,
	},
	betirium = {
		extra_sources = { count = 2, decay = 0.35, distance_to_any_base = 200, peak_density = 100 },
		satellite_sources = { decay = 0.3, distance_to_base = 75, peak_density = 80 },
	},
	cells_per_player = 250,
	map_size = "updated automatically",
	mountains = {
		height_threshold = 0.3,
		octaves = [
			{ enabled = true, size = 1, weight = 1},
			{ enabled = true, size = 2, weight = 2},
			{ enabled = true, size = 4, weight = 3},
		]
	},
	players_qty = 2,
}


func _ready():
	_params.map_size = _calculate_recommended_map_size()
	_update_betirium_settings()

	%CellsPerPlayer.value = _params.cells_per_player
	%MapSize.value = _params.map_size
	%PlayersQuantity.value = _params.players_qty

	%BasesSettings.set_params(_params.base_placement)
	%MountainsSettings.set_params(_params.mountains)

	_update_labels()


func _on_quit_button_pressed():
	get_tree().quit()


func _on_cells_per_player_value_changed(value):
	_params.cells_per_player = int(value)
	_update_labels()
	parameters_changed.emit(_params)


func _on_map_size_value_changed(value):
	_params.map_size = int(value)
	_update_labels()
	parameters_changed.emit(_params)


func _on_players_quantity_value_changed(value):
	_params.players_qty = int(value)
	_update_betirium_settings()
	_update_labels()
	parameters_changed.emit(_params)


func _on_bases_settings_parameters_changed(params):
	_params.base_placement = params
	_update_labels()
	parameters_changed.emit(_params)


func _on_betirium_settings_parameters_changed(params):
	_params.betirium = params
	_update_labels()
	betirium_parameters_changed.emit(_params)


func _update_labels():
	%CellsPerPlayerLabel.text = str(_params.cells_per_player)
	%MapSizeLabel.text = str(_params.map_size)

	%RecommendedMapSizeLabel.text = str(_calculate_recommended_map_size())


func _on_refresh_button_pressed():
	parameters_changed.emit(_params)


func _on_export_button_pressed():
	export_requested.emit()


func _on_mountains_settings_height_threshold_updated(height_threshold):
	_params.mountains.height_threshold = height_threshold
	height_threshold_changed.emit(_params)


func _calculate_recommended_map_size():
	return ceil(sqrt(_params.players_qty * _params.cells_per_player))


func _update_betirium_settings():
	_params.betirium.extra_sources.count = int(_params.players_qty / 2)
	%BetiriumSettings.set_params(_params.betirium)
