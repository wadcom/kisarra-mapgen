extends RefCounted
## Navigation distances between cells over passable terrain.
##
## Wraps Godot's AStarGrid2D, whose search runs in C++. Build one instance per
## terrain and then query it for as many base placements as needed: the grid
## setup runs once, and each query only searches.
##
## ## Public API
##
## Methods: distance_matrix()

const MountainsLayer = preload("res://editor/layers/mountains.gd")

var _grid := AStarGrid2D.new()


## Builds the search grid over the terrain, marking mountain cells solid.
##
## Movement runs in eight directions. An orthogonal step costs 1 cell and a diagonal step costs the
## square root of 2. A diagonal step between two mountains that touch at a
## corner is allowed.
func _init(terrain: MountainsLayer, map_size: int) -> void:
	_grid.region = Rect2i(0, 0, map_size, map_size)
	_grid.cell_size = Vector2.ONE
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.update()

	for x in map_size:
		for y in map_size:
			if terrain.get_terrain_at(x, y) == MountainsLayer.TerrainType.MOUNTAIN:
				_grid.set_point_solid(Vector2i(x, y), true)


## Returns the navigation distance between every pair of positions, in cells.
## Returns [[float ...] ...] indexed by position: symmetric, INF where no path
## exists, and 0.0 on the diagonal.
##
## Every position must lie inside the map and stand on passable terrain. A
## position on a mountain reaches nothing, and one outside the map makes the
## engine report an error and answer that no route exists.
func distance_matrix(positions: Array) -> Array:
	var matrix := []
	for _row in positions.size():
		var values := []
		values.resize(positions.size())
		values.fill(0.0)
		matrix.append(values)

	for a in positions.size():
		for b in range(a + 1, positions.size()):
			var distance := _path_length(positions[a], positions[b])
			matrix[a][b] = distance
			matrix[b][a] = distance

	return matrix


## Returns the length of the shortest path between two cells, or INF when no
## path exists.
func _path_length(from: Vector2i, to: Vector2i) -> float:
	var path := _grid.get_point_path(from, to)
	if path.is_empty():
		return INF

	var total := 0.0
	for step in range(1, path.size()):
		total += path[step].distance_to(path[step - 1])
	return total
