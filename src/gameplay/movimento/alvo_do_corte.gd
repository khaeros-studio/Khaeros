class_name AlvoDoCorte
extends RefCounted
## Alvo atingível visto pelo Corte da esquiva (GDD movimento-e-esquiva R8, R12; ADR-0008 §5): id, posição e
## raio por valor. O adaptador de produção copia de [code]IA.atingiveis()[/code] (ADR-0018 §5).

## Id do inimigo (GeradorDeIds).
var id: int
## Posição em px de mundo.
var pos: Vector2
## Raio do corpo em px.
var raio: float


func _init(p_id: int, p_pos: Vector2, p_raio: float) -> void:
	id = p_id
	pos = p_pos
	raio = p_raio
