class_name PadroesDoChefe
extends RefCounted
## Funções puras de execução dos 4 padrões de ataque do *Soberano do Limiar*
## (GDD chefes.md R3, R4, R5, F1–F3; ADR-0018 §8).

const ALCANCE_ENGAJAMENTO_P0_PX: float = 180.0
const ALCANCE_ENGAJAMENTO_DEMAIS_PX: float = 300.0
const VELOCIDADE_AVANCO_P1_PXS: float = 675.0
const EMPURRAO_PULSO_P2_PXS: float = 900.0
const N_PROJETEIS_RADIAIS_P2: int = 12
const VELOCIDADE_PROJ_RADIAL_PXS: float = 360.0
const RAIO_PROJ_RADIAL_PX: float = 13.5
const VIDA_PROJ_RADIAL_S: float = 3.0
const DANO_PROJ_RADIAL: float = 12.0
const SAIDA_PROJ_RADIAL_PX: float = 54.0


## Distância de caminhada na Aproximação por índice de padrão (R4).
static func alcance_caminhada_aproximacao(padrao_idx: int) -> float:
	return ALCANCE_ENGAJAMENTO_P0_PX if padrao_idx == 0 else ALCANCE_ENGAJAMENTO_DEMAIS_PX


## Verdadeiro se o padrão `padrao_idx` pode iniciar o Preparo dada a distância `d` e `timer <= 0` (R4).
static func pode_iniciar_preparo(padrao_idx: int, timer: int, distancia: float) -> bool:
	if timer > 0:
		return false
	if padrao_idx == 0:
		return distancia <= ALCANCE_ENGAJAMENTO_P0_PX + 1e-5
	return true


## Executa o disparo do Padrão 0 (*Garra do Véu Rasgado*: setor 165 px, 78,46°, 16 de dano no alvo travado).
static func disparar_padrao_0(i: EstadoDeInimigoIA, padrao: BossPatternDef, ia: Object) -> void:
	var dano := padrao.dano if padrao != null and padrao.dano > 0.0 else 16.0
	ia.resolver_golpe_setor_travado(i, dano, &"soberano_p0_garra")


## Inicia o avanço do Padrão 1 (*Irrupção do Limiar*: 24 passos a 675 px/s = 11,25 px/passo, 18 de dano por contato 1×).
static func iniciar_avanco_padrao_1(i: EstadoDeInimigoIA, _padrao: BossPatternDef, ia: Object) -> void:
	var telegrafos: Telegrafos = ia.telegrafos()
	var ec := i.estado_chefe
	ec.direcao_avanco = telegrafos.mira_de(i.id) if telegrafos != null else i.ultima_direcao
	ec.ja_feriu_no_avanco = false


## Um passo de avanço do Padrão 1 (R5.2, AC-CH-05, AC-CH-06).
static func passo_avanco_padrao_1(i: EstadoDeInimigoIA, padrao: BossPatternDef, ia: Object) -> void:
	var ec: EstadoDoChefe = i.estado_chefe
	var v_avanco_pxs: float = float(padrao.dimensoes.get(&"v_avanco_pxs", VELOCIDADE_AVANCO_P1_PXS)) if padrao != null else VELOCIDADE_AVANCO_P1_PXS
	var passo_px: float = v_avanco_pxs / float(Unidades.TICK_RATE)
	i.posicao = ia.conter(i.posicao + ec.direcao_avanco * passo_px, i.raio) as Vector2
	if not ec.ja_feriu_no_avanco:
		var dano: float = padrao.dano if padrao != null and padrao.dano > 0.0 else 18.0
		if ia.testar_e_ferir_contato_avanco(i, dano, &"soberano_p1_irrupcao"):
			ec.ja_feriu_no_avanco = true


## Executa o disparo do Padrão 2 (*Pulso de Soberania*: anel 210 px com 15 de dano + empurrão 900 px/s no alvo travado,
## mais 12 projéteis radiais a cada 30° a partir da mira travada, todos com o mesmo alvo travado; R5.3, AC-CH-07, AC-CH-27).
static func disparar_padrao_2(i: EstadoDeInimigoIA, padrao: BossPatternDef, ia: Object) -> void:
	var dano_pulso := padrao.dano if padrao != null and padrao.dano > 0.0 else 15.0
	var r_ext := float(padrao.dimensoes.get(&"r_ext", 210.0)) if padrao != null else 210.0
	ia.resolver_golpe_circular_travado(i, r_ext, dano_pulso, EMPURRAO_PULSO_P2_PXS, &"soberano_p2_pulso")
	var telegrafos: Telegrafos = ia.telegrafos()
	var mira_base := telegrafos.mira_de(i.id) if telegrafos != null else i.ultima_direcao
	if mira_base.length_squared() == 0.0:
		mira_base = Vector2.RIGHT
	else:
		mira_base = mira_base.normalized()
	for k in N_PROJETEIS_RADIAIS_P2:
		var dir_k := GeometriaDeAcerto.girar_graus(mira_base, float(k) * 30.0)
		var origem_k := i.posicao + dir_k * SAIDA_PROJ_RADIAL_PX
		ia.disparar_projetil_radial_chefe(i, origem_k, dir_k, VELOCIDADE_PROJ_RADIAL_PXS,
			RAIO_PROJ_RADIAL_PX, VIDA_PROJ_RADIAL_S, DANO_PROJ_RADIAL)


## Executa o disparo do Padrão 3 (*Convergência da Fenda*: 1º puxão de 75 px em <= 420 px em jogador e Maldição;
## 2º impacto de 14 de dano em <= 225 px no alvo travado; 3º invocação controlada de até 2 Ecos Perdidos; R5.4, F3, AC-CH-08, AC-CH-09).
static func disparar_padrao_3(i: EstadoDeInimigoIA, padrao: BossPatternDef, ia: Object) -> void:
	ia.aplicar_puxao_convergencia(i.posicao, i.raio)
	var dano_circulo := padrao.dano if padrao != null and padrao.dano > 0.0 else 14.0
	var r_circulo := float(padrao.dimensoes.get(&"raio_px", 225.0)) if padrao != null else 225.0
	ia.resolver_golpe_circular_travado(i, r_circulo, dano_circulo, 0.0, &"soberano_p3_convergencia")
	ia.enfileirar_invocacao_convergencia(i.posicao)
