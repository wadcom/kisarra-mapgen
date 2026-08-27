#!/bin/sh
# Runs the test suite.
#
# GDScript has no exception handling, so a runtime error inside a test does not
# fail that test: Godot logs the error, the assertion never runs, and the test
# reports a pass. This wrapper fails the run whenever Godot logs an error,
# which turns those silent passes into failures.
#
# The pattern covers both "SCRIPT ERROR" from GDScript and plain "ERROR" from
# the engine itself. An out-of-bounds pathfinding query reports the second kind
# and then quietly answers that no route exists.
#
# Set GODOT to point at another engine build.

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd)

output=$("$GODOT" --headless --path "$PROJECT_DIR" --script tests/run_tests.gd 2>&1)
status=$?

echo "$output" | grep -v "^Godot Engine v"

if echo "$output" | grep -q "ERROR"; then
	echo ""
	echo "FAILED: Godot logged an error, so some test did not run to its assertions."
	exit 1
fi

exit $status
