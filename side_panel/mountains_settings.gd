extends VBoxContainer

signal height_threshold_updated(height_threshold)


var _params


func _ready() -> void:
	Model.surface_updated.connect(_on_surface_updated)


func set_params(params):
	_params = params
	_update_controls_from_params()

	# TODO: ensure this is done once...
	for i in _params.octaves.size():
		var controls = _get_controls(i)

		controls.enabled_checkbox.pressed.connect(_on_octave_controls_updated)
		controls.size_spinbox.value_changed.connect(_on_size_value_changed)
		controls.weight_spinbox.value_changed.connect(_on_weight_value_changed)


func _update_controls_from_params():
	%HeightThresholdLabel.text = "%.2f" % _params.height_threshold
	%HeightThresholdSlider.value = _params.height_threshold

	var total_weight = 0

	for i in _params.octaves.size():
		var o = _params.octaves[i]
		var controls = _get_controls(i)

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
	height_threshold_updated.emit(value)
	_update_controls_from_params()


func _on_octave_controls_updated():
	for i in _params.octaves.size():
		var o = _params.octaves[i]
		var controls = _get_controls(i)
		o.enabled = controls.enabled_checkbox.button_pressed
		o.size = controls.size_spinbox.value
		o.weight = controls.weight_spinbox.value

	_update_controls_from_params()


func _on_weight_value_changed(_value):
	_on_octave_controls_updated()


func _on_size_value_changed(_value):
	_on_octave_controls_updated()


func _on_surface_updated():
	var surface = Model.get_surface()

	var r = round(_calculate_mountains_density(surface) / 0.05) * 0.05

	%DensityLabel.text = "%.2f" % [r]
	%DensitySlider.set_value_no_signal(r)


func _on_density_slider_value_changed(value: float) -> void:
	var params = Model.get_params()
	if params == null:
		return

	var threshold = -2.0
	while threshold <= 2.0:
		params.mountains.height_threshold = threshold
		var surface = Model.make_surface(params)
		var d =_calculate_mountains_density(surface)

		if d >= (value - 0.025) and d <= (value + 0.025):
			%HeightThresholdSlider.value = threshold
			break

		threshold += 0.01


func _calculate_mountains_density(surface):
	var mountains = 0
	var total = 0
	for column in surface:
		for cell in column:
			total += 1
			if cell.type == Model.SurfaceType.MOUNTAINS:
				mountains += 1

	return float(mountains) / total
