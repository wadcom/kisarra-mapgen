extends RefCounted
## Betirium sources layer - satellite source positions with orbit placement.
##
## Each base has one satellite source orbiting at a fixed distance. Sources have
## their own RNG seed separate from bases, allowing users to try different
## placements while keeping the same base positions.
##
## ## Public API
##
## Properties:
##   - SATELLITE_* constants - fixed source parameters
##
## Methods:
##   - generate(bases, terrain, map_size, seed) - generate positions with new seed
##   - regenerate(bases, terrain, map_size) - regenerate using current seed
##   - get_satellite_seed() -> int - RNG seed for satellite placement
##   - get_satellite_positions() -> Array[Vector2i] - returns satellite positions (copy)
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

## Source positions as cell coordinates.
## One satellite source per player, indexed by player number.
var _satellite_positions: Array[Vector2i] = []

## RNG seed for satellite source placement.
var _satellite_seed: int = 0


## Returns the RNG seed for satellite placement.
func get_satellite_seed() -> int:
	return _satellite_seed


## Returns satellite positions (read-only copy).
func get_satellite_positions() -> Array[Vector2i]:
	var copy: Array[Vector2i] = []
	copy.assign(_satellite_positions)
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
