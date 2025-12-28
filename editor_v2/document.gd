extends RefCounted
## Map document containing all layers and configuration.
##
## API design: Layers are exposed for reading state and connecting signals.
## Mutations should go through document methods (generate_terrain, etc.)
## to ensure proper coordination between layers.

const MountainsLayer = preload("res://editor_v2/layers/mountains.gd")

signal size_changed


## Default mountain percentage for initial generation.
const DEFAULT_MOUNTAIN_PERCENTAGE := 25


## The mountains layer containing terrain generation.
var mountains: MountainsLayer

## Map size (maps are always square).
var size := 22:
	set(value):
		size = clampi(value, 9, 120)
		size_changed.emit()
		mountains.generate(size, _current_percentage(), _terrain_seed)

## Number of players (game configuration).
var player_count := 2:
	set(value):
		player_count = clampi(value, 2, 9)

## RNG seed for terrain generation.
var terrain_seed: int:
	get:
		return _terrain_seed
	set(value):
		_terrain_seed = value
		mountains.generate(size, _current_percentage(), _terrain_seed)

var _terrain_seed := 0


func _init():
	mountains = MountainsLayer.new()


## Returns current mountain percentage, or default if no terrain exists yet.
func _current_percentage() -> int:
	if mountains.has_terrain():
		return mountains.get_actual_percentage()
	return DEFAULT_MOUNTAIN_PERCENTAGE


## Generates terrain with the given parameters.
func generate_terrain(mountain_percentage: int, seed_value: int) -> void:
	# Bypass terrain_seed setter to use caller's percentage instead of current.
	_terrain_seed = seed_value
	mountains.generate(size, mountain_percentage, _terrain_seed)


## Reclassifies terrain using the given threshold.
func reclassify_terrain(threshold: float) -> void:
	mountains.reclassify(threshold)
