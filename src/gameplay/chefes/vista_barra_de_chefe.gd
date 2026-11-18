class_name VistaBarraDeChefe
extends RefCounted

const LARGURA_BARRA_PX: float = 960.0
const ALTURA_BARRA_PX: float = 14.0
const POS_Y_TOPO_PX: float = 48.0
const PASSOS_FADE_SAIDA: int = 15

const EVENTOS_SONOROS_CHEFE: Array[StringName] = [
	&"chefe_surgimento",
	&"chefe_preparo_garra",
	&"chefe_avanco_irrupcao",
	&"chefe_pulso_soberania",
	&"chefe_convergencia_puxao",
	&"chefe_transicao_furia",
	&"chefe_subjugado",
	&"chefe_derrotado",
]

var visivel: bool = false
var chave_nome: StringName = &""
var vida_atual: int = 0
var vida_maxima: int = 700
var limiar_furia_hp: int = 350
var entalhe_furia_rachado: bool = false
var invulneravel_transicao: bool = false
var moldura_osso_claro_solido: bool = false
var mostrar_fio_sob_pes: bool = false
var opacidade: float = 1.0
var largura_px: float = LARGURA_BARRA_PX
var altura_px: float = ALTURA_BARRA_PX
var y_topo_px: float = POS_Y_TOPO_PX


static func construir_de_estado(
	est: EstadoDeInimigoIA,
	tuning: ChefesTuning,
	passos_desde_queda: int = 0
) -> VistaBarraDeChefe:
	var v := VistaBarraDeChefe.new()
	if est == null or not est.chefe or est.estado_chefe == null:
		v.visivel = false
		v.opacidade = 0.0
		return v

	v.chave_nome = est.def.chave_nome if est.def != null else &"ENEMY_SOBERANO_NAME"
	v.vida_atual = int(est.vida)
	v.vida_maxima = int(est.vida_max)
	var frac_furia: float = tuning.limiar_furia_frac if tuning != null and tuning.limiar_furia_frac > 0.0 else 0.50
	v.limiar_furia_hp = FormulasDoChefe.limiar_vida_furia(est.vida_max, frac_furia)

	var ec: EstadoDoChefe = est.estado_chefe
	v.entalhe_furia_rachado = (
		ec.em_furia
		or ec.transicao_ja_ocorreu
		or est.fase == EstadoDeInimigoIA.Fase.TRANSICAO_FASE
		or est.fase == EstadoDeInimigoIA.Fase.SUBJUGADO
		or est.fase == EstadoDeInimigoIA.Fase.MORTO
	)
	v.invulneravel_transicao = (est.fase == EstadoDeInimigoIA.Fase.TRANSICAO_FASE)
	v.moldura_osso_claro_solido = v.invulneravel_transicao
	# CH-V1: O chefe nunca mostra o fio de vida sob os pés usado por inimigos comuns
	v.mostrar_fio_sob_pes = false

	if est.fase == EstadoDeInimigoIA.Fase.SUBJUGADO or est.fase == EstadoDeInimigoIA.Fase.MORTO:
		var t: float = clampf(float(passos_desde_queda) / float(PASSOS_FADE_SAIDA), 0.0, 1.0)
		v.opacidade = 1.0 - t
		v.visivel = v.opacidade > 0.0
	else:
		v.opacidade = 1.0
		v.visivel = true
	return v
