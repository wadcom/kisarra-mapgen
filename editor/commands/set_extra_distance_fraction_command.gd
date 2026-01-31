extends "res://editor/commands/command.gd"
## Command for setting the extra betirium source distance fraction.
##
## Changes the minimum distance from bases as a fraction of map size.
## Regenerates extra sources after changing the value.

var _old_value: float
var _new_value: float


func _init(old_value: float, new_value: float):
	_old_value = old_value
	_new_value = new_value


func get_change_description() -> String:
	return "extra distance: %.0f%% → %.0f%%" % [_old_value * 100, _new_value * 100]


func execute(document: Document) -> void:
	document.set_extra_distance_fraction(_new_value)


func undo(document: Document) -> void:
	document.set_extra_distance_fraction(_old_value)
