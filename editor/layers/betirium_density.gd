extends RefCounted
## Betirium density layer - dual 2D grids computed from sources.
##
## Computes two grids:
##   - Content: initial betirium from all deposits (home + ambient)
##   - Regeneration rate: ongoing production from home deposits only
##
## Density is a pure derived layer with no RNG - it's deterministically
## computed from source positions and their parameters.
##
## ## Public API
##
## Methods:
##   - calculate(sources, map_size) - compute both grids from sources
##   - get_content_at(x, y) -> int - query initial content at cell (0-100)
##   - get_regen_rate_at(x, y) -> int - query regeneration rate at cell (0-100)
##
## Signal:
##   - changed - emitted after calculate()

const EditorV2Constants = preload("res://editor/constants.gd")
const BetiriumSourcesLayer = preload("res://editor/layers/betirium_sources.gd")

signal changed

## 2D content grid (initial betirium from home + ambient). Values are integers 0-100.
## Indexed as _content[x][y] matching Godot coordinates.
var _content: Array[Array] = []

## 2D regeneration rate grid (from home deposits only). Values are integers 0-100.
## Indexed as _regen_rate[x][y] matching Godot coordinates.
var _regen_rate: Array[Array] = []


## Returns the initial content at the given coordinates (0-100).
## Returns 0 if content hasn't been calculated yet.
func get_content_at(x: int, y: int) -> int:
	assert(x >= 0 and x < _content.size(), "x coordinate out of bounds: %d" % x)
	assert(y >= 0 and y < _content[x].size(), "y coordinate out of bounds: %d" % y)

	if _content.is_empty():
		return 0

	return _content[x][y]


## Returns the regeneration rate at the given coordinates (0-100).
## Returns 0 if regeneration rate hasn't been calculated yet.
func get_regen_rate_at(x: int, y: int) -> int:
	assert(x >= 0 and x < _regen_rate.size(), "x coordinate out of bounds: %d" % x)
	assert(y >= 0 and y < _regen_rate[x].size(), "y coordinate out of bounds: %d" % y)

	if _regen_rate.is_empty():
		return 0

	return _regen_rate[x][y]


## Calculates both grids from sources using exponential decay.
##
## Content grid: sum contributions from home + ambient deposits
## Regeneration rate grid: sum contributions from home deposits only
##
## For each cell, sums contributions from all sources:
## - If within source radius: peak density
## - If outside radius: peak * (decay_factor ^ distance_in_cells)
func calculate(sources: BetiriumSourcesLayer, map_size: int) -> void:
	_content = _compute_grid(sources, map_size, true)
	_regen_rate = _compute_grid(sources, map_size, false)
	changed.emit()


func _compute_grid(
	sources: BetiriumSourcesLayer, map_size: int, include_ambient: bool,
) -> Array[Array]:
	var grid: Array[Array] = []
	grid.resize(map_size)

	var home_positions := sources.get_home_deposit_positions()
	var home_densities := _uniform_densities(
		home_positions.size(), BetiriumSourcesLayer.HOME_DEPOSIT_PEAK_DENSITY,
	)
	var ambient_positions := sources.get_ambient_positions()
	var ambient_densities := sources.get_ambient_peak_densities()

	for x in map_size:
		var column: Array[int] = []
		column.resize(map_size)
		for y in map_size:
			var cell_center := Vector2(x + 0.5, y + 0.5)
			var total := 0.0

			total += _compute_source_contributions(
				cell_center, home_positions,
				BetiriumSourcesLayer.HOME_DEPOSIT_RADIUS_KM,
				home_densities,
				BetiriumSourcesLayer.HOME_DEPOSIT_DECAY_FACTOR,
			)

			if include_ambient:
				total += _compute_source_contributions(
					cell_center, ambient_positions,
					BetiriumSourcesLayer.AMBIENT_RADIUS_KM,
					ambient_densities,
					BetiriumSourcesLayer.AMBIENT_DECAY_FACTOR,
				)

			column[y] = clampi(int(total), 0, 100)
		grid[x] = column

	return grid


## Computes density contributions from a set of sources at a given cell.
func _compute_source_contributions(
	cell_center: Vector2, positions: Array[Vector2i],
	radius_km: float, peak_densities: Array[int], decay_factor: float,
) -> float:
	var cell_side_km := EditorV2Constants.CELL_SIDE_KMS
	var total := 0.0

	for i in positions.size():
		var source_pos := positions[i]
		var peak_density := peak_densities[i]
		var source_center := Vector2(source_pos.x + 0.5, source_pos.y + 0.5)
		var distance_cells := cell_center.distance_to(source_center)
		var distance_km := distance_cells * cell_side_km

		var contribution: float
		if distance_km <= radius_km:
			# Within source radius: full peak density
			contribution = peak_density
		else:
			# Outside radius: exponential decay
			var decay_distance_cells := (distance_km - radius_km) / cell_side_km
			contribution = peak_density * pow(decay_factor, decay_distance_cells)

		total += contribution

	return total


## Creates an array of uniform density values.
func _uniform_densities(count: int, value: int) -> Array[int]:
	var result: Array[int] = []
	result.resize(count)
	result.fill(value)
	return result
