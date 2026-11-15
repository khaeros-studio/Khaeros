extends SceneTree

# Disposable fixture: these bindings and 10 ticks are approved GDD test vectors.
class Collector extends Node:
	var held: Dictionary = {}
	var blocked: Dictionary = {}
	var pending: Dictionary = {}
	var context: String = "Jogo"
	var received: int = 0
	var mouse_distance: float = 0.0
	var mouse_events: int = 0

	func action_for(key: int) -> String:
		if context == "Transicao":
			return ""
		if key == KEY_SPACE:
			return "esquiva" if context == "Jogo" else "ui_aceitar"
		if context == "Jogo" and key in [KEY_J, KEY_K]:
			return "ataque"
		return ""

	func action_held(action: String) -> bool:
		for key: int in held:
			if not blocked.has(key) and action_for(key) == action:
				return true
		return false

	func _input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			mouse_distance += event.relative.length()
			mouse_events += 1
			return
		if not event is InputEventKey:
			return
		received += 1
		if event.echo:
			return
		var key: int = event.physical_keycode
		var action: String = action_for(key)
		var was_held: bool = action_held(action) if not action.is_empty() else false
		if event.pressed:
			held[key] = true
		else:
			held.erase(key)
			blocked.erase(key)
		if not action.is_empty() and not was_held and action_held(action):
			pending[action] = true

	func sample() -> Dictionary:
		var held_actions: Dictionary = {}
		for key: int in held:
			var action := action_for(key)
			if not action.is_empty() and not blocked.has(key):
				held_actions[action] = true
		var result := {"pressed": pending.duplicate(), "held": held_actions, "mouse_distance": mouse_distance, "mouse_events": mouse_events}
		pending.clear()
		mouse_distance = 0.0
		mouse_events = 0
		return result

	func change_context(next: String) -> void:
		context = next
		pending.clear()
		for key: int in held:
			blocked[key] = true

class CommandBuffer extends RefCounted:
	var buttons: Dictionary = {}
	var remaining: int = 0
	var limit: int = 10

	func advance(pressed: Array, hitstop: bool) -> void:
		var new_command := false
		for action: String in pressed:
			if action in ["esquiva", "especial", "ataque", "selo"]:
				buttons[action] = true
				new_command = true
		if new_command:
			remaining = limit
		elif remaining > 0 and not hitstop:
			remaining -= 1
			if remaining == 0:
				buttons.clear()

	func wants(action: String, held: bool = false) -> bool:
		return buttons.has(action) or (held and action in ["ataque", "especial"])

	func consume(action: String) -> void:
		buttons.erase(action)

var checks: int = 0
var failures: int = 0
var collector: Collector


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func key_event(key: int, pressed: bool, echo: bool = false, logical: int = 0) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = logical if logical != 0 else key
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)


func run() -> void:
	var previous_accumulation := Input.use_accumulated_input
	Input.use_accumulated_input = false
	collector = Collector.new()
	root.add_child(collector)
	collector.set_process_input(true)

	key_event(KEY_J, true)
	key_event(KEY_J, false)
	var sample := collector.sample()
	check(collector.received == 2, "parse_input_event delivers press and release to Node._input")
	check(sample.pressed.has("ataque") and not sample.held.has("ataque"), "quick tap survives between samples")
	sample = collector.sample()
	check(sample.pressed.is_empty() and sample.held.is_empty(), "second catch-up step does not repeat edge")

	key_event(KEY_J, true)
	key_event(KEY_J, false)
	key_event(KEY_J, true)
	sample = collector.sample()
	check(sample.pressed.size() == 1 and sample.held.has("ataque"), "press release press is one edge and held")
	key_event(KEY_J, true, true)
	sample = collector.sample()
	check(sample.pressed.is_empty() and sample.held.has("ataque"), "keyboard echo creates no edge")
	key_event(KEY_K, true)
	sample = collector.sample()
	check(sample.pressed.is_empty() and sample.held.has("ataque"), "second physical binding does not retrigger held action")
	key_event(KEY_J, false)
	sample = collector.sample()
	check(sample.held.has("ataque"), "releasing primary preserves held secondary")
	key_event(KEY_K, false)
	check(collector.sample().held.is_empty(), "last binding release clears held action")
	key_event(KEY_J, true, false, KEY_Z)
	check(collector.sample().pressed.has("ataque"), "physical key wins over logical layout label")
	key_event(KEY_J, false)
	collector.sample()
	for delta: Vector2 in [Vector2(3, 4), Vector2(-3, -4)]:
		var motion := InputEventMouseMotion.new()
		motion.relative = delta
		Input.parse_input_event(motion)
	sample = collector.sample()
	check(sample.mouse_events == 2, "disabled accumulation delivers opposite mouse motions separately")
	check(is_equal_approx(sample.mouse_distance, 10.0), "F5 sums individual lengths even when net displacement is zero")
	check(is_zero_approx(collector.sample().mouse_distance), "mouse distance resets after one sample")

	key_event(KEY_SPACE, true)
	key_event(KEY_SPACE, false)
	collector.change_context("Menu")
	check(collector.sample().pressed.is_empty(), "press and release in switch interval are discarded even when already released")
	collector.change_context("Jogo")

	key_event(KEY_SPACE, true)
	collector.change_context("Menu")
	sample = collector.sample()
	check(sample.pressed.is_empty() and sample.held.is_empty(), "same-interval context switch clears pending and blocks held physical key")
	key_event(KEY_SPACE, true, true)
	check(collector.sample().pressed.is_empty(), "held-key echo cannot accept menu")
	key_event(KEY_SPACE, false)
	key_event(KEY_SPACE, true)
	check(collector.sample().pressed.has("ui_aceitar"), "release then fresh press accepts new context")
	collector.change_context("Jogo")
	check(collector.sample().held.is_empty(), "menu confirmation cannot become gameplay command")
	key_event(KEY_SPACE, false)
	collector.change_context("Transicao")
	key_event(KEY_J, true)
	key_event(KEY_SPACE, true)
	check(collector.sample().pressed.is_empty(), "transition records no gameplay actions")
	collector.change_context("Jogo")
	check(collector.sample().held.is_empty(), "buttons held through transition stay suppressed")
	key_event(KEY_J, false)
	key_event(KEY_SPACE, false)
	key_event(KEY_SPACE, true)
	check(collector.sample().pressed.has("esquiva"), "release restores gameplay after transition")
	key_event(KEY_SPACE, false)
	collector.sample()

	var buffer := CommandBuffer.new()
	buffer.advance(["ataque"], false)
	check(buffer.remaining == 10 and buffer.wants("ataque"), "F3 tap step zero has T=10")
	var live_window := true
	for tick in range(1, 10):
		buffer.advance([], false)
		live_window = live_window and buffer.wants("ataque") and buffer.remaining == 10 - tick
	check(live_window, "F3 attack remains available through step nine")
	buffer.advance([], false)
	check(buffer.remaining == 0 and not buffer.wants("ataque"), "F3 expires at step ten")

	for tap_step in [0, 20]:
		buffer = CommandBuffer.new()
		for tick in range(36):
			buffer.advance(["esquiva"] if tick == tap_step else [], true)
		check(buffer.remaining == 10 and buffer.wants("esquiva"), "hitstop36 preserves tap at step %d" % tap_step)
		var post_hitstop := true
		for tick in range(36, 45):
			buffer.advance([], false)
			post_hitstop = post_hitstop and buffer.wants("esquiva")
		check(post_hitstop and buffer.remaining == 1, "tap %d lives through steps36-44" % tap_step)
		buffer.advance([], false)
		check(not buffer.wants("esquiva"), "tap %d expires at step45" % tap_step)

	buffer = CommandBuffer.new()
	for tick in range(18):
		buffer.advance(["ataque"] if tick == 0 else (["especial"] if tick == 8 else []), false)
	check(buffer.wants("ataque") and buffer.wants("especial") and buffer.remaining == 1, "new special at8 refreshes shared deadline through17")
	buffer.advance([], false)
	check(buffer.buttons.is_empty(), "both commands expire together at18")
	buffer.advance(["selo", "ataque", "especial", "esquiva"], false)
	buffer.consume("esquiva")
	check(buffer.buttons.size() == 3 and buffer.remaining == 10, "consume dodge preserves other commands and deadline")
	buffer.consume("especial")
	check(buffer.wants("ataque") and buffer.wants("selo") and buffer.remaining == 10, "consume special leaves attack and seal")
	buffer = CommandBuffer.new()
	check(buffer.wants("ataque", true) and buffer.wants("especial", true), "held attack and special repeat without buffer")
	check(not buffer.wants("esquiva", true) and not buffer.wants("selo", true), "held dodge and seal do not repeat")
	buffer.advance(["interagir", "pausar"], false)
	check(buffer.buttons.is_empty() and buffer.remaining == 0, "interact and pause never enter buffer")
	buffer.limit = 5
	buffer.advance(["esquiva"], false)
	for tick in range(4):
		buffer.advance([], false)
	check(buffer.wants("esquiva") and buffer.remaining == 1, "injected buffer5 remains through step4")
	buffer.advance([], false)
	check(not buffer.wants("esquiva"), "injected buffer5 expires at step5")
	Input.use_accumulated_input = previous_accumulation
	print("RESULT checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
