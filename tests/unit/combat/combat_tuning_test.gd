extends GdUnitTestSuite
## Story combate-nucleo-001: AC-01, AC-02, AC-03, AC-04, AC-60..AC-65 (CombatTuning, conversões, determinismo, faixas e CV1–CV22).


func _fv_ataques() -> Array[ValidadorCombatTuning.EntradaAtaque]:
	return [
		ValidadorCombatTuning.EntradaAtaque.new(&"corte", ApoioCombate.ataque_corte(), true, true),
		ValidadorCombatTuning.EntradaAtaque.new(&"investida", ApoioCombate.especial_investida(), false, false),
		ValidadorCombatTuning.EntradaAtaque.new(&"pulso", ApoioCombate.ataque_pulso(), true, false),
		ValidadorCombatTuning.EntradaAtaque.new(&"onda", ApoioCombate.especial_onda(), false, false),
	]


func _codigos_cv(t: CombatTuning, ataques: Array[ValidadorCombatTuning.EntradaAtaque] = [],
		ctx: ValidadorCombatTuning.ContextoCruzado = null) -> Array[String]:
	var lista := ataques if not ataques.is_empty() else _fv_ataques()
	var diags := ValidadorCombatTuning.validar_tudo(t, lista, ctx)
	var out: Array[String] = []
	for d in diags:
		if d.regra != &"FAIXA":
			var sufixo := ":erro" if d.eh_erro() else ":aviso"
			out.append(String(d.regra) + sufixo)
	return out


func test_ac01_conversoes_fp_e_attack_def() -> void:
	var p := ParametrosDoCombate.de(ApoioCombate.tuning_fp())
	assert_int(p.hitstop_leve).is_equal(3)
	assert_int(p.hitstop_pesado).is_equal(6)
	assert_int(p.hitstop_abate).is_equal(4)
	assert_int(p.hitstop_atingido).is_equal(6)
	assert_int(p.hitstop_abate_chefe).is_equal(36)
	assert_int(p.hitstop_recusa).is_equal(18)
	assert_int(p.janela_combo).is_equal(34)
	assert_int(p.recuperacao_max).is_equal(12)
	assert_int(p.invuln_extra_investida).is_equal(2)
	assert_int(p.cambaleio).is_equal(8)
	assert_int(p.quebrou_recuperacao).is_equal(24)
	assert_int(p.invuln_atingido).is_equal(40)
	assert_int(p.flash_acerto).is_equal(5)
	assert_int(p.extra_inversao).is_equal(4)
	assert_int(p.impact_chefe).is_equal(12)

	var corte := AtaqueConvertido.de(ApoioCombate.ataque_corte())
	var inv := AtaqueConvertido.de(ApoioCombate.especial_investida())
	var pulso := AtaqueConvertido.de(ApoioCombate.ataque_pulso())
	var onda := AtaqueConvertido.de(ApoioCombate.especial_onda())
	assert_int(corte.recarga).is_equal(16)
	assert_float(corte.cos_meio).is_equal_approx(0.350044, 0.000001)
	assert_int(inv.passos_avanco).is_equal(10)
	assert_int(inv.recarga).is_equal(70)
	assert_int(pulso.vida_projetil).is_equal(50)
	assert_int(pulso.recarga).is_equal(14)
	assert_float(pulso.passo_projetil_px).is_equal_approx(16.5, 0.001)
	assert_int(onda.recarga).is_equal(90)


func test_ac04_sem_valor_escondido_falha_com_erro_nomeado() -> void:
	var d1 := DependenciasDoCombate.new()
	assert_object(Combate.criar(d1)).is_null()
	assert_str(String(d1.erro)).is_equal(String(Combate.ERRO_SEM_TUNING))

	var d2 := DependenciasDoCombate.new()
	d2.tuning = ApoioCombate.tuning_fp()
	assert_object(Combate.criar(d2)).is_null()
	assert_str(String(d2.erro)).is_equal(String(Combate.ERRO_SEM_MOVIMENTO))

	var d3 := DependenciasDoCombate.new()
	d3.tuning = ApoioCombate.tuning_fp()
	d3.movimento = ApoioCombate.MovimentoDuble.new()
	assert_object(Combate.criar(d3)).is_null()
	assert_str(String(d3.erro)).is_equal(String(Combate.ERRO_SEM_JOGADOR))

	var d4 := DependenciasDoCombate.new()
	d4.tuning = ApoioCombate.tuning_fp()
	d4.movimento = ApoioCombate.MovimentoDuble.new()
	d4.jogadores.append(DependenciasDoCombate.Jogador.new(null, ApoioCombate.ataque_corte(), ApoioCombate.especial_investida()))
	assert_object(Combate.criar(d4)).is_null()
	assert_str(String(d4.erro)).is_equal(String(Combate.ERRO_SEM_PORTADOR))

	var d5 := DependenciasDoCombate.new()
	d5.tuning = ApoioCombate.tuning_fp()
	d5.movimento = ApoioCombate.MovimentoDuble.new()
	d5.jogadores.append(DependenciasDoCombate.Jogador.new(ApoioCombate.portador_jogador(), null, ApoioCombate.especial_investida()))
	assert_object(Combate.criar(d5)).is_null()
	assert_str(String(d5.erro)).is_equal(String(Combate.ERRO_SEM_ATTACKDEF))


func _rodar_roteiro_determinismo(usar_ressonancia: bool) -> Array:
	var sim := ApoioCombate.SimCombate.new(usar_ressonancia)
	for i in 5:
		sim.ia.lista.append(ApoioCombate.criar_eco(i + 1, Vector2(1040.0 + float(i) * 40.0, 500.0 + float(i) * 20.0), 100.0))
	sim.ia.lista.append(ApoioCombate.criar_elite(99, Vector2(1150.0, 540.0), 300.0))
	var retrato: Array = []
	for k in 300:
		var t_atk := (k % 17) == 0
		var t_esp := (k % 53) == 5
		var s_atk := (k % 11) < 4
		if (k % 50) == 25:
			sim.combate.ferir_jogador(0, 9.0, 1.0, 1)
		sim.passo(t_atk, t_esp, s_atk, false)
		var r := sim.combate.recursos(0)
		retrato.append([r.vida, r.invulneravel, r.recarga[0], r.recarga[1], sim.combate.hitstop_restante(), sim.log_eventos.size()])
	return retrato


func test_ac02_determinismo_sem_scenetree_bit_a_bit() -> void:
	var a_lam := _rodar_roteiro_determinismo(false)
	var b_lam := _rodar_roteiro_determinismo(false)
	assert_array(a_lam).is_equal(b_lam)
	var a_res := _rodar_roteiro_determinismo(true)
	var b_res := _rodar_roteiro_determinismo(true)
	assert_array(a_res).is_equal(b_res)


func test_ac03_faixas_dos_campos_combat_tuning() -> void:
	var base := ApoioCombate.tuning_fp()
	var tabela: Array = [
		[&"hitstop_leve_s", [0.0167, 0.1], [0.0, 0.101]],
		[&"hitstop_pesado_s", [0.05, 0.2], [0.049, 0.201]],
		[&"hitstop_abate_s", [0.0167, 0.2], [0.0, 0.201]],
		[&"hitstop_atingido_s", [0.0333, 0.25], [0.033, 0.251]],
		[&"hitstop_abate_chefe_s", [0.2, 1.5], [0.199, 1.501]],
		[&"hitstop_recusa_s", [0.1, 0.6], [0.099, 0.601]],
		[&"empurrao_pesado", [460.0, 1080.0], [459.99, 1080.01]],
		[&"limiar_finalizador", [1.0, 1.45], [0.99, 1.46]],
		[&"janela_combo_s", [0.5167, 1.0], [0.516, 1.001]],
		[&"recuperacao_max_s", [0.0167, 0.5], [0.016, 0.501]],
		[&"fator_recuperacao_golpe", [0.0, 1.0], [-0.01, 1.01]],
		[&"passo_apoio_px", [0.0, 24.0], [-0.01, 24.01]],
		[&"folga_encostado_px", [0.0, 20.0], [-0.01, 20.01]],
		[&"nascimento_projetil_px", [27.0, 60.0], [26.99, 60.01]],
		[&"invuln_extra_investida_s", [0.0, 0.1], [-0.01, 0.101]],
		[&"cambaleio_s", [0.0167, 0.15], [0.016, 0.151]],
		[&"fator_cambaleio", [0.0, 1.0], [-0.01, 1.01]],
		[&"quebrou_recuperacao_s", [0.1667, 0.8], [0.166, 0.801]],
		[&"parede_vel_min", [460.0, 900.0], [459.99, 900.01]],
		[&"parede_dano", [0.0, 30.0], [-0.01, 30.01]],
		[&"queda_empurrao", [0.5, 0.95], [0.49, 0.951]],
		[&"empurrao_zero", [0.9, 30.0], [0.89, 30.01]],
		[&"invuln_atingido_s", [0.25, 1.5], [0.249, 1.501]],
		[&"passes_varredura", [1, 8], [0, 9, 4.5]],
		[&"fator_guarda", [0.0, 1.0], [-0.01, 1.01]],
		[&"giro_leque_graus", [3.0, 45.0], [2.99, 45.01]],
		[&"fator_raio_obstaculo_projetil", [0.0, 1.0], [-0.01, 1.01]],
	]
	for linha: Array in tabela:
		var campo: StringName = linha[0]
		for v_ok in linha[1]:
			assert_bool(ValidadorCombatTuning.campo_em_faixa(base, campo, v_ok)).is_true()
		for v_err in linha[2]:
			assert_bool(ValidadorCombatTuning.campo_em_faixa(base, campo, v_err)).is_false()


func test_ac60_cv1_cv2_cv21_cv22_hitstop() -> void:
	# FV padrão -> nenhum
	assert_array(_codigos_cv(ApoioCombate.tuning_fp())).is_empty()

	# leve 4, abate 4, atingido 4 (0,0667 cada) -> nenhum
	var t := ApoioCombate.tuning_fp()
	t.hitstop_leve_s = 0.0667
	t.hitstop_abate_s = 0.0667
	t.hitstop_atingido_s = 0.0667
	assert_array(_codigos_cv(t)).is_empty()

	# leve 4, abate 4, atingido 3 (0,05) -> CV1
	t.hitstop_atingido_s = 0.05
	assert_array(_codigos_cv(t)).is_equal(["CV1:aviso"])

	# abate 7 (0,1167) -> CV1
	t = ApoioCombate.tuning_fp()
	t.hitstop_abate_s = 0.1167
	assert_array(_codigos_cv(t)).is_equal(["CV1:aviso"])

	# leve 6 (0,1), pesado 12 (0,2): f_cong = 24/72 = 0,333... -> CV1; CV2
	t = ApoioCombate.tuning_fp()
	t.hitstop_leve_s = 0.1
	t.hitstop_pesado_s = 0.2
	assert_array(_codigos_cv(t)).is_equal(["CV1:aviso", "CV2:aviso"])

	# invuln_atingido_s 0,25 (15) e atingido 0,25 (15) -> CV21; CV22
	t = ApoioCombate.tuning_fp()
	t.invuln_atingido_s = 0.25
	t.hitstop_atingido_s = 0.25
	assert_array(_codigos_cv(t)).is_equal(["CV21:aviso", "CV22:aviso"])

	# invuln_atingido_s 0,25 (15) e atingido 0,2333 (14) -> CV22
	t = ApoioCombate.tuning_fp()
	t.invuln_atingido_s = 0.25
	t.hitstop_atingido_s = 0.2333
	assert_array(_codigos_cv(t)).is_equal(["CV22:aviso"])


func test_ac61_cv3_cv4_cv5_combo() -> void:
	# limiar_finalizador 0,99 -> CV3 erro
	var t := ApoioCombate.tuning_fp()
	t.limiar_finalizador = 0.99
	assert_array(_codigos_cv(t)).is_equal(["CV3:erro"])

	# Corte com [1, 1, 1.2] -> CV3 aviso
	var atks := _fv_ataques()
	atks[0].def.multiplicadores_combo = PackedFloat64Array([1.0, 1.0, 1.2])
	assert_array(_codigos_cv(ApoioCombate.tuning_fp(), atks)).is_equal(["CV3:aviso"])

	# Corte com [1.5, 1, 1.8] -> CV3 aviso (dois finalizadores)
	atks = _fv_ataques()
	atks[0].def.multiplicadores_combo = PackedFloat64Array([1.5, 1.0, 1.8])
	assert_array(_codigos_cv(ApoioCombate.tuning_fp(), atks)).is_equal(["CV3:aviso"])

	# [1, 0, 1.8] -> CV4 erro
	atks = _fv_ataques()
	atks[0].def.multiplicadores_combo = PackedFloat64Array([1.0, 0.0, 1.8])
	assert_array(_codigos_cv(ApoioCombate.tuning_fp(), atks)).is_equal(["CV4:erro"])

	# [1, -0.5] -> CV3 aviso; CV4 erro
	atks = _fv_ataques()
	atks[0].def.multiplicadores_combo = PackedFloat64Array([1.0, -0.5])
	assert_array(_codigos_cv(ApoioCombate.tuning_fp(), atks)).is_equal(["CV3:aviso", "CV4:erro"])

	# [] (lista vazia declarada) -> CV3 aviso; CV4 erro
	atks = _fv_ataques()
	atks[0].def.multiplicadores_combo = PackedFloat64Array()
	atks[0].tem_combo_declarado = true
	assert_array(_codigos_cv(ApoioCombate.tuning_fp(), atks)).is_equal(["CV3:aviso", "CV4:erro"])

	# Corte com recarga 0,5667 (R = 34 == J) -> CV5 erro
	atks = _fv_ataques()
	atks[0].def.recarga_s = 0.5667
	assert_array(_codigos_cv(ApoioCombate.tuning_fp(), atks)).is_equal(["CV5:erro"])


func test_ac62_cv6_cv7_cv8_empurrao() -> void:
	# empurrao_zero 0 -> CV6 erro
	var t := ApoioCombate.tuning_fp()
	t.empurrao_zero = 0.0
	assert_array(_codigos_cv(t)).is_equal(["CV6:erro"])

	# Pulso com empurrão 240 e empurrao_zero 28,801 -> CV6 aviso; com 28,799 -> nenhum
	var atks := _fv_ataques()
	atks[2].def.empurrao = 240.0
	t = ApoioCombate.tuning_fp()
	t.empurrao_zero = 28.801
	assert_array(_codigos_cv(t, atks)).is_equal(["CV6:aviso"])
	t.empurrao_zero = 28.799
	assert_array(_codigos_cv(t, atks)).is_empty()

	# parede_vel_min 4,5 (== empurrao_zero) -> CV7 erro
	t = ApoioCombate.tuning_fp()
	t.parede_vel_min = 4.5
	assert_array(_codigos_cv(t)).is_equal(["CV7:erro"])

	# Corte com empurrão 460 e empurrao_pesado 460 -> CV7 aviso; CV8 aviso
	atks = _fv_ataques()
	atks[0].def.empurrao = 460.0
	t = ApoioCombate.tuning_fp()
	t.empurrao_pesado = 460.0
	assert_array(_codigos_cv(t, atks)).is_equal(["CV7:aviso", "CV8:aviso"])


func test_ac63_cv9_cv10_cv11_cv13_cv15_limites_de_um_campo() -> void:
	var t := ApoioCombate.tuning_fp()
	t.fator_recuperacao_golpe = -0.01
	assert_array(_codigos_cv(t)).is_equal(["CV9:erro"])

	# Corte com recarga_s 0 (R = 0) -> CV2; CV10 erro; CV17
	var atks := _fv_ataques()
	atks[0].def.recarga_s = 0.0
	assert_array(_codigos_cv(ApoioCombate.tuning_fp(), atks)).is_equal(["CV2:aviso", "CV10:erro", "CV17:aviso"])

	# passes_varredura 0 -> CV11 erro
	t = ApoioCombate.tuning_fp()
	t.passes_varredura = 0
	assert_array(_codigos_cv(t)).is_equal(["CV11:erro"])

	# Pulso com vida_s 0,0167 (L = 1) -> CV13 erro
	atks = _fv_ataques()
	atks[2].def.params[&"vida_s"] = 0.0167
	assert_array(_codigos_cv(ApoioCombate.tuning_fp(), atks)).is_equal(["CV13:erro"])

	# Investida com recarga 0,2 (R = 12 == N + E) -> CV15 erro
	atks = _fv_ataques()
	atks[1].def.recarga_s = 0.2
	assert_array(_codigos_cv(ApoioCombate.tuning_fp(), atks)).is_equal(["CV15:erro"])

	# invuln_extra_investida_s 0 (E = 0) -> CV15 aviso
	t = ApoioCombate.tuning_fp()
	t.invuln_extra_investida_s = 0.0
	assert_array(_codigos_cv(t)).is_equal(["CV15:aviso"])


func test_ac64_cv12_cv14_cv16_cv17_cv18_cv19_cv20_cruzadas() -> void:
	# Pulso com raio 1, r_min 7,2 -> CV12 erro; CV20 aviso
	var atks := _fv_ataques()
	atks[2].def.params[&"raio_px"] = 1.0
	var ctx := ValidadorCombatTuning.ContextoCruzado.new()
	ctx.r_min = 7.2
	assert_array(_codigos_cv(ApoioCombate.tuning_fp(), atks, ctx)).is_equal(["CV12:erro", "CV20:aviso"])

	# passo_apoio_px 24, raio_jogador_px 10, r_min 14 -> CV14
	var t := ApoioCombate.tuning_fp()
	t.passo_apoio_px = 24.0
	ctx = ValidadorCombatTuning.ContextoCruzado.new()
	ctx.raio_jogador_px = 10.0
	ctx.r_min = 14.0
	assert_array(_codigos_cv(t, _fv_ataques(), ctx)).is_equal(["CV14:aviso"])

	# Investida com 1830,01 px em N = 10 -> CV16
	atks = _fv_ataques()
	atks[1].def.params[&"distancia_px"] = 1830.01
	assert_array(_codigos_cv(ApoioCombate.tuning_fp(), atks)).is_equal(["CV16:aviso"])

	# cambaleio_s 0,15 (9) e Pulso recarga 0,15 (R = 9) -> CV17
	t = ApoioCombate.tuning_fp()
	t.cambaleio_s = 0.15
	atks = _fv_ataques()
	atks[2].def.recarga_s = 0.15
	assert_array(_codigos_cv(t, atks)).is_equal(["CV17:aviso"])

	# CV18: inimigo comum com Vida 53,21 e W 25 -> CV18; com 53,19 -> nenhum
	ctx = ValidadorCombatTuning.ContextoCruzado.new()
	ctx.inimigos_comuns = [[53.21, 25]]
	assert_array(_codigos_cv(ApoioCombate.tuning_fp(), _fv_ataques(), ctx)).is_equal(["CV18:aviso"])
	ctx.inimigos_comuns = [[53.19, 25]]
	assert_array(_codigos_cv(ApoioCombate.tuning_fp(), _fv_ataques(), ctx)).is_empty()

	# CV19: raio_jogador_px 50, folga_encostado_px 20, arco alcance 70 -> CV19
	t = ApoioCombate.tuning_fp()
	t.folga_encostado_px = 20.0
	atks = _fv_ataques()
	atks[0].def.params[&"alcance_px"] = 70.0
	ctx = ValidadorCombatTuning.ContextoCruzado.new()
	ctx.raio_jogador_px = 50.0
	assert_array(_codigos_cv(t, atks, ctx)).is_equal(["CV19:aviso"])


func test_ac65_erros_e_avisos_chegam_ao_destino() -> void:
	var atks := _fv_ataques()
	atks[0].def.recarga_s = 0.5667  # CV5 erro
	atks[2].def.recarga_s = 0.0     # CV10 erro
	var diags := ValidadorCombatTuning.validar_tudo(ApoioCombate.tuning_fp(), atks)
	assert_int(Diagnostico.contar_erros(diags)).is_equal(2)

	var t_av := ApoioCombate.tuning_fp()
	t_av.invuln_atingido_s = 0.25
	t_av.hitstop_atingido_s = 0.25
	var diags_av := ValidadorCombatTuning.validar_tudo(t_av, _fv_ataques())
	assert_int(Diagnostico.contar_erros(diags_av)).is_equal(0)
	assert_bool(diags_av.size() >= 2).is_true()
