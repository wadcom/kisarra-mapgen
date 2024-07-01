extends VBoxContainer

signal parameters_changed(params: Variant)


var _params


func set_params(params):
	_params = params
	_update_controls()


func _on_distance_to_other_bases_slider_value_changed(value):
	_params.min_dist_to_other_bases = int(value)

	_update_controls()
	parameters_changed.emit(_params)


func _on_distance_to_map_edge_slider_value_changed(value):
	_params.min_dist_to_map_edge = int(value)

	_update_controls()
	parameters_changed.emit(_params)


func _update_controls():
	%DistanceToMapEdgeLabel.text = str(_params.min_dist_to_map_edge)
	%DistanceToMapEdgeSlider.value = _params.min_dist_to_map_edge

	%DistanceToOtherBasesLabel.text = str(_params.min_dist_to_other_bases)
	%DistanceToOtherBasesSlider.value = _params.min_dist_to_other_bases

