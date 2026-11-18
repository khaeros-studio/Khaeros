class_name EstadoDeGolpe
extends RefCounted
## Registro de um disparo do item 5 (GDD combate-nucleo R3 itens 1–7; ADR-0010 §2 c).
## Resultado dos passos do disparo, guardado para a forma (story 004) e para os eventos
## (story 008). Também registra a recusa do Chamado (R3.1) com [member recusa_chamado].

## Passo do orquestrador em que saiu (contagem do próprio Combate, vivos e congelados).
var passo: int
var player_id: int
## [constant RecursosDoJogador.SLOT_ATAQUE] ou [constant RecursosDoJogador.SLOT_ESPECIAL].
var slot: int
var ataque: AtaqueConvertido
## Multiplicador do combo usado (1 sem combo).
var mult: float = 1.0
## [code]AttackDef.dano × mult[/code].
var dano_golpe: float
## M congelado no disparo (ADR-0009 §4).
var dano_congelado: DanoCongelado
## M sem 4º acerto, avaliado no disparo.
var m_sem: float = 1.0
## Finalizador (mult > limiar) e empurrão do golpe (F3, antes do fator do alvo).
var finalizador: bool = false
var empurrao: float
## Pesado pela F3 (finalizador ou empurrão ≥ pesado), sem o 4º acerto.
var pesado: bool = false
## Verdadeiro se é a recusa do Chamado (nenhum disparo; evento chamado_indisponivel).
var recusa_chamado: bool = false
