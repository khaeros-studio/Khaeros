# PROTOTYPE - NOT FOR PRODUCTION (engine-verificacao)
extends Node2D
## EX-0002-3 (ordem de sinais/CONNECT_DEFERRED) e EX-0010-1 (frame_post_draw e latência
## toque→golpe). Args: --vsync liga vsync (padrão: desligado, max_fps 144). Saída "EX|".

signal eventos_do_passo(n: int)

const AMOSTRAS: int = 40
var _log_sinais: PackedStringArray = []
var _quadro: int = 0
var _post_draw_no_quadro: int = 0
var _hist_post_draw: Dictionary = {}
var _rect: ColorRect
var _t_toque_us: int = 0
var _passo_golpe_pendente: bool = false
var _golpe_aplicado_us: int = 0
var _esperando_desenho: bool = false
var _amostras_ms: PackedFloat64Array = []
var _passos_ate_golpe: PackedInt32Array = []
var _passos_desde_toque: int = 0
var _proximo_toque_quadro: int = 60

func _ready() -> void:
	var vsync: bool = "--vsync" in OS.get_cmdline_user_args()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	if not vsync:
		Engine.max_fps = 144
	print("EX|versao=%s vsync=%s max_fps=%d refresh=%.0f" % [Engine.get_version_info().string, vsync, Engine.max_fps, DisplayServer.screen_get_refresh_rate()])
	_teste_sinais()
	var ev := InputEventKey.new()
	InputMap.add_action(&"golpe")
	ev.physical_keycode = KEY_J
	InputMap.action_add_event(&"golpe", ev)
	_rect = ColorRect.new()
	_rect.size = Vector2(64, 64)
	_rect.color = Color.BLACK
	add_child(_rect)
	RenderingServer.frame_post_draw.connect(_post_draw)

func _teste_sinais() -> void:
	# Conecta em ordem diferente da ordem fixa do ADR (Telemetria, HUD, Feedback, Telas, Áudio).
	for nome: String in ["Audio", "HUD", "Telemetria", "Telas", "Feedback"]:
		eventos_do_passo.connect(func(n: int) -> void: _log_sinais.append("%s(def,q%d)" % [nome, Engine.get_process_frames()]), CONNECT_DEFERRED)
	eventos_do_passo.connect(func(n: int) -> void: _log_sinais.append("Sincrono(q%d)" % Engine.get_process_frames()))
	_log_sinais.append("emit(q%d)" % Engine.get_process_frames())
	eventos_do_passo.emit(1)
	_log_sinais.append("depois_do_emit(q%d)" % Engine.get_process_frames())

func _physics_process(_delta: float) -> void:
	if _esperando_desenho or _t_toque_us == 0:
		return
	_passos_desde_toque += 1
	if Input.is_action_just_pressed(&"golpe"):
		# "Golpe": muda o visual neste passo.
		_rect.color = Color.WHITE if _rect.color == Color.BLACK else Color.BLACK
		_golpe_aplicado_us = Time.get_ticks_usec()
		_passos_ate_golpe.append(_passos_desde_toque)
		_esperando_desenho = true

func _process(_delta: float) -> void:
	_quadro += 1
	if _quadro == 2400:
		print("EX|diag TIMEOUT amostras=%d passos=%s t_toque=%d" % [_amostras_ms.size(), str(_passos_ate_golpe), _t_toque_us])
		get_tree().quit()
	if _quadro == 5:
		print("EX|sinais ordem=%s" % " ".join(_log_sinais))
	if _quadro > 2:
		_hist_post_draw[_post_draw_no_quadro] = int(_hist_post_draw.get(_post_draw_no_quadro, 0)) + 1
	_post_draw_no_quadro = 0
	if _quadro == _proximo_toque_quadro and _t_toque_us == 0:
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_J
		ev.pressed = true
		_t_toque_us = Time.get_ticks_usec()
		_passos_desde_toque = 0
		Input.parse_input_event(ev)

func _post_draw() -> void:
	_post_draw_no_quadro += 1
	if _esperando_desenho:
		_amostras_ms.append((Time.get_ticks_usec() - _t_toque_us) / 1000.0)
		_esperando_desenho = false
		_t_toque_us = 0
		var up := InputEventKey.new()
		up.physical_keycode = KEY_J
		up.pressed = false
		Input.parse_input_event(up)
		_proximo_toque_quadro = _quadro + 7 + (_amostras_ms.size() % 5)
		if _amostras_ms.size() >= AMOSTRAS:
			var s: PackedFloat64Array = _amostras_ms.duplicate(); s.sort()
			var soma: float = 0.0
			for x in s: soma += x
			print("EX|latencia n=%d media_ms=%.2f mediana_ms=%.2f p95_ms=%.2f max_ms=%.2f min_ms=%.2f" % [s.size(), soma / s.size(), s[s.size() / 2], s[int(s.size() * 0.95)], s[s.size() - 1], s[0]])
			print("EX|latencia passos_ate_golpe=%s" % str(_passos_ate_golpe))
			print("EX|post_draw por _process (histograma)=%s" % str(_hist_post_draw))
			get_tree().quit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and _amostras_ms.size() < 2:
		print("EX|diag _input key=%s pressed=%s action_golpe=%s q=%d" % [event.physical_keycode, event.pressed, event.is_action(&"golpe"), _quadro])
