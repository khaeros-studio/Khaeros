class_name ValidadorArmas
extends RefCounted
## Validação completa das Armas das Doutrinas: V2 (faixas de erro de carga), AV1–AV9,
## AV6 (regras CV do Combate aplicáveis a armas), nomes canônicos R8/V5 e relatório
## informativo da 2ª passada (GDD `design/gdd/armas-das-doutrinas.md` Formulas › Faixas
## e Validação; Story 002, AC-AR-23 a AC-AR-34, AC-AR-49, AC-AR-50).
##
## Uma entrada por regra e por objeto; um erro de carga suspende o aviso da mesma regra.

const RAIO_JOGADOR_PADRAO: float = 27.0
const FOLGA_ARCO_CV19: float = 6.0
const R_MIN_INIMIGO_PADRAO: float = 22.5


## Resultado estruturado da validação de um catálogo de armas.
class Relatorio:
	extends RefCounted
	var erros: Array[Diagnostico] = []
	var avisos: Array[Diagnostico] = []
	var informativos: Array[Diagnostico] = []
	## Chaves estruturadas `(inimigo_id, p, chave_golpe, g)` do AV3 para comparação de conjunto exato.
	var av3_tuplas: Array[Array] = []
	## Pares `id_a×id_b` que dispararam AV2.
	var av2_pares: Array[String] = []
	## Ids de inimigos que dispararam AV4.
	var av4_inimigos: Array[StringName] = []

	func codigos_erro() -> Array[StringName]:
		var out: Array[StringName] = []
		for d: Diagnostico in erros:
			out.append(d.regra)
		return out

	func codigos_aviso() -> Array[StringName]:
		var out: Array[StringName] = []
		for d: Diagnostico in avisos:
			out.append(d.regra)
		return out

	func avisos_do_codigo(regra: StringName) -> Array[Diagnostico]:
		var out: Array[Diagnostico] = []
		for d: Diagnostico in avisos:
			if d.regra == regra:
				out.append(d)
		return out

	func erros_do_codigo(regra: StringName) -> Array[Diagnostico]:
		var out: Array[Diagnostico] = []
		for d: Diagnostico in erros:
			if d.regra == regra:
				out.append(d)
		return out

	func informativos_do_codigo(regra: StringName) -> Array[Diagnostico]:
		var out: Array[Diagnostico] = []
		for d: Diagnostico in informativos:
			if d.regra == regra:
				out.append(d)
		return out


## Valida uma lista de [WeaponDef] com [param tuning_armas], [param tuning_combate],
## os inimigos do pool da região e a profundidade máxima da região [param p_max_regiao].
static func validar_catalogo(armas: Array[WeaponDef], tuning_armas: ArmasTuning = null,
		tuning_combate: CombatTuning = null, inimigos: Dictionary[StringName, EnemyDef] = {},
		p_max_regiao: int = 7) -> Relatorio:
	var rel := Relatorio.new()
	var at: ArmasTuning = tuning_armas if tuning_armas != null else FabricaDeArmas.tuning()
	var ct: CombatTuning = tuning_combate if tuning_combate != null else FabricaDeArmas.combat_tuning_padrao()
	var pool: Dictionary[StringName, EnemyDef] = inimigos if not inimigos.is_empty() else FabricaDeArmas.inimigos_limiar()

	var armas_validas: Array[WeaponDef] = []
	for w: WeaponDef in armas:
		if w == null:
			continue
		var teve_erro: bool = _validar_arma_individual(w, at, ct, pool, p_max_regiao, rel)
		if not teve_erro:
			armas_validas.append(w)

	# WV8 (Câmaras): se o alias ArmasTuning.p_max difere do p_max da região
	if at.p_max != p_max_regiao:
		rel.avisos.append(Diagnostico.novo(&"WV8", "p_max", at.p_max,
			"ArmasTuning.p_max (%d) difere do p_max da região (%d)" % [at.p_max, p_max_regiao],
			Diagnostico.Nivel.AVISO))

	# AV2: paridade combinada entre pares de armas sem Maldição (exclui `pactos`, que é validada pelo ML8)
	var sem_maldicao: Array[WeaponDef] = []
	for w: WeaponDef in armas_validas:
		if w.doutrina != &"pactos" and w.especial.forma != AtaqueConvertido.FORMA_CHAMADO:
			sem_maldicao.append(w)
	for i: int in sem_maldicao.size():
		for j: int in range(i + 1, sem_maldicao.size()):
			var wa: WeaponDef = sem_maldicao[i]
			var wb: WeaponDef = sem_maldicao[j]
			var ttk_a: float = FormulasDeArmas.ttk_chefe_continuo(FormulasDeArmas.dps_combinado(wa, 1.0, 1.0, ct)[&"dps_real"])
			var ttk_b: float = FormulasDeArmas.ttk_chefe_continuo(FormulasDeArmas.dps_combinado(wb, 1.0, 1.0, ct)[&"dps_real"])
			var par_comb: float = FormulasDeArmas.paridade_ttk(ttk_a, ttk_b)
			if par_comb > at.meta_paridade + 1e-9:
				var par_id := "%s×%s" % [wa.id, wb.id]
				rel.av2_pares.append(par_id)
				rel.avisos.append(Diagnostico.novo(&"AV2", par_id, par_comb,
					"AV2: paridade combinada %s = %.4f > %.2f" % [par_id, par_comb, at.meta_paridade],
					Diagnostico.Nivel.AVISO))
			var ttk_atk_a: float = FormulasDeArmas.ttk_chefe_continuo(FormulasDeArmas.dps_golpe(wa.ataque, 1.0, ct)[&"dps_real"])
			var ttk_atk_b: float = FormulasDeArmas.ttk_chefe_continuo(FormulasDeArmas.dps_golpe(wb.ataque, 1.0, ct)[&"dps_real"])
			var par_atk: float = FormulasDeArmas.paridade_ttk(ttk_atk_a, ttk_atk_b)
			rel.informativos.append(Diagnostico.novo(&"AV2", "%s×%s:so_ataque" % [wa.id, wb.id], par_atk,
				"AV2 informativo (só Ataque): %s×%s = %.4f" % [wa.id, wb.id, par_atk],
				Diagnostico.Nivel.AVISO))
			if wa.id == &"lamina" and wb.id == &"ressonancia":
				var folga: Dictionary = FormulasDeArmas.folga_dano_pulso(wa, wb, at.meta_paridade, ct)
				rel.informativos.append(Diagnostico.novo(&"AV2", "folga_so_ataque", folga[&"min_so_ataque"],
					"AV2 folga Pulso só Ataque: %.2f–%.2f" % [folga[&"min_so_ataque"], folga[&"max_so_ataque"]],
					Diagnostico.Nivel.AVISO))
				rel.informativos.append(Diagnostico.novo(&"AV2", "folga_combinado", folga[&"min_combinado"],
					"AV2 folga Pulso combinado: %.2f–%.2f" % [folga[&"min_combinado"], folga[&"max_combinado"]],
					Diagnostico.Nivel.AVISO))

	return rel


static func _validar_arma_individual(w: WeaponDef, at: ArmasTuning, ct: CombatTuning,
		pool: Dictionary[StringName, EnemyDef], p_max_regiao: int, rel: Relatorio) -> bool:
	var erro_arma: bool = false
	if w.ataque == null or w.especial == null:
		rel.erros.append(Diagnostico.novo(&"V1", "especial", null, "%s: ataque ou especial ausente" % w.id))
		return true

	# V2 (erro) vs AV7 (aviso) nos campos do WeaponDef
	if w.vida_max < 20 or w.vida_max > 300:
		rel.erros.append(Diagnostico.novo(&"V2", "vida_max", w.vida_max, "%s: vida_max %d fora de 20–300" % [w.id, w.vida_max]))
		erro_arma = true
	elif w.vida_max < 70 or w.vida_max > 140:
		rel.avisos.append(Diagnostico.novo(&"AV7", "vida_max", w.vida_max, "%s: vida_max %d fora de 70–140" % [w.id, w.vida_max], Diagnostico.Nivel.AVISO))

	if w.velocidade < 200.0 - 1e-9 or w.velocidade > 600.0 + 1e-9:
		rel.erros.append(Diagnostico.novo(&"V2", "velocidade", w.velocidade, "%s: velocidade fora de 200–600" % w.id))
		erro_arma = true
	elif w.velocidade < 342.0 - 1e-9 or w.velocidade > 423.0 + 1e-9:
		rel.avisos.append(Diagnostico.novo(&"AV7", "velocidade", w.velocidade, "%s: velocidade fora de 342–423" % w.id, Diagnostico.Nivel.AVISO))

	# AV9: forma `chamado`
	if w.ataque.forma == AtaqueConvertido.FORMA_CHAMADO:
		rel.erros.append(Diagnostico.novo(&"AV9", "ataque.forma", w.ataque.forma, "%s: forma chamado no slot ataque" % w.id))
		erro_arma = true
	if w.especial.forma == AtaqueConvertido.FORMA_CHAMADO:
		if w.doutrina != &"pactos":
			rel.erros.append(Diagnostico.novo(&"AV9", "especial.forma", w.especial.forma, "%s: chamado fora da doutrina pactos" % w.id))
			erro_arma = true
		elif not w.especial.multiplicadores_combo.is_empty() or w.especial.status != &"" or w.especial.guarda_s > 0.0:
			rel.erros.append(Diagnostico.novo(&"AV9", "especial", null, "%s: chamado com combo, status ou guarda_s" % w.id))
			erro_arma = true

	# Valida os dois slots (Ataque = true, Especial = false)
	if _validar_attack_def(w, w.ataque, true, at, ct, pool, p_max_regiao, rel):
		erro_arma = true
	if _validar_attack_def(w, w.especial, false, at, ct, pool, p_max_regiao, rel):
		erro_arma = true

	if erro_arma:
		return true

	# AV8: fração do Especial f_esp (0,15–0,40)
	var f_esp: float = float(FormulasDeArmas.fracao_especial(w, 0.25, ct)[&"f_esp"])
	if f_esp < at.f_esp_min - 1e-9 or f_esp > at.f_esp_max + 1e-9:
		rel.avisos.append(Diagnostico.novo(&"AV8", "f_esp", f_esp,
			"%s: f_esp %.4f fora de %.2f–%.2f" % [w.id, f_esp, at.f_esp_min, at.f_esp_max],
			Diagnostico.Nivel.AVISO))

	# AV3: pontos de corte frágeis (informativo) na região 0..p_max_regiao
	_calcular_av3_da_arma(w, at, pool, p_max_regiao, rel)

	return false


static func _validar_attack_def(w: WeaponDef, a: AttackDef, eh_ataque: bool, at: ArmasTuning,
		ct: CombatTuning, pool: Dictionary[StringName, EnemyDef], p_max_regiao: int, rel: Relatorio) -> bool:
	var teve_erro: bool = false
	var slot_nome: String = "ataque" if eh_ataque else "especial"

	# Dano: V2 (>0 e <=200) vs AV7 (Ataque 6–30; Especial 12–60, ou 12–35 para chamado)
	if a.dano <= 0.0 or a.dano > 200.0 + 1e-9:
		rel.erros.append(Diagnostico.novo(&"V2", "%s.dano" % slot_nome, a.dano, "%s.%s: dano fora de (0, 200]" % [w.id, slot_nome]))
		teve_erro = true
	else:
		var min_d: float = 6.0 if eh_ataque else 12.0
		var max_d: float = 30.0 if eh_ataque else (35.0 if a.forma == AtaqueConvertido.FORMA_CHAMADO else 60.0)
		if a.dano < min_d - 1e-9 or a.dano > max_d + 1e-9:
			rel.avisos.append(Diagnostico.novo(&"AV7", "%s.dano" % slot_nome, a.dano,
				"%s.%s: dano %.2f fora de %.0f–%.0f" % [w.id, slot_nome, a.dano, min_d, max_d], Diagnostico.Nivel.AVISO))

	# Recarga: CV10 (R >= 1) vs AV7 (Ataque 10–30; Especial 40–150)
	var r: int = Unidades.duracao_para_passos(a.recarga_s)
	if a.recarga_s <= 0.0 or r < 1:
		rel.erros.append(Diagnostico.novo(&"CV10", "%s.recarga_s" % slot_nome, a.recarga_s, "%s.%s: recarga < 1 passo" % [w.id, slot_nome]))
		teve_erro = true
	else:
		var r_min: int = 10 if eh_ataque else 40
		var r_max: int = 30 if eh_ataque else 150
		if r < r_min or r > r_max:
			rel.avisos.append(Diagnostico.novo(&"AV7", "%s.recarga_s" % slot_nome, r,
				"%s.%s: R=%d fora de %d–%d" % [w.id, slot_nome, r, r_min, r_max], Diagnostico.Nivel.AVISO))
		if eh_ataque and r <= Unidades.duracao_para_passos(ct.cambaleio_s):
			rel.avisos.append(Diagnostico.novo(&"CV17", "%s.recarga_s" % slot_nome, r,
				"%s.%s: R <= cambaleio" % [w.id, slot_nome], Diagnostico.Nivel.AVISO))

	# Empurrão: V2 (0–1980) vs AV7 (Ataque < empurrao_pesado 900)
	if a.empurrao < 0.0 - 1e-9 or a.empurrao > 1980.0 + 1e-9:
		rel.erros.append(Diagnostico.novo(&"V2", "%s.empurrao" % slot_nome, a.empurrao, "%s.%s: empurrão fora de 0–1980" % [w.id, slot_nome]))
		teve_erro = true
	elif eh_ataque and a.empurrao >= ct.empurrao_pesado - 1e-9:
		rel.avisos.append(Diagnostico.novo(&"AV7", "%s.empurrao" % slot_nome, a.empurrao,
			"%s.%s: empurrão do Ataque >= %.0f" % [w.id, slot_nome, ct.empurrao_pesado], Diagnostico.Nivel.AVISO))
		rel.avisos.append(Diagnostico.novo(&"CV8", "%s.empurrao" % slot_nome, a.empurrao,
			"%s.%s: Ataque pesado em todo acerto" % [w.id, slot_nome], Diagnostico.Nivel.AVISO))

	# AV1: guarda_s (comparação em passos: passos(guarda_s) / R > 0,5; >= R é "guarda permanente")
	if a.guarda_s > 0.0 and r >= 1:
		var g_passos: int = Unidades.duracao_para_passos(a.guarda_s)
		if g_passos >= r:
			rel.avisos.append(Diagnostico.novo(&"AV1", "%s.guarda_s" % slot_nome, g_passos,
				"%s.%s: guarda permanente (%d >= %d)" % [w.id, slot_nome, g_passos, r], Diagnostico.Nivel.AVISO))
		elif float(g_passos) / float(r) > 0.5 + 1e-9:
			rel.avisos.append(Diagnostico.novo(&"AV1", "%s.guarda_s" % slot_nome, g_passos,
				"%s.%s: razão guarda/recarga > 0,5 (%d/%d)" % [w.id, slot_nome, g_passos, r], Diagnostico.Nivel.AVISO))

	# Combo: CV3, CV5 e AV7 (2–5 entradas, cada 0,5–2,5, exatamente uma > limiar_finalizador)
	if not a.multiplicadores_combo.is_empty():
		var n_c: int = a.multiplicadores_combo.size()
		var n_fin: int = 0
		var fora_faixa_mult: bool = false
		for m: float in a.multiplicadores_combo:
			if m < 0.5 - 1e-9 or m > 2.5 + 1e-9:
				fora_faixa_mult = true
			if m > ct.limiar_finalizador + 1e-9:
				n_fin += 1
		if n_c < 2 or n_c > 5 or fora_faixa_mult or n_fin != 1:
			rel.avisos.append(Diagnostico.novo(&"AV7", "%s.multiplicadores_combo" % slot_nome, a.multiplicadores_combo,
				"%s.%s: multiplicadores_combo fora da faixa de design" % [w.id, slot_nome], Diagnostico.Nivel.AVISO))
		if n_fin > 1:
			rel.avisos.append(Diagnostico.novo(&"CV3", "%s.multiplicadores_combo" % slot_nome, a.multiplicadores_combo,
				"%s.%s: mais de um finalizador no combo" % [w.id, slot_nome], Diagnostico.Nivel.AVISO))
		var j: int = Unidades.duracao_para_passos(ct.janela_combo_s)
		if r >= j:
			rel.avisos.append(Diagnostico.novo(&"CV5", "%s.recarga_s" % slot_nome, r,
				"%s.%s: recarga %d >= janela_combo %d" % [w.id, slot_nome, r, j], Diagnostico.Nivel.AVISO))

	# AV5: Ataque leve sem combo com empurrão sustentado >= parede_vel_min
	if eh_ataque and a.multiplicadores_combo.is_empty() and a.empurrao < ct.empurrao_pesado - 1e-9 and r >= 1:
		var emp_info: Dictionary = FormulasDeArmas.empurrao_efetivo(a.empurrao, 1.0, r, ct)
		if float(emp_info[&"v_sust"]) >= ct.parede_vel_min - 1e-9:
			rel.avisos.append(Diagnostico.novo(&"AV5", "%s.empurrao" % slot_nome, a.empurrao,
				"%s.%s: v_sust %.2f >= %.0f" % [w.id, slot_nome, emp_info[&"v_sust"], ct.parede_vel_min], Diagnostico.Nivel.AVISO))

	# AV4: trava por golpe pesado no Ataque
	if eh_ataque and r >= 1:
		_validar_av4(w, a, r, at, ct, pool, p_max_regiao, rel)

	# Params por forma (V2, CVs e AV7)
	match a.forma:
		AtaqueConvertido.FORMA_ARCO:
			var alc: float = a.params.get(&"alcance_px", 0.0)
			var ang: float = a.params.get(&"meio_angulo_graus", 0.0)
			if alc <= 0.0:
				rel.erros.append(Diagnostico.novo(&"V2", "arco.alcance_px", alc, "alcance_px <= 0"))
				teve_erro = true
			elif alc < 90.0 - 1e-9 or alc > 240.0 + 1e-9:
				rel.avisos.append(Diagnostico.novo(&"AV7", "arco.alcance_px", alc, "alcance_px fora de 90–240", Diagnostico.Nivel.AVISO))
			if alc <= RAIO_JOGADOR_PADRAO + FOLGA_ARCO_CV19:
				rel.avisos.append(Diagnostico.novo(&"CV19", "arco.alcance_px", alc, "alcance_px muito curto", Diagnostico.Nivel.AVISO))
			if ang < 5.0 - 1e-9 or ang > 180.0 + 1e-9:
				rel.erros.append(Diagnostico.novo(&"V2", "arco.meio_angulo_graus", ang, "meio_angulo_graus fora de 5–180"))
				teve_erro = true
			elif ang < 45.0 - 1e-9 or ang > 90.0 + 1e-9:
				rel.avisos.append(Diagnostico.novo(&"AV7", "arco.meio_angulo_graus", ang, "meio_angulo_graus fora de 45–90", Diagnostico.Nivel.AVISO))
		AtaqueConvertido.FORMA_CIRCULO:
			var raio_c: float = a.params.get(&"raio_px", 0.0)
			var desl: float = a.params.get(&"deslocamento_px", 0.0)
			if raio_c <= 0.0:
				rel.erros.append(Diagnostico.novo(&"V2", "circulo.raio_px", raio_c, "raio_px <= 0"))
				teve_erro = true
			elif raio_c < 120.0 - 1e-9 or raio_c > 240.0 + 1e-9:
				rel.avisos.append(Diagnostico.novo(&"AV7", "circulo.raio_px", raio_c, "raio_px fora de 120–240", Diagnostico.Nivel.AVISO))
			if desl < 0.0 - 1e-9:
				rel.erros.append(Diagnostico.novo(&"V2", "circulo.deslocamento_px", desl, "deslocamento_px < 0"))
				teve_erro = true
			elif desl > 300.0 + 1e-9:
				rel.avisos.append(Diagnostico.novo(&"AV7", "circulo.deslocamento_px", desl, "deslocamento_px > 300", Diagnostico.Nivel.AVISO))
		AtaqueConvertido.FORMA_PROJETIL:
			var vel_p: float = a.params.get(&"velocidade_pxs", 0.0)
			var raio_p: float = a.params.get(&"raio_px", 0.0)
			var vida_s: float = a.params.get(&"vida_s", 0.0)
			var l: int = Unidades.duracao_para_passos(vida_s)
			if vel_p <= 0.0:
				rel.erros.append(Diagnostico.novo(&"V2", "projetil.velocidade_pxs", vel_p, "velocidade_pxs <= 0"))
				teve_erro = true
			elif vel_p < 600.0 - 1e-9 or vel_p > 1500.0 + 1e-9:
				rel.avisos.append(Diagnostico.novo(&"AV7", "projetil.velocidade_pxs", vel_p, "velocidade_pxs fora de 600–1500", Diagnostico.Nivel.AVISO))
			if raio_p <= 0.0:
				rel.erros.append(Diagnostico.novo(&"V2", "projetil.raio_px", raio_p, "raio_px <= 0"))
				teve_erro = true
			elif raio_p < 9.0 - 1e-9 or raio_p > 30.0 + 1e-9:
				rel.avisos.append(Diagnostico.novo(&"AV7", "projetil.raio_px", raio_p, "raio_px fora de 9–30", Diagnostico.Nivel.AVISO))
			if vida_s <= 0.0 or l < 2:
				rel.erros.append(Diagnostico.novo(&"CV13", "projetil.vida_s", vida_s, "%s: vida_s L=%d < 2" % [w.id, l]))
				teve_erro = true
			else:
				var alc_testado: float = FormulasDeArmas.alcance_testado_projetil_px(a, ct)
				if alc_testado < 400.0 - 1e-9 or alc_testado > 1100.0 + 1e-9:
					rel.avisos.append(Diagnostico.novo(&"AV7", "projetil.vida_s", alc_testado,
						"%s: alcance testado %.1f fora de 400–1100" % [w.id, alc_testado], Diagnostico.Nivel.AVISO))
				rel.informativos.append(Diagnostico.novo(&"AV7", "%s.alcance_projetil" % w.id, alc_testado,
					"%s: L=%d, alcance testado %.1f px" % [w.id, l, alc_testado], Diagnostico.Nivel.AVISO))
			# Leque: não vazio, ints >= 0, sem repetidos; AV7 1–5 entradas
			if a.leque.is_empty() or _leque_invalido(a.leque):
				rel.erros.append(Diagnostico.novo(&"V2", "projetil.leque", a.leque, "leque vazio, negativo ou com repetidos"))
				teve_erro = true
			elif a.leque.size() > 5:
				rel.avisos.append(Diagnostico.novo(&"AV7", "projetil.leque", a.leque, "leque > 5 entradas", Diagnostico.Nivel.AVISO))
		AtaqueConvertido.FORMA_AVANCO:
			var dist_a: float = a.params.get(&"distancia_px", -1.0)
			var dur_a: float = a.params.get(&"duracao_s", 0.0)
			var n_a: int = Unidades.duracao_para_passos(dur_a)
			var raio_a: float = a.params.get(&"raio_px", 0.0)
			if dist_a < 0.0 - 1e-9:
				rel.erros.append(Diagnostico.novo(&"V2", "avanco.distancia_px", dist_a, "distancia_px < 0"))
				teve_erro = true
			elif dist_a < 150.0 - 1e-9 or dist_a > 450.0 + 1e-9:
				rel.avisos.append(Diagnostico.novo(&"AV7", "avanco.distancia_px", dist_a, "distancia_px fora de 150–450", Diagnostico.Nivel.AVISO))
			if dur_a <= 0.0 or n_a < 1:
				rel.erros.append(Diagnostico.novo(&"V2", "avanco.duracao_s", dur_a, "duracao_s <= 0"))
				teve_erro = true
			elif n_a < 6 or n_a > 18:
				rel.avisos.append(Diagnostico.novo(&"AV7", "avanco.duracao_s", n_a, "duracao_s N=%d fora de 6–18" % n_a, Diagnostico.Nivel.AVISO))
			if raio_a <= 0.0:
				rel.erros.append(Diagnostico.novo(&"V2", "avanco.raio_px", raio_a, "raio_px <= 0"))
				teve_erro = true
			elif raio_a < 40.0 - 1e-9 or raio_a > 100.0 + 1e-9:
				rel.avisos.append(Diagnostico.novo(&"AV7", "avanco.raio_px", raio_a, "raio_px fora de 40–100", Diagnostico.Nivel.AVISO))

	return teve_erro


static func _leque_invalido(leque: PackedFloat64Array) -> bool:
	var vistos: Dictionary[int, bool] = {}
	for v: float in leque:
		var iv: int = int(v)
		if v < 0.0 or absf(v - float(iv)) > 1e-6 or vistos.has(iv):
			return true
		vistos[iv] = true
	return false


static func _validar_av4(w: WeaponDef, a: AttackDef, r: int, at: ArmasTuning, ct: CombatTuning,
		pool: Dictionary[StringName, EnemyDef], p_max_regiao: int, rel: Relatorio) -> void:
	var pesado_sempre: bool = a.empurrao >= ct.empurrao_pesado - 1e-9
	var tem_finalizador: bool = false
	var soma_mult: float = 0.0
	for m: float in a.multiplicadores_combo:
		soma_mult += m
		if m > ct.limiar_finalizador + 1e-9:
			tem_finalizador = true
	if not pesado_sempre and not tem_finalizador:
		return
	var n_periodo: int = 1 if pesado_sempre else a.multiplicadores_combo.size()
	var p_ciclo: int = n_periodo * r
	var d_periodo: float = a.dano if pesado_sempre else (a.dano * soma_mult)
	var q: int = Unidades.duracao_para_passos(ct.quebrou_recuperacao_s)
	var janela_trava: int = int(ceil(float(q) / float(p_ciclo))) * p_ciclo - q

	for id_ini: StringName in [&"eco_perdido", &"anomalia_menor", &"fenda_errante"]:
		if not pool.has(id_ini):
			continue
		var ini: EnemyDef = pool[id_ini]
		if ini.comportamento == &"chefe":
			continue
		var w_ini: int = Unidades.duracao_para_passos(ini.preparo_s)
		var vida_pmax: int = FormulasDeArmas.vida_por_profundidade(ini.vida, p_max_regiao, false)
		if float(vida_pmax) > float(at.periodos_trava) * d_periodo + 1e-9 and janela_trava < w_ini:
			rel.av4_inimigos.append(ini.id)
			rel.avisos.append(Diagnostico.novo(&"AV4", String(ini.id), vida_pmax,
				"AV4: %s trava %s em p=%d (Vida %d > %.1f, %d < W=%d)" % [
					w.id, ini.id, p_max_regiao, vida_pmax, float(at.periodos_trava) * d_periodo, janela_trava, w_ini
				], Diagnostico.Nivel.AVISO))


static func _calcular_av3_da_arma(w: WeaponDef, at: ArmasTuning, pool: Dictionary[StringName, EnemyDef],
		p_max_regiao: int, rel: Relatorio) -> void:
	var golpes: Array = [
		[_nome_curto_golpe(w, true), w.ataque],
		[_nome_curto_golpe(w, false), w.especial],
	]
	var ids_comuns: Array[StringName] = [&"eco_perdido", &"anomalia_menor", &"fenda_errante"]
	# 1. Comuns (p = 0..p_max_regiao)
	for id_ini: StringName in ids_comuns:
		if not pool.has(id_ini):
			continue
		var ini: EnemyDef = pool[id_ini]
		for p: int in range(0, p_max_regiao + 1):
			var vida_p: int = FormulasDeArmas.vida_por_profundidade(ini.vida, p, false)
			for par: Array in golpes:
				var nome_g: StringName = par[0]
				var atk: AttackDef = par[1]
				var info: Dictionary = FormulasDeArmas.golpes_ate_matar(atk, vida_p)
				var g: int = info[&"g"]
				var margem: float = info[&"margem"]
				var falta: float = info[&"falta"]
				if g <= at.g_max_fragil and (margem <= float(at.margem_fragil) + 1e-9 or falta <= float(at.margem_fragil) + 1e-9):
					var tupla: Array = [id_ini, p, nome_g, g]
					rel.av3_tuplas.append(tupla)
					rel.informativos.append(Diagnostico.novo(&"AV3", "%s:%d:%s" % [id_ini, p, nome_g], g,
						"AV3: %s p=%d %s g=%d" % [id_ini, p, nome_g, g], Diagnostico.Nivel.AVISO))
	# 2. Elites (p = 3..p_max_regiao)
	for id_ini: StringName in ids_comuns:
		if not pool.has(id_ini):
			continue
		var ini: EnemyDef = pool[id_ini]
		var id_elite := StringName(String(id_ini) + "_elite")
		for p: int in range(3, p_max_regiao + 1):
			var vida_p: int = FormulasDeArmas.vida_por_profundidade(ini.vida, p, true)
			for par: Array in golpes:
				var nome_g: StringName = par[0]
				var atk: AttackDef = par[1]
				var info: Dictionary = FormulasDeArmas.golpes_ate_matar(atk, vida_p)
				var g: int = info[&"g"]
				var margem: float = info[&"margem"]
				var falta: float = info[&"falta"]
				if g <= at.g_max_fragil and (margem <= float(at.margem_fragil) + 1e-9 or falta <= float(at.margem_fragil) + 1e-9):
					var tupla: Array = [id_elite, p, nome_g, g]
					rel.av3_tuplas.append(tupla)
					rel.informativos.append(Diagnostico.novo(&"AV3", "%s:%d:%s" % [id_elite, p, nome_g], g,
						"AV3: %s p=%d %s g=%d" % [id_elite, p, nome_g, g], Diagnostico.Nivel.AVISO))


static func _nome_curto_golpe(w: WeaponDef, eh_ataque: bool) -> StringName:
	match w.id:
		&"lamina":
			return &"Corte" if eh_ataque else &"Investida"
		&"ressonancia":
			return &"Pulso" if eh_ataque else &"Onda"
		&"pactos":
			return &"Virote" if eh_ataque else &"Chamado"
	return w.ataque.chave_nome if eh_ataque else w.especial.chave_nome


## R8 / V5 (AC-AR-33): confere um texto resolvido contra o nome canônico esperado (normalizado em NFC).
static func validar_nome_canonico(chave: StringName, texto_resolvido: String) -> Diagnostico:
	if not FabricaDeArmas.NOMES_CANONICOS.has(chave):
		return Diagnostico.novo(&"V5", String(chave), texto_resolvido, "chave %s fora da tabela canônica R8" % chave)
	var esperado: String = V5NomesCanonicos.normalizar_nfc(String(FabricaDeArmas.NOMES_CANONICOS[chave]))
	var normalizado: String = V5NomesCanonicos.normalizar_nfc(texto_resolvido)
	if normalizado != esperado:
		return Diagnostico.novo(&"V5", String(chave), texto_resolvido,
			"V5: chave %s resolve para '%s' (esperado '%s')" % [chave, normalizado, esperado])
	return null


## R8 (AC-AR-34): garante que nenhuma chave na tabela de tradução além de `WEAPON_LAMINA_ATK`
## resolve para `"Corte"` solto, e que `TRAD_BLADE_CORTE_FANTASMA_NAME` resolve para `"O Corte Fantasma"`.
static func validar_corte_vs_corte_da_esquiva(tabela_traducao: Dictionary) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	for chave: Variant in tabela_traducao.keys():
		var chave_sn := StringName(String(chave))
		var texto: String = V5NomesCanonicos.normalizar_nfc(String(tabela_traducao[chave]).strip_edges())
		if texto == "Corte" and chave_sn != &"WEAPON_LAMINA_ATK":
			out.append(Diagnostico.novo(&"V5", String(chave_sn), texto,
				"R8: chave %s não pode resolver para 'Corte' solto" % chave_sn))
	if tabela_traducao.has(&"TRAD_BLADE_CORTE_FANTASMA_NAME"):
		var nome_bencao: String = V5NomesCanonicos.normalizar_nfc(String(tabela_traducao[&"TRAD_BLADE_CORTE_FANTASMA_NAME"]))
		if nome_bencao != "O Corte Fantasma":
			out.append(Diagnostico.novo(&"V5", "TRAD_BLADE_CORTE_FANTASMA_NAME", nome_bencao,
				"R8: bênção de esquiva deve resolver para 'O Corte Fantasma'"))
	return out
