class_name EventosDaRun
extends RefCounted
## Eventos emitidos pela Run no canal do passo (ADR-0002, ADR-0015; GDD run-e-regioes.md).


## Emitido quando a run começa (em `-> ATIVA`).
class EvRunIniciada:
	extends EventoDoPasso
	const TIPO: StringName = &"run_iniciada"

	var seed_valor: int
	var seed_texto: String
	var arma: StringName
	var doutrina: StringName
	var dupla: Array[StringName] = []

	func _init(p_seed: int, p_seed_texto: String, p_arma: StringName,
			p_doutrina: StringName, p_dupla: Array[StringName] = []) -> void:
		seed_valor = p_seed
		seed_texto = p_seed_texto
		arma = p_arma
		doutrina = p_doutrina
		dupla = p_dupla.duplicate()
		dupla.make_read_only()

	func tipo() -> StringName:
		return TIPO


## Emitido antes do crédito da vitória quando a última câmara jogável é limpa (R4 passo 2, AC-RN-10).
class EvFimDaRun:
	extends EventoDoPasso
	const TIPO: StringName = &"fim_da_run"

	var regiao: StringName
	var indice_camara: int

	func _init(p_regiao: StringName, p_indice: int) -> void:
		regiao = p_regiao
		indice_camara = p_indice

	func tipo() -> StringName:
		return TIPO


## Emitido uma única vez ao encerrar a run por vitória, morte ou abandono (R4, R5, R6, ADR-0015 §7–§8).
class EvRunEncerrada:
	extends EventoDoPasso
	const TIPO: StringName = &"run_encerrada"

	var motivo: StringName
	var resumo: ResumoDaRun

	func _init(p_motivo: StringName, p_resumo: ResumoDaRun) -> void:
		motivo = p_motivo
		resumo = p_resumo

	func tipo() -> StringName:
		return TIPO
