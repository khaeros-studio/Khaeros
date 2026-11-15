extends Node
## Composition root of the first playable Khaeros integration.

const Catalog = preload("res://src/foundation/session_catalog.gd")
const Session = preload("res://src/gameplay/game_session.gd")
const InputAdapter = preload("res://src/foundation/game_input.gd")
const Camera = preload("res://src/presentation/game_camera.gd")
const World = preload("res://src/presentation/world_view.gd")
const HUD = preload("res://src/presentation/game_hud.gd")

var catalog = Catalog.new()
var session = Session.new()
var controls = InputAdapter.new()
var camera = Camera.new()
var world = World.new()
var hud = HUD.new()
var selected := 0
var screen_age := 0.0
var context := ""
var last_sample: Dictionary = {}
var reduced_motion := false
var pending_pause := false
var capture_mode := ""
var capture_frames := 0
var capture_started := false
var ready_to_play := false
var data_error := ""
var observed_wave := -1

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	canvas.add_child(hud)
	hud.app = self
	if not catalog.load_file("res://data/integration/gameplay.json"):
		data_error = "\n".join(catalog.errors)
		push_error(data_error)
		return
	if Engine.physics_ticks_per_second != 60:
		data_error = "A simulação precisa estar configurada para 60 passos por segundo."
		push_error(data_error)
		return
	session.configure(catalog.data, 0x4B484145)
	controls.configure(catalog.data.input)
	add_child(controls)
	if controls.has_signal("device_disconnected"):
		controls.connect("device_disconnected", _on_device_disconnected)
	camera.configure(catalog.data.camera, Rect2(0, 0, catalog.data.arena.largura, catalog.data.arena.altura))
	camera.resize(get_window())
	camera.cut(Vector2(catalog.data.jogador.spawn[0], catalog.data.jogador.spawn[1]))
	get_window().size_changed.connect(_on_resize)
	world.app = self
	add_child(world)
	ready_to_play = true
	sync_context()
	if OS.is_debug_build():
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--qa-capture="):
				capture_mode = arg.trim_prefix("--qa-capture=")
		if capture_mode != "" and capture_mode != "menu":
			activate(0)
			if capture_mode in ["pausa", "bencao", "morte", "vitoria"]:
				session.state = capture_mode
				sync_context()

func _physics_process(_delta: float) -> void:
	if not ready_to_play:
		return
	if not session.player.is_empty():
		controls.player_position = session.player.pos
	controls.targets = session.enemies
	last_sample = controls.sample(session.hitstop > 0, camera)
	if session.state == "jogo":
		if pending_pause or last_sample.pressed.get("pausar", false):
			pending_pause = false
			session.pause()
			sync_context()
			return
		var hp_before: float = session.player.hp
		var foes_before := _enemy_health()
		var consumed: Array = session.step(last_sample)
		for action in consumed:
			controls.consume(action)
		if session.player.hp < hp_before:
			camera.impulse(-last_sample.aim, 1.0)
		elif _enemy_health() < foes_before:
			camera.impulse(last_sample.aim, 0.5)
	else:
		session.step(last_sample)
		_handle_ui(last_sample)
	sync_context()

func _process(delta: float) -> void:
	if not ready_to_play:
		hud.queue_redraw()
		return
	var presentation_delta := minf(delta, 0.1)
	screen_age += presentation_delta
	session.advance_presentation(presentation_delta)
	if session.wave_index != observed_wave and not session.player.is_empty():
		observed_wave = session.wave_index
		camera.cut(session.player.pos)
	sync_context()
	if not session.player.is_empty():
		camera.reduced_motion = reduced_motion
		camera.aim_intensity = last_sample.get("aim_intensity", 0.0)
		camera.update(presentation_delta, session.player.prev, session.player.pos,
			Engine.get_physics_interpolation_fraction(), last_sample.get("aim", Vector2.UP),
			last_sample.get("source", "mouse"), last_sample.get("cursor", Vector2(camera.width / 2, 540)),
			session.state != "jogo")
	get_viewport().canvas_transform = camera.transform
	world.queue_redraw()
	hud.queue_redraw()
	if capture_mode != "" and not capture_started:
		capture_frames += 1
		if capture_frames >= 90:
			capture_started = true
			_capture()

## Applies context barriers exactly when a screen changes.
func sync_context() -> void:
	if context == session.state:
		return
	context = session.state
	selected = 0
	screen_age = 0
	controls.set_context(context)

## Executes the selected visible UI action; also used by integration tests.
func activate(index: int) -> void:
	if not ready_to_play:
		return
	match session.state:
		"menu":
			if index == 0:
				session.start()
				observed_wave = -1
				camera.cut(session.player.pos)
			elif index == 1:
				reduced_motion = not reduced_motion
		"pausa":
			if index == 0:
				session.resume()
			elif index == 1:
				reduced_motion = not reduced_motion
			elif index == 2:
				session.state = "menu"
		"bencao":
			if screen_age >= float(catalog.data.blessing_lock_s):
				session.choose_blessing(index)
		"morte", "vitoria":
			if index == 0:
				session.start()
				observed_wave = -1
				camera.cut(session.player.pos)
			else:
				session.state = "menu"
	sync_context()

func _handle_ui(sample: Dictionary) -> void:
	var pressed: Dictionary = sample.get("pressed", {})
	if session.state in ["pausa", "bencao"] and pressed.get("pausar", false):
		if session.state == "pausa":
			session.resume()
		else:
			session.pause()
		return
	var boxes: Array[Rect2] = hud.action_rects()
	if boxes.is_empty():
		return
	var old_selected := selected
	if pressed.get("ui_right", false) or pressed.get("ui_down", false):
		selected = (selected + 1) % boxes.size()
	if pressed.get("ui_left", false) or pressed.get("ui_up", false):
		selected = posmod(selected - 1, boxes.size())
	for i in range(3):
		if session.state == "bencao" and pressed.get("ui_carta_" + str(i + 1), false):
			selected = i
	# Mouse motion updates the same focus; an idle cursor never steals key focus.
	if sample.get("mouse_moved", false):
		for i in boxes.size():
			if boxes[i].has_point(sample.cursor):
				selected = i
	if sample.get("mouse_click", false):
		for i in boxes.size():
			if boxes[i].has_point(sample.get("click_cursor", sample.cursor)):
				selected = i
				activate(i)
				return
	if pressed.get("ui_aceitar", false):
		activate(selected)
	elif pressed.get("ui_voltar", false) and session.state == "pausa":
		# B does not close the pause root; Esc/Start use pausar above.
		selected = old_selected

func _on_resize() -> void:
	if ready_to_play:
		camera.resize(get_window())

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and ready_to_play:
		controls.clear()
		if session.state == "jogo":
			session.pause()
		elif session.state == "transicao":
			pending_pause = true
		sync_context()

func _on_device_disconnected(_id: int = -1) -> void:
	if session.state == "jogo":
		session.pause()
	elif session.state == "transicao":
		pending_pause = true
	sync_context()

func _enemy_health() -> float:
	var total := 0.0
	for enemy in session.enemies:
		total += maxf(0, enemy.hp)
	return total

func _capture() -> void:
	await RenderingServer.frame_post_draw
	var path := "res://production/qa/evidence/integracao-jogavel/" + capture_mode + ".png"
	var error := get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE ", path, " result=", error)
	get_tree().quit(0 if error == OK else 1)
