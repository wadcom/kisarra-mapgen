extends RefCounted
## Assertion base class for test cases.
##
## Subclasses define methods whose names start with "test_". The runner calls
## each one on a fresh instance and collects the failures reported here.
##
## ## Public API
##
## Properties: failures
## Methods: assert_almost_eq(), assert_eq(), assert_true(), fail()

## Messages for the assertions that failed, in call order.
var failures: Array[String] = []


## Records a failure when actual and expected differ. The message is optional,
## because the runner already prints the name of the failing test.
func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	var prefix := "%s: " % message if message else ""
	if actual != expected:
		fail("%sexpected %s, got %s" % [prefix, expected, actual])


## Records a failure when actual and expected differ by more than tolerance.
## Use for distances built from Vector2, whose components hold 32 bits, so a
## diagonal step gives 1.41421353816986 rather than the value a 64-bit square
## root would give.
func assert_almost_eq(actual: float, expected: float, tolerance: float, message: String = "") -> void:
	var prefix := "%s: " % message if message else ""
	if absf(actual - expected) > tolerance:
		fail("%sexpected %f plus or minus %f, got %f" % [prefix, expected, tolerance, actual])


## Records a failure when value is not true.
func assert_true(value: bool, message: String) -> void:
	if not value:
		fail("%s: expected true" % message)


## Records a failure with the given message.
func fail(message: String) -> void:
	failures.append(message)
