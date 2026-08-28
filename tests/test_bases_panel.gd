extends "res://tests/assertions.gd"

const BasesPanel = preload("res://editor/ui/bases_panel.gd")


## A complete placement that breaks no rule needs no warning at all.
func test_warning_is_silent_when_nothing_is_wrong() -> void:
	var lines := BasesPanel._warning_lines(4, 4, [] as Array[String])
	assert_eq(lines, [])


## Terrain that ran out of room reports the shortfall, and nothing else. No
## rule broke, so there is nothing to suggest.
func test_warning_reports_a_placement_that_ran_out_of_room() -> void:
	var lines := BasesPanel._warning_lines(3, 4, [] as Array[String])
	assert_eq(lines, ["Only placed 3 of 4 bases."])


## A complete placement that breaks rules shows each broken rule, then the one
## suggestion that can act on them.
func test_warning_lists_every_broken_rule_and_what_to_do() -> void:
	var failures: Array[String] = [
		"Unreachable base pairs: 3 of 6.",
		"Some bases have fewer than two reachable opponents.",
	]
	var lines := BasesPanel._warning_lines(4, 4, failures)
	assert_eq(lines, [
		"Unreachable base pairs: 3 of 6.",
		"Some bases have fewer than two reachable opponents.",
		"Try a different base or terrain seed.",
	])


## Both problems can hold at once, and the shortfall comes first because it is
## the reason the rules judged fewer bases than the player asked for. Three
## bases carry a limit of 1.33, since the limit widens with placement size.
func test_warning_reports_a_shortfall_and_broken_rules_together() -> void:
	var failures: Array[String] = ["Isolation ratio 1.62 (limit 1.33)."]
	var lines := BasesPanel._warning_lines(3, 4, failures)
	assert_eq(lines, [
		"Only placed 3 of 4 bases.",
		"Isolation ratio 1.62 (limit 1.33).",
		"Try a different base or terrain seed.",
	])
