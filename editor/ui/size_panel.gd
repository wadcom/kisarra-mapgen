extends VBoxContainer

const _COMMANDS = "res://editor/commands"

const DesignTokens = preload("res://editor/ui/design_tokens.gd")
const EditorDocument = preload("res://editor/document.gd")
const SetCellsPerPlayerCommand = preload(_COMMANDS + "/set_cells_per_player_command.gd")
const SetPlayerCountCommand = preload(_COMMANDS + "/set_player_count_command.gd")
const SetSizeCommand = preload(_COMMANDS + "/set_size_command.gd")

signal command_requested(command: EditorCommand)

var _document: EditorDocument


func _ready():
	%RecommendedLabel.add_theme_color_override("font_color", DesignTokens.COLOR_MUTED)


func set_document(doc: EditorDocument) -> void:
	assert(_document == null, "Document already set")
	assert(doc != null, "Document cannot be null")
	_document = doc
	_document.changed.connect(_sync_ui)
	_sync_ui()


## Syncs UI spinners with document state without triggering signals.
func _sync_ui() -> void:
	if not _document:
		return
	%CellsPerPlayerSlider.set_value_no_signal(_document.cells_per_player)
	%CellsPerPlayerLabel.text = str(_document.cells_per_player)
	%PlayerCountSpinBox.set_value_no_signal(_document.player_count)
	%SizeSpinBox.set_value_no_signal(_document.size)
	_update_recommended_size()


func apply_recommended_size():
	%SizeSpinBox.value = _calculate_recommended_size()


func _calculate_recommended_size() -> int:
	if not _document:
		return 22
	return ceili(sqrt(_document.player_count * _document.cells_per_player))


func _update_recommended_size():
	var recommended := _calculate_recommended_size()
	var current_size := int(%SizeSpinBox.value)
	var differs := recommended != current_size
	%RecommendedSizeLabel.text = str(recommended)
	%RecommendedSizeLabel.add_theme_color_override(
		"font_color", DesignTokens.COLOR_ACCENT if differs else DesignTokens.COLOR_MUTED
	)
	%UseRecommendedButton.disabled = not differs


func _on_cells_per_player_value_changed(value: float):
	var cmd := SetCellsPerPlayerCommand.new(_document.cells_per_player, int(value))
	command_requested.emit(cmd)


func _on_player_count_value_changed(value: float):
	var cmd := SetPlayerCountCommand.new(_document.player_count, int(value))
	command_requested.emit(cmd)


func _on_size_value_changed(value: float):
	_update_recommended_size()
	var cmd := SetSizeCommand.new(_document.size, int(value))
	command_requested.emit(cmd)
