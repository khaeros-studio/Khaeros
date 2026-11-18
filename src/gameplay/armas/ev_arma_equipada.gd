class_name EvArmaEquipada
extends EventoDoPasso
## Evento emitido quando o jogador confirma a arma e a run entra em `Equipada`
## (GDD `design/gdd/armas-das-doutrinas.md` R6, R9, Interactions › Telemetria local;
## ADR-0002, ADR-0015).

const TIPO: StringName = &"arma_equipada"

var player_id: int
var arma_id: StringName
var doutrina: StringName


func _init(p_arma_id: StringName, p_doutrina: StringName, p_player_id: int = 0) -> void:
	player_id = p_player_id
	arma_id = p_arma_id
	doutrina = p_doutrina


func tipo() -> StringName:
	return TIPO
