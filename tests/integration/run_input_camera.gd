extends SceneTree

const GameInput = preload("res://src/foundation/game_input.gd")
const GameCamera = preload("res://src/presentation/game_camera.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func key(code: int, down: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	event.echo = echo
	Input.parse_input_event(event)

func run() -> void:
	var input := GameInput.new()
	root.add_child(input)
	input.configure({"buffer_steps":10,"deadzone":0.2,"outer_deadzone":0.05,"auto_aim_radius":1350,"mouse_threshold":4,"trigger_press":0.5,"trigger_release":0.4})
	var camera := GameCamera.new()
	camera.configure({"half_life":0.12,"lookahead":120,"mouse_radius":480,"shake_max":40,"zoom_max":1.15,"impulse_half_life":0.1,"impulse_kick":20,"impulse_shake":8,"impulse_zoom":0.04,"max_impulses":16,"impulse_cutoff":0.05},Rect2(0,0,2880,1620))
	root.size = Vector2i(1920,1080)
	camera.resize(root)
	camera.cut(Vector2(1500,800))
	input.player_position = Vector2(1500,800)
	input.set_context("jogo")
	key(KEY_SPACE,true)
	key(KEY_SPACE,false)
	var sample: Dictionary = input.sample(true,camera)
	check(sample.pressed.has("esquiva") and not sample.held.has("esquiva"),"quick release keeps edge")
	for tick in range(35):
		sample = input.sample(true,camera)
	check(sample.wants.esquiva and input.buffer_remaining == 10,"hitstop preserves shared deadline")
	sample = input.sample(false,camera)
	check(sample.dash_taps == 1 and sample.wants.esquiva,"frozen tap delivered to first live step")
	input.consume("esquiva")
	check(not input.sample(false,camera).wants.esquiva,"consume removes only buffered command")
	for tap in range(2):
		key(KEY_SPACE,true)
		key(KEY_SPACE,false)
		input.sample(true,camera)
	check(input.sample(false,camera).dash_taps == 2 and input.sample(false,camera).dash_taps == 0,"multiple frozen taps drain exactly once at first live step")
	key(KEY_SPACE,true)
	key(KEY_SPACE,false)
	input.sample(true,camera)
	input.set_context("menu")
	input.set_context("jogo")
	check(input.sample(false,camera).dash_taps == 0,"context clears frozen reaction metadata")
	key(KEY_J,true)
	key(KEY_J,false)
	sample = input.sample(false,camera)
	for tick in range(7): input.sample(false,camera)
	key(KEY_K,true)
	key(KEY_K,false)
	sample = input.sample(false,camera)
	check(sample.wants.ataque and sample.wants.especial and input.buffer_remaining == 10,"special refreshes common attack deadline")
	input.set_context("menu")
	key(KEY_SPACE,true)
	sample = input.sample(false,camera)
	check(sample.pressed.has("ui_aceitar"),"menu accepts fresh space")
	input.set_context("jogo")
	check(not input.sample(false,camera).wants.esquiva,"held menu space blocked in game")
	key(KEY_SPACE,false)
	key(KEY_SPACE,true)
	check(input.sample(false,camera).wants.esquiva,"release rearms space")
	key(KEY_SPACE,false)
	input.clear()
	key(KEY_J,true)
	input.sample(false,camera)
	key(KEY_J,true,true)
	sample = input.sample(false,camera)
	check(not sample.pressed.has("ataque") and sample.held.has("ataque"),"echo not a fresh press")
	key(KEY_J,false)
	input.clear()
	key(KEY_W,true)
	key(KEY_D,true)
	sample = input.sample(false,camera)
	check(sample.move.is_equal_approx(Vector2(1,-1).normalized()),"diagonal normalized")
	key(KEY_W,false)
	key(KEY_D,false)
	input.clear()
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(1440,270)
	motion.relative = Vector2(10,0)
	Input.parse_input_event(motion)
	sample = input.sample(false,camera)
	check(sample.cursor == Vector2(1440,270),"mouse event remains logical without second stretch")
	check(sample.mouse_moved and not input.sample(false,camera).mouse_moved,"mouse movement edge drains once and idle cursor does not steal focus")
	check(sample.aim.is_equal_approx(Vector2(480,-270).normalized()),"logical cursor converted with base camera")
	input.set_context("menu")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(500,400)
	Input.parse_input_event(click)
	motion = motion.duplicate()
	motion.position = Vector2(900,700)
	Input.parse_input_event(motion)
	sample = input.sample(false,camera)
	check(sample.mouse_click and sample.click_cursor == Vector2(500,400) and sample.cursor == Vector2(900,700),"click location retained before later motion")
	click = click.duplicate()
	click.pressed = false
	Input.parse_input_event(click)
	input.set_context("jogo")
	var axis := InputEventJoypadMotion.new()
	axis.device = 2
	axis.axis = JOY_AXIS_LEFT_X
	axis.axis_value = 0.5
	Input.parse_input_event(axis)
	sample = input.sample(false,camera)
	check(sample.move.is_equal_approx(Vector2(0.4,0)),"gamepad radial rescale preserves partial movement")
	axis = axis.duplicate()
	axis.axis = JOY_AXIS_RIGHT_Y
	axis.axis_value = -0.5
	Input.parse_input_event(axis)
	sample = input.sample(false,camera)
	check(sample.source == "analogico" and sample.aim == Vector2.UP and is_equal_approx(sample.aim_intensity,0.4),"right stick source intensity and direction")
	var pad := InputEventJoypadButton.new()
	pad.device = 2
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	Input.parse_input_event(pad)
	check(input.sample(false,camera).wants.esquiva,"gamepad A requests dash")
	input.set_context("menu")
	check(not input.sample(false,camera).pressed.has("ui_aceitar"),"held A cannot confirm after context switch")
	pad = pad.duplicate()
	pad.pressed = false
	Input.parse_input_event(pad)
	pad = pad.duplicate()
	pad.pressed = true
	Input.parse_input_event(pad)
	check(input.sample(false,camera).pressed.has("ui_aceitar"),"released A rearms menu accept")
	pad = pad.duplicate()
	pad.pressed = false
	Input.parse_input_event(pad)
	var base: Vector2 = camera.screen_to_world(Vector2(1440,270))
	camera.impulse(Vector2.RIGHT)
	camera.update(0.05,Vector2(1500,800),Vector2(1500,800),0.5,Vector2.RIGHT,"automatica",Vector2.ZERO)
	check(camera.screen_to_world(Vector2(1440,270)).is_equal_approx(base),"shake does not change base aim")
	camera.update(0.05,Vector2.ZERO,Vector2.ZERO,0.5,Vector2.RIGHT,"mouse",Vector2.ZERO,true)
	check(camera.offset == Vector2.ZERO and camera.zoom == 1.0,"frozen clears impulse")
	var cases := [[Vector2i(1280,720),1920.0],[Vector2i(2560,1080),2560.0],[Vector2i(3840,1080),2580.0],[Vector2i(1440,1080),1920.0]]
	for entry: Array in cases:
		root.size = entry[0]
		camera.resize(root)
		check(is_equal_approx(camera.width,entry[1]) and is_equal_approx(root.get_visible_rect().size.x,entry[1]),"native viewport " + str(entry[0]))
	root.size = Vector2i(1280,720)
	camera.resize(root)
	root.canvas_transform = Transform2D(0,Vector2(-600,-300))
	var window_motion := InputEventMouseMotion.new()
	window_motion.position = Vector2(960,180)
	window_motion.relative = Vector2(6,0)
	root.push_input(window_motion,false)
	sample = input.sample(false,camera)
	print("OBS input stretch 1280: ",sample.cursor)
	check(sample.cursor.is_equal_approx(Vector2(1440,270)),"window event transformed to logical viewport, unaffected by world canvas")
	root.size = Vector2i(1920,1080)
	camera.resize(root)
	sample = input.sample(false,camera)
	check(sample.cursor.is_equal_approx(Vector2(960,180)),"resize reprojects last physical window cursor without fresh event")
	root.size = Vector2i(3840,1080)
	camera.resize(root)
	window_motion = InputEventMouseMotion.new()
	window_motion.position = Vector2(1920,540)
	window_motion.relative = Vector2(6,0)
	root.push_input(window_motion,false)
	sample = input.sample(false,camera)
	check(sample.cursor.is_equal_approx(Vector2(1290,540)),"pillarbox input origin removed by native window pipeline")
	root.size = Vector2i(1440,1080)
	camera.resize(root)
	window_motion = InputEventMouseMotion.new()
	window_motion.position = Vector2(720,540)
	window_motion.relative = Vector2(6,0)
	root.push_input(window_motion,false)
	sample = input.sample(false,camera)
	check(sample.cursor.is_equal_approx(Vector2(960,540)),"letterbox input origin and scale removed by native pipeline")
	root.canvas_transform = Transform2D.IDENTITY
	camera.cut(Vector2(1500,800))
	check(camera.pos == camera.follow_pos and camera.offset == Vector2.ZERO,"cut resets both bases and effects")
	input.queue_free()
	await process_frame
	print("INPUT_CAMERA checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
