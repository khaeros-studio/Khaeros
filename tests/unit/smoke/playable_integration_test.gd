extends GdUnitTestSuite
## Runs the isolated integration entry points through the existing CI test suite.

func test_playable_integration_runners() -> void:
	for runner in ["run_catalog", "run_gameplay", "run_input_camera", "run_app", "run_ui_flow"]:
		var output: Array = []
		var arguments := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://tests/integration/"+runner+".gd", "--quit-after", "600"])
		var result := OS.execute(OS.get_executable_path(), arguments, output, true)
		var transcript := "\n".join(output)
		assert_int(result).override_failure_message(runner+": "+transcript).is_equal(0)
		assert_str(transcript).override_failure_message(runner+": "+transcript).contains("failures=0")
		assert_bool(transcript.contains("SCRIPT ERROR")).override_failure_message(runner+": "+transcript).is_false()
