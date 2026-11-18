class_name EvAcertoVirote
extends EventoDoPasso
## Evento `acerto_virote` (GDD `design/gdd/armas-das-doutrinas.md` R2b, AC-AR-44;
## ADR-0002 Catálogo de Pactos, TR-armas-013):
## emitido quando um golpe de arma do slot Ataque acerta um alvo enquanto a arma
## equipada é `pactos`, inclusive com dano 0 (M = 0) ou quando o golpe mata.
## O Chamado do Pacto (`de_arma` falso, slot Especial) nunca emite este evento.

const TIPO: StringName = &"acerto_virote"

var autor_player_id: int
var alvo: int
var passo: int
var posicao: Vector2


func _init(p_alvo: int, p_autor_player_id: int = 0, p_passo: int = 0, p_posicao: Vector2 = Vector2.ZERO) -> void:
	alvo = p_alvo
	autor_player_id = p_autor_player_id
	passo = p_passo
	posicao = p_posicao


func tipo() -> StringName:
	return TIPO
