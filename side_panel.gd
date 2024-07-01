extends VBoxContainer


var _cells_per_player = 120
var _map_size = 22
var _players_qty = 2


func _ready():
	%CellsPerPlayer.value = _cells_per_player
	%MapSize.value = _map_size
	%PlayersQuantity.value = _players_qty

	_update_labels()


func _on_quit_button_pressed():
	get_tree().quit()


func _on_cells_per_player_value_changed(value):
	_cells_per_player = value
	_update_labels()


func _on_map_size_value_changed(value):
	_map_size = value
	_update_labels()


func _on_players_quantity_value_changed(value):
	_players_qty = value
	_update_labels()


func _update_labels():
	%CellsPerPlayerLabel.text = str(_cells_per_player)
	%MapSizeLabel.text = str(_map_size)

	%RecommendedMapSizeLabel.text = str(ceil(sqrt(_players_qty * _cells_per_player)))
