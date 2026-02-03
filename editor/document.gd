extends RefCounted
## Map document containing all layers and configuration.
##
## API design: Layers are exposed for reading state and connecting signals.
## Mutations should go through document methods (generate_terrain, etc.)
## to ensure proper coordination between layers.

const BasesLayer = preload("res://editor/layers/bases.gd")
const BetiriumDensityLayer = preload("res://editor/layers/betirium_density.gd")
const BetiriumSourcesLayer = preload("res://editor/layers/betirium_sources.gd")
const MountainsLayer = preload("res://editor/layers/mountains.gd")

## Emitted when any document property changes.
signal changed


## Default mountain percentage for initial generation.
const DEFAULT_MOUNTAIN_PERCENTAGE := 25


## The bases layer containing player base positions.
var bases: BasesLayer

## The betirium density layer (derived from sources).
var betirium_density: BetiriumDensityLayer

## The betirium sources layer containing home deposit positions.
var betirium_sources: BetiriumSourcesLayer

## The mountains layer containing terrain generation.
var mountains: MountainsLayer

## Map size (maps are always square).
var size: int:
	get:
		return _size
	set(value):
		_size = clampi(value, 9, 120)
		changed.emit()
		mountains.generate(_size, _current_percentage(), _terrain_seed)

## Cells per player used for recommended size calculation.
var cells_per_player: int:
	get:
		return _cells_per_player
	set(value):
		_cells_per_player = clampi(value, 50, 1000)
		changed.emit()

## Number of players (game configuration).
var player_count: int:
	get:
		return _player_count
	set(value):
		_player_count = clampi(value, 2, 9)
		changed.emit()
		generate_bases(bases.rng_seed)

var _cells_per_player := 250
var _player_count := 2
var _size := 22

## RNG seed for terrain generation.
var terrain_seed: int:
	get:
		return _terrain_seed
	set(value):
		_terrain_seed = value
		mountains.generate(size, _current_percentage(), _terrain_seed)

var _terrain_seed := 0


func _init():
	bases = BasesLayer.new()
	betirium_density = BetiriumDensityLayer.new()
	betirium_sources = BetiriumSourcesLayer.new()
	mountains = MountainsLayer.new()
	bases.changed.connect(_on_bases_changed)
	betirium_sources.changed.connect(_on_betirium_sources_changed)
	mountains.changed.connect(_on_mountains_changed)


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


## Generates bases with the given seed.
func generate_bases(seed_value: int) -> void:
	if not mountains.has_terrain():
		return
	bases.generate(mountains, size, player_count, seed_value)


## Generates betirium home deposit sources with the given seed.
func generate_betirium_home_deposits(seed_value: int) -> void:
	betirium_sources.generate(bases, mountains, size, seed_value)


func _on_bases_changed() -> void:
	betirium_sources.regenerate(bases, mountains, size)


func _on_betirium_sources_changed() -> void:
	betirium_density.calculate(betirium_sources, size)


func _on_mountains_changed() -> void:
	generate_bases(bases.rng_seed)


## Returns export dictionary.
func export_to_dict() -> Dictionary:
	return {
		"betirium": _format_betirium(),
		"https://github.com/wadcom/kisarra-mapgen": {
			"bases_seed": bases.rng_seed,
			"betirium_home_deposits_seed": betirium_sources.get_home_deposit_seed(),
			"editor_version": 2,
			"id": _generate_export_id(),
			"terrain_seed": terrain_seed,
		},
		"size": size,
		"terrain": _format_terrain(),
		"version": 1,
	}


func _format_betirium() -> Array[int]:
	var result: Array[int] = []
	for y in range(size):
		for x in range(size):
			result.append(betirium_density.get_density_at(x, y))
	return result


func _format_terrain() -> Array[String]:
	var base_set := {}
	for pos in bases.get_positions():
		base_set[pos] = true

	var rows: Array[String] = []
	for y in range(size):
		var row := ""
		for x in range(size):
			var pos := Vector2i(x, y)
			if base_set.has(pos):
				row += "b"
			elif mountains.get_terrain_at(x, y) == MountainsLayer.TerrainType.MOUNTAIN:
				row += "m"
			else:
				row += "s"
		rows.append(row)
	return rows


func _generate_export_id() -> String:
	var chars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var suffix := ""
	for i in range(10):
		suffix += chars[randi() % chars.length()]
	return "https://github.com/wadcom/kisarra-mapgen/v2/map-ids/%d/%s" % [player_count, suffix]
