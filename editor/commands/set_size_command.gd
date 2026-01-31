extends "res://editor/commands/command.gd"
## Command for changing the map size.
##
## The size setter regenerates terrain deterministically, so undo just sets
## the old size and terrain is regenerated automatically.

var _old_size: int
var _new_size: int


func _init(old_size: int, new_size: int):
	_old_size = old_size
	_new_size = new_size


func get_change_description() -> String:
	return "size: %d → %d" % [_old_size, _new_size]


func execute(document: Document) -> void:
	document.size = _new_size


func undo(document: Document) -> void:
	document.size = _old_size
