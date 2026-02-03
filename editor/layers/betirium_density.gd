extends RefCounted
## Betirium density layer - 2D density grid computed from sources.
##
## Density is a pure derived layer with no RNG - it's deterministically
## computed from source positions and their parameters.
##
## ## Public API
##
## Methods:
##   - calculate(sources, map_size) - compute density grid from sources
##   - get_density_at(x, y) -> int - query density at cell (0-100)
##
## Signal:
##   - changed - emitted after calculate()

const EditorV2Constants = preload("res://editor/constants.gd")
const BetiriumSourcesLayer = preload("res://editor/layers/betirium_sources.gd")

signal changed

## 2D density grid. Values are integers 0-100.
## Indexed as _density[x][y] matching Godot coordinates.
var _density: Array[Array] = []


## Returns the density at the given coordinates (0-100).
## Returns 0 if density hasn't been calculated yet.
func get_density_at(x: int, y: int) -> int:
	assert(x >= 0 and x < _density.size(), "x coordinate out of bounds: %d" % x)
	assert(y >= 0 and y < _density[x].size(), "y coordinate out of bounds: %d" % y)

	if _density.is_empty():
		return 0

	return _density[x][y]


## Calculates density grid from sources using exponential decay.
##
## For each cell, sums contributions from all sources:
## - If within source radius: peak density
## - If outside radius: peak * (decay_factor ^ distance_in_cells)
func calculate(sources: BetiriumSourcesLayer, map_size: int) -> void:
	_density = _compute_density_grid(sources, map_size)
	changed.emit()


func _compute_density_grid(sources: BetiriumSourcesLayer, map_size: int) -> Array[Array]:
	var grid: Array[Array] = []
	grid.resize(map_size)

	var cell_side_km := EditorV2Constants.CELL_SIDE_KMS

	for x in map_size:
		var column: Array[int] = []
		column.resize(map_size)
		for y in map_size:
			var cell_center := Vector2(x + 0.5, y + 0.5)
			var total := 0.0

			# Sum contributions from home deposits
			total += _compute_source_contributions(
				cell_center, sources.get_home_deposit_positions(), cell_side_km,
				BetiriumSourcesLayer.HOME_DEPOSIT_RADIUS_KM,
				BetiriumSourcesLayer.HOME_DEPOSIT_PEAK_DENSITY,
				BetiriumSourcesLayer.HOME_DEPOSIT_DECAY_FACTOR,
			)

			column[y] = clampi(int(total), 0, 100)
		grid[x] = column

	return grid


## Computes density contributions from a set of sources at a given cell.
func _compute_source_contributions(
	cell_center: Vector2, positions: Array[Vector2i], cell_side_km: float,
	radius_km: float, peak_density: int, decay_factor: float,
) -> float:
	var total := 0.0

	for source_pos in positions:
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
