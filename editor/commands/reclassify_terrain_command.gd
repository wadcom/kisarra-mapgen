extends "res://editor/commands/command.gd"
## Command for reclassifying terrain with a new threshold.
##
## Reclassification keeps the height map but re-applies the threshold,
## expanding or contracting mountain boundaries. This is a lightweight
## operation that only needs to store the old and new threshold values.

var _old_threshold: float
var _new_threshold: float


func _init(old_threshold: float, new_threshold: float):
	_old_threshold = old_threshold
	_new_threshold = new_threshold


func get_change_description() -> String:
	return "threshold: %.2f → %.2f" % [_old_threshold, _new_threshold]


func execute(document: Document) -> void:
	document.reclassify_terrain(_new_threshold)


func undo(document: Document) -> void:
	document.reclassify_terrain(_old_threshold)
