class_name ValidadorIA
extends ValidadorDoDono
## Validação de IATuning, EnemyDef e EliteRules (IV1–IV9 e IA1–IA14; GDD ia-de-inimigos-e-elites.md R12, R14, F5; ADR-0004, ADR-0018).

const COMPORTAMENTOS_VALIDOS: Array[StringName] = [
	&"corpo_a_corpo", &"distancia", &"arremetida", &"chefe",
	&"melee", &"ranged", &"charger",
]
const VELOCIDADE_MIN_JOGADOR_PADRAO: float = 342.0
const PASSOS_INVULN_PADRAO: int = 40
const DANO_MAX_COMUNS_ELITES_MVP: int = 16


func prefixo() -> StringName:
	return &"IV"


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	return validar_completo(itens)


static func validar_completo(itens: Array[ItemDoCatalogo], ia_tuning_injetado: IATuning = null,
		elite_rules_injetado: EliteRules = null, tel_tuning_injetado: TelegraphTuning = null,
		vel_min_jogador: float = VELOCIDADE_MIN_JOGADOR_PADRAO) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var item_ia: ItemDoCatalogo = null
	var item_el: ItemDoCatalogo = null
	var item_tt: ItemDoCatalogo = null
	var item_cbt: ItemDoCatalogo = null
	for i in itens:
		if i == null or i.definicao == null:
			continue
		var s := i.definicao.get_script()
		if s == IATuning:
			item_ia = i
		elif s == EliteRules:
			item_el = i
		elif s == TelegraphTuning:
			item_tt = i
		elif s == CombatTuning:
			item_cbt = i

	var iat: IATuning = ia_tuning_injetado
	if iat == null:
		iat = item_ia.definicao as IATuning if item_ia != null else IATuning.de_fabrica()
	var elr: EliteRules = elite_rules_injetado
	if elr == null:
		elr = item_el.definicao as EliteRules if item_el != null else RegrasDeElite.de_fabrica()
	var tt: TelegraphTuning = tel_tuning_injetado
	if tt == null:
		tt = item_tt.definicao as TelegraphTuning if item_tt != null else TelegraphTuning.de_fabrica()

	# IV1 / IA1: passos(surgimento_s) < 1, avanco_passos < 1, execução < 1, ou espera com piso < 1 passo
	var p_surg := Unidades.duracao_para_passos(iat.surgimento_s)
	var p_esp_ini := Unidades.duracao_para_passos(iat.espera_inicial_base_s)
	var p_esp := Unidades.duracao_para_passos(iat.espera_base_s)
	if p_surg < 1 or iat.avanco_passos < 1 or iat.execucao_melee_passos < 1 \
			or iat.execucao_ranged_passos < 1 or p_esp_ini < 1 or p_esp < 1:
		out.append(_diag(item_ia, &"IV1", "ia_tuning", p_surg,
			"IATuning: duração de surgimento, avanço, execução ou espera < 1 passo", Diagnostico.Nivel.ERRO))
		out.append(_diag(item_ia, &"IA1", "ia_tuning", p_surg,
			"IATuning: duração < 1 passo", Diagnostico.Nivel.ERRO))

	# IV2 / IA2: ranged_perto_px >= ranged_longe_px ou charger_reaproxima_px >= charger_engaja_px
	if iat.ranged_perto_px >= iat.ranged_longe_px or iat.charger_reaproxima_px >= iat.charger_engaja_px:
		out.append(_diag(item_ia, &"IV2", "ranged_perto_px", iat.ranged_perto_px,
			"IATuning: ranged_perto_px >= ranged_longe_px ou charger_reaproxima_px >= charger_engaja_px", Diagnostico.Nivel.ERRO))
		out.append(_diag(item_ia, &"IA2", "ranged_perto_px", iat.ranged_perto_px,
			"IATuning: distâncias de engajamento invertidas", Diagnostico.Nivel.ERRO))

	# IV3 / IA3: fator fora de [0, 1], ou profundidade_minima < 0, ou max_elites_onda < 1
	if iat.fator_recuperacao_andar < 0.0 or iat.fator_recuperacao_andar > 1.0 \
			or iat.fator_contorno < 0.0 or iat.fator_contorno > 1.0 \
			or iat.fator_lentidao_selo < 0.0 or iat.fator_lentidao_selo > 1.0 \
			or iat.fator_cambaleio < 0.0 or iat.fator_cambaleio > 1.0 \
			or elr.profundidade_minima < 0 or elr.max_elites_onda < 1:
		out.append(_diag(item_ia, &"IV3", "ia_tuning", iat.fator_recuperacao_andar,
			"IATuning/EliteRules: fator fora de [0, 1], profundidade_minima < 0 ou max_elites_onda < 1", Diagnostico.Nivel.ERRO))
		out.append(_diag(item_ia, &"IA3", "ia_tuning", iat.fator_recuperacao_andar,
			"IATuning/EliteRules: valores fora dos limites", Diagnostico.Nivel.ERRO))

	# IA10: multiplicadores de EliteRules inválidos
	if elr.mult_vida <= 1.0 or elr.mult_dano <= 1.0 or elr.mult_raio <= 1.0 \
			or elr.resistencia_empurrao <= 0.0 or elr.resistencia_empurrao > 1.0:
		out.append(_diag(item_el, &"IA10", "elite_rules", elr.mult_vida,
			"EliteRules: multiplicadores de elite inválidos", Diagnostico.Nivel.ERRO))

	# IV6 / IA6: avanco_passos difere do N de Telégrafos
	if iat.avanco_passos != tt.avanco_passos:
		out.append(_diag(item_ia, &"IV6", "avanco_passos", iat.avanco_passos,
			"IATuning: avanco_passos (%d) != TelegraphTuning.avanco_passos (%d)" % [iat.avanco_passos, tt.avanco_passos],
			Diagnostico.Nivel.AVISO))
		out.append(_diag(item_ia, &"IA6", "avanco_passos", iat.avanco_passos,
			"IATuning: avanco_passos diverge de Telégrafos", Diagnostico.Nivel.AVISO))

	# IV8 / IA8: margem_visivel_px > 200
	if iat.margem_visivel_px > 200.0 + 1e-9 or iat.margem_visivel_px < 0.0:
		out.append(_diag(item_ia, &"IV8", "margem_visivel_px", iat.margem_visivel_px,
			"IATuning: margem_visivel_px fora de [0, 200]", Diagnostico.Nivel.AVISO))
		out.append(_diag(item_ia, &"IA8", "margem_visivel_px", iat.margem_visivel_px,
			"IATuning: margem_visivel_px > 200 permite tiro fora da tela", Diagnostico.Nivel.AVISO))

	# IV9 / IA9: faixas de design do IATuning / EliteRules
	if _fora_da_faixa_design(iat, elr):
		out.append(_diag(item_ia, &"IV9", "ia_tuning", null,
			"IATuning/EliteRules: campo fora da faixa de design", Diagnostico.Nivel.AVISO))
		out.append(_diag(item_ia, &"IA9", "ia_tuning", null,
			"IATuning/EliteRules: campo fora da faixa de design", Diagnostico.Nivel.AVISO))

	# Inimigos e Armas (IV4, IV5, IV7, IA4, IA5, IA7, IA11..IA14)
	var dano_max_comum_elite := 0
	for item in itens:
		if item == null or not (item.definicao is EnemyDef):
			continue
		var e := item.definicao as EnemyDef
		if not COMPORTAMENTOS_VALIDOS.has(e.comportamento):
			out.append(_diag(item, &"IV4", "comportamento", e.comportamento,
				"EnemyDef %s: comportamento %s inválido" % [e.id, e.comportamento], Diagnostico.Nivel.ERRO))
			out.append(_diag(item, &"IA4", "comportamento", e.comportamento,
				"EnemyDef %s: comportamento %s inválido" % [e.id, e.comportamento], Diagnostico.Nivel.ERRO))
			continue
		if e.vida <= 0.0 or e.raio_px <= 0.0 or e.dano <= 0.0:
			out.append(_diag(item, &"IA11", "vida", e.vida,
				"EnemyDef %s: vida, raio ou dano <= 0" % e.id, Diagnostico.Nivel.ERRO))
		if e.comportamento != &"chefe":
			var rec_passos := Unidades.duracao_para_passos(e.recarga_s)
			if rec_passos < 1:
				out.append(_diag(item, &"IA12", "recarga_s", e.recarga_s,
					"EnemyDef %s: recarga_s < 1 passo" % e.id, Diagnostico.Nivel.ERRO))
			if e.velocidade >= 0.80 * vel_min_jogador - 1e-9:
				out.append(_diag(item, &"IV5", "velocidade", e.velocidade,
					"EnemyDef %s: velocidade %.1f >= 0,8 * %.1f" % [e.id, e.velocidade, vel_min_jogador],
					Diagnostico.Nivel.AVISO))
				out.append(_diag(item, &"IA5", "velocidade", e.velocidade,
					"EnemyDef %s: comum rápido demais comparado ao jogador" % e.id, Diagnostico.Nivel.AVISO))
			var d_el := Unidades.arredondar_meio_longe_do_zero(e.dano * elr.mult_dano)
			dano_max_comum_elite = maxi(dano_max_comum_elite, d_el)
			var cic_min := ciclo_minimo_passos(e, iat)
			if cic_min < 60:
				out.append(_diag(item, &"IA13", "recarga_s", cic_min,
					"EnemyDef %s: ciclo mínimo %d < 60 passos" % [e.id, cic_min], Diagnostico.Nivel.AVISO))

	if dano_max_comum_elite <= 0:
		dano_max_comum_elite = DANO_MAX_COMUNS_ELITES_MVP
	var passos_invuln := PASSOS_INVULN_PADRAO
	if item_cbt != null:
		var cbt := item_cbt.definicao as CombatTuning
		if cbt.invuln_atingido_s > 0.0:
			passos_invuln = Unidades.duracao_para_passos(cbt.invuln_atingido_s)

	var iv7_emitido := false
	if iat.alvo_dano_camera < 0.10 - 1e-9 or iat.alvo_dano_camera > 0.50 + 1e-9:
		out.append(_diag(item_ia, &"IV7", "alvo_dano_camera", iat.alvo_dano_camera,
			"IATuning: alvo_dano_camera %.2f fora de [0,10; 0,50]" % iat.alvo_dano_camera, Diagnostico.Nivel.AVISO))
		out.append(_diag(item_ia, &"IA7", "alvo_dano_camera", iat.alvo_dano_camera,
			"IATuning: alvo_dano_camera fora de [0,10; 0,50]", Diagnostico.Nivel.AVISO))
		iv7_emitido = true

	for item in itens:
		if item == null or not (item.definicao is WeaponDef):
			continue
		var w := item.definicao as WeaponDef
		var t_min := t_min_morrer_passos(w.vida_max, dano_max_comum_elite, passos_invuln)
		if t_min < 120:
			if not iv7_emitido:
				out.append(_diag(item, &"IV7", "vida_max", t_min,
					"WeaponDef %s: t_min_morrer %d passos (< 120 = 2,0 s)" % [w.id, t_min], Diagnostico.Nivel.AVISO))
				out.append(_diag(item, &"IA7", "vida_max", t_min,
					"WeaponDef %s: t_min_morrer < 2,0 s" % w.id, Diagnostico.Nivel.AVISO))
				iv7_emitido = true
			out.append(_diag(item, &"IA14", "vida_max", t_min,
				"WeaponDef %s: sobrevivência mínima violada contra elite" % w.id, Diagnostico.Nivel.AVISO))
	return out


## F3: ciclo mínimo de ataque em passos vivos (preparo + execução + recarga + espera_min).
static func ciclo_minimo_passos(def: EnemyDef, tuning: IATuning = null) -> int:
	var t := tuning if tuning != null else IATuning.de_fabrica()
	var prep := Unidades.duracao_para_passos(def.preparo_s)
	var rec := Unidades.duracao_para_passos(def.recarga_s)
	var esp_min := Unidades.duracao_para_passos(t.espera_base_s)
	var exec := t.execucao_melee_passos
	if def.comportamento == &"distancia" or def.comportamento == &"ranged":
		exec = t.execucao_ranged_passos
	elif def.comportamento == &"arremetida" or def.comportamento == &"charger":
		exec = t.avanco_passos
	return prep + exec + rec + esp_min


## F5: número de golpes para matar e tempo mínimo em passos vivos (`(ceil(vida_max / dano_max) - 1) * invuln_passos`).
static func golpes_para_morrer(vida_max: int, dano_max: int) -> int:
	if dano_max <= 0:
		return 999
	return int(ceil(float(vida_max) / float(dano_max)))


static func t_min_morrer_passos(vida_max: int, dano_max: int, invuln_passos: int = 40) -> int:
	var n := golpes_para_morrer(vida_max, dano_max)
	return maxi(0, (n - 1) * invuln_passos)


static func _fora_da_faixa_design(iat: IATuning, elr: EliteRules) -> bool:
	var p_surg := Unidades.duracao_para_passos(iat.surgimento_s)
	if p_surg < 30 or p_surg > 72:
		return true
	if iat.ranged_perto_px < 250.0 or iat.ranged_perto_px > 400.0:
		return true
	if iat.ranged_longe_px < 450.0 or iat.ranged_longe_px > 700.0:
		return true
	if iat.ranged_ataque_px < 700.0 or iat.ranged_ataque_px > 1100.0:
		return true
	if iat.charger_engaja_px < 400.0 or iat.charger_engaja_px > 700.0:
		return true
	if iat.charger_reaproxima_px < 300.0 or iat.charger_reaproxima_px > 600.0:
		return true
	if iat.recuperacao_dist_min_px < 60.0 or iat.recuperacao_dist_min_px > 150.0:
		return true
	if iat.execucao_melee_passos < 1 or iat.execucao_melee_passos > 20:
		return true
	if iat.execucao_ranged_passos < 1 or iat.execucao_ranged_passos > 15:
		return true
	if iat.avanco_passos < 12 or iat.avanco_passos > 40:
		return true
	if elr.profundidade_minima < 1 or elr.profundidade_minima > 6:
		return true
	if elr.max_elites_onda < 1 or elr.max_elites_onda > 3:
		return true
	return false


static func _diag(item: ItemDoCatalogo, codigo: StringName, campo: String, valor: Variant,
		msg: String, nivel: Diagnostico.Nivel) -> Diagnostico:
	if item != null:
		return Diagnostico.de_item(item, codigo, campo, valor, msg, nivel)
	return Diagnostico.novo(codigo, campo, valor, msg, nivel)
