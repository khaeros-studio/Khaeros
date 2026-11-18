class_name EstadoDeInimigoIA
extends RefCounted
## Estado mutável completo de um inimigo dentro do `ModuloDeIA`, estendendo / acompanhando `InimigoRef` (ADR-0003, ADR-0018).

enum Fase {
	SURGINDO,
	APROXIMACAO,
	PREPARO,
	EXECUCAO,
	RECUPERACAO,
	CAMBALEANDO,
	TRANSICAO_FASE,
	HITSTOP_FINAL,
	SUBJUGADO,
	MORTO,
}

var ref: InimigoRef = null
var id: int = -1
var def: EnemyDef = null
var elite: bool = false
var chefe: bool = false
var invocado_pelo_chefe: bool = false
var ordem: int = -1
var profundidade: int = 0

var fase: Fase = Fase.SURGINDO
var timer: int = 0
var posicao: Vector2 = Vector2.ZERO
var raio: float = 24.0
var vida_max: float = 30.0
var vida: float = 30.0
var dano_base: float = 9.0
var velocidade_base: float = 153.0
var fator_empurrao: float = 1.0
var ultima_direcao: Vector2 = Vector2.RIGHT

## Armadura de elite/chefe: para elites e chefes é permanente por padrão (R8/R10), mas suporta
## quebra opcional por contador de golpes pesados quando `armadura_hits_restantes > 0` (emitindo "Quebrou!" + hitstop).
var armadura_permanente: bool = false
var armadura_ativa: bool = false
var armadura_hits_restantes: int = 0

## Seleção de alvo, atração, respiro e imobilização (R16–R18, R22).
var alvo_padrao: TelegrafoTipos.FaccaoAlvo = TelegrafoTipos.FaccaoAlvo.JOGADOR
var restante_atracao: int = 0
var restante_respiro: int = 0
var respiro_guardado: int = 30
var maldicao_atracao_id: int = -1
var player_atracao_id: int = 0
var restante_imob: int = 0

## Alvo travado no início do Preparo (R16, ADR-0018 §4).
var alvo_travado_faccao: TelegrafoTipos.FaccaoAlvo = TelegrafoTipos.FaccaoAlvo.JOGADOR
var alvo_travado_id: int = 0
var alvo_travado_player_id: int = 0
var alvo_travado_raio: float = 27.0
var epoca_campo_travada: int = 0

## Avanço de charger/chefe.
var direcao_avanco: Vector2 = Vector2.RIGHT
var ja_feriu_no_avanco: bool = false

## Estado exclusivo do chefe (null em comuns/elites).
var estado_chefe: EstadoDoChefe = null
## Cache pré-alocado de AlvoDeInimigo para evitar alocação em `alvo_efetivo(id)`.
var alvo_cache: AlvoDeInimigo = AlvoDeInimigo.new()


func sincronizar_ref() -> void:
	if ref == null:
		return
	ref.posicao = posicao
	ref.vida = vida
	ref.passos_na_fase = timer
	match fase:
		Fase.SURGINDO:
			ref.fase = &"surgindo"
		Fase.APROXIMACAO:
			ref.fase = &"perseguindo"
		Fase.PREPARO:
			ref.fase = &"preparando"
		Fase.EXECUCAO:
			ref.fase = &"atacando"
		Fase.RECUPERACAO:
			ref.fase = &"recuperando"
		Fase.CAMBALEANDO:
			ref.fase = &"cambaleando"
		Fase.TRANSICAO_FASE:
			ref.fase = &"transicao_fase"
		Fase.HITSTOP_FINAL:
			ref.fase = &"hitstop_final"
		Fase.SUBJUGADO:
			ref.fase = &"subjugado"
		Fase.MORTO:
			ref.fase = &"morto"
