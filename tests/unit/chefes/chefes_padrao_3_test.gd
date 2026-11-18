extends GdUnitTestSuite


func test_ac_ch_08_09_e_tr_017_padrao_3_convergencia_puxa_jogador_e_maldicao_e_invoca_lacaios_ate_teto() -> void:
	var amb := FixtureChefes.criar_ambiente(&"pactos", Vector2(960.0, 585.0), true)
	var est := amb.ia.estado_de(amb.id_chefe)
	est.estado_chefe.padrao = 3

	# Jogador a 300 px (dentro do raio_puxao_px) e Maldição a 320 px (ambos serão puxados 75 px rumo ao chefe)
	amb.ctx_ia.maldicao.id_campo = 10
	amb.ctx_ia.maldicao.pos = Vector2(960.0, 605.0)
	amb.ctx_ia.maldicao.raio = 24.0

	amb.avancar_passo()
	var passos_prep := est.timer
	for _i in range(passos_prep):
		amb.avancar_passo()

	# Verifica que tanto o jogador quanto a Maldição receberam deslocamento de puxão de 75 px para cima (rumo a y=285)
	assert_int(amb.ctx_ia.deslocamentos.deslocamentos_jogador.size()).is_equal(1)
	assert_int(amb.ctx_ia.deslocamentos.deslocamentos_maldicao.size()).is_equal(1)
	assert_float(amb.ctx_ia.deslocamentos.deslocamentos_jogador[0].length()).is_equal_approx(75.0, 0.01)
	assert_float(amb.ctx_ia.deslocamentos.deslocamentos_maldicao[0].length()).is_equal_approx(75.0, 0.01)

	# Verifica que 2 lacaios (Eco Perdido) foram invocados nas posições laterais (-135 px e +135 px)
	assert_int(amb.ia.contar_lacaios_vivos()).is_equal(2)

	# TR-chefes-017: uma segunda Convergência respeita max_lacaios_vivos (3 no tuning de fábrica: só mais 1 vaga)
	est.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	est.estado_chefe.padrao = 3
	est.timer = 1
	amb.avancar_passo()
	var prep_2 := est.timer
	for _i in range(prep_2):
		amb.avancar_passo()
	assert_int(amb.ia.contar_lacaios_vivos()).is_equal(amb.ia.chefes_tuning().max_lacaios_vivos)
