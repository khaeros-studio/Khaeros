extends GdUnitTestSuite
## Story run-e-regioes/003: Sequência da região — proxima(i), avancar(), p_max e múltiplas regiões.
## Cobre AC-RN-06, AC-RN-07, AC-RN-21, AC-RN-22 e AC-RN-30.


func test_ac_rn_06_07_30_proxima_camara_com_7_e_6_camaras_e_erro_rn3() -> void:
	var run := Run.new()
	assert_str(String(run.proxima(2))).is_equal("santuario")
	assert_str(String(run.proxima(3))).is_equal("combate")
	assert_str(String(run.proxima(4))).is_equal("combate")
	assert_str(String(run.proxima(5))).is_equal("chefe")
	assert_str(String(run.proxima(6))).is_equal("fim_da_run")

	assert_str(String(run.validar_montagem_camara(6))).is_equal("")
	assert_str(String(run.validar_montagem_camara(7))).is_equal("RN3")

	# Modo legado 6 câmaras (AC-RN-07):
	var rt6 := FabricasDeCatalogo.run_tuning()
	rt6.camaras_jogaveis[&"limiar"] = 6
	var run6 := Run.new(rt6)
	assert_str(String(run6.proxima(5))).is_equal("fim_da_run")
	assert_str(String(run6.validar_montagem_camara(6))).is_equal("RN3")


func test_ac_rn_21_p_max_lido_das_camaras() -> void:
	var run := Run.new()
	assert_int(run.p_max()).is_equal(4)

	var reg_curta := RegionDef.new()
	reg_curta.id = &"curta"
	reg_curta.camaras = [&"combate", &"santuario", &"combate", &"combate"] # 3 de combate -> p_max = 2
	var rt := RunTuning.new()
	rt.camaras_jogaveis = {&"curta": 4}
	var run_curta := Run.new(rt, reg_curta)
	assert_int(run_curta.p_max()).is_equal(2)


func test_ac_rn_22_multiplas_regioes_reservadas() -> void:
	var r0 := RegionDef.new()
	r0.id = &"limiar"
	r0.camaras = [&"combate", &"combate"]
	var r1 := RegionDef.new()
	r1.id = &"veio_instavel"
	r1.camaras = [&"combate", &"combate", &"combate"]
	var rt := RunTuning.new()
	rt.arma_padrao = &"lamina"
	rt.camaras_jogaveis = {&"limiar": 2, &"veio_instavel": 3}

	var run := Run.new(rt, r0)
	var lista_regioes: Array[RegionDef] = [r0, r1]
	run.definir_regioes(lista_regioes)
	run.iniciar_escolha_de_arma()
	run.confirmar_arma(&"lamina")

	assert_int(run.regiao_indice()).is_equal(0)
	assert_int(run.indice()).is_equal(0)
	assert_bool(run.avancar()).is_true()
	assert_int(run.indice()).is_equal(1)

	# Ao avançar depois da última câmara da região 0, entra na câmara 0 da região 1!
	assert_bool(run.avancar()).is_true()
	assert_int(run.regiao_indice()).is_equal(1)
	assert_int(run.indice()).is_equal(0)
	assert_str(String(run.regiao())).is_equal("veio_instavel")
