extends GdUnitTestSuite


func test_ac_ml_15_troca_manual_dispara_saida_e_entrada_com_sinergia_f5_e_recarga_240() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"espreitador_da_fenda")
	var m_vulto: MaldicaoRef = amb.modulo.ref_de(1)
	m_vulto.pos = Vector2(400.0, 400.0)
	var id_in := FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(430.0, 400.0), 500.0)

	amb.r_troca = true
	amb.avancar_passo(false)

	var est: EstadoPactoLeitura = amb.modulo.estado_pacto(0)
	assert_str(String(est.campo.especie_id)).is_equal("espreitador_da_fenda")
	assert_str(String(est.reserva.especie_id)).is_equal("vulto_mudo")
	assert_int(est.recarga_troca_passos).is_equal(240)

	# 2 golpes no passo da troca: Saída do Vulto (5 de dano + imobiliza) e Entrada do Espreitador com sinergia +50% (6 * 1.5 = 9 de dano)
	assert_int(amb.combate_aliado.golpes_registrados.size()).is_equal(2)
	assert_int(int(amb.combate_aliado.golpes_registrados[0]["dano_int"])).is_equal(5)
	assert_int(int(amb.combate_aliado.golpes_registrados[1]["dano_int"])).is_equal(9)
	assert_bool(amb.ia.esta_imobilizado(id_in)).is_true()

	var evs_comb: Array = amb.eventos.filtrar(EventosMaldicoes.EvTecnicaCombinada.TIPO)
	assert_int(evs_comb.size()).is_equal(1)
	var ev_tc := evs_comb[0] as EventosMaldicoes.EvTecnicaCombinada
	assert_str(String(ev_tc.saida_id)).is_equal("paredes_de_sombra")
	assert_str(String(ev_tc.entrada_id)).is_equal("salto_de_emboscada")


func test_ac_ml_16_troca_recusada_em_recarga_ou_reserva_exausta() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"espreitador_da_fenda")
	var m_res: MaldicaoRef = amb.modulo.ref_de(2)
	m_res.estado = MaldicaoRef.Estado.EXAUSTA
	m_res.restante_exausta = 300

	amb.r_troca = true
	amb.avancar_passo(false)

	assert_str(String(amb.modulo.estado_pacto(0).campo.especie_id)).is_equal("vulto_mudo")
	var evs_rec: Array = amb.eventos.filtrar(EventosMaldicoes.EvTrocaIndisponivel.TIPO)
	assert_int(evs_rec.size()).is_equal(1)
	assert_str(String((evs_rec[0] as EventosMaldicoes.EvTrocaIndisponivel).motivo)).is_equal("reserva_exausta")


func test_matriz_12_pares_de_tecnica_combinada_disparam_saida_e_entrada_corretas() -> void:
	var pares: Array[Dictionary] = [
		{"s": &"vulto_mudo", "e": &"espreitador_da_fenda", "saida": &"paredes_de_sombra", "entrada": &"salto_de_emboscada", "dano_total": 14},
		{"s": &"vulto_mudo", "e": &"baluarte_de_cinza", "saida": &"paredes_de_sombra", "entrada": &"queda_de_pilar", "dano_total": 12},
		{"s": &"vulto_mudo", "e": &"soberano_do_limiar", "saida": &"paredes_de_sombra", "entrada": &"irrupcao_primordial", "dano_total": 14},
		{"s": &"espreitador_da_fenda", "e": &"vulto_mudo", "saida": &"rastro_cortante", "entrada": &"passo_raso", "dano_total": 12},
		{"s": &"espreitador_da_fenda", "e": &"baluarte_de_cinza", "saida": &"rastro_cortante", "entrada": &"queda_de_pilar", "dano_total": 12},
		{"s": &"espreitador_da_fenda", "e": &"soberano_do_limiar", "saida": &"rastro_cortante", "entrada": &"irrupcao_primordial", "dano_total": 14},
		{"s": &"baluarte_de_cinza", "e": &"vulto_mudo", "saida": &"cratera_de_cinza", "entrada": &"passo_raso", "dano_total": 12},
		{"s": &"baluarte_de_cinza", "e": &"espreitador_da_fenda", "saida": &"cratera_de_cinza", "entrada": &"salto_de_emboscada", "dano_total": 14},
		{"s": &"baluarte_de_cinza", "e": &"soberano_do_limiar", "saida": &"cratera_de_cinza", "entrada": &"irrupcao_primordial", "dano_total": 14},
		{"s": &"soberano_do_limiar", "e": &"vulto_mudo", "saida": &"fenda_retida", "entrada": &"passo_raso", "dano_total": 12},
		{"s": &"soberano_do_limiar", "e": &"espreitador_da_fenda", "saida": &"fenda_retida", "entrada": &"salto_de_emboscada", "dano_total": 14},
		{"s": &"soberano_do_limiar", "e": &"baluarte_de_cinza", "saida": &"fenda_retida", "entrada": &"queda_de_pilar", "dano_total": 12},
	]

	for par in pares:
		var amb := FixtureMaldicoes.criar_ambiente(par["s"], par["e"])
		var m_sai: MaldicaoRef = amb.modulo.ref_de(1)
		m_sai.pos = Vector2(400.0, 400.0)
		FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(420.0, 400.0), 600.0)

		amb.r_troca = true
		amb.avancar_passo(false)

		var evs: Array = amb.eventos.filtrar(EventosMaldicoes.EvTecnicaCombinada.TIPO)
		assert_int(evs.size()).is_equal(1)
		var tc := evs[0] as EventosMaldicoes.EvTecnicaCombinada
		assert_str(String(tc.saida_id)).is_equal(String(par["saida"]))
		assert_str(String(tc.entrada_id)).is_equal(String(par["entrada"]))

		var soma_dano := 0
		for g: Dictionary in amb.combate_aliado.golpes_registrados:
			soma_dano += int(g["dano_int"])
		assert_int(soma_dano).is_equal(int(par["dano_total"]))
