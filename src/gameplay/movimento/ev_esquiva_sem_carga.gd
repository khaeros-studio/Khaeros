class_name EvEsquivaSemCarga
extends EventoDoPasso
## Evento [code]esquiva_sem_carga[/code] (GDD movimento-e-esquiva R5; ADR-0008 §4): um por toque novo sem
## carga. O Movimento não filtra; a contenção de 0,2 s é do HUD/áudio.

const TIPO: StringName = &"esquiva_sem_carga"

## Jogador.
var player_id: int
## Época da run.
var epoca_run: int


func _init(p_player_id: int, p_epoca_run: int) -> void:
	player_id = p_player_id
	epoca_run = p_epoca_run


## Devolve [constant TIPO].
func tipo() -> StringName:
	return TIPO
