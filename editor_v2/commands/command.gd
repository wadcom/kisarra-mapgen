extends RefCounted
## Base class for undoable editor commands.
##
## Commands encapsulate a mutation to the document that can be executed and undone.
## They are lightweight value objects that receive the document as a parameter
## rather than storing a reference, keeping them testable and serialization-friendly.
class_name EditorCommand

const Document = preload("res://editor_v2/document.gd")


## Human-readable description showing what changed (e.g., "size: 22 → 30").
func get_change_description() -> String:
	return "Unknown command"


## Execute the command. Called on initial execution and redo.
func execute(_document: Document) -> void:
	pass


## Reverse the command's effects.
func undo(_document: Document) -> void:
	pass
