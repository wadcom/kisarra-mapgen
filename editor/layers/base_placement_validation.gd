extends RefCounted
## Balance rules that accept or reject a generated base placement.
##
## Every rule reads a distance matrix and nothing else. The matrix holds
## navigation distances in cells: matrix[i][j] is the distance between base i
## and base j, and INF when no path exists. The matrix is symmetric, because
## travel cost over the terrain grid does not depend on the direction of
## travel. Values on the diagonal are never read.
##
## Keeping the rules free of terrain and grid types makes them testable
## against hand-written matrices, with no pathfinder and no scene tree.
##
## ## Public API
##
## Methods: compute_vulnerability()


## Counts, for each base, how many other bases treat it as their nearest
## opponent. Returns [count ...] indexed by base, summing to the number of
## bases that have at least one reachable opponent.
##
## A base with no reachable opponent casts no vote. Equal distances resolve to
## the lowest base index.
static func compute_vulnerability(distances: Array) -> Array[int]:
	var counts: Array[int] = []
	counts.resize(distances.size())
	counts.fill(0)

	for attacker in distances.size():
		var target := _nearest_opponent(distances, attacker)
		if target >= 0:
			counts[target] += 1

	return counts


## Returns the index of the closest reachable base to the given one, or -1 when
## every other base is unreachable.
static func _nearest_opponent(distances: Array, attacker: int) -> int:
	var nearest := -1
	var shortest := INF

	for target in distances.size():
		if target == attacker:
			continue
		var distance: float = distances[attacker][target]
		if distance < shortest:
			shortest = distance
			nearest = target

	return nearest
