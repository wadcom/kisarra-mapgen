extends VBoxContainer


var _map_size = 22
var _cells_per_player = 9


func _on_quit_button_pressed():
	get_tree().quit()


func _on_cells_per_player_value_changed(value):
	_cells_per_player = value
	%CellsPerPlayer.text = str(value)


func _on_map_size_value_changed(value):
	_map_size = value
	%MapSizeLabel.text = str(value)
