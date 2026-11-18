class_name RecursosDoJogador
extends RefCounted
## Recursos vivos de um jogador no Combate (GDD combate-nucleo R2, R3, R17; ADR-0010 §1;
## ADR-0003). Um registro por [code]player_id[/code], fora do SceneTree. Vida, escudo,
## contadores, combo e janela pós-esquiva vivem aqui, nunca no portador (ADR-0009).
## Contadores em passos; só o [Combate] escreve.

## Índices dos slots nas listas por slot.
const SLOT_ATAQUE: int = 0
const SLOT_ESPECIAL: int = 1

var player_id: int
## Vida e escudo inteiros (ADR-0010 §3).
var vida: int
var escudo: int = 0
var invulneravel: int = 0
## Recarga por slot (ataque, especial).
var recarga: PackedInt32Array = PackedInt32Array([0, 0])
var guarda: int = 0
var apos_esquiva: int = 0
var recuperacao: int = 0
## Passo do combo e janela do combo, por slot (R3.1: combo por slot).
var passo_combo: PackedInt32Array = PackedInt32Array([0, 0])
var janela_combo: PackedInt32Array = PackedInt32Array([0, 0])
## Passos restantes da investida (R6; o deslocamento é da story 005).
var investida: int = 0
## Deslocamento por passo da investida em curso.
var deslocamento_investida: Vector2 = Vector2.ZERO
## Valor de "investida ativa" lido antes do disparo no item 5 (ADR-0010 §2, a0).
var investida_ativa_no_item_5: bool = false
## Mira e ponto mirado do passo (entregues pelo adaptador do item 5).
var mira: Vector2 = Vector2.RIGHT
var ponto_mirado: Vector2 = Vector2.ZERO
## Recusas de morte restantes (Modificadores R1, R9; Combate R13.7).
var recusas: int = 0
## Contador de acertos de arma por alvo (Modificadores R4; Combate R8.2, F1).
var contador_acertos: int = 0
## Contagem de abates na run (R14).
var abates: int = 0
## Verdadeiro se este jogador morreu sem recusa (R13.7, R14).
var morto: bool = false
var morto_neste_passo: bool = false
## Ids de inimigos já atingidos na investida em curso (R6, F6).
var atingidos_investida: Dictionary[int, bool] = {}
var primeiro_alvo_investida_atingido: bool = false
var dano_golpe_investida: float = 0.0
var dano_congelado_investida: DanoCongelado = null
var empurrao_investida: float = 0.0
var status_investida: StringName = &""
var slot_investida: int = SLOT_ESPECIAL
## Último atacante_tipo e ataque_id que feriu o jogador (para causa do EvJogadorMorreu).
var ultimo_atacante_tipo: StringName = &""
var ultimo_ataque_id: StringName = &""


func _init(p_player_id: int, p_vida: int, p_recusas: int = 0) -> void:
	player_id = p_player_id
	vida = p_vida
	recusas = p_recusas

