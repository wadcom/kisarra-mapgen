extends MarginContainer


func _on_parameters_changed(params):
	%MapArea.update_parameters(params)
	_update_stats()


func _on_export_requested():
	var data = %MapArea.export_map()
	DisplayServer.clipboard_set(JSON.stringify(data, "  "))


func _on_mountains_height_threshold_changed(params):
	%MapArea.update_mountains_height_threshold(params)
	_update_stats()


func _on_side_panel_betirium_parameters_changed(params):
	%MapArea.update_betirium(params)
	_update_stats()


func _update_stats():
	%BetiriumStats.update_stats()
	%TerrainStats.update_stats()
