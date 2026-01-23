extends "res://editor_v2/commands/command.gd"
## Command for changing the cells per player setting.
##
## This affects the recommended size calculation but has no other side effects.

var _old_value: int
var _new_value: int


func _init(old_value: int, new_value: int):
	_old_value = old_value
	_new_value = new_value


func get_change_description() -> String:
	return "cells/player: %d → %d" % [_old_value, _new_value]


func execute(document: Document) -> void:
	document.cells_per_player = _new_value


func undo(document: Document) -> void:
	document.cells_per_player = _old_value
