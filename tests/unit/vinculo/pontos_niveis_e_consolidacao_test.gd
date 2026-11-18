extends GdUnitTestSuite
## Story vinculo-e-pactos/007: Pontos e níveis (F3), consolidação no fim da run, abandono e bônus de nível (F4).
## Cobre AC-VP-16, AC-VP-17, AC-VP-18, AC-VP-19 e AC-VP-20.


func test_ac_vp_16_e_17_calculo_de_pontos_run_tetos_e_subida_de_nivel() -> void:
	var vt := FabricasDeCatalogo.vinculo_tuning()
	var acum := PontosDeVinculo.AcumuladorDaRun.new(&"vulto_mudo")
	# 6 câmaras com acerto (6*2=12), 15 abates (teto 12 -> 12), 7 técnicas (teto 6 -> 6), vitória (8) -> 38
	for _c in 6:
		acum.registrar_acerto_na_camara()
		acum.ao_limpar_camara_combate_ou_chefe()
	for _a in 15:
		acum.registrar_abate()
	for _t in 7:
		acum.registrar_tecnica_com_acerto()
	acum.registrar_vitoria()
	assert_int(PontosDeVinculo.calcular_pontos_run(acum, vt)).is_equal(38)

	# AC-VP-17: vinculo_pontos = 19 (nível 1), soma 31 -> 50 -> nível 3
	var p := PerfilVinculo.new([], vt)
	p.registrar_pacto_novo(&"vulto_mudo")
	p.estado_de(&"vulto_mudo").vinculo_pontos = 19
	assert_int(PontosDeVinculo.calcular_nivel(true, 19, vt)).is_equal(1)
	assert_bool(p.somar_pontos_e_recalcular(&"vulto_mudo", 31)).is_true()
	assert_int(p.estado_de(&"vulto_mudo").vinculo_pontos).is_equal(50)
	assert_int(p.estado_de(&"vulto_mudo").nivel).is_equal(3)


func test_ac_vp_18_e_19_consolidacao_na_morte_e_no_abandono_em_aguardando() -> void:
	var vt := FabricasDeCatalogo.vinculo_tuning()
	var p := PerfilVinculo.new([], vt)
	var v := Vinculo.new(p, vt)
	v.pedir_dupla(&"pactos")

	# AC-VP-18: pontos_run = 15 e morte -> soma 15 e runs_pactos_iniciadas += 1
	v.adicionar_pontos_diretos_na_run(&"vulto_mudo", 15)
	v.consolidar_run(&"morte", false)
	assert_int(p.estado_de(&"vulto_mudo").vinculo_pontos).is_equal(15)
	assert_int(p.runs_pactos_iniciadas).is_equal(1)

	# AC-VP-19: nova run com pontos_run = 9 e encontro em Aguardando -> sair pelo menu soma 9 e grava encontro_pendente
	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte.iniciar_run(0x55556666, true)
	v.planejar_encontro(&"pactos", FluxosDeVinculo.new(fonte).pactos(0))
	v.ao_montar_camara(1, [])
	v.ao_camara_limpa(1, &"combate") # acuada viva -> AGUARDANDO (soma +0 de câmara pois não registramos acerto)
	v.adicionar_pontos_diretos_na_run(&"vulto_mudo", 9)

	v.consolidar_abandono()
	assert_int(p.estado_de(&"vulto_mudo").vinculo_pontos).is_equal(24) # 15 + 9
	assert_array(p.encontro_pendente).is_equal(["espreitador_da_fenda"])


func test_ac_vp_20_bonus_de_nivel_5_baluarte_de_cinza() -> void:
	var vt := FabricasDeCatalogo.vinculo_tuning()
	var mt := FabricasDeCatalogo.maldicoes_tuning()
	var bal := FabricasDeCatalogo.maldicao(&"baluarte_de_cinza", &"raro")

	var info := PontosDeVinculo.calcular_bonus_nivel(bal, 5, vt, mt)
	assert_int(int(info[&"vida_max"])).is_equal(142)
	assert_int(int(info[&"passos_exausta"])).is_equal(540)
	assert_float(float(info[&"dano_basico"])).is_equal_approx(13.23, 1e-5)
	assert_float(float(info[&"dano_saida"])).is_equal_approx(5.0, 1e-5)
	assert_float(float(info[&"dano_entrada"])).is_equal_approx(7.0, 1e-5)
	assert_float(float(info[&"recarga_troca_s"])).is_equal_approx(4.0, 1e-5)
