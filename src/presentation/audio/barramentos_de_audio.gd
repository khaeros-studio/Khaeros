class_name BarramentosDeAudio
extends RefCounted
## Nomes canônicos de barramentos (`Master`, `Musica`, `Efeitos`, `Interface`) e
## conversão linear `[0, 1]` para dB/mute conforme ADR-0016 §1.

const MASTER: StringName = &"Master"
const MUSICA: StringName = &"Musica"
const EFEITOS: StringName = &"Efeitos"
const INTERFACE: StringName = &"Interface"

# Aliases compatíveis com nomenclatura de opções (SFX / Music / UI)
const SFX: StringName = &"Efeitos"
const MUSIC: StringName = &"Musica"
const UI: StringName = &"Interface"

const LIMIAR_MUDO_LINEAR: float = 0.0001
const DB_MINIMO: float = -80.0


static func linear_para_db_seguro(valor_linear: float) -> float:
	var v: float = clampf(valor_linear, 0.0, 1.0)
	if v <= LIMIAR_MUDO_LINEAR:
		return DB_MINIMO
	return maxf(DB_MINIMO, linear_to_db(v))


static func deve_mutar(valor_linear: float) -> bool:
	return clampf(valor_linear, 0.0, 1.0) <= LIMIAR_MUDO_LINEAR


static func garantir_barramentos_no_servidor() -> void:
	var nomes: Array[StringName] = [MUSICA, EFEITOS, INTERFACE]
	for nome: StringName in nomes:
		if AudioServer.get_bus_index(nome) < 0:
			var novo_idx: int = AudioServer.bus_count
			AudioServer.add_bus(novo_idx)
			AudioServer.set_bus_name(novo_idx, String(nome))
			AudioServer.set_bus_send(novo_idx, MASTER)


static func aplicar_volume_barramento(nome: StringName, valor_linear: float) -> void:
	var nome_canon: StringName = normalizar_nome_barramento(nome)
	var idx: int = AudioServer.get_bus_index(nome_canon)
	if idx < 0:
		return
	var mudo: bool = deve_mutar(valor_linear)
	AudioServer.set_bus_mute(idx, mudo)
	if not mudo:
		AudioServer.set_bus_volume_db(idx, linear_para_db_seguro(valor_linear))


static func normalizar_nome_barramento(nome: StringName) -> StringName:
	if nome == &"SFX" or nome == &"sfx" or nome == &"efeitos":
		return EFEITOS
	if nome == &"Music" or nome == &"music" or nome == &"musica":
		return MUSICA
	if nome == &"UI" or nome == &"ui" or nome == &"interface":
		return INTERFACE
	if nome == &"master":
		return MASTER
	return nome
