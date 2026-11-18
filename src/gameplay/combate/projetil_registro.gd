class_name ProjetilRegistro
extends RefCounted
## Registro em voo de um projétil do jogador ou de inimigo (GDD combate-nucleo R6, R7, R22, F5;
## ADR-0010 §7, §11). Guardado numa única lista ordenada por criação; remoção preserva a ordem.


var id: int
## true = projétil do jogador; false = projétil de inimigo.
var do_jogador: bool
var player_id: int = 0
var dono_inimigo_id: int = -1
var posicao: Vector2
var direcao: Vector2
## Deslocamento por passo (velocidade_pxs / 60).
var passo_px: float
var raio_px: float
## Passos de vida restantes (o passo em que chega a 0 não testa acerto, R7).
var vida_restante: int
var atravessa: bool = false
## Jogador: dano_golpe = AttackDef.dano * mult; Inimigo: dano_base.
var dano_golpe: float = 0.0
## Jogador: DanoCongelado avaliado no disparo.
var dano_congelado: DanoCongelado = null
## Inimigo / fallback: multiplicador M do disparo.
var m_disparo: float = 1.0
var empurrao: float = 0.0
var status: StringName = &""
var finalizador: bool = false
var pesado: bool = false
var slot_origem: int = 0
## Alvo de projétil inimigo (R22): JOGADOR, ALIADO ou ACUADA.
var alvo_faccao: ContratosDoCombate.Faccao = ContratosDoCombate.Faccao.JOGADOR
var alvo_id: int = 0
var alvo_curse_id: StringName = &""
var ataque_id: StringName = &""
## Conjunto de ids (ou curse_ids) já atingidos quando atravessa = true.
var atingidos: Dictionary = {}
