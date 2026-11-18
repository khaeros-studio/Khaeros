class_name ValidadorStatus
extends ValidadorDoDono
## Validador das regras `ST1–ST11` sobre `StatusTuning` (`design/gdd/efeitos-de-status.md` R9;
## `design/gdd/formato-e-validacao-de-conteudo.md` R9-P, TR-status-011).

const PREFIXO_ST: StringName = &"ST"

const DPS_DIRETO_L1: float = 66.471
const MULT_TETO_M: float = 4.0


func prefixo() -> StringName:
	return PREFIXO_ST


static func fabrica() -> StatusTuning:
	var t := StatusTuning.new()
	t.id = &"status_tuning"
	t.duracao_sangramento_s = 4.0
	t.dano_sangramento_s = 2.4
	t.max_acumulos_sangramento = 10
	t.duracao_queimadura_s = 3.0
	t.dano_queimadura_s = 4.8
	t.max_acumulos_queimadura = 6
	t.duracao_abalo_s = 4.0
	t.reducao_dano_causado = 0.30
	t.intervalo_numero_s = 0.5
	return t


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var item := primeiro_da_classe(itens, "StatusTuning")
	if item == null or not (item.definicao is StatusTuning):
		return []
	return validar_tuning(item.definicao as StatusTuning, item)


static func validar_tuning(t: StatusTuning, item: ItemDoCatalogo = null) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var ds_passos := Unidades.duracao_para_passos(t.duracao_sangramento_s)
	var dq_passos := Unidades.duracao_para_passos(t.duracao_queimadura_s)
	var da_passos := Unidades.duracao_para_passos(t.duracao_abalo_s)
	var int_passos := Unidades.duracao_para_passos(t.intervalo_numero_s)

	# ST1 — erro: duracao_*_s < 1 passo (0,017 s)
	if ds_passos < 1:
		out.append(_diag(item, &"ST1", "duracao_sangramento_s", t.duracao_sangramento_s,
				"duracao_sangramento_s < 1 passo", Diagnostico.Nivel.ERRO))
	if dq_passos < 1:
		out.append(_diag(item, &"ST1", "duracao_queimadura_s", t.duracao_queimadura_s,
				"duracao_queimadura_s < 1 passo", Diagnostico.Nivel.ERRO))
	if da_passos < 1:
		out.append(_diag(item, &"ST1", "duracao_abalo_s", t.duracao_abalo_s,
				"duracao_abalo_s < 1 passo", Diagnostico.Nivel.ERRO))

	# ST2 — erro: dano_*_s < 0
	if t.dano_sangramento_s < 0.0:
		out.append(_diag(item, &"ST2", "dano_sangramento_s", t.dano_sangramento_s,
				"dano_sangramento_s < 0", Diagnostico.Nivel.ERRO))
	if t.dano_queimadura_s < 0.0:
		out.append(_diag(item, &"ST2", "dano_queimadura_s", t.dano_queimadura_s,
				"dano_queimadura_s < 0", Diagnostico.Nivel.ERRO))

	# ST3 — erro: max_acumulos_queimadura < 1 ou max_acumulos_sangramento < 0
	if t.max_acumulos_queimadura < 1:
		out.append(_diag(item, &"ST3", "max_acumulos_queimadura", t.max_acumulos_queimadura,
				"max_acumulos_queimadura < 1", Diagnostico.Nivel.ERRO))
	if t.max_acumulos_sangramento < 0:
		out.append(_diag(item, &"ST3", "max_acumulos_sangramento", t.max_acumulos_sangramento,
				"max_acumulos_sangramento < 0", Diagnostico.Nivel.ERRO))

	# ST4 — erro: reducao_dano_causado fora de [0, 1)
	if t.reducao_dano_causado < 0.0 or t.reducao_dano_causado >= 1.0:
		out.append(_diag(item, &"ST4", "reducao_dano_causado", t.reducao_dano_causado,
				"reducao_dano_causado fora de [0, 1)", Diagnostico.Nivel.ERRO))

	# ST5 — aviso: DPS máximo no teto > 0,50 * DPS_direto(L1) ou max_acumulos_sangramento == 0
	var teto_dps := 0.50 * DPS_DIRETO_L1
	if t.max_acumulos_sangramento == 0:
		out.append(_diag(item, &"ST5", "max_acumulos_sangramento", t.max_acumulos_sangramento,
				"max_acumulos_sangramento == 0 (sem teto) excede 50% do DPS direto de L1", Diagnostico.Nivel.AVISO))
	else:
		var dps_s_max := float(t.max_acumulos_sangramento) * t.dano_sangramento_s
		if dps_s_max > teto_dps:
			out.append(_diag(item, &"ST5", "dano_sangramento_s", dps_s_max,
					"DPS máximo de sangramento no teto excede 50% do DPS direto de L1", Diagnostico.Nivel.AVISO))
	var dps_q_max := float(t.max_acumulos_queimadura) * t.dano_queimadura_s
	if dps_q_max > teto_dps:
		out.append(_diag(item, &"ST5", "dano_queimadura_s", dps_q_max,
				"DPS máximo de queimadura no teto excede 50% do DPS direto de L1", Diagnostico.Nivel.AVISO))
	if t.max_acumulos_sangramento > 0:
		var dps_comb := float(t.max_acumulos_sangramento) * t.dano_sangramento_s + dps_q_max
		if dps_comb > 0.50 * (DPS_DIRETO_L1 * MULT_TETO_M):
			out.append(_diag(item, &"ST5", "dano_combinado", dps_comb,
					"DPS combinado no teto excede 50% do DPS direto com M=4", Diagnostico.Nivel.AVISO))

	# ST6 — aviso: intervalo_numero_s < 1 passo
	if int_passos < 1:
		out.append(_diag(item, &"ST6", "intervalo_numero_s", t.intervalo_numero_s,
				"intervalo_numero_s < 1 passo", Diagnostico.Nivel.AVISO))

	# ST7 — aviso: tempo de matar no teto < 0,5 s para Eco (75) ou Anomalia (50)
	if t.max_acumulos_sangramento > 0 and t.dano_sangramento_s > 0.0:
		var t_matar_s := 50.0 / (float(t.max_acumulos_sangramento) * t.dano_sangramento_s)
		if t_matar_s < 0.5:
			out.append(_diag(item, &"ST7", "dano_sangramento_s", t_matar_s,
					"tempo de matar por sangramento no teto < 0,5 s", Diagnostico.Nivel.AVISO))
	if t.max_acumulos_queimadura > 0 and t.dano_queimadura_s > 0.0:
		var t_matar_q := 50.0 / (float(t.max_acumulos_queimadura) * t.dano_queimadura_s)
		if t_matar_q < 0.5:
			out.append(_diag(item, &"ST7", "dano_queimadura_s", t_matar_q,
					"tempo de matar por queimadura no teto < 0,5 s", Diagnostico.Nivel.AVISO))

	# ST8 — aviso: n_min = ceil(0,5 / (d * intervalo_numero_s)) > 1
	if t.intervalo_numero_s > 0.0:
		if t.dano_sangramento_s > 0.0:
			var n_min_s := int(ceil(0.5 / (t.dano_sangramento_s * t.intervalo_numero_s)))
			if n_min_s > 1:
				out.append(_diag(item, &"ST8", "dano_sangramento_s", n_min_s,
						"1 acúmulo de sangramento não exibe número em cada janela", Diagnostico.Nivel.AVISO))
		if t.dano_queimadura_s > 0.0:
			var n_min_q := int(ceil(0.5 / (t.dano_queimadura_s * t.intervalo_numero_s)))
			if n_min_q > 1:
				out.append(_diag(item, &"ST8", "dano_queimadura_s", n_min_q,
						"1 acúmulo de queimadura não exibe número em cada janela", Diagnostico.Nivel.AVISO))

	# ST10 — aviso: intervalo_numero_s > min(duracao_sangramento_s, duracao_queimadura_s)
	var min_dur := minf(t.duracao_sangramento_s, t.duracao_queimadura_s)
	if t.intervalo_numero_s > min_dur:
		out.append(_diag(item, &"ST10", "intervalo_numero_s", t.intervalo_numero_s,
				"intervalo_numero_s > min(duracao_sangramento_s, duracao_queimadura_s)", Diagnostico.Nivel.AVISO))

	# ST11 — aviso: valor fora da faixa de design
	if t.duracao_sangramento_s < 1.0 or t.duracao_sangramento_s > 10.0:
		out.append(_diag(item, &"ST11", "duracao_sangramento_s", t.duracao_sangramento_s,
				"fora da faixa de design 1,0 - 10,0", Diagnostico.Nivel.AVISO))
	if t.dano_sangramento_s < 0.5 or t.dano_sangramento_s > 10.0:
		out.append(_diag(item, &"ST11", "dano_sangramento_s", t.dano_sangramento_s,
				"fora da faixa de design 0,5 - 10,0", Diagnostico.Nivel.AVISO))
	if t.max_acumulos_sangramento > 20:
		out.append(_diag(item, &"ST11", "max_acumulos_sangramento", t.max_acumulos_sangramento,
				"fora da faixa de design 0 - 20", Diagnostico.Nivel.AVISO))
	if t.duracao_queimadura_s < 1.0 or t.duracao_queimadura_s > 8.0:
		out.append(_diag(item, &"ST11", "duracao_queimadura_s", t.duracao_queimadura_s,
				"fora da faixa de design 1,0 - 8,0", Diagnostico.Nivel.AVISO))
	if t.dano_queimadura_s < 1.0 or t.dano_queimadura_s > 15.0:
		out.append(_diag(item, &"ST11", "dano_queimadura_s", t.dano_queimadura_s,
				"fora da faixa de design 1,0 - 15,0", Diagnostico.Nivel.AVISO))
	if t.max_acumulos_queimadura < 1 or t.max_acumulos_queimadura > 15:
		out.append(_diag(item, &"ST11", "max_acumulos_queimadura", t.max_acumulos_queimadura,
				"fora da faixa de design 1 - 15", Diagnostico.Nivel.AVISO))
	if t.duracao_abalo_s < 1.0 or t.duracao_abalo_s > 10.0:
		out.append(_diag(item, &"ST11", "duracao_abalo_s", t.duracao_abalo_s,
				"fora da faixa de design 1,0 - 10,0", Diagnostico.Nivel.AVISO))
	if t.reducao_dano_causado < 0.10 or t.reducao_dano_causado > 0.60:
		out.append(_diag(item, &"ST11", "reducao_dano_causado", t.reducao_dano_causado,
				"fora da faixa de design 0,10 - 0,60", Diagnostico.Nivel.AVISO))
	if t.intervalo_numero_s < 0.25 or t.intervalo_numero_s > 1.0:
		out.append(_diag(item, &"ST11", "intervalo_numero_s", t.intervalo_numero_s,
				"fora da faixa de design 0,25 - 1,0", Diagnostico.Nivel.AVISO))

	return out


## Relatório informativo ST9 (tempos até matar em passos inteiros nos alvos de referência).
static func relatorio_st9(t: StatusTuning) -> Dictionary:
	var taxa_s_passo: float = (float(t.max_acumulos_sangramento) * t.dano_sangramento_s) / float(Unidades.TICK_RATE)
	var taxa_q_passo: float = (float(t.max_acumulos_queimadura) * t.dano_queimadura_s) / float(Unidades.TICK_RATE)
	var passos_s_75 := int(ceil(75.0 / taxa_s_passo - 1e-9)) if taxa_s_passo > 0.0 else -1
	var passos_s_60 := int(ceil(60.0 / taxa_s_passo - 1e-9)) if taxa_s_passo > 0.0 else -1
	var passos_s_115 := int(ceil(115.0 / taxa_s_passo - 1e-9)) if taxa_s_passo > 0.0 else -1
	var passos_q_50 := int(ceil(50.0 / taxa_q_passo - 1e-9)) if taxa_q_passo > 0.0 else -1
	return {
		&"sangramento_eco_75_passos": passos_s_75,
		&"sangramento_anomalia_60_passos": passos_s_60,
		&"sangramento_fenda_115_passos": passos_s_115,
		&"queimadura_anomalia_50_passos": passos_q_50,
	}


static func _diag(item: ItemDoCatalogo, regra: StringName, campo: String, valor: Variant,
		msg: String, nivel: Diagnostico.Nivel) -> Diagnostico:
	if item != null:
		return Diagnostico.de_item(item, regra, campo, valor, msg, nivel)
	return Diagnostico.novo(regra, campo, valor, msg, nivel)
