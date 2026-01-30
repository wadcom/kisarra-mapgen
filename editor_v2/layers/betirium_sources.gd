extends RefCounted
## Betirium sources layer - satellite and extra source positions.
##
## Two source types:
## - Satellites: One per base, orbiting at fixed distance
## - Extras: Scattered far from all bases (exploration incentives)
##
## Each type has its own RNG seed for independent variation.
##
## ## Public API
##
## Properties:
##   - SATELLITE_* constants - satellite source parameters
##   - EXTRA_* constants - extra source parameters
##
## Methods:
##   - generate(bases, terrain, map_size, seed) - generate satellites with new seed
##   - regenerate(bases, terrain, map_size) - regenerate satellites using current seed
##   - get_satellite_seed() -> int - RNG seed for satellite placement
##   - get_satellite_positions() -> Array[Vector2i] - satellite positions (copy)
##   - generate_extras(bases, terrain, map_size, player_count, seed) - generate extras
##   - regenerate_extras(bases, terrain, map_size, player_count) - regenerate extras
##   - get_extra_seed() -> int - RNG seed for extra placement
##   - get_extra_positions() -> Array[Vector2i] - extra positions (copy)
##
## Signal:
##   - changed - emitted when positions or seed change

const EditorV2Constants = preload("res://editor_v2/constants.gd")
const BasesLayer = preload("res://editor_v2/layers/bases.gd")
const MountainsLayer = preload("res://editor_v2/layers/mountains.gd")

signal changed

## Fixed source parameters (configurable UI deferred to later).

## Distance from base to satellite in km.
const SATELLITE_DISTANCE_KM := 75.0

## Radius for density contribution in km.
const SATELLITE_RADIUS_KM := 10.0

## Density at source center (0-100).
const SATELLITE_PEAK_DENSITY := 80

## Exponential decay rate.
const SATELLITE_DECAY_FACTOR := 0.3

## Extra source parameters.

## Number of extras per two players (integer division).
const EXTRA_COUNT_PER_TWO_PLAYERS := 1

## Minimum distance from any base as fraction of map size.
const EXTRA_DISTANCE_FRACTION := 0.4

## Radius for density contribution in km.
const EXTRA_RADIUS_KM := 20.0

## Density at source center (0-100).
const EXTRA_PEAK_DENSITY := 100

## Exponential decay rate.
const EXTRA_DECAY_FACTOR := 0.35

## Source positions as cell coordinates.
## One satellite source per player, indexed by player number.
var _satellite_positions: Array[Vector2i] = []

## RNG seed for satellite source placement.
var _satellite_seed: int = 0

## Extra source positions as cell coordinates.
var _extra_positions: Array[Vector2i] = []

## RNG seed for extra source placement.
var _extra_seed: int = 0


## Returns the RNG seed for satellite placement.
func get_satellite_seed() -> int:
	return _satellite_seed


## Returns satellite positions (read-only copy).
func get_satellite_positions() -> Array[Vector2i]:
	var copy: Array[Vector2i] = []
	copy.assign(_satellite_positions)
	return copy


## Returns the RNG seed for extra placement.
func get_extra_seed() -> int:
	return _extra_seed


## Returns extra positions (read-only copy).
func get_extra_positions() -> Array[Vector2i]:
	var copy: Array[Vector2i] = []
	copy.assign(_extra_positions)
	return copy


## Generates satellite source positions using orbit placement.
##
## Algorithm:
## 1. For each base, calculate orbit circle at SATELLITE_DISTANCE_KM
## 2. Build list of valid candidate cells around orbit (every degree)
## 3. Pick one randomly using provided RNG
func generate(bases: BasesLayer, terrain: MountainsLayer, map_size: int, seed_value: int) -> void:
	_satellite_seed = seed_value
	_satellite_positions = _pick_satellite_positions(bases, terrain, map_size, seed_value)
	changed.emit()


## Regenerates satellites using the current seed.
func regenerate(bases: BasesLayer, terrain: MountainsLayer, map_size: int) -> void:
	_satellite_positions = _pick_satellite_positions(bases, terrain, map_size, _satellite_seed)
	changed.emit()


func _pick_satellite_positions(
	bases: BasesLayer, terrain: MountainsLayer, map_size: int, seed_value: int,
) -> Array[Vector2i]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var cell_side_km := EditorV2Constants.CELL_SIDE_KMS
	var radius_cells := SATELLITE_DISTANCE_KM / cell_side_km
	var edge_buffer := 2.0  # Keep satellites at least 2 cells from edge

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


## Generates extra source positions far from all bases.
##
## Algorithm:
## 1. Build list of valid cells (sand, 300km+ from all bases, 2+ cells from edge)
## 2. Pick count random cells (player_count / 2)
func generate_extras(
	bases: BasesLayer, terrain: MountainsLayer, map_size: int, player_count: int, seed_value: int,
) -> void:
	_extra_seed = seed_value
	_extra_positions = _pick_extra_positions(bases, terrain, map_size, player_count, seed_value)
	changed.emit()


## Regenerates extras using the current seed.
func regenerate_extras(
	bases: BasesLayer, terrain: MountainsLayer, map_size: int, player_count: int,
) -> void:
	_extra_positions = _pick_extra_positions(bases, terrain, map_size, player_count, _extra_seed)
	changed.emit()


func _pick_extra_positions(
	bases: BasesLayer, terrain: MountainsLayer, map_size: int, player_count: int, seed_value: int,
) -> Array[Vector2i]:
	var count := player_count / 2  # Integer division
	if count <= 0:
		return []

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var min_distance_cells := map_size * EXTRA_DISTANCE_FRACTION
	var edge_buffer := 2

	# Build list of valid candidate cells
	var candidates: Array[Vector2i] = []
	var base_positions := bases.get_positions()

	for x in range(edge_buffer, map_size - edge_buffer):
		for y in range(edge_buffer, map_size - edge_buffer):
			# Check terrain (must be sand)
			if terrain.get_terrain_at(x, y) != MountainsLayer.TerrainType.SAND:
				continue

			# Check distance from all bases
			var cell_center := Vector2(x + 0.5, y + 0.5)
			var far_enough := true
			for base_pos in base_positions:
				var base_center := Vector2(base_pos.x + 0.5, base_pos.y + 0.5)
				if cell_center.distance_to(base_center) < min_distance_cells:
					far_enough = false
					break

			if far_enough:
				candidates.append(Vector2i(x, y))

	# Pick random cells from candidates
	var positions: Array[Vector2i] = []
	for i in count:
		if candidates.is_empty():
			break
		var index := rng.randi_range(0, candidates.size() - 1)
		positions.append(candidates[index])
		candidates.remove_at(index)  # No duplicates

	return positions
