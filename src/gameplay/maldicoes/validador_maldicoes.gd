class_name ValidadorMaldicoes
extends RegrasMl
## Validador de dados de Maldições (ML1–ML8; GDD maldicoes.md §Validações de dados e emenda Pactos 2026-11-15/16).
## Estende `RegrasMl` acrescentando as checagens de teto de atração vs recarga do Chamado e Abalo do Eco de Muralha (AC-ML-26, AC-ML-36).

const RECARGA_CHAMADO_PADRAO_PASSOS: int = 120
const RESPIRO_ATRACAO_PADRAO_S: float = 0.50


static func validar_completo(itens: Array[ItemDoCatalogo], catalogo: Catalogo = null,
		respiro_atracao_s: float = RESPIRO_ATRACAO_PADRAO_S,
		duracao_atracao_tecnica_s: float = 1.50,
		duracao_abalo_eco_muralha_s: float = 1.50,
		meta_paridade_pactos: float = 0.05) -> Array[Diagnostico]:
	var v := RegrasMl.new()
	var out := v.validar(itens)
	var item_mt := v.primeiro_da_classe(itens, "MaldicoesTuning")
	var recarga_chamado_passos := RECARGA_CHAMADO_PADRAO_PASSOS
	for item_w in v.itens_do_tipo(itens, &"weapon"):
		var w := item_w.definicao as WeaponDef
		if w != null and w.id == &"pactos" and w.especial != null and w.especial.recarga_s > 0.0:
			recarga_chamado_passos = Unidades.duracao_para_passos(w.especial.recarga_s)
			break

	if item_mt != null:
		var mt := item_mt.definicao as MaldicoesTuning
		var passos_atr := Unidades.duracao_para_passos(mt.duracao_atracao_s)
		var passos_resp := Unidades.duracao_para_passos(respiro_atracao_s)
		var passos_tec_atr := Unidades.duracao_para_passos(duracao_atracao_tecnica_s)
		# AC-ML-26: passos(duracao_atracao_s) + passos(respiro_atracao_s) > passos(recarga_chamado_s),
		# ou fonte de atração de CurseDef > duracao_atracao_s -> erro ML1
		if passos_atr + passos_resp > recarga_chamado_passos or passos_tec_atr > passos_atr:
			out.append(Diagnostico.de_item(item_mt, &"ML1", "duracao_atracao_s", mt.duracao_atracao_s,
				"MaldicoesTuning: duracao_atracao_s + respiro excede recarga do Chamado ou técnica excede teto (ML1)"))
		if mt.duracao_atracao_s > 1.50 + 1e-9:
			out.append(Diagnostico.de_item(item_mt, &"ML6", "duracao_atracao_s", mt.duracao_atracao_s,
				"MaldicoesTuning: duracao_atracao_s acima da faixa de design da emenda (0,75–1,50 s)", Diagnostico.Nivel.AVISO))

	# AC-ML-36: passos(duracao_abalo_s do Eco de Muralha) >= passos(recarga_chamado_s) -> erro ML1
	var passos_abalo_eco := Unidades.duracao_para_passos(duracao_abalo_eco_muralha_s)
	if passos_abalo_eco >= recarga_chamado_passos:
		out.append(Diagnostico.novo(&"ML1", "duracao_abalo_s", duracao_abalo_eco_muralha_s,
			"CurseDef baluarte_de_cinza: duracao_abalo_s do Eco de Muralha >= recarga_chamado_s (ML1)"))

	var diags_2 := v.validar_segunda_passada(itens, catalogo)
	out.append_array(diags_2)

	# Checagem fina de meta_paridade_pactos (0,05) na F6 com técnica (AC-ML-27)
	var calc := calcular_paridade_f6(itens)
	if not calc.is_empty() and float(calc.get("paridade_max", 0.0)) > meta_paridade_pactos + 1e-9:
		out.append(Diagnostico.novo(&"ML8", "meta_paridade_pactos", calc["paridade_max"],
			"Paridade de Pactos %.4f excede meta %.4f" % [float(calc["paridade_max"]), meta_paridade_pactos],
			Diagnostico.Nivel.AVISO))
	return out


## Calcula a tabela da F6 com técnica (piso, teto base, teto nível 5, f_besta e paridade máxima; AC-ML-27).
static func calcular_paridade_f6(itens: Array[ItemDoCatalogo]) -> Dictionary:
	var armas: Dictionary[StringName, WeaponDef] = {}
	var especies: Array[CurseDef] = []
	var mt: MaldicoesTuning = null
	var vt: VinculoTuning = null
	for i in itens:
		if i == null or i.definicao == null:
			continue
		if i.definicao is WeaponDef:
			var w := i.definicao as WeaponDef
			armas[w.id] = w
		elif i.definicao is CurseDef:
			especies.append(i.definicao as CurseDef)
		elif i.definicao is MaldicoesTuning:
			mt = i.definicao as MaldicoesTuning
		elif i.definicao is VinculoTuning:
			vt = i.definicao as VinculoTuning
	if not armas.has(&"pactos") or mt == null or especies.is_empty():
		return {}
	var besta: WeaponDef = armas[&"pactos"]
	var r_virote: int = maxi(1, Unidades.duracao_para_passos(besta.ataque.recarga_s))
	var r_esp: int = maxi(1, Unidades.duracao_para_passos(besta.especial.recarga_s))
	var n_salto: int = Unidades.duracao_para_passos(mt.duracao_salto_s)
	var dps_besta: float = besta.ataque.dano * float(Unidades.TICK_RATE) / float(r_virote)
	var dps_chamado: float = besta.especial.dano * float(Unidades.TICK_RATE) / float(r_esp)
	var f_campo: float = float(maxi(0, r_esp - n_salto)) / float(r_esp)
	var bonus_v: float = vt.bonus_dano_basico if vt != null else 0.05
	var dps_tec: float = DANO_TECNICA_MAX_MVP / mt.recarga_troca_s if mt.recarga_troca_s > 0.0 else 3.5

	var ttk_refs: Array[float] = []
	for ref_id: StringName in [&"lamina", &"ressonancia"]:
		if armas.has(ref_id):
			var d_ref: float = dps_arma_referencia(armas[ref_id])
			if d_ref > 0.0:
				ttk_refs.append(VIDA_CHEFE_PADRAO / d_ref)

	var dps_piso_min := INF
	var dps_piso_max := 0.0
	var dps_teto_max := 0.0
	var f_besta_min := INF
	var f_besta_max := 0.0
	var paridade_max := 0.0

	for c: CurseDef in especies:
		var d_piso := dps_besta + f_campo * dps_autonomo(c, 1.0) + dps_chamado
		var d_teto := dps_besta + f_campo * dps_autonomo(c, 1.0 + bonus_v) + dps_chamado + dps_tec
		dps_piso_min = minf(dps_piso_min, d_piso)
		dps_piso_max = maxf(dps_piso_max, d_piso)
		dps_teto_max = maxf(dps_teto_max, d_teto)
		for d_tot: float in [d_piso, d_teto]:
			var fb := dps_besta / d_tot
			f_besta_min = minf(f_besta_min, fb)
			f_besta_max = maxf(f_besta_max, fb)
			var ttk_p := VIDA_CHEFE_PADRAO / d_tot
			for ttk_r: float in ttk_refs:
				var diff := absf(ttk_p - ttk_r) / minf(ttk_p, ttk_r)
				paridade_max = maxf(paridade_max, diff)

	return {
		"dps_piso_min": dps_piso_min,
		"dps_piso_max": dps_piso_max,
		"dps_teto_max": dps_teto_max,
		"f_besta_min": f_besta_min,
		"f_besta_max": f_besta_max,
		"paridade_max": paridade_max,
	}
