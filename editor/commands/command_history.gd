extends RefCounted
## Manages undo/redo stacks for editor commands.
##
## Executes commands through a central point, maintaining history for undo/redo.
## Emits history_changed when stack states change so UI can update button states.

const Document = preload("res://editor/document.gd")

## Emitted when undo/redo availability changes.
signal history_changed

var _document: Document
var _undo_stack: Array[EditorCommand] = []
var _redo_stack: Array[EditorCommand] = []


func _init(document: Document):
	_document = document


## Executes a command and adds it to the undo stack.
## Clears the redo stack since the history has diverged.
func execute(command: EditorCommand) -> void:
	command.execute(_document)
	_undo_stack.push_back(command)
	_redo_stack.clear()
	history_changed.emit()


## Returns true if there are commands to undo.
func can_undo() -> bool:
	return not _undo_stack.is_empty()


## Returns true if there are commands to redo.
func can_redo() -> bool:
	return not _redo_stack.is_empty()


## Undoes the most recent command.
func undo() -> void:
	if can_undo():
		var command: EditorCommand = _undo_stack.pop_back()
		command.undo(_document)
		_redo_stack.push_back(command)
		history_changed.emit()


## Redoes the most recently undone command.
func redo() -> void:
	if can_redo():
		var command: EditorCommand = _redo_stack.pop_back()
		command.execute(_document)
		_undo_stack.push_back(command)
		history_changed.emit()
