class_name ValidacaoRewardTable
extends RefCounted
## Validação PV1–PV8 da [RewardTable] (GDD portas-e-recompensas.md §Validação da RewardTable; ADR-0004).
## Envolve [RegrasPv] e acrescenta a verificação de PV5 (probabilidade de bênção na escolha < 0,80)
## na 2ª passada sem editar arquivos fora de [code]src/gameplay/portas/[/code].

const LIMIAR_PROB_BENCAO: float = 0.80


## Executa 1ª e 2ª passadas das regras PV1–PV8 sobre [param itens].
static func validar_tudo(itens: Array[ItemDoCatalogo], catalogo: Catalogo = null) -> Array[Diagnostico]:
	var pv := RegrasPv.new()
	var out: Array[Diagnostico] = pv.validar(itens)
	out.append_array(pv.validar_segunda_passada(itens, catalogo))
	out.append_array(_validar_pv5(itens))
	return out


static func _validar_pv5(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	for item in itens:
		if not (item.definicao is RewardTable):
			continue
		var r := item.definicao as RewardTable
		var prob: float = prob_bencao_na_escolha(r)
		if prob < LIMIAR_PROB_BENCAO - 1e-9:
			out.append(Diagnostico.de_item(item, &"PV5", "pesos_portas", prob,
				"RewardTable: P(bencao na escolha) %.4f < 0,80" % prob, Diagnostico.Nivel.AVISO))
	return out


## F2: calcula P(bênção aparecer numa escolha livre de portas) para a [param r] dada.
static func prob_bencao_na_escolha(r: RewardTable) -> float:
	var w_b: float = maxf(0.0, float(r.pesos_portas.get(&"bencao", 0.0)))
	var w_f: float = maxf(0.0, float(r.pesos_portas.get(&"fragmentos", 0.0)))
	var w_c: float = maxf(0.0, float(r.pesos_portas.get(&"cura", 0.0)))
	var soma: float = w_b + w_f + w_c
	if soma <= 0.0 or w_b <= 0.0:
		return 0.0
	var positivos: int = (1 if w_b > 0.0 else 0) + (1 if w_f > 0.0 else 0) + (1 if w_c > 0.0 else 0)
	if positivos == 1:
		return 1.0
	var p1_b: float = w_b / soma
	var p1_f: float = w_f / soma
	var p1_c: float = w_c / soma
	var p2_b_apos_f: float = (w_b / (w_b + w_c)) if (w_b + w_c) > 0.0 else 0.0
	var p2_b_apos_c: float = (w_b / (w_b + w_f)) if (w_b + w_f) > 0.0 else 0.0
	var p_b_em_2: float = p1_b + p1_f * p2_b_apos_f + p1_c * p2_b_apos_c
	if positivos < 3:
		return p_b_em_2
	var c3: float = clampf(r.chance_tres_portas, 0.0, 1.0)
	return c3 * 1.0 + (1.0 - c3) * p_b_em_2
