extends Node
## Local device boundary for the playable integration. Gameplay reads samples only.
## Bind editing/persistence and text entry are deliberately not implemented here.

signal device_disconnected

const BUFFERED := ["esquiva", "especial", "ataque", "selo"]
var player_position := Vector2.ZERO
var targets: Array = []
var context := "menu"
var cursor := Vector2(960, 540)
var source := "mouse"
var aim_intensity := 0.0
var active_device := "teclado"
var active_pad := -1
var buffer_remaining := 0
var _tuning: Dictionary = {}
var _physical: Dictionary = {}
var _blocked: Dictionary = {}
var _pending: Dictionary = {}
var _buffer: Dictionary = {}
var _axes: Dictionary = {}
var _axis_blocked: Dictionary = {}
var _last_aim := Vector2.UP
var _click := false
var _click_cursor := Vector2.ZERO
var _keyboard_significant := false
var _pad_significant := false
var _mouse_distance := 0.0
var _cursor_window := Vector2.ZERO
var _click_window := Vector2.ZERO
var _has_cursor := false
var _dash_taps := 0
var _old_accumulation := true

func _ready() -> void:
	_old_accumulation = Input.use_accumulated_input
	Input.use_accumulated_input = false
	Input.joy_connection_changed.connect(_joy_connection)

func _exit_tree() -> void:
	Input.use_accumulated_input = _old_accumulation
	if Input.joy_connection_changed.is_connected(_joy_connection):
		Input.joy_connection_changed.disconnect(_joy_connection)

## Installs validated input tuning; values come from the integration catalog.
func configure(tuning: Dictionary) -> void:
	_tuning = tuning.duplicate(true)
	clear()

## Changes routing and suppresses every held physical input until release.
func set_context(value: String) -> void:
	if context == value:
		return
	context = value
	clear()

## Cancels pending commands and blocks inputs held across pause/focus/context changes.
func clear() -> void:
	for token in _physical:
		_blocked[token] = true
	for pad in _axes:
		_axis_blocked[pad] = true
	_pending.clear()
	_buffer.clear()
	buffer_remaining = 0
	_dash_taps = 0
	_click = false
	_mouse_distance = 0.0

## Removes one successfully executed command without changing the shared deadline.
func consume(action: String) -> void:
	_buffer.erase(action)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.echo:
			return
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		var location: int = int(event.get("location")) if event.get("location") != null else 0
		var token := "k:%s:%s" % [code, location]
		_keyboard_significant = _keyboard_significant or event.pressed
		_button(token, {"kind":"key", "code":code}, event.pressed)
	elif event is InputEventMouseMotion:
		# _input positions are already local to the stretched viewport, not world.
		_capture_cursor(event.position)
		_mouse_distance += event.relative.length()*_window_geometry().scale
	elif event is InputEventMouseButton:
		_capture_cursor(event.position)
		var token := "m:%s" % event.button_index
		var was_blocked: bool = _blocked.has(token)
		_keyboard_significant = _keyboard_significant or event.pressed
		_button(token, {"kind":"mouse", "code":event.button_index}, event.pressed)
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not was_blocked and not _click and context != "transicao":
			_click = true
			_click_cursor = event.position
			var geometry := _window_geometry()
			_click_window = event.position*geometry.scale+geometry.origin
	elif event is InputEventJoypadButton:
		if event.pressed:
			active_pad = event.device
			_pad_significant = true
		_button("p:%s:%s" % [event.device,event.button_index], {"kind":"pad", "code":event.button_index,"pad":event.device},event.pressed)
	elif event is InputEventJoypadMotion:
		if _tuning.is_empty():
			return
		if not _axes.has(event.device):
			_axes[event.device] = {}
		_axes[event.device][event.axis] = event.axis_value
		var dz := float(_tuning.deadzone)
		if absf(event.axis_value) > dz:
			active_pad = event.device
			_pad_significant = true
		if event.axis == JOY_AXIS_TRIGGER_RIGHT:
			var token := "t:%s" % event.device
			var down: bool = event.axis_value >= float(_tuning.trigger_press) or (_physical.has(token) and event.axis_value >= float(_tuning.trigger_release))
			_button(token,{"kind":"trigger","code":0,"pad":event.device},down)
		elif event.axis in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]:
			_axis_navigation(event.device)

func _button(token: String, description: Dictionary, down: bool) -> void:
	var action := _action(description)
	var before := _held_action(action)
	if down:
		_physical[token] = description
	else:
		_physical.erase(token)
		_blocked.erase(token)
	if not action.is_empty() and not before and _held_action(action):
		_pending[action] = true

func _action(entry: Dictionary) -> String:
	if context == "transicao":
		return ""
	var game := context == "jogo"
	var pause_allowed := context in ["jogo","pausa","bencao"]
	var code: int = entry.code
	if entry.kind == "key":
		if code == KEY_ESCAPE:
			return "pausar" if pause_allowed else "ui_voltar"
		if game:
			if code == KEY_J: return "ataque"
			if code == KEY_K: return "especial"
			if code in [KEY_SPACE,KEY_SHIFT,KEY_L]: return "esquiva"
			if code in [KEY_Q,KEY_F]: return "selo"
			if code == KEY_E: return "interagir"
		else:
			if code in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE,KEY_E]: return "ui_aceitar"
			if code in [KEY_A,KEY_LEFT]: return "ui_left"
			if code in [KEY_D,KEY_RIGHT]: return "ui_right"
			if code in [KEY_W,KEY_UP]: return "ui_up"
			if code in [KEY_S,KEY_DOWN]: return "ui_down"
			if context == "bencao" and code in [KEY_1,KEY_2,KEY_3]: return "ui_carta_%s" % (code-KEY_0)
			if code == KEY_R: return "reiniciar"
	elif entry.kind == "mouse":
		if game:
			if code == MOUSE_BUTTON_LEFT: return "ataque"
			if code == MOUSE_BUTTON_RIGHT: return "especial"
	elif entry.kind == "trigger":
		if game and int(entry.pad) == active_pad: return "esquiva"
	elif entry.kind == "pad":
		if int(entry.pad) != active_pad: return ""
		if code == JOY_BUTTON_START: return "pausar" if pause_allowed else ""
		if game:
			if code == JOY_BUTTON_X: return "ataque"
			if code == JOY_BUTTON_Y: return "especial"
			if code == JOY_BUTTON_A: return "esquiva"
			if code in [JOY_BUTTON_B,JOY_BUTTON_LEFT_SHOULDER]: return "selo"
			if code == JOY_BUTTON_RIGHT_SHOULDER: return "interagir"
		else:
			if code == JOY_BUTTON_A: return "ui_aceitar"
			if code == JOY_BUTTON_B and context not in ["pausa","bencao"]: return "ui_voltar"
			if code == JOY_BUTTON_DPAD_LEFT: return "ui_left"
			if code == JOY_BUTTON_DPAD_RIGHT: return "ui_right"
			if code == JOY_BUTTON_DPAD_UP: return "ui_up"
			if code == JOY_BUTTON_DPAD_DOWN: return "ui_down"
	elif entry.kind == "axis_ui" and not game and int(entry.pad) == active_pad:
		return str(entry.action)
	return ""

func _held_action(action: String) -> bool:
	if action.is_empty(): return false
	for token in _physical:
		if not _blocked.has(token) and _action(_physical[token]) == action:
			return true
	return false

func _key_down(codes: Array) -> bool:
	for token in _physical:
		var entry: Dictionary = _physical[token]
		if not _blocked.has(token) and entry.kind == "key" and entry.code in codes:
			return true
	return false

func _stick(pad: int, x_axis: int, y_axis: int) -> Vector2:
	var values: Dictionary = _axes.get(pad,{})
	return Vector2(float(values.get(x_axis,0)),float(values.get(y_axis,0)))

func _radial(value: Vector2) -> Vector2:
	if _tuning.is_empty() or value == Vector2.ZERO:
		return Vector2.ZERO
	var amount := clampf((value.length()-float(_tuning.deadzone))/(1.0-float(_tuning.deadzone)-float(_tuning.outer_deadzone)),0.0,1.0)
	return value.normalized()*amount

func _axis_navigation(pad: int) -> void:
	var stick := _radial(_stick(pad,JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y))
	for action in ["ui_left","ui_right","ui_up","ui_down"]:
		var down: bool = (action == "ui_left" and stick.x < -0.5) or (action == "ui_right" and stick.x > 0.5) or (action == "ui_up" and stick.y < -0.5) or (action == "ui_down" and stick.y > 0.5)
		_button("axis:%s:%s" % [pad,action],{"kind":"axis_ui","code":0,"pad":pad,"action":action},down)

func _joy_connection(device: int, connected: bool) -> void:
	if connected: return
	_axes.erase(device)
	for token in _physical.keys():
		if int(_physical[token].get("pad",-2)) == device:
			_physical.erase(token)
	if active_pad == device:
		active_pad = -1
		if active_device == "gamepad":
			clear()
			device_disconnected.emit()

func _window_geometry() -> Dictionary:
	var logical_size := get_viewport().get_visible_rect().size
	var window_size := Vector2(get_window().size)
	if logical_size.x <= 0 or logical_size.y <= 0 or window_size.x <= 0 or window_size.y <= 0:
		return {"scale":1.0,"origin":Vector2.ZERO}
	var scale := minf(window_size.x/logical_size.x,window_size.y/logical_size.y)
	return {"scale":scale,"origin":(window_size-logical_size*scale)/2.0}

func _capture_cursor(logical_position: Vector2) -> void:
	var geometry := _window_geometry()
	var window_position: Vector2 = logical_position*geometry.scale+geometry.origin
	# Keep the last valid point when the pointer leaves the content window.
	if not Rect2(Vector2.ZERO,Vector2(get_window().size)).has_point(window_position): return
	_cursor_window = window_position
	cursor = logical_position
	_has_cursor = true

## Captures one physics-step sample; the caller consumes successful commands afterward.
func sample(hitstop: bool, camera) -> Dictionary:
	var geometry := _window_geometry()
	if _has_cursor:
		cursor = (_cursor_window-geometry.origin)/geometry.scale
	if _click:
		_click_cursor = (_click_window-geometry.origin)/geometry.scale
	var pressed := _pending.duplicate()
	_pending.clear()
	var held: Dictionary = {}
	for token in _physical:
		if _blocked.has(token): continue
		var action := _action(_physical[token])
		if not action.is_empty(): held[action] = true
	var kb := Vector2(float(_key_down([KEY_D,KEY_RIGHT]))-float(_key_down([KEY_A,KEY_LEFT])),float(_key_down([KEY_S,KEY_DOWN]))-float(_key_down([KEY_W,KEY_UP])))
	var left := _radial(_stick(active_pad,JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y))
	var right := _radial(_stick(active_pad,JOY_AXIS_RIGHT_X,JOY_AXIS_RIGHT_Y))
	if _axis_blocked.has(active_pad):
		if left == Vector2.ZERO and right == Vector2.ZERO:
			_axis_blocked.erase(active_pad)
		else:
			left = Vector2.ZERO
			right = Vector2.ZERO
	var move := kb.normalized() if kb != Vector2.ZERO else left
	var mouse_moved := _mouse_distance > 0.0
	var significant := _keyboard_significant or (not _tuning.is_empty() and _mouse_distance >= float(_tuning.mouse_threshold))
	if significant != _pad_significant:
		active_device = "teclado" if significant else "gamepad"
	_keyboard_significant = false
	_pad_significant = false
	_mouse_distance = 0
	aim_intensity = 0.0
	if active_device == "teclado":
		source = "mouse"
		var aim_delta: Vector2 = camera.screen_to_world(cursor)-player_position
		if aim_delta != Vector2.ZERO: _last_aim = aim_delta.normalized()
	elif right != Vector2.ZERO:
		source = "analogico"
		aim_intensity = right.length()
		_last_aim = right.normalized()
	else:
		source = "automatica"
		var best := float(_tuning.get("auto_aim_radius",0.0))
		var best_squared := best*best
		var selected := Vector2.ZERO
		for enemy: Dictionary in targets:
			if float(enemy.get("hp",0)) <= 0 or str(enemy.get("phase","")) in ["spawn","surgindo"]: continue
			var delta: Vector2 = enemy.pos-player_position
			var distance := delta.length_squared()
			if distance > 0 and (distance < best_squared or (distance == best_squared and selected == Vector2.ZERO)):
				best_squared = distance
				selected = delta
		if selected != Vector2.ZERO: _last_aim = selected.normalized()
		elif move != Vector2.ZERO: _last_aim = move.normalized()
	var game := context == "jogo"
	if game:
		var fresh := false
		for action in BUFFERED:
			if pressed.has(action):
				_buffer[action] = true
				fresh = true
		if pressed.has("esquiva"): _dash_taps += 1
		if fresh: buffer_remaining = int(_tuning.buffer_steps)
		elif buffer_remaining > 0 and not hitstop:
			buffer_remaining -= 1
			if buffer_remaining == 0: _buffer.clear()
	else:
		if context != "campus":
			move = Vector2.ZERO
		_buffer.clear()
		buffer_remaining = 0
	var wants: Dictionary = {}
	for action in BUFFERED:
		wants[action] = game and (_buffer.has(action) or (action in ["ataque","especial"] and held.has(action)))
	var taps := _dash_taps if game and not hitstop else 0
	if game and not hitstop: _dash_taps = 0
	var result := {"move":move,"aim":_last_aim,"pressed":pressed,"held":held,"wants":wants,"cursor":cursor,"mouse_moved":mouse_moved,"mouse_click":_click,"click_cursor":_click_cursor,"source":source,"aim_intensity":aim_intensity,"dash_taps":taps}
	_click = false
	return result
