class_name EvBencaoTomada
extends EventoDoPasso
## Evento [code]bencao_tomada[/code] (GDD bencaos-tradicoes.md R5; ADR-0002):
## emitido em [method Bencaos.notificar_tela_fechada] depois da escolha de uma carta.
## Payload só de dados; imutável por convenção.

## Contrato do tipo.
const TIPO: StringName = &"bencao_tomada"

## Jogador que tomou a bênção (0 no solo).
var player_id: int
## Id da [BoonDef] escolhida.
var id: StringName
## Raridade escolhida ([constant SorteioDeOferta.COMUM], [constant SorteioDeOferta.RARA] ou [constant SorteioDeOferta.EPICA]).
var raridade: int
## Trocas restantes na run após a escolha.
var trocas_restantes: int


## Cria o evento.
func _init(p_id: StringName, p_raridade: int, p_trocas_restantes: int, p_player_id: int = 0) -> void:
	player_id = p_player_id
	id = p_id
	raridade = p_raridade
	trocas_restantes = p_trocas_restantes


## Devolve [constant TIPO].
func tipo() -> StringName:
	return TIPO
