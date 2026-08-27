extends RefCounted
## Assertion base class for test cases.
##
## Subclasses define methods whose names start with "test_". The runner calls
## each one on a fresh instance and collects the failures reported here.
##
## ## Public API
##
## Properties: failures
## Methods: assert_eq(), fail()

## Messages for the assertions that failed, in call order.
var failures: Array[String] = []


## Records a failure when actual and expected differ. The message is optional,
## because the runner already prints the name of the failing test.
func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	var prefix := "%s: " % message if message else ""
	if actual != expected:
		fail("%sexpected %s, got %s" % [prefix, expected, actual])


## Records a failure with the given message.
func fail(message: String) -> void:
	failures.append(message)
