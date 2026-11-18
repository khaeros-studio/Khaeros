# PROTOTYPE - NOT FOR PRODUCTION (EX-0001-4, EX-0001-5, EX-0012-E3; story-003)
## Fase de apresentação: mede quanto cada nó anima com a flag pausado_proprio (sem SceneTree.paused),
## com parada explícita por tipo e com process_mode DISABLED. Depois registra foco/joy/clique por 16 s.
extends Node2D

var pausado_proprio := false
var _t0 := 0
var _box: Node2D
var _alvo_tween: Node2D
var _tween: Tween
var _anim: AnimationPlayer
var _gpu: GPUParticles2D
var _cpu: CPUParticles2D
var _spr: AnimatedSprite2D
var _aud: AudioStreamPlayer
var _trocas_spr := 0


func _ms() -> int:
	return Time.get_ticks_msec() - _t0


func _notification(what: int) -> void:
	var nomes := {NOTIFICATION_APPLICATION_FOCUS_IN: "APPLICATION_FOCUS_IN", NOTIFICATION_APPLICATION_FOCUS_OUT: "APPLICATION_FOCUS_OUT",
		NOTIFICATION_WM_WINDOW_FOCUS_IN: "WM_WINDOW_FOCUS_IN", NOTIFICATION_WM_WINDOW_FOCUS_OUT: "WM_WINDOW_FOCUS_OUT",
		NOTIFICATION_APPLICATION_PAUSED: "APPLICATION_PAUSED", NOTIFICATION_APPLICATION_RESUMED: "APPLICATION_RESUMED"}
	if nomes.has(what):
		print("EX|foco t=%d notif %s (no nó raiz da cena) foreground_input=%s" % [_ms(), nomes[what], str(get_window().has_focus())])


func _input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		print("EX|foco t=%d _input %s pressed=%s pos=%s" % [_ms(), ev.get_class(), str(ev.pressed), str(ev.position)])


func _ready() -> void:
	_t0 = Time.get_ticks_msec()
	print("EX|engine ", Engine.get_version_info().string, " pause_on_focus_loss existe=", ProjectSettings.has_setting("application/run/pause_on_focus_loss"),
		" ignore_joypad_on_unfocused=", ProjectSettings.get_setting("input_devices/joypads/ignore_joypad_on_unfocused_application", "?"))
	print("EX|joy conectados=", Input.get_connected_joypads())
	Input.joy_connection_changed.connect(func(d: int, c: bool) -> void: print("EX|joy t=%d joy_connection_changed device=%d connected=%s" % [_ms(), d, str(c)]))
	get_window().focus_entered.connect(func() -> void: print("EX|foco t=%d Window.focus_entered" % _ms()))
	get_window().focus_exited.connect(func() -> void: print("EX|foco t=%d Window.focus_exited" % _ms()))
	_montar()
	await _apresentacao()
	await get_tree().create_timer(16.0).timeout
	get_tree().quit()


func _tex(cor: Color) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(cor)
	return ImageTexture.create_from_image(img)


func _montar() -> void:
	_box = Node2D.new()
	add_child(_box)
	_alvo_tween = Node2D.new()
	_box.add_child(_alvo_tween)
	_tween = _alvo_tween.create_tween().set_loops()
	_tween.tween_property(_alvo_tween, "position:x", 100.0, 1.0)
	_tween.tween_property(_alvo_tween, "position:x", 0.0, 1.0)
	var alvo_anim := Node2D.new()
	alvo_anim.name = "AlvoAnim"
	_box.add_child(alvo_anim)
	_anim = AnimationPlayer.new()
	_box.add_child(_anim)
	var a := Animation.new()
	a.length = 2.0
	a.loop_mode = Animation.LOOP_LINEAR
	var tr := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tr, NodePath("AlvoAnim:rotation"))
	a.track_insert_key(tr, 0.0, 0.0)
	a.track_insert_key(tr, 2.0, TAU)
	var lib := AnimationLibrary.new()
	lib.add_animation("gira", a)
	_anim.add_animation_library("", lib)
	_anim.play("gira")
	_gpu = GPUParticles2D.new()
	_gpu.process_material = ParticleProcessMaterial.new()
	_gpu.amount = 32
	_gpu.lifetime = 4.0
	_box.add_child(_gpu)
	_cpu = CPUParticles2D.new()
	_cpu.amount = 32
	_cpu.lifetime = 4.0
	_box.add_child(_cpu)
	_spr = AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.add_frame("default", _tex(Color.RED))
	sf.add_frame("default", _tex(Color.BLUE))
	sf.set_animation_speed("default", 20.0)
	sf.set_animation_loop("default", true)
	_spr.sprite_frames = sf
	_spr.frame_changed.connect(func() -> void: _trocas_spr += 1)
	_box.add_child(_spr)
	_spr.play("default")
	_aud = AudioStreamPlayer.new()
	var w := AudioStreamWAV.new()
	var dados := PackedByteArray()
	dados.resize(44100 * 2)
	for k in 44100:
		dados.encode_s16(k * 2, int(sin(TAU * 441.0 * k / 44100.0) * 3000.0))
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = 44100
	w.data = dados
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = 44099
	_aud.stream = w
	_box.add_child(_aud)
	_aud.play()


## Retrato do estado de cada nó; partículas via tempo de simulação não exposto, então
## GPU/CPU usam o deslocamento médio das partículas visíveis lido pela captura da tela.
func _retrato() -> Dictionary:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	return {"tween_x": _alvo_tween.position.x, "anim_pos": _anim.current_animation_position, "spr_trocas": _trocas_spr,
		"aud_pos": _aud.get_playback_position(), "img": img}


func _difere(a: Image, b: Image, centro: Vector2i) -> int:
	var n := 0
	for y in range(centro.y - 60, centro.y + 60):
		for x in range(centro.x - 60, centro.x + 60):
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				n += 1
	return n


func _fase(nome: String) -> void:
	var r0 := await _retrato()
	await get_tree().create_timer(0.7).timeout
	var r1 := await _retrato()
	print("EX|apres fase=%s tween_dx=%.2f anim_dpos=%.3f spr_trocas=%d aud_dpos=%.3f gpu_px_mudados=%d cpu_px_mudados=%d" % [
		nome, absf(r1["tween_x"] - r0["tween_x"]), absf(r1["anim_pos"] - r0["anim_pos"]), r1["spr_trocas"] - r0["spr_trocas"],
		r1["aud_pos"] - r0["aud_pos"],
		_difere(r0["img"], r1["img"], Vector2i(200, 180)), _difere(r0["img"], r1["img"], Vector2i(440, 180))])


func _parar(sim: bool) -> void:
	if sim:
		_tween.pause()
	else:
		_tween.play()
	_anim.speed_scale = 0.0 if sim else 1.0
	_gpu.speed_scale = 0.0 if sim else 1.0
	_cpu.speed_scale = 0.0 if sim else 1.0
	_spr.speed_scale = 0.0 if sim else 1.0
	_aud.stream_paused = sim


func _apresentacao() -> void:
	_gpu.position = Vector2(200, 180)
	_cpu.position = Vector2(440, 180)
	await get_tree().create_timer(1.0).timeout
	await _fase("0_normal")
	pausado_proprio = true
	await _fase("1_flag_sem_parar")
	_parar(true)
	await _fase("2_parada_explicita")
	_parar(false)
	pausado_proprio = false
	await _fase("3_retomado")
	_box.process_mode = Node.PROCESS_MODE_DISABLED
	await _fase("4_process_mode_disabled")
	_box.process_mode = Node.PROCESS_MODE_INHERIT
	await _fase("5_retomado")
	print("EX|apres fim t=%d" % _ms())
