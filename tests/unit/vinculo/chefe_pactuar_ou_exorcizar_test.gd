extends GdUnitTestSuite
## Story vinculo-e-pactos/008: Chefe subjugado — Pactuar ou Exorcizar (V18, V18.5).
## Cobre AC-VP-22 e AC-VP-23.


func test_ac_vp_22_pactuar_soberano_nao_pactuado() -> void:
	var eventos := EventosDoPasso.new()
	var p := PerfilVinculo.new()
	var v := Vinculo.new(p, FabricasDeCatalogo.vinculo_tuning(), eventos)
	v.pedir_dupla(&"pactos")
	v.ao_chefe_subjugado(&"soberano_do_limiar")

	var res := v.escolher_destino_chefe(&"pactuar", &"soberano_do_limiar")
	assert_bool(res.pacto_novo).is_true()
	var est := p.estado_de(&"soberano_do_limiar")
	assert_bool(est.pactuada).is_true()
	assert_int(est.nivel).is_equal(1)
	assert_int(est.encontros_bem_sucedidos).is_equal(1)

	var ev_esc := eventos.do_tipo(&"chefe_escolhido")
	assert_int(ev_esc.size()).is_equal(1)
	assert_str(String((ev_esc[0] as EventosVinculo.EvChefeEscolhido).escolha)).is_equal("pactuar")


func test_ac_vp_23_fardo_repartido_soberano_no_nivel_5_transfere_pontos_para_dupla_e_fora_da_dupla() -> void:
	var vt := FabricasDeCatalogo.vinculo_tuning()
	var p := PerfilVinculo.new([], vt)
	p.primeiro_pacto_concedido = true
	for id: StringName in [&"vulto_mudo", &"espreitador_da_fenda", &"baluarte_de_cinza", &"soberano_do_limiar"]:
		p.registrar_pacto_novo(id)

	# Vulto nível 2 (25 pts), Espreitador nível 5 (140 pts), Baluarte nível 1 (0 pts), Soberano nível 5 (140 pts)
	p.somar_pontos_e_recalcular(&"vulto_mudo", 25)
	p.somar_pontos_e_recalcular(&"espreitador_da_fenda", 140)
	p.somar_pontos_e_recalcular(&"soberano_do_limiar", 140)
	assert_int(p.estado_de(&"vulto_mudo").nivel).is_equal(2)
	assert_int(p.estado_de(&"espreitador_da_fenda").nivel).is_equal(5)
	assert_int(p.estado_de(&"baluarte_de_cinza").nivel).is_equal(1)
	assert_int(p.estado_de(&"soberano_do_limiar").nivel).is_equal(5)

	var v := Vinculo.new(p, vt)
	v.pedir_dupla(&"pactos")
	assert_bool(v.confirmar_dupla(&"vulto_mudo", &"espreitador_da_fenda")).is_true()
	v.ao_chefe_subjugado(&"soberano_do_limiar")

	# Escolhe Pactuar: Vulto ganha +10 e os +10 do Espreitador (nível 5) vão para o Baluarte (menor nível fora da dupla)!
	var res := v.escolher_destino_chefe(&"pactuar", &"soberano_do_limiar")
	assert_int(int(res.pontos_por_especie.get(&"vulto_mudo", 0))).is_equal(10)
	assert_int(int(res.pontos_por_especie.get(&"baluarte_de_cinza", 0))).is_equal(10)
	assert_int(v.pontos_da_run(&"vulto_mudo")).is_equal(10)
	assert_int(v.pontos_da_run(&"baluarte_de_cinza")).is_equal(10)
