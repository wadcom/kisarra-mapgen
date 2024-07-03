extends MarginContainer


func _on_parameters_changed(params):
	%MapArea.update_parameters(params)


func _on_export_requested():
	var data = %MapArea.export_map()
	DisplayServer.clipboard_set(JSON.stringify(data, "  "))
