extends VBoxContainer

const _COMMANDS = "res://editor_v2/commands"

const EditorDocument = preload("res://editor_v2/document.gd")
const GenerateBetiriumExtrasCommand = preload(_COMMANDS + "/generate_betirium_extras_command.gd")
const GenerateBetiriumSatellitesCommand = preload(_COMMANDS + "/generate_betirium_satellites_command.gd")

signal command_requested(command: EditorCommand)

var _document: EditorDocument


func set_document(doc: EditorDocument) -> void:
	assert(_document == null, "Document already set")
	assert(doc != null, "Document cannot be null")
	_document = doc
	_document.betirium_sources.changed.connect(_sync_ui)
	_document.changed.connect(_sync_ui)  # For player_count changes


## Syncs UI spinners with document state without triggering signals.
func _sync_ui() -> void:
	if not _document:
		return

	%SeedSpinBox.set_value_no_signal(_document.betirium_sources.get_satellite_seed())
	%ExtraSeedSpinBox.set_value_no_signal(_document.betirium_sources.get_extra_seed())
	%ExtraCountLabel.text = str(_document.player_count / 2)


func _on_regenerate_button_pressed():
	var new_seed := randi_range(0, 1000)
	var cmd := GenerateBetiriumSatellitesCommand.new(
		_document.betirium_sources.get_satellite_seed(), new_seed,
	)
	command_requested.emit(cmd)


func _on_seed_spin_box_value_changed(_value: float):
	var new_seed := int(%SeedSpinBox.value)
	var cmd := GenerateBetiriumSatellitesCommand.new(_document.betirium_sources.get_satellite_seed(), new_seed)
	command_requested.emit(cmd)


func _on_regenerate_extras_button_pressed():
	var new_seed := randi_range(0, 1000)
	var cmd := GenerateBetiriumExtrasCommand.new(
		_document.betirium_sources.get_extra_seed(), new_seed,
	)
	command_requested.emit(cmd)


func _on_extra_seed_spin_box_value_changed(_value: float):
	var new_seed := int(%ExtraSeedSpinBox.value)
	var cmd := GenerateBetiriumExtrasCommand.new(
		_document.betirium_sources.get_extra_seed(), new_seed,
	)
	command_requested.emit(cmd)
