class_name EstadoDoPacto
extends RefCounted
## Estado mutável da dupla de Pactos de um `player_id` (ADR-0017 §1).

var player_id: int = 0
var campo: MaldicaoRef = null
var reserva: MaldicaoRef = null
var todas: Array[MaldicaoRef] = []

var recarga_troca: int = 0
var recarga_troca_total: int = 240
var marca_virote: int = -1

## Pedido do Chamado do Pacto vindo do item 5 (Combate R3.1).
var chamado_pendente: bool = false
var chamado_ponto: Vector2 = Vector2.ZERO
var chamado_dano: float = 17.0
var chamado_m: float = 1.0

## Rastreamento de ids atraídos e imobilizados para emissão de fim no sub-passo 1 do 6.1 (R20).
var ids_atraidos: Array[int] = []
var ids_imobilizados: Array[int] = []
var ids_marcados_saida: Dictionary[int, bool] = {}

var seq_exaustao: int = 0
