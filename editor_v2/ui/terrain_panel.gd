extends VBoxContainer

const EditorDocument = preload("res://editor_v2/document.gd")

var _document: EditorDocument


func set_document(doc: EditorDocument) -> void:
	assert(_document == null, "Document already set")
	assert(doc != null, "Document cannot be null")
	_document = doc
	_document.mountains.changed.connect(_sync_ui)


## Syncs UI spinners with document state without triggering signals.
func _sync_ui() -> void:
	if not _document:
		return

	%MountainPercentSpinBox.set_value_no_signal(_document.mountains.get_actual_percentage())
	%SeedSpinBox.set_value_no_signal(_document.terrain_seed)
	%ThresholdSpinBox.set_value_no_signal(_document.mountains.height_threshold)


func _on_regenerate_button_pressed():
	_document.terrain_seed = randi_range(0, 1000)


func _on_seed_spin_box_value_changed(_value: float):
	_generate()


func _on_mountain_percent_spin_box_value_changed(_value: float):
	_generate()


func _on_threshold_spin_box_value_changed(value: float):
	_document.reclassify_terrain(value)


func _generate() -> void:
	var percentage := int(%MountainPercentSpinBox.value)
	var rng_seed := int(%SeedSpinBox.value)
	_document.generate_terrain(percentage, rng_seed)
