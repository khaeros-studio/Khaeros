class_name ComandoDeVoz
extends RefCounted
## Comando emitido pelo `MixadorDeVozes` instruindo qual slot tocar (e se deve parar antes).

var slot: int = 0
var gancho: StringName = &""
var parar_antes: bool = false
var prioridade: int = 2


func _init(
	p_slot: int = 0,
	p_gancho: StringName = &"",
	p_parar_antes: bool = false,
	p_prioridade: int = 2
) -> void:
	slot = p_slot
	gancho = p_gancho
	parar_antes = p_parar_antes
	prioridade = p_prioridade
