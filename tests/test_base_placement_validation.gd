extends "res://tests/assertions.gd"

const Validation = preload("res://editor/layers/base_placement_validation.gd")

## Three bases 10, 11 and 12 apart. Every base reaches the others, the most
## targeted base is the first choice of two opponents, and the isolation ratio
## is about 1.10, so every rule passes.
const BALANCED_TRIO := [[0.0, 10.0, 11.0], [10.0, 0.0, 12.0], [11.0, 12.0, 0.0]]

## Four bases evenly spaced along a line, 10 apart. Each end base must reach
## past its neighbour for a second opponent, scoring 30 against the middle
## bases' 20, so the isolation ratio is 1.5.
const EVENLY_SPACED_LINE := [
	[ 0.0, 10.0, 20.0, 30.0],
	[10.0,  0.0, 10.0, 20.0],
	[20.0, 10.0,  0.0, 10.0],
	[30.0, 20.0, 10.0,  0.0],
]

## Two groups of three bases with no path between them. Each group is equally
## spaced, so every isolation score is 20 and the ratio is 1.0.
const TWO_TRIOS_EVENLY_SPACED := [
	[ 0.0, 10.0, 10.0,  INF,  INF,  INF],
	[10.0,  0.0, 10.0,  INF,  INF,  INF],
	[10.0, 10.0,  0.0,  INF,  INF,  INF],
	[ INF,  INF,  INF,  0.0, 10.0, 10.0],
	[ INF,  INF,  INF, 10.0,  0.0, 10.0],
	[ INF,  INF,  INF, 10.0, 10.0,  0.0],
]

## The same split, but the second group is spread unevenly, so its most
## isolated base scores 40 against the first group's 20, giving a ratio of 2.0.
const TWO_TRIOS_SECOND_SPREAD := [
	[ 0.0, 10.0, 10.0,  INF,  INF,  INF],
	[10.0,  0.0, 10.0,  INF,  INF,  INF],
	[10.0, 10.0,  0.0,  INF,  INF,  INF],
	[ INF,  INF,  INF,  0.0, 10.0, 20.0],
	[ INF,  INF,  INF, 10.0,  0.0, 20.0],
	[ INF,  INF,  INF, 20.0, 20.0,  0.0],
]


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


## Every base still has two reachable opponents inside its own group, so no
## score is infinite and the ratio stays finite. An unreachable opponent only
## forces INF when it costs some base its second nearest opponent.
func test_isolation_stays_finite_when_each_group_holds_three_bases() -> void:
	assert_eq(Validation.compute_isolation_ratio(TWO_TRIOS_SECOND_SPREAD), 2.0)


# --- Combined validation: accepting ---


func test_validate_accepts_a_balanced_placement() -> void:
	assert_eq(Validation.validate(BALANCED_TRIO).accepted, true)


## An accepted placement sits at no distance from passing.
func test_validate_penalty_is_zero_when_accepted() -> void:
	assert_eq(Validation.validate(BALANCED_TRIO).penalty, 0.0)


## Placement can stop early and leave one base, or none at all. Neither case
## holds a pair to judge, so no rule can break.
func test_validate_accepts_a_placement_too_small_to_judge() -> void:
	assert_eq(Validation.validate([[0.0]]).accepted, true)
	assert_eq(Validation.validate([]).accepted, true)


## Four bases on a line at 0, 3, 10 and 13. The end bases score 3 + 10 and the
## middle bases score 3 + 7, giving a ratio of exactly 1.3. The limit accepts
## its own value, so this placement passes.
func test_validate_accepts_an_isolation_ratio_exactly_at_the_limit() -> void:
	var distances := [
		[ 0.0,  3.0, 10.0, 13.0],
		[ 3.0,  0.0,  7.0, 10.0],
		[10.0,  7.0,  0.0,  3.0],
		[13.0, 10.0,  3.0,  0.0],
	]
	assert_eq(Validation.validate(distances).accepted, true)


# --- Combined validation: rejecting ---


## Bases 1, 2 and 3 all lie nearer to base 0 than to each other, so base 0 is
## the first target of three opponents. They sit close enough together that
## the isolation ratio stays at about 1.24, so only vulnerability breaks. The
## penalty is the overshoot of 1 over the limit of 2.
func test_validate_rejects_a_base_targeted_by_three_opponents() -> void:
	var distances := [
		[0.0, 5.0, 5.5, 6.0],
		[5.0, 0.0, 7.0, 7.0],
		[5.5, 7.0, 0.0, 7.0],
		[6.0, 7.0, 7.0, 0.0],
	]
	var result := Validation.validate(distances)
	assert_eq(result.failures, ["Base 0 is the first target of 3 opponents (limit 2)."])
	assert_eq(result.penalty, 0.5)


## Every base is the first target of at most two opponents, so only the
## isolation rule rejects the evenly spaced line.
func test_validate_rejects_an_isolation_ratio_above_the_limit() -> void:
	var result := Validation.validate(EVENLY_SPACED_LINE)
	assert_eq(result.failures, ["Isolation ratio 1.50 (limit 1.30)."])


## Both other rules pass on two evenly spaced groups: every base is the first
## target of at most two opponents, and every isolation score is 20. Only the
## connectivity rule sees that half the players cannot be reached.
func test_validate_rejects_a_placement_split_into_unreachable_groups() -> void:
	var result := Validation.validate(TWO_TRIOS_EVENLY_SPACED)
	assert_eq(result.failures, ["Unreachable base pairs: 9 of 15."])


## Spreading the second group breaks isolation on top of connectivity. Both
## sentences appear, in rule order.
func test_validate_reports_every_broken_rule() -> void:
	assert_eq(Validation.validate(TWO_TRIOS_SECOND_SPREAD).failures, [
		"Unreachable base pairs: 9 of 15.",
		"Isolation ratio 2.00 (limit 1.30).",
	])


## Two players on terrain that splits in half. The single base pair has no
## path, which is the smallest possible break in connectivity. Neither base
## then has a second reachable opponent, so isolation breaks as well and
## reports the cause rather than an infinite ratio.
##
## The penalty is 1.0 from connectivity plus 1.0 from the isolation ceiling.
func test_validate_rejects_two_bases_that_cannot_reach_each_other() -> void:
	var result := Validation.validate([[0.0, INF], [INF, 0.0]])
	assert_eq(result.failures, [
		"Unreachable base pairs: 1 of 1.",
		"Some bases have fewer than two reachable opponents.",
	])
	assert_eq(result.penalty, 2.0)


# --- Combined validation: ranking rejected placements ---


## Nine of the fifteen base pairs have no path between them, and no other rule
## breaks, so the penalty is exactly 9 / 15.
func test_validate_penalty_stays_finite_when_bases_cannot_reach_each_other() -> void:
	assert_eq(Validation.validate(TWO_TRIOS_EVENLY_SPACED).penalty, 0.6)


## Bases at 0, 5, 10 and 40 on a line leave the last base far from the rest,
## giving a ratio of 6.5 against the evenly spaced line's 1.5. The worse
## placement must rank worse, so that a caller keeps the closer one.
##
## An overshoot of 4.0 saturates at the per-rule ceiling of 1.0, which is the
## bound that keeps a hopeless placement comparable instead of infinite.
func test_validate_penalty_grows_with_the_size_of_the_breach() -> void:
	var one_base_far_out := [
		[ 0.0,  5.0, 10.0, 40.0],
		[ 5.0,  0.0,  5.0, 35.0],
		[10.0,  5.0,  0.0, 30.0],
		[40.0, 35.0, 30.0,  0.0],
	]
	var milder: float = Validation.validate(EVENLY_SPACED_LINE).penalty
	var worse: float = Validation.validate(one_base_far_out).penalty
	assert_true(worse > milder, "%f should exceed %f" % [worse, milder])
	assert_eq(worse, 1.0)
