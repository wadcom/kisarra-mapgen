extends "res://editor/commands/command.gd"
## Command for generating/regenerating betirium ambient deposits.
##
## Generation is deterministic - same terrain and seed produces
## the same positions. Undo simply regenerates with the old seed.

var _old_seed: int
var _new_seed: int


func _init(old_seed: int, new_seed: int):
	_old_seed = old_seed
	_new_seed = new_seed


func get_change_description() -> String:
	return "betirium ambient deposits: seed %d → %d" % [_old_seed, _new_seed]


func execute(document: Document) -> void:
	document.generate_betirium_ambient_deposits(_new_seed)


func undo(document: Document) -> void:
	document.generate_betirium_ambient_deposits(_old_seed)
