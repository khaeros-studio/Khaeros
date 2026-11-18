# PROTOTYPE - NOT FOR PRODUCTION
## EX-0016-A: gera default_bus_layout.tres e os WAV de teste. Rodar com
## godot --headless --path . --script res://gerar.gd
extends SceneTree

const TAXA := 44100


func _initialize() -> void:
	# Barramentos do ADR-0016: Musica, Efeitos, Interface -> Master.
	for nome in ["Musica", "Efeitos", "Interface"]:
		if AudioServer.get_bus_index(nome) != -1:
			continue
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, nome)
		AudioServer.set_bus_send(i, "Master")
	var layout := AudioServer.generate_bus_layout()
	print("EX|gerar layout save=", ResourceSaver.save(layout, "res://default_bus_layout.tres"))
	# 441 Hz cabe 441 ciclos exatos em 1 s (100 amostras/ciclo): loop sem degrau.
	print("EX|gerar tom_loop=", _wav(441.0, 1.0).save_to_wav("res://tom_loop.wav"))
	# Controle: 441,25 Hz termina em 1/4 de ciclo (pico) -> degrau de ~0,5 na emenda.
	print("EX|gerar tom_emenda_ruim=", _wav(441.25, 1.0).save_to_wav("res://tom_emenda_ruim.wav"))
	print("EX|gerar tom_loop_fim44100=", _wav(441.0, 1.0).save_to_wav("res://tom_loop_fim44100.wav"))
	print("EX|gerar tom_sem_loop=", _wav(441.0, 1.0).save_to_wav("res://tom_sem_loop.wav"))
	quit()


func _wav(freq: float, seg: float) -> AudioStreamWAV:
	var n := int(TAXA * seg)
	var dados := PackedByteArray()
	dados.resize(n * 2)
	for k in n:
		var v := int(round(sin(TAU * freq * k / TAXA) * 0.5 * 32767.0))
		dados.encode_s16(k * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = TAXA
	w.stereo = false
	w.data = dados
	return w
