class_name PedidoDeSom
extends RefCounted
## Pedido tipado de execução de gancho sonoro (`sfx_*` ou `ui_*`). Ver ADR-0016 §1.

var gancho: StringName = &""
var prioridade: int = 2
var player_id: int = -1


func _init(
	p_gancho: StringName = &"",
	p_prioridade: int = 2,
	p_player_id: int = -1
) -> void:
	gancho = p_gancho
	prioridade = clampi(p_prioridade, 0, 4)
	player_id = p_player_id


func configurar(p_gancho: StringName, p_prioridade: int, p_player_id: int = -1) -> void:
	gancho = p_gancho
	prioridade = clampi(p_prioridade, 0, 4)
	player_id = p_player_id
