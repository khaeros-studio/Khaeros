extends GdUnitTestSuite


func test_ac_ch_21_22_26_soberano_padrao_passa_sem_erros_nem_avisos_ch1_a_ch8() -> void:
	var chefe := CatalogoChefes.criar_soberano_do_limiar()
	var tuning := CatalogoChefes.criar_chefes_tuning_padrao()
	var diags := ValidacaoChefes.validar_padroes_direto(chefe, tuning)
	assert_int(diags.size()).is_equal(0)


func test_ac_ch_21_ch1_ch2_ch3_rejeitam_padroes_invalidos_e_tuning_quebrado() -> void:
	var chefe_ch1 := CatalogoChefes.criar_soberano_do_limiar()
	chefe_ch1.padroes.pop_back()
	var diags_ch1 := ValidacaoChefes.validar_padroes_direto(chefe_ch1, CatalogoChefes.criar_chefes_tuning_padrao())
	assert_bool(diags_ch1.map(func(d: Diagnostico) -> StringName: return d.regra).has(&"CH1")).is_true()

	var tuning_ch2 := CatalogoChefes.criar_chefes_tuning_padrao()
	tuning_ch2.limiar_furia_frac = 0.95
	var diags_ch2 := ValidacaoChefes.validar_padroes_direto(CatalogoChefes.criar_soberano_do_limiar(), tuning_ch2)
	assert_bool(diags_ch2.map(func(d: Diagnostico) -> StringName: return d.regra).has(&"CH2")).is_true()

	var tuning_ch3 := CatalogoChefes.criar_chefes_tuning_padrao()
	tuning_ch3.lacaios_por_convergencia = 5
	tuning_ch3.max_lacaios_vivos = 2
	var diags_ch3 := ValidacaoChefes.validar_padroes_direto(CatalogoChefes.criar_soberano_do_limiar(), tuning_ch3)
	assert_bool(diags_ch3.map(func(d: Diagnostico) -> StringName: return d.regra).has(&"CH3")).is_true()


func test_ac_ch_22_e_26_avisos_ch4_ch5_ch6_ch7_ch8_em_dados_fora_de_faixa() -> void:
	var chefe := CatalogoChefes.criar_soberano_do_limiar()
	chefe.padroes[0].preparo_s = 0.20 # < 23 passos -> CH4
	chefe.padroes[0].dano = 50.0 # arma de 80 HP morre em 2 golpes -> CH5
	chefe.padroes[3].raio_secundario_px = 100.0 # != raio_puxao_px -> CH8

	var tuning := CatalogoChefes.criar_chefes_tuning_padrao()
	tuning.max_lacaios_vivos = 10 # > max_onda -> CH6 e CH7
	var diags := ValidacaoChefes.validar_padroes_direto(chefe, tuning, true, [80], 40, 6)
	var cods := diags.map(func(d: Diagnostico) -> StringName: return d.regra)
	for regra_esp: StringName in [&"CH4", &"CH5", &"CH6", &"CH7", &"CH8"]:
		assert_bool(cods.has(regra_esp)).is_true()
