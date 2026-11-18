extends GdUnitTestSuite
## Story selo-e-fluxo-001: SealTuning e validação SV1–SV12 (AC-SF-24, AC-SF-32).


func _codigos(diags: Array[Diagnostico], regra: StringName) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	for d: Diagnostico in diags:
		if d.regra == regra:
			out.append(d)
	return out


func test_ac_sf_24_validacao_sv1_a_sv12_e_catalogo_de_fabrica() -> void:
	# Catálogo de fábrica: produz apenas o SV10 informativo de Anomalia p 0 (Vida 24 = 24)
	# e Fenda p 1 (Vida 48 = 2 × 24), e nenhum erro nem SV12
	var s_fab: SealTuning = SealTuning.fabrica()
	var diags_fab: Array[Diagnostico] = ValidadorSealTuning.validar_tuning(s_fab)
	var sv10: Array[Diagnostico] = _codigos(diags_fab, &"SV10")
	assert_int(diags_fab.size()).is_equal(2)
	assert_int(sv10.size()).is_equal(2)
	assert_int(_codigos(diags_fab, &"SV12").size()).is_equal(0)

	# SV1: custo_fluxo > fluxo_max ou <= 0 -> erro
	var s_sv1: SealTuning = SealTuning.fabrica()
	s_sv1.custo_fluxo = 120.0
	var d_sv1 := _codigos(ValidadorSealTuning.validar_tuning(s_sv1), &"SV1")
	assert_int(d_sv1.size()).is_equal(1)
	assert_bool(d_sv1[0].eh_erro()).is_true()

	# SV2: recarga < 1 passo ou fator_lentidao fora de [0, 1] -> erro
	var s_sv2: SealTuning = SealTuning.fabrica()
	s_sv2.recarga_s = 0.0
	var d_sv2 := _codigos(ValidadorSealTuning.validar_tuning(s_sv2), &"SV2")
	assert_int(d_sv2.size()).is_equal(1)
	assert_bool(d_sv2[0].eh_erro()).is_true()

	# SV3: 2 * margem_borda_px >= dimensão jogável -> erro
	var s_sv3: SealTuning = SealTuning.fabrica()
	s_sv3.margem_borda_px = 600.0
	var d_sv3 := _codigos(ValidadorSealTuning.validar_tuning(s_sv3), &"SV3")
	assert_int(d_sv3.size()).is_equal(1)
	assert_bool(d_sv3[0].eh_erro()).is_true()

	# SV11: campo fora da faixa de design (ex.: raio_px = 250 > 195) -> aviso SV11
	var s_sv11: SealTuning = SealTuning.fabrica()
	s_sv11.raio_px = 250.0
	assert_int(_codigos(ValidadorSealTuning.validar_tuning(s_sv11), &"SV11").size()).is_equal(1)

	# F5 f_selo com Lâmina e Ressonância de fábrica (1 alvo: 10,5% e 13,4%; grupo 5: 31,8% e 34,4%)
	var f_lam_1 := ValidadorSealTuning.calcular_f3_f4_f5(s_fab, FabricaDeArmas.lamina(), 1, 1, 1)
	var f_res_1 := ValidadorSealTuning.calcular_f3_f4_f5(s_fab, FabricaDeArmas.ressonancia(), 1, 1, 1)
	var f_lam_5 := ValidadorSealTuning.calcular_f3_f4_f5(s_fab, FabricaDeArmas.lamina(), 1, 5, 5)
	var f_res_5 := ValidadorSealTuning.calcular_f3_f4_f5(s_fab, FabricaDeArmas.ressonancia(), 1, 5, 5)
	assert_float(float(f_lam_1[&"f_selo"])).is_equal_approx(0.105, 0.002)
	assert_float(float(f_res_1[&"f_selo"])).is_equal_approx(0.134, 0.002)
	assert_float(float(f_lam_5[&"f_selo"])).is_equal_approx(0.318, 0.002)
	assert_float(float(f_res_5[&"f_selo"])).is_equal_approx(0.344, 0.002)


func test_ac_sf_32_numeros_da_besta_do_vinculo_f3_f4_f5() -> void:
	var s_fab: SealTuning = SealTuning.fabrica()
	var besta: WeaponDef = FabricaDeArmas.pactos()
	var info: Dictionary = ValidadorSealTuning.calcular_f3_f4_f5(s_fab, besta, 1, 1, 1)
	assert_float(float(info[&"g_vivo"])).is_equal_approx(15.60, 0.01)
	assert_float(float(info[&"g_real"])).is_equal_approx(15.60, 0.01)
	assert_float(float(info[&"t_entre_selos_s"])).is_equal_approx(2.56, 0.01)
	assert_float(float(info[&"a_ativos"])).is_equal_approx(1.30, 0.01)
	assert_int(int(info[&"terceiro_selo_passo"])).is_equal(77)
	assert_float(float(info[&"f_selo"])).is_equal_approx(0.162, 0.001)

	# Em grupo de 5 com a parcela autônoma da Maldição (16,20 DPS): 42,0% <= 0,45 (sem SV12)
	var info_grupo: Dictionary = ValidadorSealTuning.calcular_f3_f4_f5(s_fab, besta, 1, 0, 5, true)
	assert_float(float(info_grupo[&"f_selo"])).is_equal_approx(0.420, 0.002)
