class_name EvChamadoIndisponivel
extends EventoDoPasso
## Evento `chamado_indisponivel` (GDD `design/gdd/armas-das-doutrinas.md` R2b, AC-AR-46;
## ADR-0010 §11): emitido uma vez por toque novo de Especial quando o Chamado do Pacto
## é recusado (sem Maldição em campo ou com ela `Saltando`).

const TIPO: StringName = &"chamado_indisponivel"

var player_id: int
var passo: int
## &"sem_maldicao" ou &"saltando".
var motivo: StringName


func _init(p_player_id: int = 0, p_segundo: Variant = 0, p_motivo: StringName = &"sem_maldicao") -> void:
	player_id = p_player_id
	if p_segundo is StringName or p_segundo is String:
		motivo = StringName(p_segundo)
		passo = 0
	else:
		passo = int(p_segundo)
		motivo = p_motivo


func tipo() -> StringName:
	return TIPO
