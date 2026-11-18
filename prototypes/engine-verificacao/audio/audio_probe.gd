# PROTOTYPE - NOT FOR PRODUCTION (EX-0016-A, story-009)
## Mede a API de áudio com captura do barramento Efeitos (AudioEffectCapture).
## Modos: --modo=bus (só barramentos, para o .pck exportado) e --modo=tudo.
extends Node

var _cap: AudioEffectCapture
var _gravando := false
var _amostras := PackedFloat32Array()
var _modo := "tudo"


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--modo="):
			_modo = a.substr(7)
	print("EX|engine ", Engine.get_version_info().string, " driver=", AudioServer.get_driver_name(),
		" mix_rate=", AudioServer.get_mix_rate(), " debug=", OS.is_debug_build())
	_barramentos()
	if _modo == "bus":
		get_tree().quit()
		return
	_volumes_estaticos()
	var ief := AudioServer.get_bus_index("Efeitos")
	_cap = AudioEffectCapture.new()
	_cap.buffer_length = 2.0
	AudioServer.add_bus_effect(ief, _cap)
	await _medir()
	get_tree().quit()


func _process(_d: float) -> void:
	if _cap == null:
		return
	var n := _cap.get_frames_available()
	if n <= 0:
		return
	var buf := _cap.get_buffer(n)
	if _gravando:
		for v in buf:
			_amostras.append(v.x)


func _barramentos() -> void:
	var nomes: Array[String] = []
	for i in AudioServer.bus_count:
		nomes.append("%d:%s->%s" % [i, AudioServer.get_bus_name(i), AudioServer.get_bus_send(i)])
	print("EX|bus count=", AudioServer.bus_count, " ", nomes)
	for nome in ["Master", "Musica", "Efeitos", "Interface", "Inexistente", ""]:
		print("EX|bus get_bus_index('", nome, "')=", AudioServer.get_bus_index(nome))
	print("EX|bus setting default_bus_layout=", ProjectSettings.get_setting("audio/buses/default_bus_layout", "<ausente>"))


func _volumes_estaticos() -> void:
	for x in [1.0, 0.5, 0.25, 0.0]:
		print("EX|lin2db linear_to_db(", x, ")=", linear_to_db(x))
	print("EX|lin2db db_to_linear(-6.0206)=", db_to_linear(-6.0206), " db_to_linear(-INF)=", db_to_linear(-INF))
	var p := AudioStreamPlayer.new()
	add_child(p)
	p.volume_db = linear_to_db(0.0)
	print("EX|vol volume_db apos linear_to_db(0)=", p.volume_db)
	p.volume_db = -6.0
	print("EX|vol volume_db leitura=", p.volume_db, " volume_linear=", p.get("volume_linear"))
	p.pitch_scale = 0.0
	print("EX|pitch pitch_scale=0.0 lido=", p.pitch_scale)
	p.pitch_scale = 8.0
	print("EX|pitch pitch_scale=8.0 lido=", p.pitch_scale)
	p.pitch_scale = 20.0
	print("EX|pitch pitch_scale=20.0 lido=", p.pitch_scale)
	p.queue_free()


func _gravar(seg: float) -> PackedFloat32Array:
	_cap.clear_buffer()
	_amostras = PackedFloat32Array()
	_gravando = true
	await get_tree().create_timer(seg).timeout
	_gravando = false
	return _amostras


func _rms(s: PackedFloat32Array) -> float:
	if s.is_empty():
		return 0.0
	var acc := 0.0
	for v in s:
		acc += v * v
	return sqrt(acc / s.size())


func _freq(s: PackedFloat32Array) -> float:
	var cruz := 0
	for k in range(1, s.size()):
		if s[k - 1] < 0.0 and s[k] >= 0.0:
			cruz += 1
	return cruz / (s.size() / AudioServer.get_mix_rate())


func _max_delta(s: PackedFloat32Array) -> float:
	var m := 0.0
	for k in range(1, s.size()):
		m = maxf(m, absf(s[k] - s[k - 1]))
	return m


## Saltos maiores que 1,5x o delta de um seno puro; devolve [qtd, posições].
func _saltos(s: PackedFloat32Array, ref: float) -> Array:
	var pos: Array[int] = []
	for k in range(1, s.size()):
		if absf(s[k] - s[k - 1]) > ref * 1.5:
			pos.append(k)
	return [pos.size(), pos.slice(0, 8)]


func _player(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "Efeitos"
	add_child(p)
	return p


func _tom_mem(seg: float, loop: bool) -> AudioStreamWAV:
	var taxa := 44100
	var n := int(taxa * seg)
	var dados := PackedByteArray()
	dados.resize(n * 2)
	for k in n:
		dados.encode_s16(k * 2, int(round(sin(TAU * 441.0 * k / taxa) * 0.5 * 32767.0)))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = taxa
	w.data = dados
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = n
	return w


func _medir() -> void:
	await get_tree().create_timer(0.3).timeout
	# pitch_scale em tempo real, mesma voz tocando.
	var p := _player(_tom_mem(1.0, true))
	p.play()
	await get_tree().create_timer(0.3).timeout
	for ps in [1.0, 0.25, 0.5, 2.0, 4.0, 1.0]:
		p.pitch_scale = ps
		await get_tree().create_timer(0.15).timeout
		var s := await _gravar(0.4)
		print("EX|pitch pitch_scale=%.2f freq_medida=%.1f Hz (esperado %.1f) rms=%.4f amostras=%d" % [ps, _freq(s), 441.0 * ps, _rms(s), s.size()])
	# volume_db: razão de RMS.
	p.pitch_scale = 1.0
	var ref := 0.0
	for lin in [1.0, 0.5, 0.0]:
		p.volume_db = linear_to_db(lin)
		await get_tree().create_timer(0.15).timeout
		var s := await _gravar(0.3)
		var r := _rms(s)
		if lin == 1.0:
			ref = r
		print("EX|vol linear=%.2f volume_db=%s rms=%.5f razao=%.4f" % [lin, str(p.volume_db), r, (r / ref) if ref > 0.0 else 0.0])
	p.stop()
	p.queue_free()
	await get_tree().create_timer(0.2).timeout
	# stream_paused: stream de 3 s sem loop.
	var q := _player(_tom_mem(3.0, false))
	q.play()
	await get_tree().create_timer(0.8).timeout
	var pos1 := q.get_playback_position()
	q.stream_paused = true
	var s_pausa := await _gravar(0.6)
	var pos2 := q.get_playback_position()
	print("EX|pausa pos_antes=%.3f pos_durante=%.3f playing=%s rms_durante=%.5f" % [pos1, pos2, str(q.playing), _rms(s_pausa)])
	q.stream_paused = false
	await get_tree().create_timer(0.5).timeout
	print("EX|pausa pos_0.5s_depois=%.3f playing=%s (reinicio daria ~0.5)" % [q.get_playback_position(), str(q.playing)])
	q.stop()
	q.queue_free()
	# Loop por flag de import.
	var mem := _tom_mem(1.0, true)
	mem.resource_name = "memoria_loop_end_n"
	for arq in ["mem", "res://tom_loop.wav", "res://tom_loop_fim44100.wav", "res://tom_emenda_ruim.wav", "res://tom_sem_loop.wav"]:
		var st: AudioStreamWAV = mem if arq == "mem" else load(arq) as AudioStreamWAV
		print("EX|loop ", arq, " loop_mode=", st.loop_mode, " loop_begin=", st.loop_begin, " loop_end=", st.loop_end, " len=", st.get_length())
		var v := _player(st)
		v.play()
		await get_tree().create_timer(0.5).timeout
		var s := await _gravar(1.6)
		var dref := 0.5 * TAU * 441.0 / AudioServer.get_mix_rate()
		print("EX|loop ", arq, " playing_apos_2.1s=", v.playing, " max_delta=%.4f (seno puro %.4f) rms=%.4f saltos=%s" % [_max_delta(s), dref, _rms(s), str(_saltos(s, dref))])
		v.stop()
		v.queue_free()
		await get_tree().create_timer(0.2).timeout
