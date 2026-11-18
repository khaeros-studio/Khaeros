class_name EventosDeTelegrafos
extends RefCounted
## Eventos tipados do módulo Telégrafos para o canal EventosDoPasso (ADR-0002, ADR-0014).


class EvTelegrafoIniciado extends EventoDoPasso:
	const TIPO: StringName = &"telegrafo_iniciado"
	var dono_id: int
	var alvo_id: int
	var alvo_faccao: int
	var forma: int

	func _init(p_dono_id: int, p_alvo_id: int, p_alvo_faccao: int, p_forma: int) -> void:
		dono_id = p_dono_id
		alvo_id = p_alvo_id
		alvo_faccao = p_alvo_faccao
		forma = p_forma

	func tipo() -> StringName:
		return TIPO


class EvTelegrafoDisparou extends EventoDoPasso:
	const TIPO: StringName = &"telegrafo_disparou"
	var dono_id: int
	var forma: int

	func _init(p_dono_id: int, p_forma: int) -> void:
		dono_id = p_dono_id
		forma = p_forma

	func tipo() -> StringName:
		return TIPO


class EvTelegrafoCancelado extends EventoDoPasso:
	const TIPO: StringName = &"telegrafo_cancelado"
	var dono_id: int
	var causa: int

	func _init(p_dono_id: int, p_causa: int) -> void:
		dono_id = p_dono_id
		causa = p_causa

	func tipo() -> StringName:
		return TIPO
