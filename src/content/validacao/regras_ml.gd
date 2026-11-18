class_name RegrasMl
extends ValidadorDoDono
## ML1–ML8 (Maldições; GDD maldicoes.md §Validações de dados e GDD de Conteúdo R9-P;
## ADR-0004 + ADR-0017): ML1–ML4 (erros de 1ª passada), ML5–ML6 (avisos de 1ª passada)
## e ML7–ML8 (avisos da 2ª passada: F6 60/40 e paridade de TTK de Pactos). ML7 e ML8 só
## rodam na [SegundaPassada], com os dados já carregados.
##
## Exemplo:
## [codeblock]
## var diags := RegrasMl.new().validar(itens)
## var diags_2 := RegrasMl.new().validar_segunda_passada(itens, catalogo)
## [/codeblock]

const VIDA_MIN_MALDICAO: float = 20.0
const RAZAO_VIDA_MAX: float = 1.50
const RAZAO_DPS_MAX: float = 1.15
const F_BESTA_MIN: float = 0.50
const F_BESTA_MAX: float = 0.70
const META_PARIDADE_EXTERNA: float = 0.15
const VIDA_CHEFE_PADRAO: float = 700.0
const DANO_TECNICA_MAX_MVP: float = 14.0
const DANO_EXTRA_CICLO_PRIMORDIAL: float = 1.0


func prefixo() -> StringName:
	return &"ML"


func precisa_da_segunda_passada() -> bool:
	return true


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var item_mt := primeiro_da_classe(itens, "MaldicoesTuning")
	if item_mt != null:
		var mt := item_mt.definicao as MaldicoesTuning
		if mt.distancia_seguir_px >= mt.alcance_fio_px or mt.alcance_chamado_px > mt.alcance_fio_px or mt.raio_atracao_px < mt.raio_chamado_px:
			out.append(Diagnostico.de_item(item_mt, &"ML1", "distancia_seguir_px", mt.distancia_seguir_px,
				"MaldicoesTuning: geometria do fio ou do Chamado inválida (ML1)"))
		for c_dur: String in ["duracao_salto_s", "duracao_imobilizar_s", "duracao_atracao_s", "recarga_troca_s", "recuperacao_exausta_s"]:
			var val_s := float(mt.get(c_dur))
			if Unidades.duracao_para_passos(val_s) < 1:
				out.append(Diagnostico.de_item(item_mt, &"ML2", c_dur, val_s,
					"MaldicoesTuning: %s < 1 passo" % c_dur))
		if mt.vida_retorno_frac <= 0.0 or mt.vida_retorno_frac > 1.0:
			out.append(Diagnostico.de_item(item_mt, &"ML2", "vida_retorno_frac", mt.vida_retorno_frac,
				"MaldicoesTuning: vida_retorno_frac fora de (0, 1]"))
		if _mt_fora_design(mt):
			out.append(Diagnostico.de_item(item_mt, &"ML6", "maldicoes_tuning", null,
				"MaldicoesTuning: campo fora da faixa de design", Diagnostico.Nivel.AVISO))
	var chefes_ids: Array[StringName] = []
	for item_e in itens_do_tipo(itens, &"enemy"):
		var e := item_e.definicao as EnemyDef
		if e != null and e.comportamento == &"chefe":
			chefes_ids.append(e.id)
	var chefes_usados: Array[StringName] = []
	var vidas: Array[float] = []
	var dps_lista: Array[float] = []
	for item_c in itens_do_tipo(itens, &"curse"):
		var c := item_c.definicao as CurseDef
		if c == null:
			continue
		for c_dur: String in ["preparo_s", "execucao_s", "recuperacao_s"]:
			var val_s := float(c.get(c_dur))
			if Unidades.duracao_para_passos(val_s) < 1:
				out.append(Diagnostico.de_item(item_c, &"ML2", c_dur, val_s,
					"CurseDef %s: %s < 1 passo" % [c.id, c_dur]))
		if c.vida_max < VIDA_MIN_MALDICAO:
			out.append(Diagnostico.de_item(item_c, &"ML2", "vida_max", c.vida_max,
				"CurseDef %s: vida_max %s < 20" % [c.id, str(c.vida_max)]))
		if not _kit_valido(c):
			out.append(Diagnostico.de_item(item_c, &"ML3", "raridade", c.raridade,
				"CurseDef %s: kit incompatível com raridade %s" % [c.id, c.raridade]))
		if c.raridade == &"primordial":
			if c.chefe_origem_id == &"" or not chefes_ids.has(c.chefe_origem_id) or chefes_usados.has(c.chefe_origem_id):
				out.append(Diagnostico.de_item(item_c, &"ML4", "chefe_origem_id", c.chefe_origem_id,
					"CurseDef %s: primordial sem chefe_origem_id válido ou duplicado" % c.id))
			else:
				chefes_usados.append(c.chefe_origem_id)
		elif c.chefe_origem_id != &"":
			out.append(Diagnostico.de_item(item_c, &"ML4", "chefe_origem_id", c.chefe_origem_id,
				"CurseDef %s: chefe_origem_id preenchido em raridade não primordial" % c.id))
		vidas.append(c.vida_max)
		var d_atk := dps_autonomo(c, 1.0)
		if d_atk > 0.0:
			dps_lista.append(d_atk)
	if vidas.size() >= 2:
		var v_min: float = vidas.min()
		var v_max: float = vidas.max()
		if v_min > 0.0 and v_max / v_min > RAZAO_VIDA_MAX + 1e-9:
			out.append(Diagnostico.novo(&"ML5", "vida_max", v_max / v_min,
				"CurseDef: max(vida_max)/min(vida_max) > 1,50", Diagnostico.Nivel.AVISO))
	if dps_lista.size() >= 2:
		var d_min: float = dps_lista.min()
		var d_max: float = dps_lista.max()
		if d_min > 0.0 and d_max / d_min > RAZAO_DPS_MAX + 1e-9:
			out.append(Diagnostico.novo(&"ML5", "dano_basico", d_max / d_min,
				"CurseDef: max(DPS_autonomo)/min(DPS_autonomo) > 1,15", Diagnostico.Nivel.AVISO))
	return out


func validar_segunda_passada(itens: Array[ItemDoCatalogo], _catalogo: Catalogo) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
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
	var bonus_dano_v := 0.0
	var item_vt := primeiro_da_classe(itens, "VinculoTuning")
	if item_vt != null:
		bonus_dano_v = (item_vt.definicao as VinculoTuning).bonus_dano_basico
	var dps_tecnica := DANO_TECNICA_MAX_MVP / mt.recarga_troca_s if mt.recarga_troca_s > 0.0 else 0.0
	var vida_chefe := _vida_chefe_referencia(itens)
	var ttk_refs: Array[float] = []
	for ref_id: StringName in [&"lamina", &"ressonancia"]:
		if armas.has(ref_id):
			var d_ref := dps_arma_referencia(armas[ref_id])
			if d_ref > 0.0:
				ttk_refs.append(vida_chefe / d_ref)
	for item_c in itens_do_tipo(itens, &"curse"):
		var c := item_c.definicao as CurseDef
		if c == null:
			continue
		var d_piso := dps_besta + f_campo * dps_autonomo(c, 1.0) + dps_chamado
		var d_teto := dps_besta + f_campo * dps_autonomo(c, 1.0 + bonus_dano_v) + dps_chamado + dps_tecnica
		for dps_tot: float in [d_piso, d_teto]:
			if dps_tot <= 0.0:
				continue
			var f_b := dps_besta / dps_tot
			if f_b < F_BESTA_MIN - 1e-9 or f_b > F_BESTA_MAX + 1e-9:
				out.append(Diagnostico.de_item(item_c, &"ML7", "dano_basico", f_b,
					"CurseDef %s: f_besta %.4f fora de [0,50; 0,70]" % [c.id, f_b], Diagnostico.Nivel.AVISO))
				break
		for dps_tot: float in [d_piso, d_teto]:
			if dps_tot <= 0.0:
				continue
			var ttk_p := vida_chefe / dps_tot
			var estourou := false
			for ttk_ref: float in ttk_refs:
				var diff := absf(ttk_p - ttk_ref) / minf(ttk_p, ttk_ref)
				if diff > META_PARIDADE_EXTERNA + 1e-9:
					out.append(Diagnostico.de_item(item_c, &"ML8", "dano_basico", diff,
						"CurseDef %s: paridade TTK %.4f > 0,15" % [c.id, diff], Diagnostico.Nivel.AVISO))
					estourou = true
					break
			if estourou:
				break
	return out


## F3 de Maldições: DPS autônomo do ataque básico com multiplicador [param mult_dano].
static func dps_autonomo(c: CurseDef, mult_dano: float = 1.0) -> float:
	var p := Unidades.duracao_para_passos(c.preparo_s)
	var e := Unidades.duracao_para_passos(c.execucao_s)
	var r := Unidades.duracao_para_passos(c.recuperacao_s)
	var c_atk := p + e + r
	if c_atk <= 0:
		return 0.0
	var extra := DANO_EXTRA_CICLO_PRIMORDIAL if c.habilidade_unica != &"" else 0.0
	var dano_golpe := c.dano_basico * mult_dano + extra
	return (dano_golpe * float(Unidades.TICK_RATE)) / float(c_atk)


## F1 de Armas: DPS combinado real de uma arma de referência (Lâmina ou Ressonância).
static func dps_arma_referencia(w: WeaponDef) -> float:
	if w == null or w.ataque == null or w.especial == null:
		return 0.0
	var r_atk := Unidades.duracao_para_passos(w.ataque.recarga_s)
	var r_esp := Unidades.duracao_para_passos(w.especial.recarga_s)
	if r_atk <= 0 or r_esp <= 0:
		return 0.0
	var k := float(r_esp) / float(r_atk)
	var c_bar := 1.0
	if not w.ataque.multiplicadores_combo.is_empty():
		var soma := 0.0
		for m: float in w.ataque.multiplicadores_combo:
			soma += m
		c_bar = soma / float(w.ataque.multiplicadores_combo.size())
	var h_atk := 0.0
	if w.ataque.forma == &"arco":
		h_atk = 4.0
	var h_esp := 0.0
	if w.especial.forma == &"avanco" or w.especial.forma == &"circulo":
		h_esp = 6.0
	var d_ciclo := k * w.ataque.dano * c_bar + w.especial.dano
	var h_ciclo := k * h_atk + h_esp
	return (d_ciclo * float(Unidades.TICK_RATE)) / (float(r_esp) + h_ciclo)


static func _vida_chefe_referencia(itens: Array[ItemDoCatalogo]) -> float:
	for i in itens_do_tipo(itens, &"enemy"):
		var e := i.definicao as EnemyDef
		if e != null and e.id == &"soberano_do_limiar":
			return e.vida
	return VIDA_CHEFE_PADRAO


static func _kit_valido(c: CurseDef) -> bool:
	if c.efeito_saida == &"" or c.efeito_entrada == &"":
		return false
	var n_passivas := c.passivas.size()
	var tem_chamado := c.efeito_chamado != &""
	var tem_unica := c.habilidade_unica != &""
	match c.raridade:
		&"comum":
			return n_passivas == 0 and not tem_chamado and not tem_unica
		&"refinado":
			return n_passivas == 1 and not tem_chamado and not tem_unica
		&"raro":
			return n_passivas == 1 and tem_chamado and not tem_unica
		&"epico":
			return n_passivas == 2 and tem_chamado and not tem_unica
		&"primordial":
			return n_passivas == 2 and tem_chamado and tem_unica
	return false


static func _mt_fora_design(mt: MaldicoesTuning) -> bool:
	if mt.alcance_fio_px < 360.0 or mt.alcance_fio_px > 660.0:
		return true
	if mt.distancia_seguir_px < 75.0 or mt.distancia_seguir_px > 150.0:
		return true
	if mt.alcance_chamado_px < 240.0 or mt.alcance_chamado_px > 480.0:
		return true
	if mt.duracao_salto_s < 0.10 - 1e-9 or mt.duracao_salto_s > 0.30 + 1e-9:
		return true
	if mt.raio_chamado_px < 90.0 or mt.raio_chamado_px > 195.0:
		return true
	if mt.raio_atracao_px < 135.0 or mt.raio_atracao_px > 300.0:
		return true
	if mt.duracao_imobilizar_s < 0.75 - 1e-9 or mt.duracao_imobilizar_s > 2.50 + 1e-9:
		return true
	if mt.duracao_atracao_s < 0.75 - 1e-9 or mt.duracao_atracao_s > 5.00 + 1e-9:
		return true
	if mt.recarga_troca_s < 2.00 - 1e-9 or mt.recarga_troca_s > 8.00 + 1e-9:
		return true
	if mt.recuperacao_exausta_s < 6.00 - 1e-9 or mt.recuperacao_exausta_s > 16.00 + 1e-9:
		return true
	if mt.vida_retorno_frac < 0.25 - 1e-9 or mt.vida_retorno_frac > 0.75 + 1e-9:
		return true
	if mt.regen_reserva_frac_s < 0.02 - 1e-9 or mt.regen_reserva_frac_s > 0.10 + 1e-9:
		return true
	return false
