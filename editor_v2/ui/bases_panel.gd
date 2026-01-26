extends VBoxContainer

const _COMMANDS = "res://editor_v2/commands"

const EditorDocument = preload("res://editor_v2/document.gd")
const GenerateBasesCommand = preload(_COMMANDS + "/generate_bases_command.gd")

signal command_requested(command: EditorCommand)
signal show_constraints_changed(value: bool)

var _document: EditorDocument


func set_document(doc: EditorDocument) -> void:
	assert(_document == null, "Document already set")
	assert(doc != null, "Document cannot be null")
	_document = doc
	_document.bases.changed.connect(_sync_ui)


## Syncs UI spinners with document state without triggering signals.
func _sync_ui() -> void:
	if not _document:
		return

	%SeedSpinBox.set_value_no_signal(_document.bases.rng_seed)


func _on_regenerate_button_pressed():
	var new_seed := randi_range(0, 1000)
	var cmd := GenerateBasesCommand.new(_document.bases.rng_seed, new_seed)
	command_requested.emit(cmd)


func _on_seed_spin_box_value_changed(_value: float):
	var new_seed := int(%SeedSpinBox.value)
	var cmd := GenerateBasesCommand.new(_document.bases.rng_seed, new_seed)
	command_requested.emit(cmd)


func _on_show_constraints_check_box_toggled(toggled_on: bool) -> void:
	show_constraints_changed.emit(toggled_on)
