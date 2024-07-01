extends VBoxContainer

signal parameters_changed(params: Variant)

var _params = {
	base_placement = { min_dist_to_other_bases = 40 },
	cells_per_player = 120,
	map_size = 22,
	players_qty = 2,
}


func _ready():
	%CellsPerPlayer.value = _params.cells_per_player
	%MapSize.value = _params.map_size
	%PlayersQuantity.value = _params.players_qty

	%BaseDistanceToOtherBasesSlider.value = _params.base_placement.min_dist_to_other_bases

	_update_labels()


func _on_quit_button_pressed():
	get_tree().quit()


func _on_base_distance_to_other_bases_value_changed(value):
	_params.base_placement.min_dist_to_other_bases = int(value)
	_update_labels()
	parameters_changed.emit(_params)


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
	_update_labels()
	parameters_changed.emit(_params)


func _update_labels():
	%CellsPerPlayerLabel.text = str(_params.cells_per_player)
	%MapSizeLabel.text = str(_params.map_size)

	%RecommendedMapSizeLabel.text = str(ceil(sqrt(_params.players_qty * _params.cells_per_player)))

	%BaseDistanceToOtherBasesLabel.text = str(_params.base_placement.min_dist_to_other_bases)
