class_name EvTeleporteDoJogador
extends EventoDoPasso
## Aviso de teleporte (GDD movimento-e-esquiva R1; ADR-0008 §2; ADR-0007): a Apresentação reseta a
## interpolação do nó do jogador ao recebê-lo. A mesma informação existe como consulta
## ([method MovimentoDoJogador.contador_teleportes]) para o nó que lê no quadro, sem esperar a entrega.

const TIPO: StringName = &"teleporte_do_jogador"

## Jogador.
var player_id: int
## Época da run.
var epoca_run: int
## Posição de destino.
var posicao: Vector2


func _init(p_player_id: int, p_epoca_run: int, p_posicao: Vector2) -> void:
	player_id = p_player_id
	epoca_run = p_epoca_run
	posicao = p_posicao


## Devolve [constant TIPO].
func tipo() -> StringName:
	return TIPO
