extends VBoxContainer

const _COMMANDS = "res://editor/commands"

const EditorDocument = preload("res://editor/document.gd")
const GenerateTerrainCommand = preload(_COMMANDS + "/generate_terrain_command.gd")
const ReclassifyTerrainCommand = preload(_COMMANDS + "/reclassify_terrain_command.gd")

signal command_requested(command: EditorCommand)

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
	var percentage := int(%MountainPercentSpinBox.value)
	var new_seed := randi_range(0, 1000)
	var cmd := GenerateTerrainCommand.new(
		_document.terrain_seed,
		_document.mountains.get_actual_percentage(),
		new_seed,
		percentage
	)
	command_requested.emit(cmd)


func _on_seed_spin_box_value_changed(_value: float):
	_request_generate()


func _on_mountain_percent_spin_box_value_changed(_value: float):
	_request_generate()


func _on_threshold_spin_box_value_changed(value: float):
	var cmd := ReclassifyTerrainCommand.new(_document.mountains.height_threshold, value)
	command_requested.emit(cmd)


func _request_generate() -> void:
	var percentage := int(%MountainPercentSpinBox.value)
	var rng_seed := int(%SeedSpinBox.value)
	var cmd := GenerateTerrainCommand.new(
		_document.terrain_seed,
		_document.mountains.get_actual_percentage(),
		rng_seed,
		percentage
	)
	command_requested.emit(cmd)
