extends VBoxContainer

const _COMMANDS = "res://editor/commands"

const DesignTokens = preload("res://editor/ui/design_tokens.gd")
const EditorDocument = preload("res://editor/document.gd")
const GenerateBasesCommand = preload(_COMMANDS + "/generate_bases_command.gd")

signal command_requested(command: EditorCommand)
signal show_constraints_changed(value: bool)

var _document: EditorDocument


func _ready() -> void:
	%WarningLabel.add_theme_color_override("font_color", DesignTokens.COLOR_WARNING)


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
	_update_warning()


func _update_warning() -> void:
	var lines := _warning_lines(
		_document.bases.get_positions().size(),
		_document.player_count,
		_document.bases.get_validation_failures(),
	)
	%WarningLabel.text = "\n".join(lines)
	%WarningLabel.visible = not lines.is_empty()


## Returns what the warning label should say about a placement, one line each,
## and nothing at all when the placement fills every slot and breaks no rule.
##
## The closing suggestion follows broken rules only. A placement that ran out
## of room is not helped by another seed on the same terrain.
##
## This is static so that every choice about what the warning says can be
## tested without a scene. Keep new conditions here rather than in the caller,
## which only reads the document and writes the label.
static func _warning_lines(placed: int, expected: int, failures: Array[String]) -> Array[String]:
	var lines: Array[String] = []

	if placed < expected:
		lines.append("Only placed %d of %d bases." % [placed, expected])

	if not failures.is_empty():
		lines.append_array(failures)
		lines.append("Try a different base or terrain seed.")

	return lines


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
