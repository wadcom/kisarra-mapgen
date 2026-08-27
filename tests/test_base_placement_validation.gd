extends "res://tests/assertions.gd"

const Validation = preload("res://editor/layers/base_placement_validation.gd")


## Bases on a line at 0, 1 and 10. The outer two both pick the middle one, so
## its count reaches 2 while the far base is nobody's nearest opponent.
func test_vulnerability_counts_several_attackers_on_one_base() -> void:
	var distances := [[0.0, 1.0, 10.0], [1.0, 0.0, 9.0], [10.0, 9.0, 0.0]]
	assert_eq(Validation.compute_vulnerability(distances), [1, 2, 0])


## A base walled off in its own sand pocket has no reachable opponent, so it
## casts no vote, and the reachable pair ignores it as a candidate target.
func test_vulnerability_unreachable_base_casts_no_vote() -> void:
	var distances := [[0.0, 5.0, INF], [5.0, 0.0, INF], [INF, INF, 0.0]]
	assert_eq(Validation.compute_vulnerability(distances), [1, 1, 0])


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


## Placement can stop early when candidates run out, leaving a single base.
func test_vulnerability_single_base_has_no_opponent() -> void:
	var distances := [[0.0]]
	assert_eq(Validation.compute_vulnerability(distances), [0])
