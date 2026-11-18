class_name ChefesNulo
extends RefCounted


func iniciar_confronto(_doutrina: StringName, _pos_surgimento: Vector2 = Vector2(960.0, 285.0)) -> int:
	return -1


func chefe_vencido(_id: int, _subjugado: bool) -> void:
	return


func escolha(_id: int, _escolha: StringName) -> void:
	return


func atualizar_passo(_passo_atual: int) -> void:
	return


func drenar_eventos_vencido() -> Array[EventosDeChefes.EvChefeVencido]:
	return []


func drenar_eventos_subjugado() -> Array[EventosDeChefes.EvChefeSubjugado]:
	return []


func drenar_eventos_exorcizado() -> Array[EventosDeChefes.EvChefeExorcizado]:
	return []
