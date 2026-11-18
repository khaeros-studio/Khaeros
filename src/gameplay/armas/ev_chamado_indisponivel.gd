class_name EvChamadoIndisponivel
extends EventoDoPasso
## Evento `chamado_indisponivel` (GDD `design/gdd/armas-das-doutrinas.md` R2b, AC-AR-46;
## ADR-0010 §11): emitido uma vez por toque novo de Especial quando o Chamado do Pacto
## é recusado (sem Maldição em campo ou com ela `Saltando`).

const TIPO: StringName = &"chamado_indisponivel"

var player_id: int
var passo: int


func _init(p_player_id: int = 0, p_passo: int = 0) -> void:
	player_id = p_player_id
	passo = p_passo


func tipo() -> StringName:
	return TIPO
