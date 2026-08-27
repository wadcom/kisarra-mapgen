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
## Methods: compute_isolation_ratio(), compute_vulnerability(), validate()


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


## Highest number of opponents that may treat one base as their first target.
const MAX_VULNERABILITY := 2

## Highest ratio allowed between the most and the least isolated base.
const MAX_ISOLATION_RATIO := 1.3

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


## Runs every balance rule over a placement and reports the outcome.
##
## Returns:
##   - accepted: bool - true when every rule passes
##   - failures: Array[String] - one sentence per broken rule, empty when
##       accepted. Ready to show to the user.
##   - penalty: float - 0.0 when accepted, larger the further the placement
##       sits from passing. Lets a caller keep the closest of several attempts.
##       Each rule adds at most 1.0, so the penalty never reaches INF and
##       always orders one rejected placement against another. That ceiling
##       makes the penalty order near misses rather than disasters: two badly
##       broken placements both saturate and tie.
static func validate(distances: Array) -> Dictionary:
	var failures: Array[String] = []

	var penalty := 0.0

	var pair_count := distances.size() * (distances.size() - 1) / 2
	var unreachable := _count_unreachable_pairs(distances)
	if unreachable > 0:
		penalty += float(unreachable) / pair_count
		failures.append("Unreachable base pairs: %d of %d." % [unreachable, pair_count])

	var counts := compute_vulnerability(distances)
	var most_targeted: int = counts.max() if not counts.is_empty() else 0
	penalty += _overshoot(most_targeted, MAX_VULNERABILITY)
	if most_targeted > MAX_VULNERABILITY:
		failures.append("Base %d is the first target of %d opponents (limit %d)." % [
			counts.find(most_targeted), most_targeted, MAX_VULNERABILITY,
		])

	var ratio := compute_isolation_ratio(distances)
	penalty += _overshoot(ratio, MAX_ISOLATION_RATIO)
	if ratio == INF:
		failures.append("Some bases have fewer than two reachable opponents.")
	elif ratio > MAX_ISOLATION_RATIO:
		failures.append("Isolation ratio %.2f (limit %.2f)." % [ratio, MAX_ISOLATION_RATIO])

	return {accepted = failures.is_empty(), failures = failures, penalty = penalty}


## Returns how far a value overshoots its limit, as a fraction of that limit,
## bounded to the range 0.0 to 1.0. A value at or under the limit gives 0.0,
## and an infinite value gives 1.0.
static func _overshoot(value: float, limit: float) -> float:
	if value == INF:
		return 1.0
	return clampf((value - limit) / limit, 0.0, 1.0)


## Counts the pairs of bases with no path between them. The matrix is
## symmetric, so each pair is read once.
static func _count_unreachable_pairs(distances: Array) -> int:
	var count := 0
	for base in distances.size():
		for other in range(base + 1, distances.size()):
			if distances[base][other] == INF:
				count += 1
	return count
