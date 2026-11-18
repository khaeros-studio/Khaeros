class_name EvSelo
extends EventoDoPasso
## Evento `selo(centro, raio_px, duracao_passos)` (GDD `design/gdd/selo-e-fluxo.md` R2;
## ADR-0002 Catálogo de eventos, TR-selo-012): emitido quando o jogador planta um Selo.

const TIPO: StringName = &"selo"

var player_id: int
var centro: Vector2
var raio_px: float
var duracao_passos: int


func _init(p_centro: Vector2, p_raio_px: float, p_duracao_passos: int, p_player_id: int = 0) -> void:
	player_id = p_player_id
	centro = p_centro
	raio_px = p_raio_px
	duracao_passos = p_duracao_passos


func tipo() -> StringName:
	return TIPO
