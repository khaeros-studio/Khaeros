extends GdUnitTestSuite


func test_ac_ml_10_ferir_maldicao_aplica_reducao_de_dano_sem_afetar_jogador_e_ignora_saltando() -> void:
	# Baluarte tem passiva carapaca_ancorada (+15% redução de dano): dano 20 -> round(20 * 0.85) = 17
	var amb := FixtureMaldicoes.criar_ambiente(&"baluarte_de_cinza", &"vulto_mudo")
	var id_m: int = amb.modulo.maldicao_em_campo(0)
	var vida_jog_antes := amb.combate_aliado.vida_jogador

	var dano_aplicado := amb.modulo.ferir_maldicao(id_m, 20.0, 1.0)
	assert_int(dano_aplicado).is_equal(17)
	assert_int(amb.modulo.estado_pacto(0).campo.vida).is_equal(140 - 17)
	assert_int(amb.combate_aliado.vida_jogador).is_equal(vida_jog_antes)

	# Durante o salto do Chamado (estado SALTANDO), maldicao_atingivel é false e ferir_maldicao retorna 0
	amb.modulo.pedir_chamado(0, Vector2(600.0, 400.0), 17.0, 1.0)
	amb.avancar_passo(false)
	assert_int(amb.modulo.ferir_maldicao(id_m, 50.0, 1.0)).is_equal(0)


func test_ac_ml_11_exaustao_com_reserva_pronta_troca_automaticamente_no_mesmo_passo_sem_tecnica() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"espreitador_da_fenda")
	var id_vulto: int = amb.modulo.maldicao_em_campo(0)
	FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(440.0, 505.0), 300.0)

	amb.modulo.ferir_maldicao(id_vulto, 200.0, 1.0)

	var est: EstadoPactoLeitura = amb.modulo.estado_pacto(0)
	assert_str(String(est.campo.especie_id)).is_equal("espreitador_da_fenda")
	assert_str(String(est.reserva.especie_id)).is_equal("vulto_mudo")
	assert_str(String(est.reserva.estado)).is_equal("Exausta")
	assert_int(est.reserva.restante_exausta).is_equal(600)
	assert_int(est.recarga_troca_passos).is_equal(0)

	var evs_ex := amb.eventos.filtrar(EventosMaldicoes.EvMaldicaoExausta.TIPO)
	assert_int(evs_ex.size()).is_equal(1)
	var evs_tr := amb.eventos.filtrar(EventosMaldicoes.EvMaldicaoTrocada.TIPO)
	assert_int(evs_tr.size()).is_equal(1)
	assert_str(String((evs_tr[0] as EventosMaldicoes.EvMaldicaoTrocada).modo)).is_equal("automatica")
	# Troca automática por Exaustão não dispara Técnica Combinada
	assert_int(amb.eventos.filtrar(EventosMaldicoes.EvTecnicaCombinada.TIPO).size()).is_equal(0)


func test_ac_ml_12_exaustao_sem_reserva_disponivel_deixa_campo_vazio_e_reentra_apos_prazo() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"")
	var id_vulto: int = amb.modulo.maldicao_em_campo(0)
	amb.modulo.ferir_maldicao(id_vulto, 200.0, 1.0)

	assert_int(amb.modulo.maldicao_em_campo(0)).is_equal(-1)
	assert_object(amb.modulo.estado_pacto(0).campo).is_null()
	assert_str(String(amb.modulo.estado_pacto(0).reserva.estado)).is_equal("Exausta")

	for _i in range(599):
		amb.avancar_passo(false)
	assert_int(amb.modulo.maldicao_em_campo(0)).is_equal(-1)

	# No passo 600, volta a Pronta com 50% da Vida (55 PV) e reentra em campo no sub-passo 3
	amb.avancar_passo(false)
	assert_int(amb.modulo.maldicao_em_campo(0)).is_equal(id_vulto)
	assert_int(amb.modulo.estado_pacto(0).campo.vida).is_equal(55)
	assert_int(amb.eventos.filtrar(EventosMaldicoes.EvMaldicaoEntrou.TIPO).size()).is_equal(1)


func test_ac_ml_13_soberano_do_limiar_reduz_exaustao_em_20_porcento_480_e_432_com_vinculo_3() -> void:
	var amb_n1 := FixtureMaldicoes.criar_ambiente(&"soberano_do_limiar", &"vulto_mudo")
	var id_sob_1: int = amb_n1.modulo.maldicao_em_campo(0)
	amb_n1.modulo.ferir_maldicao(id_sob_1, 300.0, 1.0)
	assert_int(amb_n1.modulo.estado_pacto(0).reserva.restante_exausta).is_equal(480)

	var amb_n3 := FixtureMaldicoes.criar_ambiente(
		&"soberano_do_limiar",
		&"vulto_mudo",
		null,
		{&"soberano_do_limiar": 3}
	)
	var id_sob_3: int = amb_n3.modulo.maldicao_em_campo(0)
	amb_n3.modulo.ferir_maldicao(id_sob_3, 300.0, 1.0)
	assert_int(amb_n3.modulo.estado_pacto(0).reserva.restante_exausta).is_equal(432)


func test_ac_ml_30_exaustao_sincrona_encerra_atracao_e_abre_respiro_na_ia_no_mesmo_passo() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"espreitador_da_fenda")
	var id_vulto: int = amb.modulo.maldicao_em_campo(0)
	var id_in := FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(450.0, 450.0), 300.0)

	assert_bool(amb.ia.atrair(id_in, 90, 30, 0)).is_true()
	assert_bool(amb.ia.esta_atraido(id_in)).is_true()

	amb.modulo.ferir_maldicao(id_vulto, 250.0, 1.0)

	# No mesmo passo da Exaustão, a IA zera restante_atracao e abre o respiro de 30 passos
	assert_bool(amb.ia.esta_atraido(id_in)).is_false()
	assert_int(amb.ia.estado_de(id_in).restante_respiro).is_equal(30)
