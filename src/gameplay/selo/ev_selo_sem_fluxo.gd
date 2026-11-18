class_name EvSeloSemFluxo
extends EventoDoPasso
## Evento `selo_sem_fluxo` (GDD `design/gdd/selo-e-fluxo.md` R2;
## ADR-0002 Catálogo de eventos, TR-selo-012): emitido uma vez por toque novo de Selo
## quando `φ₆ < custo_fluxo` no passo do toque.

const TIPO: StringName = &"selo_sem_fluxo"

var player_id: int


func _init(p_player_id: int = 0) -> void:
	player_id = p_player_id


func tipo() -> StringName:
	return TIPO
