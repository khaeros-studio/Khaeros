@abstract
class_name CombateParaMovimento
extends RefCounted
## Contrato do Combate visto pelo Movimento (GDD movimento-e-esquiva R5, R9, R12; ADR-0008 §2–3; ADR-0010).
## Consultas (recuperação, investida) e os três pedidos síncronos da largada da esquiva. O hitstop NÃO é
## consultado aqui (quem congela é o orquestrador). A invulnerabilidade é do Combate (AC-42).
## Implementação real: adaptador do épico de Combate; nos testes, dublê que registra os pedidos.


## O jogador está em recuperação de golpe (f_rec = fator_recuperacao).
@abstract func em_recuperacao(player_id: int) -> bool

## Há investida ativa para o jogador.
@abstract func investida_ativa(player_id: int) -> bool

## Deslocamento da investida em px por passo (só vale com [method investida_ativa]).
@abstract func deslocamento_investida(player_id: int) -> Vector2

## Pedido 1 da largada: cancelar investida e recuperação no mesmo passo.
@abstract func cancelar(player_id: int) -> void

## Pedido 2 da largada: invulnerabilidade = max(atual, [param passos]).
@abstract func garantir_invulneravel(player_id: int, passos: int) -> void

## Pedido 3 da largada: aviso que abre a janela [code]apos_esquiva[/code].
@abstract func esquiva_iniciada(player_id: int) -> void

## Consulta [code]contexto_de_dano[/code] (R8/R12): só a Vida atual do jogador (a máxima é atributo do portador).
## O Movimento monta o [ContextoDeDano] com [code]apos_esquiva[/code] = falso.
@abstract func vida_atual(player_id: int) -> float

## Pedido do Corte (R8; ADR-0010 Key Interfaces). O Combate revalida o alvo e aplica dano, empurrão e
## Sangramento; não conta acerto, não gera Fluxo, não pede hitstop.
@abstract func aplicar_corte(player_id: int, alvo_id: int, dano: float, dir: Vector2, empurrao: float,
		sangramento: float) -> void
