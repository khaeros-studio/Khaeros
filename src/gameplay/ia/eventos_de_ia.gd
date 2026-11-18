class_name EventosDeIA
extends RefCounted
## Eventos emitidos pelo `ModuloDeIA` no canal `EventosDoPasso` (ADR-0002, ADR-0010, ADR-0018).


class EvQuebrouArmadura extends EventoDoPasso:
	const TIPO: StringName = &"quebrou"
	var inimigo_id: int
	var elite: bool

	func _init(p_inimigo_id: int, p_elite: bool = false) -> void:
		inimigo_id = p_inimigo_id
		elite = p_elite

	func tipo() -> StringName:
		return TIPO
