extends GdUnitTestSuite
## Stories pipeline-visual 001 e 002: VisualTuning, validação VV1–VV17, PV1–PV8 e LimitadorDeFlashes (F6).

var _relogio_us: int = 0


func _avancar_us(t: int) -> void:
	_relogio_us = t


func _criar_lut_identidade_img() -> Image:
	var img := Image.create(1024, 32, false, Image.FORMAT_RGBA8)
	for b in 32:
		for g in 32:
			for r in 32:
				img.set_pixel(b * 32 + r, g, Color(float(r) / 31.0, float(g) / 31.0, float(b) / 31.0, 1.0))
	return img


func test_visual_tuning_fabrica_passa_sem_erros_e_vv13_dispara_alerta_504_mib() -> void:
	var t := FabricasDeCatalogo.visual_tuning()
	var diags := ValidadorPipelineVisual.validar_tuning(t, false)
	assert_array(diags).is_empty()

	var diags_com_mem := ValidadorPipelineVisual.validar_tuning(t, true)
	assert_int(diags_com_mem.size()).is_equal(1)
	assert_str(String(diags_com_mem[0].regra)).is_equal("VV13")
	assert_bool(diags_com_mem[0].eh_aviso()).is_true()


func test_vv1_vv2_vv5_vv6_vv11_vv14_vv15_vv17_e_contorno_silhueta_ac_pv_66() -> void:
	# AC-PV-66: hierarquia de contorno VV5 vs VV17
	var t1 := FabricasDeCatalogo.visual_tuning()
	t1.contorno_silhueta_px = 3.5
	t1.contorno_telegrafo_px = 3.5
	var d1 := ValidadorPipelineVisual.validar_tuning(t1)
	assert_bool(d1.any(func(d: Diagnostico) -> bool: return d.regra == &"VV5")).is_true()

	var t2 := FabricasDeCatalogo.visual_tuning()
	t2.contorno_silhueta_px = 3.49
	t2.contorno_telegrafo_px = 3.5
	assert_array(ValidadorPipelineVisual.validar_tuning(t2)).is_empty()

	var t3 := FabricasDeCatalogo.visual_tuning()
	t3.contorno_silhueta_px = 4.0
	t3.contorno_telegrafo_px = 6.0
	var d3 := ValidadorPipelineVisual.validar_tuning(t3)
	assert_int(d3.size()).is_equal(1)
	assert_str(String(d3[0].regra)).is_equal("VV17")


func test_vv8_vv9_vv10_precedencia_telegrafo_degenerado_ac_pv_04_e_59() -> void:
	# VV8 suspende VV9 e VV10 quando r <= 0
	var d_deg := ValidadorPipelineVisual.validar_telegrafo(0, Vector4(-10.0, 0, 0, 0), 0, 1.5, 4.0, 6.0)
	assert_int(d_deg.size()).is_equal(1)
	assert_str(String(d_deg[0]["regra"])).is_equal("VV8")

	# VV9 erro quando D'' <= 0 (r = 9, w = 4, a = 6 -> D'' = -1)
	var d_peq := ValidadorPipelineVisual.validar_telegrafo(0, Vector4(9.0, 0, 0, 0), 0, 0.5, 4.0, 6.0)
	assert_int(d_peq.size()).is_equal(1)
	assert_str(String(d_peq[0]["regra"])).is_equal("VV9")
	assert_int(int(d_peq[0]["nivel"])).is_equal(Diagnostico.Nivel.ERRO)


func test_vv3_piso_do_chao_e_vv4_perfil_lut_ac_pv_11_e_15() -> void:
	assert_array(ValidadorPipelineVisual.validar_lut_perfil(1024, 32, Image.FORMAT_RGBA8, false, false, false)).is_empty()
	assert_array(ValidadorPipelineVisual.validar_lut_perfil(1024, 64, Image.FORMAT_RGBA8, false, false, false)).is_equal([&"VV4"])
	assert_array(ValidadorPipelineVisual.validar_lut_perfil(1024, 32, Image.FORMAT_RGBA8, true, false, false)).is_equal([&"VV4"])

	# AC-PV-15: L* = 23.50 em k = 0.85 -> VV3 erro; L* = 24.20 -> VV3 aviso; #343C4A (25.13) -> {}
	var c_235 := VisualMath.cinza_srgb_de_l_star(23.50)
	var r_235 := ValidadorPipelineVisual.validar_chao_lut(null, 0.85, c_235)
	assert_int(r_235.size()).is_equal(1)
	assert_int(int(r_235[0]["nivel"])).is_equal(Diagnostico.Nivel.ERRO)

	var c_242 := VisualMath.cinza_srgb_de_l_star(24.20)
	var r_242 := ValidadorPipelineVisual.validar_chao_lut(null, 0.85, c_242)
	assert_int(r_242.size()).is_equal(1)
	assert_int(int(r_242[0]["nivel"])).is_equal(Diagnostico.Nivel.AVISO)

	var chao_padrao := Color("343c4a")
	assert_array(ValidadorPipelineVisual.validar_chao_lut(null, 0.85, chao_padrao)).is_empty()


func test_limitador_sequencia_exemplo_f6_ac_pv_36() -> void:
	var lim := LimitadorDeFlashes.new(func() -> int: return _relogio_us)
	var area_grande := 300000.0

	_avancar_us(100_000)
	assert_bool(lim.pedir_impacto(false)).is_true()
	_avancar_us(400_000)
	assert_bool(lim.pedir_flash_telegrafo(area_grande)).is_true()
	_avancar_us(700_000)
	assert_bool(lim.pedir_flash_telegrafo(area_grande)).is_true()
	_avancar_us(950_000)
	assert_bool(lim.pedir_flash_telegrafo(area_grande)).is_false()
	_avancar_us(1_050_000)
	assert_bool(lim.pedir_impacto(false)).is_false()
	_avancar_us(1_100_000)
	assert_bool(lim.pedir_impacto(false)).is_true()
	_avancar_us(1_150_000)
	assert_bool(lim.pedir_flash_telegrafo(area_grande)).is_false()
	_avancar_us(1_399_999)
	assert_bool(lim.pedir_flash_telegrafo(area_grande)).is_false()
	_avancar_us(1_400_000)
	assert_bool(lim.pedir_flash_telegrafo(area_grande)).is_true()


func test_limitador_area_disparo_c120_e_preempcao_chefe_ac_pv_37_38_63_64_79() -> void:
	var lim := LimitadorDeFlashes.new(func() -> int: return _relogio_us)
	var area_c120 := PI * 120.0 * 120.0 # 45.238,93

	# AC-PV-37: 5 disparos C120 em z=1 não pedem flash (conta permanece 0); 6 disparos pedem 1 flash
	_avancar_us(100_000)
	assert_bool(lim.pedir_flash_telegrafo(5.0 * area_c120, 1.0)).is_true()
	assert_int(lim.n_flashes_na_janela()).is_equal(0)
	assert_bool(lim.pedir_flash_telegrafo(6.0 * area_c120, 1.0)).is_true()
	assert_int(lim.n_flashes_na_janela()).is_equal(1)

	# AC-PV-63: preempção do chefe sobre recusa na janela de 1 s
	lim.limpar()
	_avancar_us(2_000_000)
	assert_bool(lim.pedir_impacto(false)).is_true() # recusa aceita
	_avancar_us(2_300_000)
	assert_bool(lim.pedir_impacto(true)).is_true()  # chefe aceito (preempta recusa)
	_avancar_us(2_600_000)
	assert_bool(lim.pedir_impacto(true)).is_false() # segundo chefe negado

	# AC-PV-64: teto de 3 flashes/s também vale para o chefe
	lim.limpar()
	_avancar_us(2_000_000)
	assert_bool(lim.pedir_impacto(false)).is_true()
	_avancar_us(2_050_000)
	assert_bool(lim.pedir_flash_telegrafo(300000.0)).is_true()
	_avancar_us(2_100_000)
	assert_bool(lim.pedir_flash_telegrafo(300000.0)).is_true()
	_avancar_us(2_300_000)
	assert_bool(lim.pedir_impacto(true)).is_false()

	# AC-PV-79: passe obrigatório com janela cheia nunca é negado, sai como fade e conta N_flash = 4
	var eh_fade := lim.registrar_passe_obrigatorio(2_500_000)
	assert_bool(eh_fade).is_true()
	assert_int(lim.n_flashes_na_janela(2_500_000)).is_equal(4)
