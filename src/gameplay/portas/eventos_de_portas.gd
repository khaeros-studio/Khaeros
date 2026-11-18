class_name EventosDePortas
extends RefCounted
## Eventos emitidos pelo módulo de Portas e recompensas no canal do passo (ADR-0002, ADR-0015).


## Emitido ao conceder a recompensa da câmara limpa (R2 passo 2).
class EvRecompensa:
	extends EventoDoPasso
	const TIPO: StringName = &"recompensa"

	var tipo_recompensa: StringName
	var quantidade: int

	func _init(p_tipo_recompensa: StringName, p_quantidade: int) -> void:
		tipo_recompensa = p_tipo_recompensa
		quantidade = p_quantidade

	func tipo() -> StringName:
		return TIPO


## Emitido quando as portas da câmara limpa se abrem (R2 passo 3).
class EvPortasAbertas:
	extends EventoDoPasso
	const TIPO: StringName = &"portas_abertas"

	var tipos: Array[StringName] = []
	var quantidades: Array[int] = []

	func _init(p_tipos: Array[StringName], p_quantidades: Array[int] = []) -> void:
		tipos = p_tipos.duplicate()
		tipos.make_read_only()
		quantidades = p_quantidades.duplicate()
		quantidades.make_read_only()

	func tipo() -> StringName:
		return TIPO


## Emitido quando o jogador escolhe uma porta aberta (TR-portas-008, ADR-0015 §4.4).
class EvPortaEscolhida:
	extends EventoDoPasso
	const TIPO: StringName = &"porta_escolhida_recompensa"

	var indice_porta: int
	var tipo_escolhido: StringName
	var opcoes: Array[StringName] = []

	func _init(p_indice: int, p_tipo: StringName, p_opcoes: Array[StringName]) -> void:
		indice_porta = p_indice
		tipo_escolhido = p_tipo
		opcoes = p_opcoes.duplicate()
		opcoes.make_read_only()

	func tipo() -> StringName:
		return TIPO
