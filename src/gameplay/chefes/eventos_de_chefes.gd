class_name EventosDeChefes
extends RefCounted


class EvChefeVencido extends RefCounted:
	var id: int
	var subjugado: bool

	func _init(p_id: int, p_subjugado: bool) -> void:
		id = p_id
		subjugado = p_subjugado


class EvChefeSubjugado extends RefCounted:
	var id: int
	var especie_id: StringName

	func _init(p_id: int, p_especie_id: StringName) -> void:
		id = p_id
		especie_id = p_especie_id


class EvChefeExorcizado extends RefCounted:
	var id: int

	func _init(p_id: int) -> void:
		id = p_id
