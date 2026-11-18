extends GdUnitTestSuite
## Stories pipeline-visual 003, 004 e 005: modos de tela, passes, relógios, espelho LUT/profundidade/Bênção
## e PipelineVisual como único escritor de globais.

var _relogio_us: int = 100_000


func _criar_lut_identidade() -> Image:
	var img := Image.create(1024, 32, false, Image.FORMAT_RGBA8)
	for b in 32:
		for g in 32:
			for r in 32:
				img.set_pixel(b * 32 + r, g, Color(float(r) / 31.0, float(g) / 31.0, float(b) / 31.0, 1.0))
	return img


func _criar_lut_permutada(inverter_g: bool = false) -> Image:
	var img := Image.create(1024, 32, false, Image.FORMAT_RGBA8)
	for b in 32:
		for g in 32:
			for r in 32:
				var rf := float(r) / 31.0
				var gf := float(31 - g if inverter_g else g) / 31.0
				var bf := float(b) / 31.0
				img.set_pixel(b * 32 + r, g, Color(bf, rf, gf, 1.0))
	return img


func test_prioridade_modos_impacto_cortado_e_bencao_espera_ac_pv_35_81_77() -> void:
	var ev := EstadoVisual.new()
	ev.configurar(FabricasDeCatalogo.visual_tuning(), func() -> int: return _relogio_us)

	# AC-PV-81: impacto de 12 passos aceito no quadro 0; Bênção pedida no quadro 5 espera até o quadro 12
	assert_bool(ev.pedir_impacto(EstadoVisual.ModoImpacto.RECUSA, 12)).is_true()
	assert_int(ev.modo_tela()).is_equal(EstadoVisual.ModoTela.IMPACTO)
	for q in 5:
		ev.avancar_apres(1.0 / 60.0)
	ev.definir_bencao(true)
	assert_int(ev.modo_tela()).is_equal(EstadoVisual.ModoTela.IMPACTO)
	for q in range(5, 11):
		ev.avancar_apres(1.0 / 60.0)
		assert_int(ev.modo_tela()).is_equal(EstadoVisual.ModoTela.IMPACTO)
	ev.avancar_apres(1.0 / 60.0) # quadro 12
	assert_int(ev.modo_tela()).is_equal(EstadoVisual.ModoTela.BENCAO)
	assert_bool(ev.modo_bencao_efetivo()).is_true()

	# AC-PV-77: pausa no meio do impact frame congela a contagem e retoma depois
	ev.definir_bencao(false)
	_relogio_us += 2_000_000
	assert_bool(ev.pedir_impacto(EstadoVisual.ModoImpacto.RECUSA, 12)).is_true()
	for q in 5:
		ev.avancar_apres(1.0 / 60.0, false)
	for q in 120:
		ev.avancar_apres(1.0 / 60.0, true) # pausado
	assert_int(ev.modo_tela()).is_equal(EstadoVisual.ModoTela.IMPACTO)
	for q in 7:
		ev.avancar_apres(1.0 / 60.0, false)
	assert_int(ev.modo_tela()).is_equal(EstadoVisual.ModoTela.NORMAL)


func test_wipe_troca_lut_na_metade_e_zero_dos_relogios_nao_afeta_wipe_ac_pv_12_41_65() -> void:
	var ev := EstadoVisual.new()
	ev.configurar(FabricasDeCatalogo.visual_tuning(), func() -> int: return _relogio_us)
	var tex_nova := ImageTexture.create_from_image(_criar_lut_identidade())
	ev.agendar_regiao(tex_nova, EstadoVisual.CoresDaRegiao.new())
	ev.globais_sujos() # limpa iniciais

	var passe := ev.pedir_passe(&"wipe")
	assert_bool(passe.eh_fade()).is_false()

	# 24 quadros de 1/60 s para duracao_wipe_s = 0.40 s
	for q in range(1, 25):
		ev.avancar_apres(1.0 / 60.0)
		if q == 12:
			assert_float(passe.progresso()).is_equal_approx(0.5, 1e-6)
			ev.receber_relogios(0.0, 0.0) # zero dos relógios na metade
			var sujos_metade := ev.globais_sujos()
			assert_bool(sujos_metade.has(&"lut_regiao")).is_true()
		else:
			var sujos_outros := ev.globais_sujos()
			assert_bool(sujos_outros.has(&"lut_regiao")).is_false()
	assert_float(passe.progresso()).is_equal_approx(1.0, 1e-6)
	assert_int(ev.modo_tela()).is_equal(EstadoVisual.ModoTela.NORMAL)


func test_espelho_lut_f1_profundidade_f2_e_bencao_f5_ac_pv_07_08_09_13_14_16() -> void:
	var lut_id := _criar_lut_identidade()
	# AC-PV-07: grade deamostragem LUT identidade erro <= 1/255
	for r_i in [0, 5, 11, 17]:
		for g_i in [0, 8, 17]:
			for b_i in [0, 9, 17]:
				var c := Color(float(r_i) / 17.0, float(g_i) / 17.0, float(b_i) / 17.0, 0.5)
				var out := VisualMath.amostrar_lut(lut_id, c)
				assert_float(absf(out.r - c.r)).is_less_equal(1.0 / 255.0 + 1e-5)
				assert_float(absf(out.g - c.g)).is_less_equal(1.0 / 255.0 + 1e-5)
				assert_float(absf(out.b - c.b)).is_less_equal(1.0 / 255.0 + 1e-5)
				assert_float(out.a).is_equal_approx(0.5, 1e-6)

	# AC-PV-08: lut_permutada devolve (b, r, g)
	var lut_perm := _criar_lut_permutada(false)
	var cp := VisualMath.amostrar_lut(lut_perm, Color(0.2, 0.5, 0.9))
	assert_float(cp.r).is_equal_approx(0.9, 1.0 / 255.0 + 1e-3)
	assert_float(cp.g).is_equal_approx(0.2, 1.0 / 255.0 + 1e-3)
	assert_float(cp.b).is_equal_approx(0.5, 1.0 / 255.0 + 1e-3)

	# AC-PV-09: exemplo c = (0.60, 0.50, 0.40)
	var coords := VisualMath.coordenadas_lut(Color(0.60, 0.50, 0.40))
	assert_float(float(coords["b"])).is_equal_approx(12.4, 1e-5)
	assert_int(int(coords["s0"])).is_equal(12)
	assert_int(int(coords["s1"])).is_equal(13)
	assert_float(float(coords["t"])).is_equal_approx(0.4, 1e-5)
	assert_float(float(coords["u0"])).is_equal_approx(0.393652, 1e-5)
	assert_float(float(coords["u1"])).is_equal_approx(0.424902, 1e-5)
	assert_float(float(coords["v"])).is_equal_approx(0.5, 1e-5)

	# AC-PV-13 e AC-PV-14: F2 em linear sobre chão #343C4A e parede #2B3240
	var chao := Color("343c4a")
	var parede := Color("2b3240")
	assert_float(VisualMath.cor_para_l_star(VisualMath.aplicar_f2(chao, 1.0))).is_equal_approx(25.13, 0.05)
	assert_float(VisualMath.cor_para_l_star(VisualMath.aplicar_f2(chao, 0.85))).is_equal_approx(22.96, 0.05)
	assert_float(VisualMath.cor_para_l_star(VisualMath.aplicar_f2(parede, 0.85))).is_equal_approx(18.76, 0.05)

	# AC-PV-16: F5 Bênção sobre chão #343C4A e magenta #E0259C
	var chao_bencao := VisualMath.aplicar_f5(chao, 0.20, 0.60)
	assert_float(chao_bencao.r).is_equal_approx(0.1366, 0.0005)
	assert_float(chao_bencao.g).is_equal_approx(0.1404, 0.0005)
	assert_float(chao_bencao.b).is_equal_approx(0.1470, 0.0005)
	assert_float(VisualMath.cor_para_l_star(chao_bencao)).is_equal_approx(14.06, 0.05)


func test_pipeline_visual_unico_escritor_e_float32_ac_pv_44() -> void:
	# AC-PV-44: n_vivos = 216.001 -> float32 bit a bit e VV16 acima de 4096 s
	var t_double := 216001.0 / 60.0
	var t_f32 := VisualMath.para_float32(t_double)
	assert_float(t_f32).is_equal_approx(3600.016602, 1e-4)
	assert_float(VisualMath.ulp_float32(1800.0)).is_equal_approx(pow(2.0, -13.0), 1e-9)
	assert_float(VisualMath.ulp_float32(4096.0)).is_equal_approx(pow(2.0, -11.0), 1e-9)

	var ev := EstadoVisual.new()
	ev.configurar(FabricasDeCatalogo.visual_tuning())
	var escritor := EscritorPorMaterial.new()
	var pv := auto_free(PipelineVisual.new())
	pv.configurar(ev, null, escritor)

	ev.receber_relogios(245760.0 / 60.0, 10.0)
	assert_bool(ev.aviso_vv16_emitido()).is_false()
	ev.receber_relogios(245761.0 / 60.0, 10.0)
	assert_bool(ev.aviso_vv16_emitido()).is_true()

	ev.definir_profundidade(2)
	pv.aplicar_quadro()
	assert_int(escritor.total_escritas(&"t_vivo")).is_equal(1)
	assert_int(escritor.total_escritas(&"t_apres")).is_equal(1)
	assert_int(escritor.total_escritas(&"fator_profundidade")).is_equal(1)

	# Segundo quadro na mesma câmara não reescreve fator_profundidade
	pv.aplicar_quadro()
	assert_int(escritor.total_escritas(&"t_vivo")).is_equal(2)
	assert_int(escritor.total_escritas(&"fator_profundidade")).is_equal(1)
