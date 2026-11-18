extends GdUnitTestSuite
## Story movimento-010: AC-35..39, AC-53, AC-54, AC-59 e AC-48 (MovementTuning MV1–MV8, faixas R11, precisão e orçamento de 0,2 ms).


func _fp() -> MovementTuning:
	var t := ApoioMovimento.tuning_fp()
	t.id = &"movement_tuning"
	return t


func _codigos(diags: Array[Diagnostico], nivel: int = -1) -> Array[StringName]:
	var r: Array[StringName] = []
	for d in diags:
		if nivel == -1 or int(d.nivel) == nivel:
			r.append(d.regra)
	return r


func test_ac35_mv1_atravessar_obstaculo_erro_e_aviso() -> void:
	# 3000 px/s (50 px), raio 10, r_obs_min 30 -> erro (50 >= 40)
	var t1 := _fp()
	t1.velocidade_esquiva_pxs = 3000.0
	t1.raio_jogador_px = 10.0
	assert_bool(_codigos(t1.validar_com_contexto(30.0), Diagnostico.Nivel.ERRO).has(&"MV1")).is_true()

	# 2400 px/s (40 px), raio 27, r_obs_min 42 -> aviso (margem 69/40 = 1,725 < 2)
	var t2 := _fp()
	t2.velocidade_esquiva_pxs = 2400.0
	t2.raio_jogador_px = 27.0
	var d2 := t2.validar_com_contexto(42.0)
	assert_bool(_codigos(d2, Diagnostico.Nivel.ERRO).has(&"MV1")).is_false()
	assert_bool(_codigos(d2, Diagnostico.Nivel.AVISO).has(&"MV1")).is_true()

	# 1350, raio 27, r_obs_min 42 -> nada (margem 3,07)
	var t3 := _fp()
	assert_bool(_codigos(t3.validar_com_contexto(42.0)).has(&"MV1")).is_false()


func test_ac36_mv2_invulnerabilidade_perpetua_e_cobertura() -> void:
	# recarga_s 0,2 (R = 12) com D + E = 12 -> erro
	var t1 := _fp()
	t1.recarga_s = 0.2
	assert_bool(_codigos(t1.validar_com_contexto(), Diagnostico.Nivel.ERRO).has(&"MV2")).is_true()

	# recarga_s 0,35 (R = 21) -> aviso (12/21 = 0,571 > 0,5)
	var t2 := _fp()
	t2.recarga_s = 0.35
	var d2 := t2.validar_com_contexto()
	assert_bool(_codigos(d2, Diagnostico.Nivel.ERRO).has(&"MV2")).is_false()
	assert_bool(_codigos(d2, Diagnostico.Nivel.AVISO).has(&"MV2")).is_true()

	# recarga_s 0,4 (R = 24) -> nada (0,5 não é > 0,5)
	var t3 := _fp()
	t3.recarga_s = 0.4
	assert_bool(_codigos(t3.validar_com_contexto()).has(&"MV2")).is_false()

	# recarga_s 0,7 (R = 42) -> nada
	assert_bool(_codigos(_fp().validar_com_contexto()).has(&"MV2")).is_false()


func test_ac37_mv4_e_mv5_raio_e_alvos_max_corte() -> void:
	for r_invalido: float in [9.0, 51.0]:
		var t := _fp()
		t.raio_jogador_px = r_invalido
		assert_bool(_codigos(t.validar_com_contexto(), Diagnostico.Nivel.ERRO).has(&"MV4")).is_true()
	for r_valido: float in [10.0, 50.0]:
		var t := _fp()
		t.raio_jogador_px = r_valido
		assert_bool(_codigos(t.validar_com_contexto(), Diagnostico.Nivel.ERRO).has(&"MV4")).is_false()

	# MV5: 0 explícito e -1 -> erro; vazio (null) e 1 -> aceitos
	var t_zero := _fp()
	t_zero.definir_alvos_max_corte(0)
	assert_bool(_codigos(t_zero.validar_com_contexto(), Diagnostico.Nivel.ERRO).has(&"MV5")).is_true()

	var t_neg := _fp()
	t_neg.alvos_max_corte = -1
	assert_bool(_codigos(t_neg.validar_com_contexto(), Diagnostico.Nivel.ERRO).has(&"MV5")).is_true()

	var t_vazio := _fp()
	t_vazio.definir_alvos_max_corte(null)
	assert_bool(_codigos(t_vazio.validar_com_contexto(), Diagnostico.Nivel.ERRO).has(&"MV5")).is_false()

	var t_um := _fp()
	t_um.definir_alvos_max_corte(1)
	assert_bool(_codigos(t_um.validar_com_contexto(), Diagnostico.Nivel.ERRO).has(&"MV5")).is_false()


func test_ac53_faixas_dos_campos_r11() -> void:
	var tabela: Array = [
		[&"cargas_base", [1, 3], [0, 4]],
		[&"duracao_esquiva_s", [0.05, 0.5], [0.049, 0.51]],
		[&"velocidade_esquiva_pxs", [300.0, 3000.0], [299.0, 3001.0]],
		[&"invuln_extra_s", [0.0, 0.25], [-0.01, 0.26]],
		[&"recarga_s", [0.1, 3.0], [0.09, 3.01]],
		[&"fator_recuperacao", [0.0, 1.0], [-0.01, 1.01]],
	]
	for linha: Array in tabela:
		var campo: StringName = linha[0]
		for aceito in linha[1]:
			var t := _fp()
			if campo == &"recarga_s" and float(aceito) == 0.1:
				t.duracao_esquiva_s = 0.05
				t.invuln_extra_s = 0.0
			t.set(campo, aceito)
			var erros := _codigos(t.validar_com_contexto(), Diagnostico.Nivel.ERRO)
			assert_bool(erros.has(&"FAIXA")).is_false()
		for invalido in linha[2]:
			var t := _fp()
			t.set(campo, invalido)
			var erros := _codigos(t.validar_com_contexto(), Diagnostico.Nivel.ERRO)
			assert_bool(erros.has(&"FAIXA")).is_true()

	# Arredondamento F7: 0,125 s dá 7,5 -> 8 passos (meio para longe do zero)
	assert_int(Unidades.duracao_para_passos(0.125)).is_equal(8)


func test_ac38_mv6_e_mv7_avisos_podem_coexistir() -> void:
	# MV6: raio 10, r_inimigo_min 10, alcance_extra_px 0, 3000 px/s -> aviso (50 > 40)
	var t_mv6 := _fp()
	t_mv6.raio_jogador_px = 10.0
	t_mv6.velocidade_esquiva_pxs = 3000.0
	assert_bool(_codigos(t_mv6.validar_com_contexto(-1.0, 10.0, 0.0), Diagnostico.Nivel.AVISO).has(&"MV6")).is_true()
	# Com valores da FP, sem aviso MV6
	assert_bool(_codigos(_fp().validar_com_contexto(-1.0, 22.5, 9.0), Diagnostico.Nivel.AVISO).has(&"MV6")).is_false()

	# MV7: D = 3 (0,05 s) a 300 px/s dá 15 px < 54 -> aviso
	var t_curta := _fp()
	t_curta.duracao_esquiva_s = 0.05
	t_curta.velocidade_esquiva_pxs = 300.0
	assert_bool(_codigos(t_curta.validar_com_contexto(), Diagnostico.Nivel.AVISO).has(&"MV7")).is_true()

	# MV7: D = 30 (0,5 s) a 1350 px/s dá 675 px > 600 -> aviso (coexiste com MV8)
	var t_longa := _fp()
	t_longa.duracao_esquiva_s = 0.5
	var avisos_longa := _codigos(t_longa.validar_com_contexto(), Diagnostico.Nivel.AVISO)
	assert_bool(avisos_longa.has(&"MV7") and avisos_longa.has(&"MV8")).is_true()

	# MV7: D = 24 (0,4 s) a 1500 px/s dá 600 px exatos -> sem aviso MV7
	var t_600 := _fp()
	t_600.duracao_esquiva_s = 0.4
	t_600.velocidade_esquiva_pxs = 1500.0
	assert_bool(_codigos(t_600.validar_com_contexto(), Diagnostico.Nivel.AVISO).has(&"MV7")).is_false()

	# 202,5 px da FP -> sem aviso MV7
	assert_bool(_codigos(_fp().validar_com_contexto(), Diagnostico.Nivel.AVISO).has(&"MV7")).is_false()


func test_ac54_limites_exatos_mv1_mv2_mv6_mv7_mv8() -> void:
	# MV1: 1350 px/s (22,5), raio 10, r_obs_min 12,5 -> erro (22,5 >= 22,5)
	var t1 := _fp()
	t1.raio_jogador_px = 10.0
	assert_bool(_codigos(t1.validar_com_contexto(12.5), Diagnostico.Nivel.ERRO).has(&"MV1")).is_true()
	# 1350 px/s, raio 27, r_obs_min 18 -> margem 2,0 exata -> nada
	assert_bool(_codigos(_fp().validar_com_contexto(18.0)).has(&"MV1")).is_false()

	# MV2: recarga_s 0,2167 (R = 13) com D + E = 12 -> só aviso (12/13 > 0,5), não erro
	var t2 := _fp()
	t2.recarga_s = 0.2167
	var d2 := t2.validar_com_contexto()
	assert_bool(_codigos(d2, Diagnostico.Nivel.ERRO).has(&"MV2")).is_false()
	assert_bool(_codigos(d2, Diagnostico.Nivel.AVISO).has(&"MV2")).is_true()

	# MV6: raio 10, r_inimigo_min 10, alcance_extra_px 0: 2400 px/s (40 = 40) -> sem aviso; 2401 -> aviso
	var t6_ok := _fp()
	t6_ok.raio_jogador_px = 10.0
	t6_ok.velocidade_esquiva_pxs = 2400.0
	assert_bool(_codigos(t6_ok.validar_com_contexto(-1.0, 10.0, 0.0), Diagnostico.Nivel.AVISO).has(&"MV6")).is_false()
	t6_ok.velocidade_esquiva_pxs = 2401.0
	assert_bool(_codigos(t6_ok.validar_com_contexto(-1.0, 10.0, 0.0), Diagnostico.Nivel.AVISO).has(&"MV6")).is_true()

	# MV7: D = 3 (0,05 s) a 1080 px/s dá 54 px (2 * 27) -> sem aviso
	var t7 := _fp()
	t7.duracao_esquiva_s = 0.05
	t7.velocidade_esquiva_pxs = 1080.0
	assert_bool(_codigos(t7.validar_com_contexto(), Diagnostico.Nivel.AVISO).has(&"MV7")).is_false()

	# MV8: duracao_esquiva_s 0,17 (D = 10) -> sem aviso; 0,18 (D = 11) -> aviso; 0,15 (D = 9) -> sem aviso
	var t8_10 := _fp()
	t8_10.duracao_esquiva_s = 0.17
	assert_bool(_codigos(t8_10.validar_com_contexto(-1.0, -1.0, -1.0, 10), Diagnostico.Nivel.AVISO).has(&"MV8")).is_false()
	var t8_11 := _fp()
	t8_11.duracao_esquiva_s = 0.18
	assert_bool(_codigos(t8_11.validar_com_contexto(-1.0, -1.0, -1.0, 10), Diagnostico.Nivel.AVISO).has(&"MV8")).is_true()
	assert_bool(_codigos(_fp().validar_com_contexto(-1.0, -1.0, -1.0, 10), Diagnostico.Nivel.AVISO).has(&"MV8")).is_false()


func test_ac39_erros_e_avisos_chegam_ao_destino() -> void:
	# Catálogo com MV2 e MV5 violados -> 2 erros (MV2 e MV5)
	var t_err := _fp()
	t_err.recarga_s = 0.2
	t_err.definir_alvos_max_corte(0)
	var diags_err := t_err.validar_com_contexto()
	assert_int(Diagnostico.contar_erros(diags_err)).is_equal(2)
	assert_array(_codigos(diags_err, Diagnostico.Nivel.ERRO)).is_equal([&"MV5", &"MV2"])

	# Catálogo só com avisos (MV6, MV7, MV8 e margem do MV2) -> 0 erros, 4 avisos
	var t_av := _fp()
	t_av.raio_jogador_px = 10.0
	t_av.duracao_esquiva_s = 0.25  # D = 15 (> 10 -> MV8)
	t_av.velocidade_esquiva_pxs = 3000.0  # d_passo = 50 (> 40 -> MV6; dist = 750 > 600 -> MV7)
	t_av.invuln_extra_s = 0.0  # inv = 15
	t_av.recarga_s = 0.4  # R = 24 -> 15/24 = 0,625 > 0,5 -> MV2 aviso
	var diags_av := t_av.validar_com_contexto(-1.0, 10.0, 0.0, 10)
	assert_int(Diagnostico.contar_erros(diags_av)).is_equal(0)
	var avisos := _codigos(diags_av, Diagnostico.Nivel.AVISO)
	assert_bool(avisos.has(&"MV2") and avisos.has(&"MV6") and avisos.has(&"MV7") and avisos.has(&"MV8")).is_true()

	# MV1 na 2ª passada com r_obs_min = 12,5 e raio = 10 -> erro bloqueante
	var t_mv1 := _fp()
	t_mv1.raio_jogador_px = 10.0
	var diags_mv1 := t_mv1.validar_com_contexto(12.5)
	assert_int(Diagnostico.contar_erros(diags_mv1)).is_equal(1)
	assert_str(String(diags_mv1[0].regra)).is_equal("MV1")


func test_ac59_precisao_int64_e_ieee754_binary64() -> void:
	var f52 := pow(2.0, 52.0)
	var f53 := pow(2.0, 53.0)
	assert_bool(f52 + 1.0 != f52).is_true()
	assert_bool(f53 + 1.0 == f53).is_true()
	var acumulador_int: int = (1 << 40) + 99
	assert_int(acumulador_int - 99).is_equal(1 << 40)


func test_ac48_orcamento_do_movimento_10000_passos_p99_abaixo_de_0_2_ms() -> void:
	var obs: Array[ObstaculoCircular] = [
		ObstaculoCircular.new(Vector2(400, 300), 42.0),
		ObstaculoCircular.new(Vector2(800, 300), 42.0),
		ObstaculoCircular.new(Vector2(1200, 300), 42.0),
		ObstaculoCircular.new(Vector2(400, 780), 42.0),
		ObstaculoCircular.new(Vector2(800, 780), 42.0),
		ObstaculoCircular.new(Vector2(1200, 780), 42.0),
	]
	var sim := ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp(), 1, obs)
	sim.atributos.resumo_corte = ApoioMovimento.resumo_fp_corte()
	var alvos: Array[AlvoDoCorte] = []
	for i in 9:
		alvos.append(AlvoDoCorte.new(i + 1, Vector2(500.0 + float(i) * 110.0, 540.0), 24.0))
	sim.alvos.lista = alvos

	var tempos_us: Array[int] = []
	tempos_us.resize(10000)
	for k in 10000:
		var mover := Vector2(cos(float(k) * 0.07), sin(float(k) * 0.05))
		var toque := (k % 42) == 0
		var apertados: Array[StringName] = []
		if toque:
			apertados.append(Acoes.ESQUIVA)
		sim.buffer.atualizar(apertados, k, 0, false)
		var amostra := AmostraDeEntrada.new([], apertados, sim.buffer.visao())
		amostra.id_passo = k
		amostra.mover = mover
		amostra.mirar = Vector2.RIGHT
		var t0 := Time.get_ticks_usec()
		sim.mov.passo(amostra)
		var t1 := Time.get_ticks_usec()
		tempos_us[k] = t1 - t0
		sim.eventos.esvaziar()
		sim.combate.pedidos.clear()
		sim.combate.cortes.clear()

	tempos_us.sort()
	var p99_us: int = tempos_us[int(floor(10000.0 * 0.99))]
	# Guardrail: p99 <= 200 us (0,2 ms); em debug headless permitimos margem segura, mas medimos e verificamos <= 200 us.
	assert_int(p99_us).is_less_equal(200)
