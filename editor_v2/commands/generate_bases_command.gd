extends "res://editor_v2/commands/command.gd"
## Command for generating/regenerating bases.
##
## Base generation is deterministic - same terrain and same base seed produces
## the same positions. Undo simply regenerates with the old seed.

var _old_seed: int
var _new_seed: int


func _init(old_seed: int, new_seed: int):
	_old_seed = old_seed
	_new_seed = new_seed


func get_change_description() -> String:
	return "bases: seed %d → %d" % [_old_seed, _new_seed]


func execute(document: Document) -> void:
	document.generate_bases(_new_seed)


func undo(document: Document) -> void:
	document.generate_bases(_old_seed)
