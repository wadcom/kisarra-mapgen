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
## Methods: compute_isolation_ratio(), compute_vulnerability()


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


## Number of nearest opponents that the isolation score adds up.
const ISOLATION_OPPONENT_COUNT := 2


## Returns the ratio between the most isolated and the least isolated base.
## A ratio of 1.0 means every base is equally well connected to its nearest
## opponents. Larger values mean some base sits further out than the rest.
##
## The ratio is INF when any base lacks a second reachable opponent. That case
## needs its own answer, because dividing INF by INF would give NaN, and NaN
## compares false against every limit.
##
## Fewer than two bases gives 1.0. No pair of bases exists, so no base can be
## more isolated than another.
static func compute_isolation_ratio(distances: Array) -> float:
	if distances.size() < 2:
		return 1.0

	var scores: Array[float] = []
	for base in distances.size():
		scores.append(_isolation_score(distances, base))

	var most_isolated: float = scores.max()
	if most_isolated == INF:
		return INF

	return most_isolated / scores.min()


## Returns the sum of the distances to the base's nearest opponents, over at
## most ISOLATION_OPPONENT_COUNT of them. The sum is INF when any of those
## opponents is unreachable.
static func _isolation_score(distances: Array, base: int) -> float:
	var others: Array[float] = []
	for other in distances.size():
		if other != base:
			others.append(distances[base][other])
	others.sort()

	var total := 0.0
	for rank in mini(ISOLATION_OPPONENT_COUNT, others.size()):
		total += others[rank]
	return total
