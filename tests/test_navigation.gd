extends "res://tests/assertions.gd"

const FakeTerrain = preload("res://tests/fake_terrain.gd")
const Navigation = preload("res://editor/navigation.gd")


## Builds a navigation grid over ASCII terrain.
func _navigation_over(rows: Array) -> Navigation:
	var terrain := FakeTerrain.new(rows)
	return Navigation.new(terrain, terrain.size())


## Two bases two cells apart on open sand, with nothing to walk around.
func test_distance_across_open_sand_counts_cells() -> void:
	var matrix := _navigation_over(["...", "...", "..."]).distance_matrix([
		Vector2i(0, 0), Vector2i(2, 0),
	])
	assert_eq(matrix[0][1], 2.0)


## A wall fills the middle column except for the bottom row, so the route runs
## down one side, across the gap, and back up: 1 + sqrt(2) + sqrt(2) + 1. The
## straight line would be 2, so the wall more than doubles the distance.
##
## Counting steps rather than measuring them would give 4.0, and forbidding
## diagonal movement would give 6.0.
func test_distance_follows_the_route_around_a_wall() -> void:
	var matrix := _navigation_over([".#.", ".#.", "..."]).distance_matrix([
		Vector2i(0, 0), Vector2i(2, 0),
	])
	assert_almost_eq(matrix[0][1], 4.828, 0.001)


## Base (0, 0) touches its neighbour only at a corner, with mountains on both
## sides. Corner cutting is allowed, so the two are one diagonal step apart.
## Forbidding it would seal base (0, 0) in and give INF.
func test_bases_touching_only_at_a_corner_are_one_step_apart() -> void:
	var matrix := _navigation_over([".#.", "#..", "..."]).distance_matrix([
		Vector2i(0, 0), Vector2i(1, 1),
	])
	assert_almost_eq(matrix[0][1], 1.414, 0.001)


## Mountains ring base (2, 2) on all eight sides, so no route reaches it.
func test_an_enclosed_base_is_unreachable() -> void:
	var matrix := _navigation_over([
		".....",
		".###.",
		".#.#.",
		".###.",
		".....",
	]).distance_matrix([Vector2i(0, 0), Vector2i(2, 2)])
	assert_eq(matrix[0][1], INF)


## A base belongs on sand. A mountain cell has no route anywhere, while its own
## diagonal still reads 0.0, because a cell always reaches itself at no cost.
func test_a_base_on_a_mountain_cell_reaches_nobody() -> void:
	var matrix := _navigation_over([".#.", "...", "..."]).distance_matrix([
		Vector2i(0, 0), Vector2i(1, 0),
	])
	assert_eq(matrix[0][1], INF)
	assert_eq(matrix[1][1], 0.0)


## The balance rules read only one direction of each pair and rely on the
## matrix being symmetric, so a wall between two bases must not make the trip
## cost more one way than the other. The reverse direction is checked against
## the route cost itself, because comparing the two cells to each other would
## also hold if both stayed at 0.0.
func test_the_matrix_is_symmetric_across_a_wall() -> void:
	var matrix := _navigation_over([".#.", ".#.", "..."]).distance_matrix([
		Vector2i(0, 0), Vector2i(2, 0),
	])
	assert_almost_eq(matrix[1][0], 4.828, 0.001)


## Three bases give a three by three matrix whose diagonal holds 0.0, because
## the rules skip the diagonal and never read a base's distance to itself.
## Bases 1 and 2 are not neighbours in index order, so their cell proves that
## every pair gets filled rather than only consecutive ones.
func test_the_matrix_is_square_with_a_zero_diagonal() -> void:
	var matrix := _navigation_over(["...", "...", "..."]).distance_matrix([
		Vector2i(0, 0), Vector2i(2, 0), Vector2i(0, 2),
	])
	assert_eq(matrix.size(), 3)
	assert_eq([matrix[0].size(), matrix[1].size(), matrix[2].size()], [3, 3, 3])
	assert_eq([matrix[0][0], matrix[1][1], matrix[2][2]], [0.0, 0.0, 0.0])
	assert_eq(matrix[0][2], 2.0)
	assert_almost_eq(matrix[1][2], 2.828, 0.001)


## Generation reuses one instance for every placement attempt on a terrain,
## which is what makes the grid setup a one-off cost. An earlier query must
## leave nothing behind that changes a later answer.
func test_one_instance_answers_many_placements() -> void:
	var navigation := _navigation_over([".#.", ".#.", "..."])
	navigation.distance_matrix([Vector2i(0, 0), Vector2i(2, 2)])
	var matrix := navigation.distance_matrix([Vector2i(0, 0), Vector2i(2, 0)])
	assert_almost_eq(matrix[0][1], 4.828, 0.001)


## Placement can stop early and leave one base, or none at all.
func test_a_placement_too_small_to_compare_gives_a_tiny_matrix() -> void:
	var navigation := _navigation_over(["...", "...", "..."])
	assert_eq(navigation.distance_matrix([]), [])
	assert_eq(navigation.distance_matrix([Vector2i(1, 1)]), [[0.0]])
