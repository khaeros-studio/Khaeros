class_name RegrasVp
extends ValidadorDoDono
## VP1–VP9 (Vínculo e pactos; GDD vinculo-e-pactos.md §Validações e GDD de Conteúdo
## R9-P; ADR-0004): VP1–VP4 e VP8 (erros de 1ª passada), VP9 (aviso de faixa de design)
## e VP5–VP7 (avisos da 2ª passada: ML5, ML8 e F5 com o vínculo).
##
## Exemplo:
## [codeblock]
## var diags := RegrasVp.new().validar(itens)
## var diags_2 := RegrasVp.new().validar_segunda_passada(itens, catalogo)
## [/codeblock]

const ORDEM_RARIDADES: Array[StringName] = [&"comum", &"refinado", &"raro", &"epico", &"primordial"]
const META_PARIDADE_PACTOS: float = 0.05


func prefixo() -> StringName:
	return &"VP"


func precisa_da_segunda_passada() -> bool:
	return true


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var item_vt := primeiro_da_classe(itens, "VinculoTuning")
	if item_vt == null:
		return out
	var vt := item_vt.definicao as VinculoTuning
	# VP1: limiares_nivel vazio, não estritamente crescente ou com valor <= 0
	var vp1 := vt.limiares_nivel.is_empty()
	for i in vt.limiares_nivel.size():
		if vt.limiares_nivel[i] <= 0 or (i > 0 and vt.limiares_nivel[i] <= vt.limiares_nivel[i - 1]):
			vp1 = true
			break
	if vp1:
		out.append(Diagnostico.de_item(item_vt, &"VP1", "limiares_nivel", vt.limiares_nivel,
			"VinculoTuning: limiares_nivel vazio, não estritamente crescente ou com valor <= 0"))
	# VP2 e VP8: especie_primeiro_pacto Comum regular e ao menos outra espécie regular
	var especies: Dictionary[StringName, CurseDef] = {}
	var regulares_alem := 0
	for item_c in itens_do_tipo(itens, &"curse"):
		var c := item_c.definicao as CurseDef
		if c == null:
			continue
		especies[c.id] = c
		if c.raridade != &"primordial" and c.id != vt.especie_primeiro_pacto:
			regulares_alem += 1
	var primeiro: CurseDef = especies.get(vt.especie_primeiro_pacto, null)
	if primeiro == null or primeiro.raridade != &"comum":
		out.append(Diagnostico.de_item(item_vt, &"VP2", "especie_primeiro_pacto", vt.especie_primeiro_pacto,
			"VinculoTuning: especie_primeiro_pacto %s não é CurseDef comum regular" % vt.especie_primeiro_pacto))
	if regulares_alem < 1:
		out.append(Diagnostico.de_item(item_vt, &"VP8", "especie_primeiro_pacto", vt.especie_primeiro_pacto,
			"VinculoTuning: manifesto sem espécie regular além da do primeiro pacto"))
	# VP3: indices_encontro vazio, com 0, >= camaras_jogaveis - 2, ou que não é combate
	var vp3 := vt.indices_encontro.is_empty()
	var reg_limiar: RegionDef = null
	for item_r in itens_do_tipo(itens, &"region"):
		var r := item_r.definicao as RegionDef
		if r != null and (reg_limiar == null or r.id == &"limiar"):
			reg_limiar = r
	var n_jog := reg_limiar.camaras.size() if reg_limiar != null else 7
	var item_rt := primeiro_da_classe(itens, "RunTuning")
	if item_rt != null and reg_limiar != null:
		var rt := item_rt.definicao as RunTuning
		if rt.camaras_jogaveis.has(reg_limiar.id):
			n_jog = int(rt.camaras_jogaveis[reg_limiar.id])
	for idx_enc: int in vt.indices_encontro:
		if idx_enc <= 0 or idx_enc >= n_jog - 2:
			vp3 = true
			break
		if reg_limiar != null and (idx_enc >= reg_limiar.camaras.size() or reg_limiar.camaras[idx_enc] != &"combate"):
			vp3 = true
			break
	if vp3:
		out.append(Diagnostico.de_item(item_vt, &"VP3", "indices_encontro", vt.indices_encontro,
			"VinculoTuning: indices_encontro inválido (vazio, 0, >= camaras_jogaveis - 2 ou fora de combate)"))
	# VP4: chance_* fora de [0, 1], frac_vida_acuada <= 0, pity_runs < 1, encontros_para_consentir < 1 ou peso < 0
	var vp4 := vt.chance_encontro < 0.0 or vt.chance_encontro > 1.0 or vt.chance_nao_pactuada < 0.0 or vt.chance_nao_pactuada > 1.0 or vt.frac_vida_acuada <= 0.0 or vt.pity_runs < 1 or vt.encontros_para_consentir.is_empty()
	for ec_val: int in vt.encontros_para_consentir:
		if ec_val < 1:
			vp4 = true
			break
	for p_val: float in vt.peso_raridade:
		if p_val < 0.0 or not is_finite(p_val):
			vp4 = true
			break
	if vp4:
		out.append(Diagnostico.de_item(item_vt, &"VP4", "vinculo_tuning", null,
			"VinculoTuning: chance fora de [0, 1], frac_vida_acuada <= 0, pity_runs < 1, encontros_para_consentir < 1 ou peso < 0"))
	# VP9: faixa de design
	if _vt_fora_design(vt):
		out.append(Diagnostico.de_item(item_vt, &"VP9", "vinculo_tuning", null,
			"VinculoTuning: campo fora da faixa de design", Diagnostico.Nivel.AVISO))
	return out


func validar_segunda_passada(itens: Array[ItemDoCatalogo], _catalogo: Catalogo) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var item_vt := primeiro_da_classe(itens, "VinculoTuning")
	if item_vt == null:
		return out
	var vt := item_vt.definicao as VinculoTuning
	var vidas_base: Array[float] = []
	var dps_base: Array[float] = []
	for item_c in itens_do_tipo(itens, &"curse"):
		var c := item_c.definicao as CurseDef
		if c == null:
			continue
		vidas_base.append(c.vida_max)
		var d := RegrasMl.dps_autonomo(c, 1.0)
		if d > 0.0:
			dps_base.append(d)
		# VP7 (memórias): len(CurseDef.memorias) != memorias_por_raridade(raridade)
		var idx_rar := ORDEM_RARIDADES.find(c.raridade)
		if idx_rar >= 0 and idx_rar < vt.memorias_por_raridade.size():
			var esperado := int(vt.memorias_por_raridade[idx_rar])
			if c.memorias.size() != esperado:
				out.append(Diagnostico.de_item(item_c, &"VP7", "memorias", c.memorias.size(),
					"CurseDef %s: %d memórias != %d esperadas para %s" % [c.id, c.memorias.size(), esperado, c.raridade],
					Diagnostico.Nivel.AVISO))
	# VP5: round(max(vida_max) * (1 + bonus_vida)) / min(vida_max) > 1.50 ou max(DPS) * (1 + bonus_dano_basico) / min(DPS) > 1.15
	if vidas_base.size() >= 2:
		var v_min: float = vidas_base.min()
		var v_max_v := float(Unidades.arredondar_meio_longe_do_zero(vidas_base.max() * (1.0 + vt.bonus_vida)))
		if v_min > 0.0 and v_max_v / v_min > RegrasMl.RAZAO_VIDA_MAX + 1e-9:
			out.append(Diagnostico.de_item(item_vt, &"VP5", "bonus_vida", v_max_v / v_min,
				"VinculoTuning: razão de Vida com bonus_vida %.4f > 1,50" % (v_max_v / v_min), Diagnostico.Nivel.AVISO))
	if dps_base.size() >= 2:
		var d_min: float = dps_base.min()
		var d_max_v: float = dps_base.max() * (1.0 + vt.bonus_dano_basico)
		if d_min > 0.0 and d_max_v / d_min > RegrasMl.RAZAO_DPS_MAX + 1e-9:
			out.append(Diagnostico.de_item(item_vt, &"VP5", "bonus_dano_basico", d_max_v / d_min,
				"VinculoTuning: razão de DPS com bonus_dano_basico %.4f > 1,15" % (d_max_v / d_min), Diagnostico.Nivel.AVISO))
	# VP6 e VP7 (paridade F4 com vínculo nível 5)
	var item_mt := primeiro_da_classe(itens, "MaldicoesTuning")
	if item_mt == null:
		return out
	var mt := item_mt.definicao as MaldicoesTuning
	var armas: Dictionary[StringName, WeaponDef] = {}
	for i in itens_do_tipo(itens, &"weapon"):
		var w := i.definicao as WeaponDef
		if w != null:
			armas[w.id] = w
	if not armas.has(&"pactos"):
		return out
	var besta := armas[&"pactos"]
	if besta.ataque == null or besta.especial == null:
		return out
	var r_virote := maxi(1, Unidades.duracao_para_passos(besta.ataque.recarga_s))
	var r_esp := maxi(1, Unidades.duracao_para_passos(besta.especial.recarga_s))
	var n_salto := Unidades.duracao_para_passos(mt.duracao_salto_s)
	var dps_besta := besta.ataque.dano * float(Unidades.TICK_RATE) / float(r_virote)
	var dps_chamado := besta.especial.dano * float(Unidades.TICK_RATE) / float(r_esp)
	var f_campo := float(maxi(0, r_esp - n_salto)) / float(r_esp)
	var dps_tec := RegrasMl.DANO_TECNICA_MAX_MVP / mt.recarga_troca_s if mt.recarga_troca_s > 0.0 else 0.0
	var vida_chefe := RegrasMl.VIDA_CHEFE_PADRAO
	for i in itens_do_tipo(itens, &"enemy"):
		var e := i.definicao as EnemyDef
		if e != null and e.id == &"soberano_do_limiar":
			vida_chefe = e.vida
			break
	var ttk_refs: Array[float] = []
	for ref_id: StringName in [&"lamina", &"ressonancia"]:
		if armas.has(ref_id):
			var d_ref := RegrasMl.dps_arma_referencia(armas[ref_id])
			if d_ref > 0.0:
				ttk_refs.append(vida_chefe / d_ref)
	var vp6_emitido := false
	var vp7_emitido := false
	for item_c in itens_do_tipo(itens, &"curse"):
		var c := item_c.definicao as CurseDef
		if c == null:
			continue
		var dps_v := RegrasMl.dps_autonomo(c, 1.0 + vt.bonus_dano_basico)
		var d_sem_tec := dps_besta + f_campo * dps_v + dps_chamado
		var d_com_tec := d_sem_tec + dps_tec
		if not vp6_emitido and d_sem_tec > 0.0:
			var ttk_s := vida_chefe / d_sem_tec
			for ttk_ref: float in ttk_refs:
				var diff := absf(ttk_s - ttk_ref) / minf(ttk_s, ttk_ref)
				if diff > META_PARIDADE_PACTOS + 1e-9:
					out.append(Diagnostico.de_item(item_vt, &"VP6", "bonus_dano_basico", diff,
						"VinculoTuning: paridade sem técnica %.4f > 0,05" % diff, Diagnostico.Nivel.AVISO))
					vp6_emitido = true
					break
		if not vp7_emitido and d_com_tec > 0.0:
			var ttk_t := vida_chefe / d_com_tec
			for ttk_ref: float in ttk_refs:
				var diff := absf(ttk_t - ttk_ref) / minf(ttk_t, ttk_ref)
				if diff > META_PARIDADE_PACTOS + 1e-9:
					out.append(Diagnostico.de_item(item_vt, &"VP7", "bonus_dano_basico", diff,
						"VinculoTuning: teto com técnica %.4f > 0,05" % diff, Diagnostico.Nivel.AVISO))
					vp7_emitido = true
					break
	return out


static func _vt_fora_design(vt: VinculoTuning) -> bool:
	if vt.chance_encontro < 0.3 - 1e-9 or vt.chance_encontro > 0.9 + 1e-9:
		return true
	if vt.pity_runs < 1 or vt.pity_runs > 4:
		return true
	if vt.chance_nao_pactuada < 0.5 - 1e-9 or vt.chance_nao_pactuada > 1.0 + 1e-9:
		return true
	if vt.frac_vida_acuada < 0.8 - 1e-9 or vt.frac_vida_acuada > 1.6 + 1e-9:
		return true
	if vt.bonus_vida < 0.0 or vt.bonus_vida > 0.055 + 1e-9:
		return true
	if vt.mult_recuperacao < 0.80 - 1e-9 or vt.mult_recuperacao > 1.0 + 1e-9:
		return true
	if vt.bonus_dano_basico < 0.0 or vt.bonus_dano_basico > 0.07 + 1e-9:
		return true
	return false
