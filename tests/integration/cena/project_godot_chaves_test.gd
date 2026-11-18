## Story cena-e-camera 001 — AC-01: chaves explícitas de display/stretch no project.godot.
extends GdUnitTestSuite


func test_project_godot_tem_chaves_de_stretch_do_r1() -> void:
	assert_int(ProjectSettings.get_setting("display/window/size/viewport_width")).is_equal(1920)
	assert_int(ProjectSettings.get_setting("display/window/size/viewport_height")).is_equal(1080)
	assert_int(ProjectSettings.get_setting("display/window/size/window_width_override")).is_equal(1280)
	assert_int(ProjectSettings.get_setting("display/window/size/window_height_override")).is_equal(720)
	assert_str(str(ProjectSettings.get_setting("display/window/stretch/mode"))).is_equal("canvas_items")
	assert_str(str(ProjectSettings.get_setting("display/window/stretch/aspect"))).is_equal("keep_height")
	assert_str(str(ProjectSettings.get_setting("display/window/stretch/scale_mode"))).is_equal("fractional")


func test_project_godot_liga_interpolacao_de_fisica() -> void:
	assert_bool(ProjectSettings.get_setting("physics/common/physics_interpolation")).is_true()
