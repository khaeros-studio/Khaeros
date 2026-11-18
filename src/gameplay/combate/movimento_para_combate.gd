@abstract
class_name MovimentoParaCombate
extends RefCounted
## Consultas e pedidos do Movimento que o Combate usa (GDD combate-nucleo R16, R4 passo de
## apoio; Movimento R9; ADR-0008). Implementado por um adaptador sobre o Movimento real
## (integração) ou por dublês nos testes.


## Posição do jogador [param player_id].
@abstract func posicao(player_id: int) -> Vector2

## "Em esquiva" do jogador.
@abstract func em_esquiva(player_id: int) -> bool

## Raio do corpo do jogador, px.
@abstract func raio(player_id: int) -> float

## Pedido síncrono de deslocamento (passo de apoio do arco).
@abstract func deslocar(player_id: int, v: Vector2) -> void
