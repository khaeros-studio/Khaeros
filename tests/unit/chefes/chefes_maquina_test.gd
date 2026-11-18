extends GdUnitTestSuite


func test_ac_ch_01_10_13_surgimento_700_hp_4_pilares_e_rotacao_deterministica_0_1_2_3_sem_rng() -> void:
	var amb := FixtureChefes.criar_ambiente(&"lamina", Vector2(960.0, 400.0), false)
	var est := amb.ia.estado_de(amb.id_chefe)

	# AC-CH-01: Vida 700, posição inicial (960, 285), 4 pilares de 51 px configurados
	assert_float(est.vida_max).is_equal_approx(700.0, 0.01)
	assert_float(est.posicao.x).is_equal_approx(960.0, 0.01)
	assert_float(est.posicao.y).is_equal_approx(285.0, 0.01)
	assert_int(amb.camaras_spy.pilares_configurados.size()).is_equal(4)
	assert_float(amb.camaras_spy.raio_pilar_configurado).is_equal_approx(51.0, 0.01)

	# 50 passos de SURGINDO -> entra em APROXIMACAO com timer 30 e padrão 0
	for _i in range(50):
		amb.ia.passo(amb.id_chefe)
	assert_int(int(est.fase)).is_equal(int(EstadoDeInimigoIA.Fase.APROXIMACAO))
	assert_int(est.timer).is_equal(30)
	assert_int(est.estado_chefe.padrao).is_equal(0)

	# Coloca o jogador perto para engajar P0, P1, P2, P3 em sequência e verifica rotação (0 -> 1 -> 2 -> 3 -> 0)
	amb.ia.definir_jogador(0, Vector2(960.0, 350.0), 27.0)
	var padroes_vistos: Array[int] = []
	for _ciclo in range(4):
		var pad_atual := est.estado_chefe.padrao
		padroes_vistos.append(pad_atual)
		# Avança até entrar em PREPARO e depois concluir EXECUCAO e entrar em RECUPERACAO
		var seguranca := 0
		while est.fase != EstadoDeInimigoIA.Fase.RECUPERACAO and seguranca < 200:
			amb.ia.definir_jogador(0, est.posicao + Vector2(0.0, 80.0), 27.0)
			amb.avancar_passo()
			seguranca += 1
		# Remove lacaios invocados pelo Padrão 3 para isolar a medição de RNG do chefe
		amb.ia.limpar_lacaios_invocados()
		# Avança o tempo de RECUPERACAO até voltar a APROXIMACAO
		while est.fase == EstadoDeInimigoIA.Fase.RECUPERACAO and seguranca < 400:
			amb.avancar_passo()
			seguranca += 1

	assert_array(padroes_vistos).is_equal([0, 1, 2, 3])
	assert_int(est.estado_chefe.padrao).is_equal(0)
	# AC-CH-13: 0 chamadas ao fluxo RNG da IA durante toda a rotação
	assert_int(amb.ctx_ia.fluxo_ia.chamadas_inteiro).is_equal(0)
	assert_int(amb.ctx_ia.fluxo_ia.chamadas_real).is_equal(0)
