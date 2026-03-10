extends RefCounted
## Bases layer - player base positions with constraint-based placement.
##
## Each base corresponds to a player (indexed by player number). Bases have
## their own RNG seed separate from terrain, allowing users to try different
## placements while keeping the same terrain.
##
## ## Public API
##
## Properties: rng_seed
## Methods: generate(), get_positions(), get_constraint_params()
## Signal: changed

const EditorV2Constants = preload("res://editor/constants.gd")
const MountainsLayer = preload("res://editor/layers/mountains.gd")

signal changed

## Placement constraints (currently fixed, UI controls may be added later).

## Central dead zone diameter as fraction of map size (0.0 to 1.0).
const CENTRAL_DEAD_ZONE_DIAMETER_FRACTION := 0.3

const MIN_DIST_TO_EDGE_KM := 60.0

## Minimum inter-base distance as fraction of map size (0.0 to 1.0).
## Scales linearly from MAX (2 players) to MIN (9 players).
const MIN_DIST_BETWEEN_BASES_FRACTION_MAX := 0.4
const MIN_DIST_BETWEEN_BASES_FRACTION_MIN := 0.3
const MIN_PLAYER_COUNT := 2
const MAX_PLAYER_COUNT := 9

## Number of placement attempts with different shuffles before giving up.
const PLACEMENT_RETRY_COUNT := 100

## Base positions as cell coordinates.
## One base per player, indexed by player number.
var _positions: Array[Vector2i] = []

## RNG seed for base placement (separate from terrain seed).
var rng_seed: int:
	get:
		return _seed
	set(value):
		_seed = value
		changed.emit()

var _seed: int = 0


## Generates base positions using constraint-based placement.
##
## Algorithm:
## 1. Build list of valid candidate cells (sand, outside dead zone, away from edges)
## 2. Shuffle candidates using provided RNG
## 3. For each player, pop a candidate and filter remaining by inter-base distance
func generate(terrain: MountainsLayer, map_size: int, player_count: int, seed_value: int) -> void:
	_seed = seed_value
	_positions = _pick_positions(terrain, map_size, player_count, seed_value)
	changed.emit()


## Returns base positions (read-only copy).
func get_positions() -> Array[Vector2i]:
	var copy: Array[Vector2i] = []
	copy.assign(_positions)
	return copy


## Returns computed constraint parameters for a given map size.
## All values are in cell units.
##
## Returns:
##   - dead_zone_radius: float - radius of central exclusion zone
##   - edge_buffer: float - width of edge exclusion zone
##   - inter_base_distance: float - minimum distance between base centers
##   - inter_base_radius: float - half of inter_base_distance (for visualization:
##       circles of this radius around each base will just touch when bases are
##       at minimum distance)
func get_constraint_params(map_size: int, player_count: int) -> Dictionary:
	var cell_side_km := EditorV2Constants.CELL_SIDE_KMS
	var dead_zone_radius := (map_size * CENTRAL_DEAD_ZONE_DIAMETER_FRACTION) / 2.0
	var edge_buffer := MIN_DIST_TO_EDGE_KM / cell_side_km
	var fraction := _inter_base_fraction(player_count)
	var inter_base_distance := map_size * fraction

	return {
		dead_zone_radius = dead_zone_radius,
		edge_buffer = edge_buffer,
		inter_base_distance = inter_base_distance,
		inter_base_radius = inter_base_distance / 2.0,
	}


## Linearly interpolates inter-base fraction from MAX (2 players) to MIN (9 players).
static func _inter_base_fraction(player_count: int) -> float:
	var t := float(player_count - MIN_PLAYER_COUNT) / (MAX_PLAYER_COUNT - MIN_PLAYER_COUNT)
	return lerpf(MIN_DIST_BETWEEN_BASES_FRACTION_MAX, MIN_DIST_BETWEEN_BASES_FRACTION_MIN, t)


func _pick_positions(
	terrain: MountainsLayer, map_size: int,
	player_count: int, seed_value: int,
) -> Array[Vector2i]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var params := get_constraint_params(map_size, player_count)
	var candidates := _build_candidates(terrain, map_size, params)

	if candidates.is_empty():
		return [] as Array[Vector2i]

	# Try multiple shuffles, keep the best result
	var best_positions: Array[Vector2i] = []
	for attempt in PLACEMENT_RETRY_COUNT:
		var positions := _try_place_bases(
			candidates.duplicate(), player_count, params.inter_base_distance, rng,
		)

		if positions.size() > best_positions.size():
			best_positions = positions

		if best_positions.size() >= player_count:
			break

	return best_positions


## Returns all sand cells satisfying dead zone and edge constraints.
func _build_candidates(
	terrain: MountainsLayer, map_size: int, params: Dictionary,
) -> Array[Vector2i]:
	var dead_zone_cells: float = params.dead_zone_radius
	var edge_buffer_cells: float = params.edge_buffer
	var map_center := Vector2(map_size / 2.0, map_size / 2.0)

	var candidates: Array[Vector2i] = []
	for x in map_size:
		for y in map_size:
			if terrain.get_terrain_at(x, y) != MountainsLayer.TerrainType.SAND:
				continue

			var cell_center := Vector2(x + 0.5, y + 0.5)

			if cell_center.distance_to(map_center) < dead_zone_cells:
				continue

			if x < edge_buffer_cells or x >= map_size - edge_buffer_cells:
				continue

			if y < edge_buffer_cells or y >= map_size - edge_buffer_cells:
				continue

			candidates.append(Vector2i(x, y))

	return candidates


## Greedy placement: shuffle candidates, pick one per player, filtering by inter-base distance after 
## each pick.
func _try_place_bases(
	candidates: Array[Vector2i], 
	player_count: int,
	inter_base_cells: float, 
	rng: RandomNumberGenerator,
) -> Array[Vector2i]:
	_shuffle_array(candidates, rng)

	var positions: Array[Vector2i] = []
	for i in player_count:
		if candidates.is_empty():
			break

		var pos: Vector2i = candidates.pop_back()
		positions.append(pos)

		var pos_center := Vector2(pos.x + 0.5, pos.y + 0.5)
		var filtered: Array[Vector2i] = []
		for candidate in candidates:
			var center := Vector2(candidate.x + 0.5, candidate.y + 0.5)
			if center.distance_to(pos_center) >= inter_base_cells:
				filtered.append(candidate)
		candidates = filtered

	return positions


func _shuffle_array(arr: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp := arr[i]
		arr[i] = arr[j]
		arr[j] = temp
