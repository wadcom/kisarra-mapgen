extends VBoxContainer

signal height_threshold_updated(height_threshold)


var _params


func set_params(params):
	_params = params
	_update_controls()


func _update_controls():
	%HeightThresholdLabel.text = "%.2f" % _params.height_threshold
	%HeightThresholdSlider.value = _params.height_threshold

	var total_weight = 0

	print("XXX:", _params)
	for i in _params.octaves.size():
		var o = _params.octaves[i]
		var controls = _get_controls(i)

		print("XXX ", i, ": ", o)
		controls.enabled_checkbox.button_pressed = o.enabled

		controls.size_spinbox.value = o.size
		controls.size_spinbox.editable = o.enabled

		controls.weight_spinbox.value = o.weight
		controls.weight_spinbox.editable = o.enabled

		if o.enabled:
			total_weight += o.weight

	for i in _params.octaves.size():
		var o = _params.octaves[i]
		var controls = _get_controls(i)

		if total_weight > 0 and o.enabled:
			controls.percentage_label.text = "%d%%" % [int(100.0 * o.weight / total_weight)]
		else:
			controls.percentage_label.text = ""
			


func _get_controls(i):
	var parent = "OctavesSettings"
	return {
		enabled_checkbox = get_node("%s/Enabled%d" % [parent, i + 1]),
		percentage_label = get_node("%s/PercentageLabel%d" % [parent, i + 1]),
		size_spinbox = get_node("%s/Size%d" % [parent, i + 1]),
		weight_spinbox = get_node("%s/Weight%d" % [parent, i + 1]),
	}


func _on_height_threshold_slider_value_changed(value):
	_params.height_threshold = value

	_update_controls()
	height_threshold_updated.emit(value)


func _on_octave_controls_updated():
	for i in _params.octaves.size():
		var o = _params.octaves[i]
		var controls = _get_controls(i)
		o.enabled = controls.enabled_checkbox.button_pressed
		o.size = controls.size_spinbox.value
		o.weight = controls.weight_spinbox.value

	_update_controls()


func _on_weight_value_changed(_value):
	_on_octave_controls_updated()


func _on_size_value_changed(_value):
	_on_octave_controls_updated()
