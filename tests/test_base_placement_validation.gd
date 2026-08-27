extends "res://tests/assertions.gd"

const Validation = preload("res://editor/layers/base_placement_validation.gd")


# --- Vulnerability: which base each opponent attacks first ---


## Bases on a line at 0, 1 and 10. The outer two both pick the middle one, so
## its count reaches 2 while the far base is nobody's nearest opponent.
func test_vulnerability_counts_several_attackers_on_one_base() -> void:
	var distances := [[0.0, 1.0, 10.0], [1.0, 0.0, 9.0], [10.0, 9.0, 0.0]]
	assert_eq(Validation.compute_vulnerability(distances), [1, 2, 0])


## Base 0 sits at the same distance from bases 1 and 2, and picks the lower
## index. Without a fixed rule the reported counts would shift between runs
## whenever two candidates tie.
##
## The diagonal holds -1.0 here to show that the rule never reads it. A
## negative diagonal beats every real distance, so a missing self-skip would
## make every base pick itself.
func test_vulnerability_breaks_ties_towards_the_lower_index() -> void:
	var distances := [[-1.0, 5.0, 5.0], [5.0, -1.0, 100.0], [5.0, 100.0, -1.0]]
	assert_eq(Validation.compute_vulnerability(distances), [2, 1, 0])


## A base walled off in its own sand pocket has no reachable opponent, so it
## casts no vote, and the reachable pair ignores it as a candidate target.
func test_vulnerability_unreachable_base_casts_no_vote() -> void:
	var distances := [[0.0, 5.0, INF], [5.0, 0.0, INF], [INF, INF, 0.0]]
	assert_eq(Validation.compute_vulnerability(distances), [1, 1, 0])


## Placement can stop early when candidates run out, leaving a single base.
func test_vulnerability_single_base_has_no_opponent() -> void:
	var distances := [[0.0]]
	assert_eq(Validation.compute_vulnerability(distances), [0])


# --- Isolation: how the score adds up ---


## Bases 0 and 1 sit 1 apart, bases 2 and 3 sit 11 apart, and every crossing
## distance is 9. The tight pair scores 1 + 9, and the spread pair scores
## 9 + 9, because its two nearest opponents are across the gap rather than its
## own partner.
##
## The expected 1.8 pins down that the score adds exactly two distances.
## Reading only the nearest opponent would give 9.0, and adding all three
## would give roughly 1.53.
func test_isolation_adds_the_two_nearest_opponents() -> void:
	var distances := [
		[ 0.0,  1.0,  9.0,  9.0],
		[ 1.0,  0.0,  9.0,  9.0],
		[ 9.0,  9.0,  0.0, 11.0],
		[ 9.0,  9.0, 11.0,  0.0],
	]
	assert_eq(Validation.compute_isolation_ratio(distances), 1.8)


## Base 0 lies far from base 1 but close to bases 2 and 3, so its two nearest
## opponents are the last two in index order. Selecting by position instead of
## by distance would score base 0 at 25 rather than 11.
##
## Equal distances need no tie-break rule here, unlike the vulnerability
## count, because the score adds both values whichever order the sort picks.
func test_isolation_picks_the_two_smallest_not_the_first_two() -> void:
	var distances := [
		[ 0.0, 20.0,  5.0,  6.0],
		[20.0,  0.0, 20.0, 20.0],
		[ 5.0, 20.0,  0.0,  5.0],
		[ 6.0, 20.0,  5.0,  0.0],
	]
	assert_eq(Validation.compute_isolation_ratio(distances), 4.0)


# --- Isolation: placements too small to compare ---


## Placement can stop early when candidates run out, leaving a single base.
## One base cannot be more isolated than anybody, so the ratio is 1.0.
func test_isolation_single_base_is_balanced() -> void:
	var distances := [[0.0]]
	assert_eq(Validation.compute_isolation_ratio(distances), 1.0)


## Two bases have one opponent each, so a score holds a single distance rather
## than two. The matrix is symmetric, so both scores match.
func test_isolation_two_bases_use_their_single_opponent() -> void:
	var distances := [[0.0, 5.0], [5.0, 0.0]]
	assert_eq(Validation.compute_isolation_ratio(distances), 1.0)


# --- Isolation: unreachable opponents ---


## Base 2 sits in its own sand pocket, so bases 0 and 1 reach each other and
## nobody else. Every base then lacks a second reachable opponent and every
## score is infinite, which is the INF / INF case that would give NaN.
func test_isolation_is_infinite_when_every_base_is_cut_off() -> void:
	var distances := [[0.0, 5.0, INF], [5.0, 0.0, INF], [INF, INF, 0.0]]
	assert_eq(Validation.compute_isolation_ratio(distances), INF)


## Bases 0, 1 and 2 form a reachable group and base 3 is walled off. The
## connected majority does not rescue the ratio, and the finite minimum shows
## that the infinite maximum alone decides the result.
func test_isolation_is_infinite_when_one_base_is_walled_off() -> void:
	var distances := [
		[0.0, 5.0, 6.0, INF],
		[5.0, 0.0, 7.0, INF],
		[6.0, 7.0, 0.0, INF],
		[INF, INF, INF, 0.0],
	]
	assert_eq(Validation.compute_isolation_ratio(distances), INF)


## Two groups of three bases with no path between them. Every base still has
## two reachable opponents inside its own group, so no score is infinite and
## the ratio stays finite. An unreachable opponent only forces INF when it
## costs some base its second nearest opponent.
func test_isolation_stays_finite_when_each_group_holds_three_bases() -> void:
	var distances := [
		[ 0.0, 10.0, 10.0,  INF,  INF,  INF],
		[10.0,  0.0, 10.0,  INF,  INF,  INF],
		[10.0, 10.0,  0.0,  INF,  INF,  INF],
		[ INF,  INF,  INF,  0.0, 10.0, 20.0],
		[ INF,  INF,  INF, 10.0,  0.0, 20.0],
		[ INF,  INF,  INF, 20.0, 20.0,  0.0],
	]
	assert_eq(Validation.compute_isolation_ratio(distances), 2.0)
