class_name EvSeloFim
extends EventoDoPasso
## Evento `selo_fim(centro)` (GDD `design/gdd/selo-e-fluxo.md` R3;
## ADR-0002 Catálogo de eventos, TR-selo-012): emitido quando `restante` de um Selo chega a 0.
## Não é emitido quando os Selos são apagados na troca de câmara (R6).

const TIPO: StringName = &"selo_fim"

var player_id: int
var centro: Vector2


func _init(p_centro: Vector2, p_player_id: int = 0) -> void:
	player_id = p_player_id
	centro = p_centro


func tipo() -> StringName:
	return TIPO
