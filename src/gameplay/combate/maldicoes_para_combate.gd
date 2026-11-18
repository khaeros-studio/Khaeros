@abstract
class_name MaldicoesParaCombate
extends RefCounted
## Parte das Maldições usada pela forma [code]chamado[/code] e pelos impactos/danos
## da facção do jogador (GDD combate-nucleo R3.1, R19–R23; ADR-0010 §11; ADR-0017).
## Sem Maldições injetadas, o Chamado está sempre indisponível.


## Verdadeiro se há Maldição em campo e ela não está [code]Saltando[/code].
@abstract func chamado_disponivel(player_id: int) -> bool

## Motivo pelo qual o Chamado está indisponível (&"sem_maldicao" ou &"saltando").
func motivo_indisponivel(_player_id: int) -> StringName:
	return &"sem_maldicao"

## Pede o salto até [param ponto]; corre no item 6.1 (R23).
@abstract func pedir_chamado(player_id: int, ponto: Vector2, dano_golpe: float, m_chamado: float) -> void

## Verdadeiro se a Maldição [param curse_id] está em campo, Vida > 0 e fora de [code]Saltando[/code] (R19).
func maldicao_atingivel(_curse_id: StringName) -> bool:
	return false

## Verdadeiro se a Maldição [param curse_id] está em campo (mesmo Saltando; para R22).
func maldicao_em_campo(_curse_id: StringName) -> bool:
	return false

## Verdadeiro se a Maldição [param curse_id] está em [code]Saltando[/code] (R22: projétil atravessa).
func maldicao_saltando(_curse_id: StringName) -> bool:
	return false

## Posição da Maldição [param curse_id] em px de mundo.
func posicao_maldicao(_curse_id: StringName) -> Vector2:
	return Vector2.ZERO

## Raio do corpo da Maldição [param curse_id] em px.
func raio_maldicao(_curse_id: StringName) -> float:
	return 24.0

## Vida inteira atual da Maldição [param curse_id].
func vida_maldicao(_curse_id: StringName) -> int:
	return 0

## Atualiza a Vida inteira da Maldição [param curse_id] (R21.3).
func definir_vida_maldicao(_curse_id: StringName, _vida_nova: int) -> void:
	pass

## Portador da Maldição [param curse_id] (Modificadores R14).
func portador_maldicao(_curse_id: StringName) -> Portador:
	return null

## Player_id do dono da Maldição [param curse_id].
func dono_maldicao(_curse_id: StringName) -> int:
	return 0

## Pedido síncrono de Exaustão quando Vida chega a <= 0 (R21.7).
func exaurir(_curse_id: StringName) -> void:
	pass

