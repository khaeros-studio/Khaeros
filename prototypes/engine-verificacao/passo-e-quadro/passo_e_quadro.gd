# PROTOTYPE - NOT FOR PRODUCTION (engine-verificacao)
extends Node
## EX-0001-1/2/6: mede padrões do passo de física, ordem _physics_process × _process,
## passos por quadro com quadro atrasado e o primeiro quadro após mover a janela.
## Modos (args de usuário depois de `--`): ordem | atraso | arrasto. Saída em stdout, prefixo "EX|".

var _modo: String = "ordem"
var _passos_no_quadro: int = 0
var _quadro: int = 0
var _seq: PackedStringArray = []
var _hist_passos: Dictionary = {}
var _atrasos: Array[int] = [50, 100, 250]
var _atraso_idx: int = 0
var _rep: int = 0
var _aguardando_medida: bool = false
var _atraso_ms: int = 0
var _t0_us: int = 0
var _max_delta: float = 0.0
var _deltas_altos: PackedStringArray = []


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--modo="):
			_modo = a.substr(7)
	print("EX|modo=%s versao=%s debug_build=%s headless=%s" % [_modo, Engine.get_version_info().string, OS.is_debug_build(), DisplayServer.get_name()])
	print("EX|PS physics_ticks_per_second=%s" % str(ProjectSettings.get_setting("physics/common/physics_ticks_per_second")))
	print("EX|PS max_physics_steps_per_frame=%s" % str(ProjectSettings.get_setting("physics/common/max_physics_steps_per_frame")))
	print("EX|PS physics_jitter_fix=%s" % str(ProjectSettings.get_setting("physics/common/physics_jitter_fix")))
	print("EX|PS physics_interpolation=%s" % str(ProjectSettings.get_setting("physics/common/physics_interpolation")))
	print("EX|Engine physics_ticks_per_second=%d max_physics_steps_per_frame=%d max_fps=%d" % [Engine.physics_ticks_per_second, Engine.max_physics_steps_per_frame, Engine.max_fps])
	_t0_us = Time.get_ticks_usec()
	if _modo == "arrasto":
		print("EX|arrasto: pronto (hwnd=%d)" % DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE))


func _physics_process(delta: float) -> void:
	_passos_no_quadro += 1
	if _modo == "ordem" and _quadro >= 20 and _quadro < 120:
		_seq.append("P%d" % Engine.get_process_frames())


func _process(delta: float) -> void:
	_quadro += 1
	var n: int = _passos_no_quadro
	_passos_no_quadro = 0
	match _modo:
		"ordem":
			_modo_ordem(n, delta)
		"atraso":
			_modo_atraso(n, delta)
		"arrasto":
			_modo_arrasto(n, delta)


func _modo_ordem(n: int, delta: float) -> void:
	# Força quadros com 0, 1 e 2+ passos: alterna quadro rápido e quadro de 40 ms.
	if _quadro >= 20 and _quadro < 120:
		_seq.append("R%d(n=%d)" % [Engine.get_process_frames(), n])
		_hist_passos[n] = int(_hist_passos.get(n, 0)) + 1
		if _quadro % 10 == 0:
			OS.delay_msec(40)
	elif _quadro == 120:
		print("EX|ordem seq(100 quadros)=%s" % " ".join(_seq))
		print("EX|ordem histograma passos/quadro=%s" % str(_hist_passos))
		# Verifica: todo P<f> aparece antes do R<f> do mesmo quadro.
		var viol: int = 0
		var vistos_r: Dictionary = {}
		for s: String in _seq:
			if s.begins_with("R"):
				vistos_r[s.substr(1).split("(")[0]] = true
			elif vistos_r.has(s.substr(1)):
				viol += 1
		print("EX|ordem violacoes(P depois de R no mesmo quadro)=%d" % viol)
		get_tree().quit()


func _modo_atraso(n: int, delta: float) -> void:
	if _quadro < 30:
		return
	if _aguardando_medida:
		print("EX|atraso=%dms rep=%d passos_no_quadro_seguinte=%d delta_process=%.4f" % [_atraso_ms, _rep, n, delta])
		_aguardando_medida = false
		_rep += 1
		if _rep >= 5:
			_rep = 0
			_atraso_idx += 1
		return
	if _atraso_idx >= _atrasos.size():
		get_tree().quit()
		return
	if _quadro % 8 == 0:
		_atraso_ms = _atrasos[_atraso_idx]
		OS.delay_msec(_atraso_ms)
		_aguardando_medida = true


func _modo_arrasto(n: int, delta: float) -> void:
	if delta > _max_delta:
		_max_delta = delta
	if delta > 0.05 or n > 2:
		_deltas_altos.append("q%d d=%.4f n=%d t=%.2fs" % [_quadro, delta, n, (Time.get_ticks_usec() - _t0_us) / 1e6])
	if Time.get_ticks_usec() - _t0_us > 14_000_000:
		print("EX|arrasto quadros=%d max_delta=%.4f" % [_quadro, _max_delta])
		print("EX|arrasto quadros_altos=%s" % ", ".join(_deltas_altos))
		get_tree().quit()
