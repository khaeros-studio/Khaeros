class_name EvBencaoEscolhida
extends EventoDoPasso
## Evento [code]bencao_escolhida[/code] (GDD bencaos-tradicoes.md R5; ADR-0002, ADR-0012 §5):
## emitido após [EvBencaoTomada] para avisar as Portas e a Run que a escolha terminou
## e as portas podem abrir (ou a Run encerrar com vitória).

## Contrato do tipo.
const TIPO: StringName = &"bencao_escolhida"

## Jogador que concluiu a escolha (0 no solo).
var player_id: int
## Id da [BoonDef] escolhida.
var id: StringName
## Raridade escolhida.
var raridade: int


## Cria o evento.
func _init(p_id: StringName, p_raridade: int, p_player_id: int = 0) -> void:
	player_id = p_player_id
	id = p_id
	raridade = p_raridade


## Devolve [constant TIPO].
func tipo() -> StringName:
	return TIPO
