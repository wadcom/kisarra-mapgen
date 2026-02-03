extends RefCounted
## Betirium sources layer - home and ambient deposit positions.
##
## Home deposits are placed one per base, orbiting at a fixed distance.
## Ambient deposits are scattered across sand using Poisson disk sampling.
##
## ## Public API
##
## Properties:
##   - HOME_DEPOSIT_* constants - home deposit source parameters
##   - AMBIENT_* constants - ambient deposit source parameters
##
## Methods:
##   - generate(bases, terrain, map_size, seed) - generate home deposits with new seed
##   - generate_ambient(terrain, map_size, seed) - generate ambient deposits with new seed
##   - regenerate(bases, terrain, map_size) - regenerate home deposits using current seed
##   - regenerate_ambient(terrain, map_size) - regenerate ambient deposits using current seed
##   - get_ambient_peak_densities() -> Array[int] - per-deposit peak densities (copy)
##   - get_ambient_positions() -> Array[Vector2i] - ambient deposit positions (copy)
##   - get_ambient_seed() -> int - RNG seed for ambient placement
##   - get_home_deposit_positions() -> Array[Vector2i] - home deposit positions (copy)
##   - get_home_deposit_seed() -> int - RNG seed for home deposit placement
##
## Signal:
##   - changed - emitted when positions or seed change

const EditorV2Constants = preload("res://editor/constants.gd")
const BasesLayer = preload("res://editor/layers/bases.gd")
const MountainsLayer = preload("res://editor/layers/mountains.gd")

signal changed

## Fixed source parameters (configurable UI deferred to later).

## Exponential decay rate for ambient deposits (faster decay = more localized).
const AMBIENT_DECAY_FACTOR := 0.2

## Minimum distance between ambient deposits in km.
const AMBIENT_MIN_SPACING_KM := 80.0

## Maximum peak density for ambient deposits.
const AMBIENT_PEAK_DENSITY_MAX := 20

## Minimum peak density for ambient deposits.
const AMBIENT_PEAK_DENSITY_MIN := 10

## Radius for ambient density contribution in km.
const AMBIENT_RADIUS_KM := 10.0

## Exponential decay rate for home deposits.
const HOME_DEPOSIT_DECAY_FACTOR := 0.3

## Distance from base to home deposit in km.
const HOME_DEPOSIT_DISTANCE_KM := 75.0

## Density at source center (0-100).
const HOME_DEPOSIT_PEAK_DENSITY := 80

## Radius for density contribution in km.
const HOME_DEPOSIT_RADIUS_KM := 10.0

## Ambient deposit peak densities (randomized per deposit).
var _ambient_peak_densities: Array[int] = []

## Ambient deposit positions as cell coordinates.
var _ambient_positions: Array[Vector2i] = []

## RNG seed for ambient deposit placement.
var _ambient_seed: int = 0

## Home deposit positions as cell coordinates.
## One home deposit per player, indexed by player number.
var _home_deposit_positions: Array[Vector2i] = []

## RNG seed for home deposit placement.
var _home_deposit_seed: int = 0


## Returns ambient deposit peak densities (read-only copy).
func get_ambient_peak_densities() -> Array[int]:
	var copy: Array[int] = []
	copy.assign(_ambient_peak_densities)
	return copy


## Returns ambient deposit positions (read-only copy).
func get_ambient_positions() -> Array[Vector2i]:
	var copy: Array[Vector2i] = []
	copy.assign(_ambient_positions)
	return copy


## Returns the RNG seed for ambient deposit placement.
func get_ambient_seed() -> int:
	return _ambient_seed


## Returns home deposit positions (read-only copy).
func get_home_deposit_positions() -> Array[Vector2i]:
	var copy: Array[Vector2i] = []
	copy.assign(_home_deposit_positions)
	return copy


## Returns the RNG seed for home deposit placement.
func get_home_deposit_seed() -> int:
	return _home_deposit_seed


## Generates home deposit positions using orbit placement.
##
## Algorithm:
## 1. For each base, calculate orbit circle at HOME_DEPOSIT_DISTANCE_KM
## 2. Build list of valid candidate cells around orbit (every degree)
## 3. Pick one randomly using provided RNG
func generate(bases: BasesLayer, terrain: MountainsLayer, map_size: int, seed_value: int) -> void:
	_home_deposit_seed = seed_value
	_home_deposit_positions = _pick_home_deposit_positions(bases, terrain, map_size, seed_value)
	changed.emit()


## Regenerates home deposits using the current seed.
func regenerate(bases: BasesLayer, terrain: MountainsLayer, map_size: int) -> void:
	_home_deposit_positions = _pick_home_deposit_positions(bases, terrain, map_size, _home_deposit_seed)
	changed.emit()


func _pick_home_deposit_positions(
	bases: BasesLayer, terrain: MountainsLayer, map_size: int, seed_value: int,
) -> Array[Vector2i]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var cell_side_km := EditorV2Constants.CELL_SIDE_KMS
	var radius_cells := HOME_DEPOSIT_DISTANCE_KM / cell_side_km
	var edge_buffer := 2.0  # Keep home deposits at least 2 cells from edge

	var positions: Array[Vector2i] = []

	for base_pos in bases.get_positions():
		var base_center := Vector2(base_pos.x + 0.5, base_pos.y + 0.5)
		var candidates: Array[Vector2i] = []

		# Test every degree around the orbit circle
		for angle_deg in 360:
			var angle_rad := deg_to_rad(angle_deg)
			var offset := Vector2(cos(angle_rad), sin(angle_rad)) * radius_cells
			var pos := base_center + offset
			var cell := Vector2i(roundi(pos.x - 0.5), roundi(pos.y - 0.5))

			# Check bounds
			if cell.x < edge_buffer or cell.x >= map_size - edge_buffer:
				continue
			if cell.y < edge_buffer or cell.y >= map_size - edge_buffer:
				continue

			# Check terrain (must be sand)
			if terrain.get_terrain_at(cell.x, cell.y) != MountainsLayer.TerrainType.SAND:
				continue

			# Avoid duplicate cells
			if cell not in candidates:
				candidates.append(cell)

		# Pick one randomly if candidates exist
		if not candidates.is_empty():
			var index := rng.randi_range(0, candidates.size() - 1)
			positions.append(candidates[index])

	return positions


## Generates ambient deposit positions scattered across sand cells.
func generate_ambient(terrain: MountainsLayer, map_size: int, seed_value: int) -> void:
	_ambient_seed = seed_value
	var result := _pick_ambient_positions(terrain, map_size, seed_value)
	_ambient_positions = result[0]
	_ambient_peak_densities = result[1]
	changed.emit()


## Regenerates ambient deposits using the current seed.
func regenerate_ambient(terrain: MountainsLayer, map_size: int) -> void:
	generate_ambient(terrain, map_size, _ambient_seed)


func _pick_ambient_positions(
	terrain: MountainsLayer, map_size: int, seed_value: int,
) -> Array:  # Returns [Array[Vector2i], Array[int]]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var cell_side_km := EditorV2Constants.CELL_SIDE_KMS
	var min_spacing_cells := AMBIENT_MIN_SPACING_KM / cell_side_km

	# Build initial candidate set: all sand cells
	var candidates: Dictionary = {}  # Vector2i -> true (used as a set)
	for x in map_size:
		for y in map_size:
			if terrain.get_terrain_at(x, y) != MountainsLayer.TerrainType.SAND:
				continue
			candidates[Vector2i(x, y)] = true

	# Poisson disk sampling - shuffle candidates for varied spatial distribution
	var candidate_list: Array = candidates.keys()
	_shuffle_array(candidate_list, rng)

	var positions: Array[Vector2i] = []
	var densities: Array[int] = []
	var candidate_index := 0

	while candidate_index < candidate_list.size():
		var chosen: Vector2i = candidate_list[candidate_index]
		candidate_index += 1

		# Skip if this cell was already removed (too close to a previous pick)
		if not candidates.has(chosen):
			continue

		# Assign random peak density
		var peak := rng.randi_range(AMBIENT_PEAK_DENSITY_MIN, AMBIENT_PEAK_DENSITY_MAX)

		positions.append(chosen)
		densities.append(peak)

		# Remove all cells within min_spacing from candidates
		var to_remove: Array[Vector2i] = []
		for cell in candidates.keys():
			var dist := Vector2(cell).distance_to(Vector2(chosen))
			if dist <= min_spacing_cells:
				to_remove.append(cell)
		for cell in to_remove:
			candidates.erase(cell)

	return [positions, densities]


## Fisher-Yates shuffle using provided RNG.
func _shuffle_array(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp
