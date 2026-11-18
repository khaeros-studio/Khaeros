extends GdUnitTestSuite


func test_ac_ch_02_03_12_transicao_de_furia_em_350_hp_invulneravel_30_passos_pulso_repulsor_e_fase_2() -> void:
	var amb := FixtureChefes.criar_ambiente(&"lamina", Vector2(960.0, 400.0), true)
	var est := amb.ia.estado_de(amb.id_chefe)

	# AC-CH-02: Chefe é imune a imobilizar, puxar e pedir_recuperacao ("Quebrou!") e tem fator_empurrao = 0.12 (R1)
	assert_bool(amb.ia.imobilizar(amb.id_chefe, 90)).is_false()
	assert_bool(amb.ia.puxar(amb.id_chefe, Vector2.ZERO, 100.0, 30.0)).is_false()
	assert_bool(amb.ia.pedir_recuperacao(amb.id_chefe)).is_false()
	assert_float(est.fator_empurrao).is_equal_approx(0.12, 0.001)

	# Inicia preparo de P0 e sofre dano até 350 HP (50% de 700 HP): cancela telégrafo e entra em TRANSICAO_FASE por 30 passos
	amb.avancar_passo()
	assert_int(int(est.fase)).is_equal(int(EstadoDeInimigoIA.Fase.PREPARO))
	est.vida = 350.0
	amb.ia.notificar_dano_no_chefe(amb.id_chefe)

	assert_int(int(est.fase)).is_equal(int(EstadoDeInimigoIA.Fase.TRANSICAO_FASE))
	assert_int(est.timer).is_equal(30)
	assert_bool(amb.ia.invulneravel_por_fase(amb.id_chefe)).is_true()

	# Vista da barra mostra invulnerabilidade e entalhe rachado (CH-V2, CH-V3)
	var vb := amb.modulo.obter_vista_barra()
	assert_bool(vb.entalhe_furia_rachado).is_true()
	assert_bool(vb.invulneravel_transicao).is_true()
	assert_bool(vb.moldura_osso_claro_solido).is_true()
	assert_bool(vb.mostrar_fio_sob_pes).is_false()

	# No 1º passo da transição, aplica pulso repulsor de 120 px em quem está a < 240 px
	amb.avancar_passo()
	assert_int(amb.ctx_ia.deslocamentos.deslocamentos_jogador.size()).is_equal(1)
	assert_float(amb.ctx_ia.deslocamentos.deslocamentos_jogador[0].length()).is_equal_approx(120.0, 0.01)

	# Após os 29 passos restantes, entra em Fase 2 (em_furia = true, velocidade x1.15 e padrão avançado para 1)
	for _i in range(29):
		amb.avancar_passo()
	assert_bool(est.estado_chefe.em_furia).is_true()
	assert_int(est.estado_chefe.padrao).is_equal(1)
	assert_float(amb.ia.velocidade_andar_passo(est)).is_greater(est.velocidade_base / 60.0)


func test_ac_ch_14_dano_letal_direto_de_acima_de_350_para_zero_pula_transicao_de_furia() -> void:
	var amb := FixtureChefes.criar_ambiente(&"lamina", Vector2(960.0, 400.0), true)
	var est := amb.ia.estado_de(amb.id_chefe)
	est.vida = 0.0
	amb.ia.notificar_dano_no_chefe(amb.id_chefe)
	assert_int(int(est.fase)).is_not_equal(int(EstadoDeInimigoIA.Fase.TRANSICAO_FASE))
