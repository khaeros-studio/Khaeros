extends SceneTree
## Deterministic UI integration: real composition root, real device events and modules.
## Callbacks are advanced explicitly; this is not a visual or hardware test.

const Main = preload("res://src/app/main.gd")

class CameraCounter extends "res://src/presentation/game_camera.gd":
	var cuts := 0
	func cut(position: Vector2) -> void:
		cuts += 1
		super.cut(position)

var app
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func key(code: int, down: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	event.echo = echo
	Input.parse_input_event(event)

func tick() -> void:
	app._physics_process(1.0/60.0)

func render_step(delta: float) -> void:
	app._process(delta)

func window_point(logical: Vector2) -> Vector2:
	var size := root.get_visible_rect().size
	var window_size := Vector2(root.size)
	var scale := minf(window_size.x/size.x,window_size.y/size.y)
	return logical*scale+(window_size-size*scale)/2

func mouse(logical: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = window_point(logical)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	root.push_input(event,false)

func run() -> void:
	app = Main.new()
	app.camera = CameraCounter.new()
	root.add_child(app)
	app.set_process(false)
	app.set_physics_process(false)
	check(app.ready_to_play and app.session.state == "menu","real Main loads validated catalog into menu")
	var entry: Vector2 = app.hud.action_rects()[0].get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = window_point(entry)
	motion.relative = Vector2(4,0)
	root.push_input(motion,false)
	tick()
	check(app.selected == 0,"mouse hover selects shared menu focus")
	key(KEY_DOWN,true)
	tick()
	check(app.selected == 1,"keyboard navigates away from idle mouse")
	key(KEY_DOWN,false)
	tick()
	check(app.selected == 1,"idle mouse does not take keyboard focus back")
	key(KEY_ENTER,true)
	tick()
	check(app.reduced_motion and app.session.state == "menu","Enter toggles selected accessibility action")
	key(KEY_ENTER,false)
	key(KEY_UP,true)
	tick()
	key(KEY_UP,false)
	key(KEY_ENTER,true)
	tick()
	check(app.session.state == "jogo" and not app.session.player.is_empty(),"Enter starts game through root menu handler")
	key(KEY_ENTER,false)
	tick()
	check(app.session.player.dash_remaining == 0 and app.session.player.attack_cd == 0,"menu confirmation does not become gameplay action")
	render_step(1.0/60)
	var cuts_before_pause: int = app.camera.cuts
	key(KEY_ESCAPE,true)
	tick()
	check(app.session.state == "pausa" and app.controls.context == "pausa","Escape pauses and applies context barrier")
	var live_steps: int = app.session.live_steps
	key(KEY_ESCAPE,true,true)
	tick()
	check(app.session.state == "pausa" and app.session.live_steps == live_steps,"held Escape echo cannot close pause and simulation stays frozen")
	key(KEY_ESCAPE,false)
	tick()
	key(KEY_ESCAPE,true)
	tick()
	check(app.session.state == "jogo","release and fresh Escape resumes")
	tick()
	check(app.session.state == "jogo","held resume Escape cannot immediately pause again")
	key(KEY_ESCAPE,false)
	render_step(1.0/60)
	check(app.camera.cuts == cuts_before_pause,"pause and resume do not cut the camera")
	# Setup only: entering the offer bypasses killing the wave, not its UI logic.
	app.session.state = "bencao"
	app.sync_context()
	var card: Vector2 = app.hud.action_rects()[1].get_center()
	mouse(card,true)
	tick()
	check(app.session.state == "bencao","blessing cannot confirm before its settling lock")
	mouse(card,false)
	tick()
	app.screen_age = float(app.catalog.data.blessing_lock_s)+0.01
	var original_max: int = app.session.player.charge_max
	var old_wave: int = app.session.wave_index
	mouse(card,true)
	tick()
	check(app.session.state == "transicao" and app.session.player.charge_max == original_max+1,"native mouse click selects second blessing exactly once")
	var cuts_before_transition: int = app.camera.cuts
	for frame in range(3): render_step(0.1)
	check(app.session.wave_index == old_wave and app.camera.cuts == cuts_before_transition,"old wave and camera remain before wipe midpoint")
	render_step(0.1)
	check(app.session.wave_index == old_wave+1 and app.camera.cuts == cuts_before_transition+1,"midpoint advances wave and cuts actual camera once")
	check(app.session.player.prev == app.session.player.pos and app.camera.pos == app.camera.follow_pos,"teleport and camera base collapse at midpoint")
	check(app.session.state == "transicao" and app.session.presentation_time == 0,"midpoint resets presentation clock but retains transition")
	for frame in range(6): render_step(0.1)
	check(app.session.state == "jogo" and app.camera.cuts == cuts_before_transition+1,"wipe completes with no repeated camera cut")
	tick()
	check(app.session.player.attack_cd == 0 and not app.last_sample.wants.ataque,"held blessing mouse click does not become attack after wipe")
	mouse(card,false)
	tick()
	mouse(card,true)
	tick()
	check(app.session.player.attack_cd > 0,"release then fresh mouse click attacks in gameplay")
	mouse(card,false)
	# Pause over an offer restores the offer instead of gameplay.
	app.session.state = "bencao"
	app.sync_context()
	key(KEY_ESCAPE,true)
	tick()
	check(app.session.state == "pausa","Escape opens pause above blessing")
	key(KEY_ESCAPE,false)
	tick()
	key(KEY_ESCAPE,true)
	tick()
	check(app.session.state == "bencao","closing overlay restores blessing context")
	key(KEY_ESCAPE,false)
	app.queue_free()
	await process_frame
	print("UI_FLOW checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
