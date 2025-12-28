extends MarginContainer

const _globals = preload("res://globals.gd")


func _ready():
	# Check feature flag and switch to v2 editor if enabled
	if _globals.USE_EDITOR_V2:
		get_tree().change_scene_to_file.call_deferred("res://editor_v2/ui/editor.tscn")


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
