extends VBoxContainer

var _params


func set_params(params):
	_params = params
	_update_controls()


func _update_controls():
	%HeightThresholdLabel.text = "%.2f" % _params.height_threshold
	%HeightThresholdSlider.value = _params.height_threshold


func _on_height_threshold_slider_value_changed(value):
	_params.height_threshold = value

	_update_controls()
	# parameters_changed.emit(_params)
