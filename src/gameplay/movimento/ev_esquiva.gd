class_name EvEsquiva
extends EventoDoPasso
## Evento [code]esquiva[/code] (GDD movimento-e-esquiva R5 item 7; ADR-0008 §3): posição de início e direção.

const TIPO: StringName = &"esquiva"

## Jogador.
var player_id: int
## Época da run.
var epoca_run: int
## Posição no início da esquiva.
var posicao_inicio: Vector2
## Direção fixada (unitária).
var direcao: Vector2


func _init(p_player_id: int, p_epoca_run: int, p_posicao_inicio: Vector2, p_direcao: Vector2) -> void:
	player_id = p_player_id
	epoca_run = p_epoca_run
	posicao_inicio = p_posicao_inicio
	direcao = p_direcao


## Devolve [constant TIPO].
func tipo() -> StringName:
	return TIPO
