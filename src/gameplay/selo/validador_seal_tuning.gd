class_name ValidadorSealTuning
extends ValidadorDoDono
## Validação SV1–SV12 e fórmulas de referência F3–F5 do `SealTuning`
## (GDD `design/gdd/selo-e-fluxo.md` Formulas › Faixas e Validação; Story 001, AC-SF-24, AC-SF-32;
## ADR-0004).
##
## Erros (SV1–SV3) bloqueiam o início da run; avisos (SV4–SV12) vão para o relatório de validação.

const ALVOS_REF: int = 3
const F_SELO_MIN: float = 0.05
const F_SELO_MAX: float = 0.20
const F_SELO_GRUPO_MAX: float = 0.45
const RAIO_JOGADOR_PADRAO: float = 27.0
const R_MIN_INIMIGO_PADRAO: float = 22.5
const LARGURA_CAMARA_PADRAO: float = 1920.0
const ALTURA_CAMARA_PADRAO: float = 1080.0


func prefixo() -> StringName:
	return &"SV"


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var item_s := primeiro_da_classe(itens, "SealTuning")
	if item_s == null:
		return []
	var s := item_s.definicao as SealTuning
	return validar_tuning(s)


## Valida [param s] contra SV1–SV12, cruzando com [param armas], [param inimigos] e
## dimensões de câmara `[largura, altura]`.
static func validar_tuning(s: SealTuning, armas: Array[WeaponDef] = [],
		inimigos: Dictionary[StringName, EnemyDef] = {},
		largura_camara: float = LARGURA_CAMARA_PADRAO,
		altura_camara: float = ALTURA_CAMARA_PADRAO,
		p_max: int = 4) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	if s == null:
		return out
	var armas_ref: Array[WeaponDef] = armas if not armas.is_empty() else FabricaDeArmas.armas_mvp()
	var pool: Dictionary[StringName, EnemyDef] = inimigos if not inimigos.is_empty() else FabricaDeArmas.inimigos_limiar()

	var r_s: int = Unidades.duracao_para_passos(s.recarga_s)
	var d_passos: int = Unidades.duracao_para_passos(s.duracao_s)
	var delta: float = s.dano_selo_s / float(Unidades.TICK_RATE)
	var teve_erro: bool = false

	# SV1 (erro): fluxo_max <= 0, custo_fluxo <= 0 ou custo_fluxo > fluxo_max
	if s.fluxo_max <= 0.0 or s.custo_fluxo <= 0.0 or s.custo_fluxo > s.fluxo_max:
		out.append(Diagnostico.novo(&"SV1", "custo_fluxo", s.custo_fluxo,
			"SealTuning: fluxo_max <= 0, custo_fluxo <= 0 ou custo_fluxo > fluxo_max"))
		teve_erro = true

	# SV2 (erro): recarga/duração < 1 passo, raio <= 0, fator_lentidao fora de [0, 1], ou taxas/distâncias < 0
	if s.recarga_s <= 0.0 or r_s < 1 or s.duracao_s <= 0.0 or d_passos < 1 \
			or s.raio_px <= 0.0 or s.fator_lentidao < 0.0 or s.fator_lentidao > 1.0 \
			or s.regen_fluxo_s < 0.0 or s.fluxo_por_acerto < 0.0 or s.dano_selo_s < 0.0 \
			or s.distancia_px < 0.0 or s.margem_borda_px < 0.0:
		out.append(Diagnostico.novo(&"SV2", "seal_tuning", null,
			"SealTuning: duração/recarga < 1 passo, raio <= 0, lentidão fora de [0,1] ou campo negativo"))
		teve_erro = true

	# SV3 (erro): 2 * margem_borda_px >= largura ou altura jogável
	if 2.0 * s.margem_borda_px >= largura_camara or 2.0 * s.margem_borda_px >= altura_camara:
		out.append(Diagnostico.novo(&"SV3", "margem_borda_px", s.margem_borda_px,
			"SealTuning: 2 × margem_borda_px >= dimensão da câmara"))
		teve_erro = true

	if teve_erro:
		return out

	# SV4 (aviso): fluxo_max < 2 * custo_fluxo ou >= 4 * custo_fluxo
	if s.fluxo_max < 2.0 * s.custo_fluxo - 1e-9 or s.fluxo_max >= 4.0 * s.custo_fluxo - 1e-9:
		out.append(Diagnostico.novo(&"SV4", "fluxo_max", s.fluxo_max,
			"SealTuning: fluxo_max fora de [2×custo, 4×custo)", Diagnostico.Nivel.AVISO))

	# SV5 (aviso): regen_fluxo_s * duracao_s >= custo_fluxo
	if s.regen_fluxo_s > 0.0 and s.regen_fluxo_s * s.duracao_s >= s.custo_fluxo - 1e-9:
		out.append(Diagnostico.novo(&"SV5", "regen_fluxo_s", s.regen_fluxo_s,
			"SealTuning: regeneração mantém Selo permanente", Diagnostico.Nivel.AVISO))

	# SV6 (aviso): custo_fluxo <= fluxo_por_acerto * alvos_ref ou G_vivo(alvos_ref) >= custo * 60 / R_s
	var taxa_recarga: float = s.custo_fluxo * float(Unidades.TICK_RATE) / float(r_s)
	var sv6_disparou: bool = s.custo_fluxo <= s.fluxo_por_acerto * float(ALVOS_REF) + 1e-9
	if not sv6_disparou:
		for w: WeaponDef in armas_ref:
			var f3_ref: Dictionary = calcular_f3_f4_f5(s, w, ALVOS_REF, ALVOS_REF, 1)
			if float(f3_ref[&"g_vivo"]) >= taxa_recarga - 1e-9:
				sv6_disparou = true
				break
	if sv6_disparou:
		out.append(Diagnostico.novo(&"SV6", "fluxo_por_acerto", s.fluxo_por_acerto,
			"SealTuning: laço de Fluxo na recarga", Diagnostico.Nivel.AVISO))

	# SV7 (aviso): passos(recarga_s) >= passos(duracao_s)
	if r_s >= d_passos:
		out.append(Diagnostico.novo(&"SV7", "recarga_s", r_s,
			"SealTuning: recarga >= duração (Selos nunca se sobrepõem)", Diagnostico.Nivel.AVISO))

	# SV8 (aviso): distancia_px > raio_px + raio_jogador + 2 * r_min ou <= raio_px - raio_jogador
	if s.distancia_px > s.raio_px + RAIO_JOGADOR_PADRAO + 2.0 * R_MIN_INIMIGO_PADRAO + 1e-9 \
			or s.distancia_px <= s.raio_px - RAIO_JOGADOR_PADRAO + 1e-9:
		out.append(Diagnostico.novo(&"SV8", "distancia_px", s.distancia_px,
			"SealTuning: zona cega na frente ou Selo cobre as costas", Diagnostico.Nivel.AVISO))

	# SV9 (aviso): margem_borda_px > raio_px + 2 * r_min
	if s.margem_borda_px > s.raio_px + 2.0 * R_MIN_INIMIGO_PADRAO + 1e-9:
		out.append(Diagnostico.novo(&"SV9", "margem_borda_px", s.margem_borda_px,
			"SealTuning: inimigo na parede escapa de todo Selo", Diagnostico.Nivel.AVISO))

	# SV10 (aviso informativo): Vida_p <= delta * D ou Vida_p == k * delta * D (k = 1..3)
	var dano_total_selo: float = delta * float(d_passos)
	for id_ini: StringName in [&"eco_perdido", &"anomalia_menor", &"fenda_errante"]:
		if not pool.has(id_ini):
			continue
		var ini: EnemyDef = pool[id_ini]
		for p: int in range(0, p_max + 1):
			var vida_p: float = float(FormulasDeArmas.vida_por_profundidade(ini.vida, p, false))
			var empata: bool = vida_p <= dano_total_selo + 1e-6
			if not empata:
				for k_selo: int in [1, 2, 3]:
					if absf(vida_p - float(k_selo) * dano_total_selo) <= 1e-6:
						empata = true
						break
			if empata:
				out.append(Diagnostico.novo(&"SV10", "%s:%d" % [id_ini, p], vida_p,
					"SV10: %s p=%d Vida=%.0f vs Selo=%.1f" % [id_ini, p, vida_p, dano_total_selo],
					Diagnostico.Nivel.AVISO))

	# SV11 (aviso): faixas de design
	if _fora_faixa_design(s, r_s, d_passos):
		out.append(Diagnostico.novo(&"SV11", "seal_tuning", null,
			"SealTuning: campo fora da faixa de design", Diagnostico.Nivel.AVISO))

	# SV12 (aviso): f_selo fora de 0,05–0,20 em 1 alvo, ou > 0,45 em grupo de 5 (com o mesmo M para Selo e arma)
	for w: WeaponDef in armas_ref:
		var info_1: Dictionary = calcular_f3_f4_f5(s, w, 1, 1, 1)
		var f_1: float = float(info_1[&"f_selo"])
		var m_grupo: int = 1 if w.ataque.forma == AtaqueConvertido.FORMA_PROJETIL else 1
		var n_esp_grupo: int = 0 if w.especial.forma == AtaqueConvertido.FORMA_CHAMADO else 5
		var info_5: Dictionary = calcular_f3_f4_f5(s, w, m_grupo, n_esp_grupo, 5, true)
		var f_5: float = float(info_5[&"f_selo"])
		if f_1 < F_SELO_MIN - 1e-9 or f_1 > F_SELO_MAX + 1e-9 or f_5 > F_SELO_GRUPO_MAX + 1e-9:
			out.append(Diagnostico.novo(&"SV12", String(w.id), f_1,
				"SV12: %s f_selo_1=%.4f f_selo_5=%.4f fora da meta" % [w.id, f_1, f_5],
				Diagnostico.Nivel.AVISO))

	return out


## F3, F4 e F5 do GDD `selo-e-fluxo.md` (AC-SF-24, AC-SF-32):
## devolve `{g_vivo, g_real, g_passo, t_entre_selos_s, a_ativos, terceiro_selo_passo, f_selo}`.
## Quando [param incluir_maldicao_grupo] é verdadeiro para `pactos` em grupo, soma a parcela
## autônoma da Maldição em campo (`16,20 DPS`, GDD OQ 9 / F5 emenda Pactos).
static func calcular_f3_f4_f5(s: SealTuning, w: WeaponDef, alvos_atk: int = 1,
		alvos_esp: int = 1, n_dentro: int = 1, incluir_maldicao_grupo: bool = false) -> Dictionary:
	var ct: CombatTuning = FabricaDeArmas.combat_tuning_padrao()
	var r_atk: int = maxi(1, Unidades.duracao_para_passos(w.ataque.recarga_s))
	var r_esp: int = maxi(1, Unidades.duracao_para_passos(w.especial.recarga_s))
	var k: float = float(r_esp) / float(r_atk)
	var m_ef: int = 1 if w.ataque.forma == AtaqueConvertido.FORMA_PROJETIL else alvos_atk
	var n_ef: int = 0 if w.especial.forma == AtaqueConvertido.FORMA_CHAMADO else alvos_esp
	var acertos_ciclo: float = k * float(m_ef) + float(n_ef)
	var g_vivo: float = s.regen_fluxo_s + s.fluxo_por_acerto * acertos_ciclo * float(Unidades.TICK_RATE) / float(r_esp)

	var h_atk: float = FormulasDeArmas.hitstop_medio_golpe(w.ataque, ct)
	var h_esp: float = 0.0
	if w.especial.forma == AtaqueConvertido.FORMA_CIRCULO:
		h_esp = float(Unidades.duracao_para_passos(ct.hitstop_pesado_s))
	elif w.especial.forma == AtaqueConvertido.FORMA_AVANCO:
		var h_p: int = Unidades.duracao_para_passos(ct.hitstop_pesado_s)
		var h_l: int = Unidades.duracao_para_passos(ct.hitstop_leve_s)
		h_esp = float(h_p + maxi(0, n_ef - 1) * h_l)
	var h_ciclo: float = k * h_atk + h_esp
	var rho: float = float(r_esp) / (float(r_esp) + h_ciclo)
	var g_real: float = g_vivo * rho
	var g_passo: float = g_vivo / float(Unidades.TICK_RATE)

	var r_s: int = maxi(1, Unidades.duracao_para_passos(s.recarga_s))
	var d_passos: int = maxi(1, Unidades.duracao_para_passos(s.duracao_s))
	var t_passos: float = maxf(float(r_s), s.custo_fluxo / g_passo) if g_passo > 0.0 else INF
	var t_segundos: float = t_passos / float(Unidades.TICK_RATE)
	var a_ativos: float = minf(g_passo / s.custo_fluxo, 1.0 / float(r_s)) * float(d_passos)
	var t_3: int = maxi(2 * r_s, int(ceil((3.0 * s.custo_fluxo - s.fluxo_max) / g_passo))) if g_passo > 0.0 else 999999

	var dps_selo_real: float = a_ativos * s.dano_selo_s * float(n_dentro) * rho
	var j: int = Unidades.duracao_para_passos(ct.janela_combo_s)
	var c_atk: float = FormulasDeArmas.media_combo(w.ataque, j)
	var c_esp: float = FormulasDeArmas.media_combo(w.especial, j)
	var alvos_dano_esp: int = 1 if w.especial.forma == AtaqueConvertido.FORMA_CHAMADO else alvos_esp
	var d_ciclo_grupo: float = k * w.ataque.dano * c_atk * float(m_ef) + w.especial.dano * c_esp * float(alvos_dano_esp)
	var dps_arma_real: float = d_ciclo_grupo * float(Unidades.TICK_RATE) / (float(r_esp) + h_ciclo)
	if incluir_maldicao_grupo and w.id == FabricaDeArmas.ID_PACTOS:
		dps_arma_real += 16.20
	var f_selo: float = dps_selo_real / (dps_selo_real + dps_arma_real) if (dps_selo_real + dps_arma_real) > 0.0 else 0.0

	return {
		&"g_vivo": g_vivo,
		&"g_real": g_real,
		&"g_passo": g_passo,
		&"t_entre_selos_s": t_segundos,
		&"a_ativos": a_ativos,
		&"terceiro_selo_passo": t_3,
		&"f_selo": f_selo,
		&"rho": rho,
	}


static func _fora_faixa_design(s: SealTuning, r_s: int, d_passos: int) -> bool:
	if s.fluxo_max < 80.0 - 1e-9 or s.fluxo_max > 160.0 + 1e-9:
		return true
	if s.regen_fluxo_s != 0.0 and (s.regen_fluxo_s < 1.8 - 1e-9 or s.regen_fluxo_s > 6.0 + 1e-9):
		return true
	if s.fluxo_por_acerto != 0.0 and (s.fluxo_por_acerto < 1.0 - 1e-9 or s.fluxo_por_acerto > 4.0 + 1e-9):
		return true
	if s.custo_fluxo < 35.0 - 1e-9 or s.custo_fluxo > 50.0 + 1e-9:
		return true
	if r_s < 15 or r_s > 60:
		return true
	if s.raio_px < 105.0 - 1e-9 or s.raio_px > 195.0 + 1e-9:
		return true
	if d_passos < 150 or d_passos > 240:
		return true
	if s.dano_selo_s < 4.8 - 1e-9 or s.dano_selo_s > 8.4 + 1e-9:
		return true
	if s.fator_lentidao < 0.35 - 1e-9 or s.fator_lentidao > 0.65 + 1e-9:
		return true
	if s.distancia_px < 120.0 - 1e-9 or s.distancia_px > 210.0 + 1e-9:
		return true
	if s.margem_borda_px < 0.0 - 1e-9 or s.margem_borda_px > 60.0 + 1e-9:
		return true
	return false
