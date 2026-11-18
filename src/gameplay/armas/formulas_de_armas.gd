class_name FormulasDeArmas
extends RefCounted
## Fórmulas de referência das Armas das Doutrinas (F1–F7 do GDD `design/gdd/armas-das-doutrinas.md`;
## Story 003, AC-AR-16 a AC-AR-22, AC-AR-40, AC-AR-47, AC-AR-48; ADR-0009, ADR-0010).
##
## Funções estáticas e puras em `float` (64 bits), usando exclusivamente
## [method FormulasDeModificadores.arredondar_meio_longe_do_zero] quando há arredondamento.
## Não usa `round()` nem `roundi()`.

const MULT_VIDA_ELITE_PADRAO: float = 2.4
const MULT_DANO_ELITE_PADRAO: float = 1.25
const BONUS_VIDA_PROFUNDIDADE: float = 0.05


## Média do combo `c̄` de um [AttackDef] (Combate F11): se `R < J` e há combo, média dos
## multiplicadores; se `R >= J` com combo, `combo[0]`; sem combo, `1.0`.
static func media_combo(a: AttackDef, janela_combo_passos: int = 34) -> float:
	if a == null or a.multiplicadores_combo.is_empty():
		return 1.0
	var r: int = Unidades.duracao_para_passos(a.recarga_s)
	if r >= janela_combo_passos:
		return a.multiplicadores_combo[0]
	var soma: float = 0.0
	for m: float in a.multiplicadores_combo:
		soma += m
	return soma / float(a.multiplicadores_combo.size())


## Hitstop médio por disparo com 1 alvo atingido (Combate R10; Armas F1):
## projétil ou chamado = 0; investida ou círculo pesado = 6; arco com combo = média de
## leve (3) nos normais e pesado (6) nos finalizadores (`mult > limiar_finalizador`).
static func hitstop_medio_golpe(a: AttackDef, ct: CombatTuning = null) -> float:
	if a == null:
		return 0.0
	if a.forma == AtaqueConvertido.FORMA_PROJETIL or a.forma == AtaqueConvertido.FORMA_CHAMADO:
		return 0.0
	var t: CombatTuning = ct if ct != null else FabricaDeArmas.combat_tuning_padrao()
	var h_leve: int = Unidades.duracao_para_passos(t.hitstop_leve_s)
	var h_pesado: int = Unidades.duracao_para_passos(t.hitstop_pesado_s)
	if a.forma == AtaqueConvertido.FORMA_AVANCO:
		return float(h_pesado)
	if not a.multiplicadores_combo.is_empty():
		var soma: int = 0
		for m: float in a.multiplicadores_combo:
			var pesado: bool = (m > t.limiar_finalizador) or (a.empurrao * m >= t.empurrao_pesado)
			soma += h_pesado if pesado else h_leve
		return float(soma) / float(a.multiplicadores_combo.size())
	return float(h_pesado if a.empurrao >= t.empurrao_pesado else h_leve)


## F1 por golpe individual: `{dps_vivo, dps_real, r, c_bar, h_bar}`.
static func dps_golpe(a: AttackDef, m: float = 1.0, ct: CombatTuning = null) -> Dictionary:
	var t: CombatTuning = ct if ct != null else FabricaDeArmas.combat_tuning_padrao()
	var j: int = Unidades.duracao_para_passos(t.janela_combo_s)
	var r: int = maxi(1, Unidades.duracao_para_passos(a.recarga_s))
	var c_bar: float = media_combo(a, j)
	var h_bar: float = hitstop_medio_golpe(a, t)
	var dano_medio: float = a.dano * c_bar * m
	var vivo: float = dano_medio * float(Unidades.TICK_RATE) / float(r)
	var real: float = dano_medio * float(Unidades.TICK_RATE) / (float(r) + h_bar)
	return {
		&"dps_vivo": vivo,
		&"dps_real": real,
		&"r": r,
		&"c_bar": c_bar,
		&"h_bar": h_bar,
	}


## F1 combinado de uma arma (Especial a cada recarga e Ataque no resto):
## devolve `{k, d_ciclo, h_ciclo, dps_vivo, dps_real, r_atk, r_esp}`.
static func dps_combinado(w: WeaponDef, m_atk: float = 1.0, m_esp: float = 1.0,
		ct: CombatTuning = null, teto_m: float = 4.0) -> Dictionary:
	var t: CombatTuning = ct if ct != null else FabricaDeArmas.combat_tuning_padrao()
	var j: int = Unidades.duracao_para_passos(t.janela_combo_s)
	var r_atk: int = maxi(1, Unidades.duracao_para_passos(w.ataque.recarga_s))
	var r_esp: int = maxi(1, Unidades.duracao_para_passos(w.especial.recarga_s))
	var k: float = float(r_esp) / float(r_atk)
	var c_atk: float = media_combo(w.ataque, j)
	var c_esp: float = media_combo(w.especial, j)
	var m_a: float = minf(maxf(0.0, m_atk), teto_m)
	var m_e: float = minf(maxf(0.0, m_esp), teto_m)
	var d_ciclo_base: float = k * w.ataque.dano * c_atk + w.especial.dano * c_esp
	var d_ciclo_m: float = k * w.ataque.dano * c_atk * m_a + w.especial.dano * c_esp * m_e
	var h_atk: float = hitstop_medio_golpe(w.ataque, t)
	var h_esp: float = hitstop_medio_golpe(w.especial, t)
	var h_ciclo: float = k * h_atk + h_esp
	var dps_vivo: float = d_ciclo_m * float(Unidades.TICK_RATE) / float(r_esp)
	var dps_real: float = d_ciclo_m * float(Unidades.TICK_RATE) / (float(r_esp) + h_ciclo)
	return {
		&"k": k,
		&"d_ciclo": d_ciclo_base,
		&"d_ciclo_m": d_ciclo_m,
		&"h_ciclo": h_ciclo,
		&"dps_vivo": dps_vivo,
		&"dps_real": dps_real,
		&"r_atk": r_atk,
		&"r_esp": r_esp,
	}


## F2: TTK contínuo contra o chefe (`vida_chefe / dps_real`).
static func ttk_chefe_continuo(dps_real: float, vida_chefe: float = 700.0) -> float:
	if dps_real <= 0.0:
		return INF
	return vida_chefe / dps_real


## F2: paridade relativa `|ttk_a - ttk_b| / min(ttk_a, ttk_b)`.
static func paridade_ttk(ttk_a: float, ttk_b: float) -> float:
	var menor: float = minf(ttk_a, ttk_b)
	if menor <= 0.0:
		return 0.0
	return absf(ttk_a - ttk_b) / menor


## F2 discreto (só Ataque): `{g, passos, segundos}` para abater `vida_chefe` com o Ataque de `w`.
static func ttk_ataque_discreto(w: WeaponDef, vida_chefe: float = 700.0, ct: CombatTuning = null) -> Dictionary:
	var t: CombatTuning = ct if ct != null else FabricaDeArmas.combat_tuning_padrao()
	var a: AttackDef = w.ataque
	var r_atk: int = maxi(1, Unidades.duracao_para_passos(a.recarga_s))
	var h_leve: int = Unidades.duracao_para_passos(t.hitstop_leve_s)
	var h_pesado: int = Unidades.duracao_para_passos(t.hitstop_pesado_s)
	var tem_combo: bool = not a.multiplicadores_combo.is_empty()
	var n_combo: int = a.multiplicadores_combo.size()
	var eh_proj: bool = a.forma == AtaqueConvertido.FORMA_PROJETIL or a.forma == AtaqueConvertido.FORMA_CHAMADO
	var acumulado: float = 0.0
	var g: int = 0
	var hitstops: Array[int] = []
	while acumulado < vida_chefe - 1e-9:
		var mult: float = a.multiplicadores_combo[g % n_combo] if tem_combo else 1.0
		acumulado += a.dano * mult
		var h: int = 0
		if not eh_proj:
			var pesado: bool = (mult > t.limiar_finalizador) or (a.empurrao * mult >= t.empurrao_pesado)
			h = h_pesado if pesado else h_leve
		hitstops.append(h)
		g += 1
	var soma_h: int = 0
	for i: int in range(0, maxi(0, g - 1)):
		soma_h += hitstops[i]
	var passos: int = maxi(0, g - 1) * r_atk + soma_h
	return {
		&"g": g,
		&"passos": passos,
		&"segundos": float(passos) / float(Unidades.TICK_RATE),
	}


## F2 folga do dano do Pulso mantendo a Lâmina fixa e `paridade <= meta` (passo de 0,01):
## devolve `{min_so_ataque, max_so_ataque, min_combinado, max_combinado}`.
static func folga_dano_pulso(lamina: WeaponDef, ressonancia: WeaponDef, meta: float = 0.15,
		ct: CombatTuning = null) -> Dictionary:
	var ttk_lam_atk: float = ttk_chefe_continuo(dps_golpe(lamina.ataque, 1.0, ct)[&"dps_real"])
	var ttk_lam_comb: float = ttk_chefe_continuo(dps_combinado(lamina, 1.0, 1.0, ct)[&"dps_real"])
	var clone: WeaponDef = ressonancia.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as WeaponDef
	var min_atk: float = INF
	var max_atk: float = -INF
	var min_comb: float = INF
	var max_comb: float = -INF
	for passo_int: int in range(500, 2001):
		var d: float = float(passo_int) * 0.01
		clone.ataque.dano = d
		var t_atk: float = ttk_chefe_continuo(dps_golpe(clone.ataque, 1.0, ct)[&"dps_real"])
		if paridade_ttk(ttk_lam_atk, t_atk) <= meta + 1e-9:
			min_atk = minf(min_atk, d)
			max_atk = maxf(max_atk, d)
		var t_comb: float = ttk_chefe_continuo(dps_combinado(clone, 1.0, 1.0, ct)[&"dps_real"])
		if paridade_ttk(ttk_lam_comb, t_comb) <= meta + 1e-9:
			min_comb = minf(min_comb, d)
			max_comb = maxf(max_comb, d)
	return {
		&"min_so_ataque": min_atk,
		&"max_so_ataque": max_atk,
		&"min_combinado": min_comb,
		&"max_combinado": max_comb,
	}


## F3: `Vida_p = round_longe_zero(Vida_base × (1 + 0,05 × p) × (elite ? 2,4 : 1))`
## avaliado em double na ordem da F1 do Modificadores (AC-AR-18).
static func vida_por_profundidade(vida_base: float, p: int, elite: bool = false,
		mult_elite: float = MULT_VIDA_ELITE_PADRAO) -> int:
	var pct: float = BONUS_VIDA_PROFUNDIDADE * float(p)
	var mult: float = mult_elite if elite else 1.0
	var v: float = vida_base * (1.0 + pct) * mult
	return maxi(1, FormulasDeModificadores.arredondar_meio_longe_do_zero(v))


## F3: golpes até matar `vida_p` com o `AttackDef` [param a] (combo começando em 0):
## devolve `{g, d_g, d_anterior, margem, falta}`.
static func golpes_ate_matar(a: AttackDef, vida_p: int) -> Dictionary:
	var tem_combo: bool = not a.multiplicadores_combo.is_empty()
	var n: int = a.multiplicadores_combo.size()
	var d_ant: float = 0.0
	var d_k: float = 0.0
	var g: int = 0
	var alvo: float = float(vida_p)
	while d_k < alvo - 1e-9:
		d_ant = d_k
		var mult: float = a.multiplicadores_combo[g % n] if tem_combo else 1.0
		d_k += a.dano * mult
		g += 1
	return {
		&"g": g,
		&"d_g": d_k,
		&"d_anterior": d_ant,
		&"margem": d_k - alvo,
		&"falta": alvo - d_ant,
	}


## F4: golpes recebidos até morrer (`dano`, `g_morte`, `tempo_min_passos`).
static func golpes_ate_morrer(vida_max: int, dano_base: float, elite: bool = false,
		invuln_atingido_passos: int = 40) -> Dictionary:
	var mult: float = MULT_DANO_ELITE_PADRAO if elite else 1.0
	var dano: int = maxi(1, FormulasDeModificadores.arredondar_meio_longe_do_zero(dano_base * mult))
	var g_morte: int = int(ceil(float(vida_max) / float(dano)))
	var tempo_min: int = maxi(0, g_morte - 1) * invuln_atingido_passos
	return {
		&"dano": dano,
		&"g_morte": g_morte,
		&"tempo_min_passos": tempo_min,
	}


## F5 / F5b: simulação discreta do empurrão de um golpe (F7 do Combate) e velocidade sustentada.
## Devolve `{emp_ef, passos, distancia_px, bate_parede, v_sust, teto_av5}`.
static func empurrao_efetivo(empurrao_base: float, fator_empurrao: float, recarga_passos: int,
		ct: CombatTuning = null) -> Dictionary:
	var t: CombatTuning = ct if ct != null else FabricaDeArmas.combat_tuning_padrao()
	var emp_ef: float = empurrao_base * fator_empurrao
	var q: float = t.queda_empurrao
	var z: float = t.empurrao_zero
	var v: float = emp_ef
	var passos: int = 0
	var dist: float = 0.0
	var bate: bool = emp_ef >= t.parede_vel_min
	while v >= z:
		dist += v / float(Unidades.TICK_RATE)
		v *= q
		passos += 1
		if v < z:
			break
	var denom: float = 1.0 - pow(q, float(maxi(1, recarga_passos)))
	var v_sust: float = emp_ef / denom if denom > 0.0 else emp_ef
	var teto_av5: float = t.parede_vel_min * denom
	return {
		&"emp_ef": emp_ef,
		&"passos": passos,
		&"distancia_px": dist,
		&"bate_parede": bate,
		&"v_sust": v_sust,
		&"teto_av5": teto_av5,
	}


## Alcance testado de um projétil do jogador (Combate F5): `nascimento_px + (L - 1) × s`.
static func alcance_testado_projetil_px(a: AttackDef, ct: CombatTuning = null) -> float:
	var t: CombatTuning = ct if ct != null else FabricaDeArmas.combat_tuning_padrao()
	var l: int = Unidades.duracao_para_passos(a.params.get(&"vida_s", 0.0))
	var s: float = a.params.get(&"velocidade_pxs", 0.0) / float(Unidades.TICK_RATE)
	if l <= 0:
		return 0.0
	return t.nascimento_projetil_px + float(l - 1) * s


## F6: fração do dano do Especial no ciclo combinado (`f_esp`) e ganho relativo de bênção de slot.
static func fracao_especial(w: WeaponDef, bonus_slot: float = 0.25, ct: CombatTuning = null) -> Dictionary:
	var comb: Dictionary = dps_combinado(w, 1.0, 1.0, ct)
	var j: int = Unidades.duracao_para_passos((ct if ct != null else FabricaDeArmas.combat_tuning_padrao()).janela_combo_s)
	var d_esp: float = w.especial.dano * media_combo(w.especial, j)
	var d_ciclo: float = float(comb[&"d_ciclo"])
	var f_esp: float = d_esp / d_ciclo if d_ciclo > 0.0 else 0.0
	return {
		&"f_esp": f_esp,
		&"ganho_especial_pct": bonus_slot * f_esp,
		&"ganho_ataque_pct": bonus_slot * (1.0 - f_esp),
	}


## F7: DPS composto da Besta do Vínculo + Maldição em campo (valores da emenda Pactos e pré-emenda).
## Se [param usar_tecnica] for verdadeiro, soma `d_tecnica_max / recarga_troca_s` (14 / 4,0 = 3,50 DPS)
## e aplica `1 + bonus_dano_vinculo` (0,05 no nível 5) ao ataque básico da Maldição.
static func dps_composto_pactos(besta: WeaponDef, curse: CurseDef, mt: MaldicoesTuning,
		vida_chefe: float = 700.0, usar_tecnica: bool = false, bonus_dano_vinculo: float = 0.0,
		dps_autonomo_override: float = -1.0) -> Dictionary:
	var r_atk: int = maxi(1, Unidades.duracao_para_passos(besta.ataque.recarga_s))
	var r_esp: int = maxi(1, Unidades.duracao_para_passos(besta.especial.recarga_s))
	var k: float = float(r_esp) / float(r_atk)
	var dps_virote: float = besta.ataque.dano * float(Unidades.TICK_RATE) / float(r_atk)
	var dps_chamado: float = besta.especial.dano * float(Unidades.TICK_RATE) / float(r_esp)
	var dps_arma: float = (k * besta.ataque.dano + besta.especial.dano) * float(Unidades.TICK_RATE) / float(r_esp)
	if curse == null or mt == null:
		return {
			&"dps_virote": dps_virote,
			&"dps_chamado": dps_chamado,
			&"dps_arma": dps_virote,
			&"dps_maldicao_campo": 0.0,
			&"dps_tecnica": 0.0,
			&"dps_pactos": dps_virote,
			&"ttk": vida_chefe / dps_virote if dps_virote > 0.0 else INF,
			&"f_besta": 1.0,
		}
	var n_salto: int = Unidades.duracao_para_passos(mt.duracao_salto_s)
	var f_campo: float = float(maxi(0, r_esp - n_salto)) / float(r_esp)
	var mult_vinc: float = (1.0 + bonus_dano_vinculo) if usar_tecnica else 1.0
	var d_aut: float = dps_autonomo_override if dps_autonomo_override >= 0.0 else RegrasMl.dps_autonomo(curse, mult_vinc)
	var dps_mald_campo: float = f_campo * d_aut
	var dps_tec: float = (RegrasMl.DANO_TECNICA_MAX_MVP / mt.recarga_troca_s) if (usar_tecnica and mt.recarga_troca_s > 0.0) else 0.0
	var dps_tot: float = dps_arma + dps_mald_campo + dps_tec
	var ttk: float = vida_chefe / dps_tot if dps_tot > 0.0 else INF
	var f_besta: float = dps_virote / dps_tot if dps_tot > 0.0 else 0.0
	return {
		&"dps_virote": dps_virote,
		&"dps_chamado": dps_chamado,
		&"dps_arma": dps_arma,
		&"dps_maldicao_campo": dps_mald_campo,
		&"dps_tecnica": dps_tec,
		&"dps_pactos": dps_tot,
		&"ttk": ttk,
		&"f_besta": f_besta,
		&"f_campo": f_campo,
	}
