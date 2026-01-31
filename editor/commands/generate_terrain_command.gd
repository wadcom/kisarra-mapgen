extends "res://editor/commands/command.gd"
## Command for generating new terrain.
##
## Terrain generation is deterministic - same seed and percentage produces
## the same terrain. So undo just regenerates with the old parameters.

var _old_seed: int
var _old_percentage: int
var _new_seed: int
var _new_percentage: int


func _init(old_seed: int, old_percentage: int, new_seed: int, new_percentage: int):
	_old_seed = old_seed
	_old_percentage = old_percentage
	_new_seed = new_seed
	_new_percentage = new_percentage


func get_change_description() -> String:
	return "terrain: seed %d/%d%% → %d/%d%%" % [
		_old_seed, _old_percentage, _new_seed, _new_percentage,
	]


func execute(document: Document) -> void:
	document.generate_terrain(_new_percentage, _new_seed)


func undo(document: Document) -> void:
	document.generate_terrain(_old_percentage, _old_seed)
