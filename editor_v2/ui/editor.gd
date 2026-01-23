extends MarginContainer

const CommandHistory = preload("res://editor_v2/commands/command_history.gd")
const EditorDocument = preload("res://editor_v2/document.gd")

var _document: EditorDocument
var _command_history: CommandHistory


func _ready():
	_document = EditorDocument.new()
	_command_history = CommandHistory.new(_document)
	_command_history.history_changed.connect(_on_history_changed)

	%MapView.set_document(_document)
	%Size.set_document(_document)
	%Terrain.set_document(_document)
	%Size.apply_recommended_size()

	# Connect panel commands directly to history
	%Size.command_requested.connect(_command_history.execute)
	%Terrain.command_requested.connect(_command_history.execute)

	# Auto-generate terrain on editor load so user sees terrain immediately
	_document.terrain_seed = randi_range(0, 1000)

	# Initialize toolbar button states
	_on_history_changed()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.is_command_or_control_pressed():
			match event.keycode:
				KEY_Z:
					if event.shift_pressed:
						_command_history.redo()
					else:
						_command_history.undo()
					get_viewport().set_input_as_handled()
				KEY_Y:
					_command_history.redo()
					get_viewport().set_input_as_handled()


func _on_history_changed() -> void:
	%UndoButton.disabled = not _command_history.can_undo()
	%RedoButton.disabled = not _command_history.can_redo()


func _on_undo_button_pressed() -> void:
	_command_history.undo()


func _on_redo_button_pressed() -> void:
	_command_history.redo()


func _on_quit_button_pressed():
	get_tree().quit()
