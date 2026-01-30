extends "res://editor_v2/commands/command.gd"
## Command for generating/regenerating extra betirium sources.
##
## Generation is deterministic - same bases, terrain, and seed produces
## the same positions. Undo simply regenerates with the old seed.

var _old_seed: int
var _new_seed: int


func _init(old_seed: int, new_seed: int):
	_old_seed = old_seed
	_new_seed = new_seed


func get_change_description() -> String:
	return "betirium extras: seed %d → %d" % [_old_seed, _new_seed]


func execute(document: Document) -> void:
	document.generate_betirium_extras(_new_seed)


func undo(document: Document) -> void:
	document.generate_betirium_extras(_old_seed)
