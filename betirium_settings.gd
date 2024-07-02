extends VBoxContainer

signal parameters_changed(params: Variant)


var _params


func set_params(params):
	_params = params
	_update_controls()


func _update_controls():
	%SatelliteBtDecayLabel.text = "%.2f" % [_params.satellite_sources.decay]
	%SatelliteBtDecaySlider.value = _params.satellite_sources.decay

	%SatelliteBtDistanceToBaseLabel.text = str(_params.satellite_sources.distance_to_base)
	%SatelliteBtDistanceToBaseSlider.value = _params.satellite_sources.distance_to_base

	%SatelliteBtPeakDensityLabel.text = str(_params.satellite_sources.peak_density)
	%SatelliteBtPeakDensitySlider.value = _params.satellite_sources.peak_density


func _on_satellite_bt_distance_to_base_slider_value_changed(value):
	_params.satellite_sources.distance_to_base = int(value)

	_update_controls()
	parameters_changed.emit(_params)


func _on_satellite_bt_peak_density_slider_value_changed(value):
	_params.satellite_sources.peak_density = int(value)

	_update_controls()
	parameters_changed.emit(_params)


func _on_satellite_bt_decay_slider_value_changed(value):
	_params.satellite_sources.decay = value

	_update_controls()
	parameters_changed.emit(_params)
