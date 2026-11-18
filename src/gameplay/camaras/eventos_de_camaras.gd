class_name EventosDeCamaras
extends RefCounted
## Eventos emitidos pelo módulo de Câmaras e ondas no canal do passo (ADR-0002, ADR-0015).


## Emitido uma única vez quando a câmara limpa (R11, R18-P).
class EvCamaraLimpa:
	extends EventoDoPasso
	const TIPO: StringName = &"camara_limpa"

	var profundidade: int
	var tipo_camara: StringName
	var indice_camara: int

	func _init(p_profundidade: int, p_tipo_camara: StringName, p_indice_camara: int = 0) -> void:
		profundidade = p_profundidade
		tipo_camara = p_tipo_camara
		indice_camara = p_indice_camara

	func tipo() -> StringName:
		return TIPO


## Emitido quando uma nova onda nasce na câmara.
class EvOndaIniciada:
	extends EventoDoPasso
	const TIPO: StringName = &"onda_iniciada"

	var indice_onda: int
	var quantidade_inimigos: int

	func _init(p_indice_onda: int, p_qtd: int) -> void:
		indice_onda = p_indice_onda
		quantidade_inimigos = p_qtd

	func tipo() -> StringName:
		return TIPO


## Emitido quando o jogador interage com uma porta aberta (R13).
class EvPortaInteragida:
	extends EventoDoPasso
	const TIPO: StringName = &"porta_escolhida"

	var indice_porta: int
	var tipo_porta: StringName

	func _init(p_indice_porta: int, p_tipo_porta: StringName = &"") -> void:
		indice_porta = p_indice_porta
		tipo_porta = p_tipo_porta

	func tipo() -> StringName:
		return TIPO
