extends "res://tests/assertions.gd"

const BasesLayer = preload("res://editor/layers/bases.gd")
const FakeTerrain = preload("res://tests/fake_terrain.gd")

const MAP_SIZE := 30
const PLAYER_COUNT := 4


## Returns square terrain with every cell set to one character: "." for open
## sand, "#" for solid mountain.
func _uniform_terrain(cell: String) -> FakeTerrain:
	var rows: Array = []
	for _y in MAP_SIZE:
		rows.append(cell.repeat(MAP_SIZE))
	return FakeTerrain.new(rows)


## Terrain cut in two by a wall three cells wide. Four bases fit on one side
## only in a tight zig-zag that the greedy pick never finds, so in practice
## every attempt straddles the wall: one base against three, leaving three
## unreachable pairs, or two against two, leaving four.
func _split_terrain() -> FakeTerrain:
	var rows: Array = []
	for _y in MAP_SIZE:
		rows.append(".".repeat(14) + "###" + ".".repeat(MAP_SIZE - 17))
	return FakeTerrain.new(rows)


## A pocket four cells across, and a strip seven columns wide, with no route
## between them. The pocket holds one base and the strip holds three at the
## minimum spacing, so every complete placement splits one against three.
func _pocket_and_strip_terrain() -> FakeTerrain:
	var rows: Array = []
	for y in MAP_SIZE:
		var row := ""
		for x in MAP_SIZE:
			var pocket := x >= 3 and x <= 6 and y >= 3 and y <= 6
			var strip := x >= 20 and x <= 26 and y >= 3 and y <= 26
			row += "." if pocket or strip else "#"
		rows.append(row)
	return FakeTerrain.new(rows)


## A corridor one cell wide and eighteen tall. Two bases fit at the minimum
## spacing, but only when the first pick lands near an end: a pick in the
## middle leaves no room and the attempt stops at one base.
func _corridor_terrain() -> FakeTerrain:
	var rows: Array = []
	for y in MAP_SIZE:
		if y >= 3 and y <= 20:
			rows.append("###." + "#".repeat(MAP_SIZE - 4))
		else:
			rows.append("#".repeat(MAP_SIZE))
	return FakeTerrain.new(rows)


# --- Retrying until the rules pass ---


## Seed 8's first shuffle fills every player slot but breaks a rule, so
## acceptance here can only come from a later attempt. A complete placement is
## not necessarily a balanced one.
func test_generate_on_open_sand_retries_until_every_rule_passes() -> void:
	var bases := BasesLayer.new()
	bases.generate(_uniform_terrain("."), MAP_SIZE, PLAYER_COUNT, 8)
	assert_eq(bases.get_positions().size(), PLAYER_COUNT)
	assert_eq(bases.get_validation_failures(), [] as Array[String])


## Seed 2's first attempt on the corridor places a single base, which breaks
## no rule: the rules need two bases before they can compare anything. Fewer
## bases than players is not a placement, however balanced it reads, so
## generation must keep going and return the two that fit.
func test_generate_keeps_looking_after_a_partial_placement_breaks_no_rule() -> void:
	var bases := BasesLayer.new()
	bases.generate(_corridor_terrain(), MAP_SIZE, PLAYER_COUNT, 2)
	assert_eq(bases.get_positions().size(), 2)
	assert_eq(bases.get_validation_failures(), [] as Array[String])


## The undo command regenerates from the previous seed instead of storing
## positions, so one seed must always give one placement.
func test_generate_repeats_a_placement_for_the_same_seed() -> void:
	var first := BasesLayer.new()
	var second := BasesLayer.new()
	first.generate(_uniform_terrain("."), MAP_SIZE, PLAYER_COUNT, 7)
	second.generate(_uniform_terrain("."), MAP_SIZE, PLAYER_COUNT, 7)
	assert_eq(first.get_positions(), second.get_positions())


# --- Keeping the closest attempt when none can pass ---


## Nothing on this terrain can pass, so generation spends its whole budget and
## then keeps the attempt closest to passing. It still returns a full set of
## bases, and it still says what is wrong with them.
func test_generate_keeps_the_closest_attempt_when_none_can_pass() -> void:
	var bases := BasesLayer.new()
	bases.generate(_pocket_and_strip_terrain(), MAP_SIZE, PLAYER_COUNT, 1)
	assert_eq(bases.get_positions().size(), PLAYER_COUNT)
	assert_eq(bases.get_validation_failures(), [
		"Unreachable base pairs: 3 of 6.",
		"Some bases have fewer than two reachable opponents.",
	] as Array[String])


## Splitting four bases one against three leaves three unreachable pairs and a
## penalty of 1.5, while two against two leaves four pairs and a penalty of
## 1.667. Both fail, so generation must keep the one that breaks least.
func test_generate_keeps_the_least_broken_placement() -> void:
	var bases := BasesLayer.new()
	bases.generate(_split_terrain(), MAP_SIZE, PLAYER_COUNT, 1)
	assert_eq(bases.get_validation_failures()[0], "Unreachable base pairs: 3 of 6.")


## Terrain with no sand offers no candidate cell, so generation returns before
## it judges anything. An earlier run's failures must not linger.
func test_generate_clears_earlier_failures_when_no_cell_can_hold_a_base() -> void:
	var bases := BasesLayer.new()
	bases.generate(_split_terrain(), MAP_SIZE, PLAYER_COUNT, 1)
	assert_eq(bases.get_validation_failures()[0], "Unreachable base pairs: 3 of 6.")

	bases.generate(_uniform_terrain("#"), MAP_SIZE, PLAYER_COUNT, 1)
	assert_eq(bases.get_positions(), [] as Array[Vector2i])
	assert_eq(bases.get_validation_failures(), [] as Array[String])


# --- Ranking policy: which attempt generation keeps ---
#
# A placement missing a player is unusable however balanced it is, so the
# ranking cannot be expressed as one number. These cases fix the order that
# the generation loop applies to every attempt.


func test_ranking_prefers_more_bases_even_when_less_balanced() -> void:
	assert_eq(BasesLayer._beats_best(2, 9.0, 1, 0.0), true)


func test_ranking_rejects_fewer_bases_even_when_better_balanced() -> void:
	assert_eq(BasesLayer._beats_best(1, 0.0, 2, 9.0), false)


func test_ranking_prefers_the_lower_penalty_between_equal_sized_placements() -> void:
	assert_eq(BasesLayer._beats_best(4, 0.5, 4, 1.0), true)


## A tie keeps the placement already held, so the earliest of several equally
## good attempts is the one that survives.
func test_ranking_keeps_the_incumbent_on_a_tie() -> void:
	assert_eq(BasesLayer._beats_best(4, 1.0, 4, 1.0), false)
