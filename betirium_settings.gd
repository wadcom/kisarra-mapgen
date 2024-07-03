extends VBoxContainer

signal parameters_changed(params: Variant)


var _params


func set_params(params):
	_params = params
	_update_controls()


func _update_controls():
	%ExtraSourceDistanceToBasesLabel.text = str(_params.extra_sources.distance_to_any_base)
	%ExtraSourceDistanceToBasesSlider.value = _params.extra_sources.distance_to_any_base

	%ExtraSourcePeakDensityLabel.text = str(_params.extra_sources.peak_density)
	%ExtraSourcePeakDensitySlider.value = _params.extra_sources.peak_density

	%ExtraSourcesQuantitySpinBox.value = _params.extra_sources.count

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


func _on_extra_source_distance_to_bases_slider_value_changed(value):
	_params.extra_sources.distance_to_any_base = value

	_update_controls()
	parameters_changed.emit(_params)


func _on_extra_sources_quantity_spin_box_value_changed(value):
	_params.extra_sources.count = int(value)

	_update_controls()
	parameters_changed.emit(_params)


func _on_extra_source_peak_density_slider_value_changed(value):
	_params.extra_sources.peak_density = int(value)

	_update_controls()
	parameters_changed.emit(_params)
