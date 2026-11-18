class_name RegrasCh
extends ValidadorDoDono
## CH1–CH8 (Chefes; GDD chefes.md §Validação de dados e GDD de Conteúdo R9-P; ADR-0004):
## CH1–CH3 (erros de 1ª passada), CH4, CH7 e CH8 (avisos de 1ª passada) e CH5–CH6
## (avisos da 2ª passada: sobrevivência mínima contra o chefe e teto de lacaios).
##
## Exemplo:
## [codeblock]
## var diags := RegrasCh.new().validar(itens)
## var diags_2 := RegrasCh.new().validar_segunda_passada(itens, catalogo)
## [/codeblock]

const FORMAS_VALIDAS: Array[StringName] = [&"setor", &"retangulo", &"anel", &"circulo"]
const LACAIO_ID := &"eco_perdido"
const RAIO_PADRAO_3_PX: float = 225.0
const PASSOS_PREPARO_MIN_CH4: int = 23
const PASSOS_INVULN_PADRAO: int = 40
const MAX_INIMIGOS_ONDA_PADRAO: int = 9
const TETO_TELEGRAFOS_PADRAO: int = 24


func prefixo() -> StringName:
	return &"CH"


func precisa_da_segunda_passada() -> bool:
	return true


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var inimigos: Dictionary[StringName, ItemDoCatalogo] = {}
	for i in itens_do_tipo(itens, &"enemy"):
		inimigos[i.definicao.id] = i
	var chefes_ativos: Array[StringName] = []
	for item_r in itens_do_tipo(itens, &"region"):
		var r := item_r.definicao as RegionDef
		if r != null and r.chefe != &"" and not chefes_ativos.has(r.chefe):
			chefes_ativos.append(r.chefe)
	var item_ct := primeiro_da_classe(itens, "ChefesTuning")
	var ct: ChefesTuning = item_ct.definicao as ChefesTuning if item_ct != null else null
	var fator_furia := ct.fator_recarga_furia if ct != null and ct.fator_recarga_furia > 0.0 else 0.60
	if ct != null:
		if Unidades.duracao_para_passos(ct.espera_inicial_chefe_s) < 1 or Unidades.duracao_para_passos(ct.espera_entre_padroes_chefe_s) < 1 or Unidades.duracao_para_passos(ct.transicao_fase_s) < 1 or ct.limiar_furia_frac <= 0.10 or ct.limiar_furia_frac >= 0.90:
			out.append(Diagnostico.de_item(item_ct, &"CH2", "chefes_tuning", ct.limiar_furia_frac,
				"ChefesTuning: duração < 1 passo ou limiar_furia_frac fora de (0,10; 0,90)"))
		if ct.lacaios_por_convergencia > ct.max_lacaios_vivos or not inimigos.has(LACAIO_ID) or ct.raio_puxao_px <= RAIO_PADRAO_3_PX:
			out.append(Diagnostico.de_item(item_ct, &"CH3", "lacaios_por_convergencia", ct.lacaios_por_convergencia,
				"ChefesTuning: lacaios_por_convergencia > max_lacaios_vivos, eco_perdido ausente ou raio_puxao_px <= 225"))
		if _ct_fora_design(ct):
			out.append(Diagnostico.de_item(item_ct, &"CH7", "chefes_tuning", null,
				"ChefesTuning: campo fora da faixa de design", Diagnostico.Nivel.AVISO))
	for cid: StringName in chefes_ativos:
		if not inimigos.has(cid):
			continue
		var item_e := inimigos[cid]
		var chefe := item_e.definicao as EnemyDef
		var ch1 := chefe.padroes.size() != 4
		for p: BossPatternDef in chefe.padroes:
			if p == null or not FORMAS_VALIDAS.has(p.forma_telegrafo):
				ch1 = true
				break
		if ch1:
			out.append(Diagnostico.de_item(item_e, &"CH1", "padroes", chefe.padroes.size(),
				"EnemyDef %s: chefe ativo sem 4 padrões válidos" % cid))
		for idx in chefe.padroes.size():
			var p := chefe.padroes[idx]
			if p == null:
				continue
			var p_passos := Unidades.duracao_para_passos(p.preparo_s)
			var e_passos := Unidades.duracao_para_passos(p.execucao_s)
			var r_furia := Unidades.duracao_para_passos(p.recarga_s * fator_furia)
			if p_passos < 1 or e_passos < 1 or r_furia < 1:
				out.append(Diagnostico.de_item(item_e, &"CH2", "padroes[%d]" % idx, p.preparo_s,
					"EnemyDef %s: padrão %d com preparo, execução ou recarga em fúria < 1 passo" % [cid, idx]))
			if p_passos < PASSOS_PREPARO_MIN_CH4:
				out.append(Diagnostico.de_item(item_e, &"CH4", "padroes[%d].preparo_s" % idx, p.preparo_s,
					"EnemyDef %s: padrão %d com folga de leitura < 8 passos" % [cid, idx], Diagnostico.Nivel.AVISO))
			var raio_tel := float(p.dimensoes.get(&"raio_px", p.dimensoes.get(&"r_ext", RAIO_PADRAO_3_PX)))
			var ch8 := p.raio_secundario_px < 0.0 or (p.raio_secundario_px > 0.0 and p.raio_secundario_px <= raio_tel)
			if idx == 3 and ct != null and not is_equal_approx(p.raio_secundario_px, ct.raio_puxao_px):
				ch8 = true
			if ch8:
				out.append(Diagnostico.de_item(item_e, &"CH8", "padroes[%d].raio_secundario_px" % idx, p.raio_secundario_px,
					"EnemyDef %s: padrão %d com raio_secundario_px inválido" % [cid, idx], Diagnostico.Nivel.AVISO))
	return out


func validar_segunda_passada(itens: Array[ItemDoCatalogo], _catalogo: Catalogo) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var item_ct := primeiro_da_classe(itens, "ChefesTuning")
	var ct: ChefesTuning = item_ct.definicao as ChefesTuning if item_ct != null else null
	if ct != null:
		var max_onda := MAX_INIMIGOS_ONDA_PADRAO
		for item_w in itens_do_tipo(itens, &"wave_rules"):
			var w := item_w.definicao as WaveRules
			if w != null and w.max_inimigos_onda > 0:
				max_onda = w.max_inimigos_onda
		if 1 + ct.max_lacaios_vivos > max_onda or 1 + ct.max_lacaios_vivos > TETO_TELEGRAFOS_PADRAO:
			out.append(Diagnostico.de_item(item_ct, &"CH6", "max_lacaios_vivos", ct.max_lacaios_vivos,
				"ChefesTuning: 1 + max_lacaios_vivos excede max_inimigos_onda ou teto_telegrafos", Diagnostico.Nivel.AVISO))
	var passos_invuln := PASSOS_INVULN_PADRAO
	var item_cbt := primeiro_da_classe(itens, "CombatTuning")
	if item_cbt != null:
		var cbt := item_cbt.definicao as CombatTuning
		if cbt.invuln_atingido_s > 0.0:
			passos_invuln = Unidades.duracao_para_passos(cbt.invuln_atingido_s)
	var armas := itens_do_tipo(itens, &"weapon")
	for item_e in itens_do_tipo(itens, &"enemy"):
		var e := item_e.definicao as EnemyDef
		if e == null or e.comportamento != &"chefe" or e.padroes.is_empty():
			continue
		var ch5_emitido := false
		for p: BossPatternDef in e.padroes:
			if p == null or p.dano <= 0.0:
				continue
			var dano_golpe := maxi(1, Unidades.arredondar_meio_longe_do_zero(p.dano))
			for item_w in armas:
				var w := item_w.definicao as WeaponDef
				if w == null or w.vida_max <= 0:
					continue
				var g_morte := int(ceil(float(w.vida_max) / float(dano_golpe)))
				var t_min := float((g_morte - 1) * passos_invuln) / float(Unidades.TICK_RATE)
				if g_morte < 4 or t_min < 2.0 - 1e-9:
					out.append(Diagnostico.de_item(item_e, &"CH5", "padroes", t_min,
						"EnemyDef %s: arma %s morre em %d golpes (%.2f s)" % [e.id, w.id, g_morte, t_min],
						Diagnostico.Nivel.AVISO))
					ch5_emitido = true
					break
			if ch5_emitido:
				break
	return out


static func _ct_fora_design(ct: ChefesTuning) -> bool:
	if ct.espera_inicial_chefe_s < 0.25 - 1e-9 or ct.espera_inicial_chefe_s > 1.00 + 1e-9:
		return true
	if ct.espera_entre_padroes_chefe_s < 0.15 - 1e-9 or ct.espera_entre_padroes_chefe_s > 0.60 + 1e-9:
		return true
	if ct.limiar_furia_frac < 0.35 - 1e-9 or ct.limiar_furia_frac > 0.65 + 1e-9:
		return true
	if ct.fator_recarga_furia < 0.40 - 1e-9 or ct.fator_recarga_furia > 0.85 + 1e-9:
		return true
	if ct.mult_velocidade_furia < 1.00 - 1e-9 or ct.mult_velocidade_furia > 1.35 + 1e-9:
		return true
	if ct.transicao_fase_s < 0.30 - 1e-9 or ct.transicao_fase_s > 1.00 + 1e-9:
		return true
	if ct.raio_pulso_furia_px < 150.0 or ct.raio_pulso_furia_px > 360.0:
		return true
	if ct.empurrao_pulso_furia_px < 60.0 or ct.empurrao_pulso_furia_px > 210.0:
		return true
	if ct.raio_puxao_px < 300.0 or ct.raio_puxao_px > 600.0:
		return true
	if ct.puxao_convergencia_px < 45.0 or ct.puxao_convergencia_px > 120.0:
		return true
	if ct.max_lacaios_vivos < 1 or ct.max_lacaios_vivos > 4:
		return true
	if ct.lacaios_por_convergencia < 1 or ct.lacaios_por_convergencia > 3:
		return true
	if ct.dist_spawn_lacaio_px < 90.0 or ct.dist_spawn_lacaio_px > 180.0:
		return true
	return false
