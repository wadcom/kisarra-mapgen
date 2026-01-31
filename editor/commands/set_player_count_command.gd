extends "res://editor/commands/command.gd"
## Command for changing the player count.
##
## Player count changes don't affect terrain, so this is a simple value swap.

var _old_count: int
var _new_count: int


func _init(old_count: int, new_count: int):
	_old_count = old_count
	_new_count = new_count


func get_change_description() -> String:
	return "players: %d → %d" % [_old_count, _new_count]


func execute(document: Document) -> void:
	document.player_count = _new_count


func undo(document: Document) -> void:
	document.player_count = _old_count
