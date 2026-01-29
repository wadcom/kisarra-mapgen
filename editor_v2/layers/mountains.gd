extends RefCounted
## Mountains layer - terrain classification using Perlin noise.
##
## Generates a height map using multi-octave Perlin noise, then classifies
## each cell as SAND or MOUNTAIN based on a height threshold.
##
## ## Public API
##
## Read-only properties:
##   - height_threshold: float - current threshold (0.0-1.0)
##
## Methods:
##   - generate(map_size, mountain_percentage, seed) - generate new terrain
##   - reclassify(threshold) - re-apply threshold without regenerating
##   - has_terrain() -> bool - check if terrain exists
##   - get_terrain_at(x, y) -> TerrainType - query cell type
##   - get_actual_percentage() -> int - compute current mountain %
##
## Signal:
##   - changed - emitted after generate() or reclassify()
##

const PerlinNoise = preload("res://editor_v2/perlin_noise.gd")

signal changed

enum TerrainType { SAND, MOUNTAIN }

## Height threshold (0.0-1.0). Set during generate() or reclassify().
var height_threshold: float:
	get:
		return _height_threshold

var _height_threshold := 0.5

## Octave configuration: array of {size: int, weight: float}.
## Weights are normalized during generation.
## Note: May be exposed to users in future iterations.
var _octaves: Array[Dictionary] = [
	{size = 8, weight = 0.5},
	{size = 1, weight = 0.5},
]

## Internal height map for threshold fine-tuning. Empty until generated.
var _height_map: Array = []

## 2D array [x][y] of TerrainType values. Empty until generated.
var _terrain: Array = []


## Generates terrain based on given parameters.
## Seed is provided by caller (owned by document) for reproducible generation.
func generate(map_size: int, mountain_percentage: int, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	# Generate height map
	_height_map = PerlinNoise.generate_height_map(_octaves, map_size, rng)
	_height_threshold = _compute_threshold_for_percentage(mountain_percentage)

	# Classify cells based on computed threshold
	_classify_terrain()

	changed.emit()


## Reclassifies terrain using existing height map and given threshold.
## "Reclassify" keeps the height map (terrain shape) but re-applies the threshold,
## expanding or contracting mountain boundaries without changing the pattern.
## Stores threshold for later retrieval (e.g., UI display).
func reclassify(threshold: float) -> void:
	if _height_map.is_empty():
		return

	_height_threshold = threshold
	_classify_terrain()
	changed.emit()


## Returns true if terrain has been generated.
func has_terrain() -> bool:
	return not _terrain.is_empty()


## Returns the terrain type at the given coordinates.
## Requires terrain to be generated and coordinates to be in bounds.
func get_terrain_at(x: int, y: int) -> TerrainType:
	assert(not _terrain.is_empty(), "Terrain not generated")
	assert(x >= 0 and x < _terrain.size(), "X coordinate out of bounds")
	assert(y >= 0 and y < _terrain[x].size(), "Y coordinate out of bounds")
	return _terrain[x][y]


## Computes the actual mountain percentage from current terrain.
func get_actual_percentage() -> int:
	if _terrain.is_empty():
		return 0

	var mountain_count := 0
	var total_count := 0
	for x in _terrain.size():
		for y in _terrain[x].size():
			total_count += 1
			if _terrain[x][y] == TerrainType.MOUNTAIN:
				mountain_count += 1

	if total_count == 0:
		return 0
	return roundi(float(mountain_count) / total_count * 100)


## Internal: compute threshold value that yields the given mountain percentage.
## Uses _height_map, which must be populated before calling.
func _compute_threshold_for_percentage(mountain_percentage: int) -> float:
	var all_heights: Array[float] = []
	for x in _height_map.size():
		for y in _height_map[x].size():
			all_heights.append(_height_map[x][y])

	all_heights.sort()
	var percentile_index := int((100.0 - mountain_percentage) / 100.0 * all_heights.size())
	percentile_index = clampi(percentile_index, 0, all_heights.size() - 1)
	return all_heights[percentile_index]


## Internal: classify all cells based on current _height_threshold.
## Uses _height_map to determine map size.
func _classify_terrain() -> void:
	var map_size := _height_map.size()

	_terrain = []
	_terrain.resize(map_size)

	for x in map_size:
		_terrain[x] = []
		_terrain[x].resize(map_size)
		for y in map_size:
			if _height_map[x][y] >= _height_threshold:
				_terrain[x][y] = TerrainType.MOUNTAIN
			else:
				_terrain[x][y] = TerrainType.SAND
