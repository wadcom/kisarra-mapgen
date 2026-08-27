extends SceneTree
## Headless test runner.
##
## Loads every "test_*.gd" file in this directory, calls each "test_" method on
## a fresh instance, and prints one line per test under a heading naming the
## file. Exits with status 1 when any assertion fails or any file is unusable,
## so a shell or CI job can detect the failure.
##
## A file is unusable when it fails to parse or does not extend assertions.gd.
## The runner reports it as one failure and moves on, rather than crashing.
##
## Run with tests/run.sh, which also fails the run when Godot logs a script
## error. A runtime error inside a test does not fail that test on its own,
## because GDScript has no exception handling.

const TESTS_DIR := "res://tests"
const ASSERTIONS_PATH := "res://tests/assertions.gd"

var _passed := 0
var _failed := 0


func _init() -> void:
	for script_path in _find_test_scripts():
		print("%s:" % script_path.get_file())
		_run_script(script_path)

	print("")
	print("%d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _run_script(script_path: String) -> void:
	var script: GDScript = load(script_path)

	if script == null or not script.can_instantiate():
		_report_failure("(file failed to parse)", [])
		return

	if not _extends_test_case(script):
		_report_failure("(file does not extend assertions.gd)", [])
		return

	for method_name in _find_test_methods(script):
		var test_case = script.new()
		test_case.call(method_name)

		if test_case.failures.is_empty():
			_passed += 1
			print("  ok    %s" % method_name)
		else:
			_report_failure(method_name, test_case.failures)


func _report_failure(label: String, messages: Array[String]) -> void:
	_failed += 1
	print("  FAIL  %s" % label)
	for message in messages:
		print("          %s" % message)


## Returns true when the script inherits from assertions.gd, at any depth.
func _extends_test_case(script: GDScript) -> bool:
	var base := script.get_base_script()
	while base != null:
		if base.resource_path == ASSERTIONS_PATH:
			return true
		base = base.get_base_script()
	return false


## Returns the "res://" paths of the test scripts, sorted by file name.
func _find_test_scripts() -> Array[String]:
	var paths: Array[String] = []
	for file_name in DirAccess.get_files_at(TESTS_DIR):
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			paths.append("%s/%s" % [TESTS_DIR, file_name])
	paths.sort()
	return paths


## Returns the names of the "test_" methods visible on the script, sorted
## alphabetically. Methods inherited from assertions.gd appear here too, but
## none of them use the prefix.
func _find_test_methods(script: GDScript) -> Array[String]:
	var names: Array[String] = []
	for method in script.get_script_method_list():
		if method.name.begins_with("test_"):
			names.append(method.name)
	names.sort()
	return names
