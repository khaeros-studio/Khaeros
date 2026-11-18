extends GdUnitTestSuite
## Story ia-003: Ranged e charger, e o retângulo visível (AC-IA-03, AC-IA-04, AC-IA-08, AC-IA-09, AC-IA-19, AC-IA-22, AC-IA-28).


func test_ac_ia_03_08_19_28_ranged_anomalia_recuo_contorno_vista_e_disparo() -> void:
	var ctx := FixtureIA.ContextoTeste.new(Rect2(Vector2(-1000.0, -1000.0), Vector2(2000.0, 2000.0)))
	ctx.ia.definir_jogador(0, Vector2.ZERO)
	var anom := FixtureTelegrafos.anomalia_menor() # 117 px/s = 1.95 px/passo
	var id1 := ctx.ia.criar_inimigo(anom, Vector2(300.0, 0.0))
	var e := ctx.ia.estado_de(id1)
	e.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	e.timer = 10

	# A 300 px (< 345): recua 1.95 px/passo -> 301.95
	ctx.ia.passo(id1)
	assert_float(e.posicao.x).is_equal_approx(301.95, 1e-4)

	# A 450 px (entre 345 e 570): contorna perpendicularmente a 0.975 px/passo
	e.posicao = Vector2(450.0, 0.0)
	ctx.ia.passo(id1)
	assert_float(e.posicao.x).is_equal_approx(450.0, 1e-4)
	assert_float(absf(e.posicao.y)).is_equal_approx(0.975, 1e-4)

	# AC-IA-19 e AC-IA-28: fora da vista e a 300 px com timer <= 0 -> avança rumo ao jogador (não recua e não prepara)
	ctx.vista.retangulo = Rect2(Vector2(-100.0, -100.0), Vector2(350.0, 200.0)) # x vai de -100 a +250
	e.posicao = Vector2(300.0, 0.0)
	e.timer = 0
	ctx.ia.passo(id1)
	assert_float(e.posicao.x).is_equal_approx(300.0 - 1.95, 1e-4)
	assert_int(int(e.fase)).is_equal(int(EstadoDeInimigoIA.Fase.APROXIMACAO))

	# Quando entra na vista (ou com margem_visivel_px = 100), inicia o preparo e dispara no 36º passo
	ctx.ia.tuning().margem_visivel_px = 100.0
	ctx.ia.passo(id1)
	assert_int(int(e.fase)).is_equal(int(EstadoDeInimigoIA.Fase.PREPARO))
	for p in 36:
		ctx.ia.executar_item_7()
	assert_int(ctx.combate.projeteis_disparados.size()).is_equal(1)
	assert_int(int(e.fase)).is_equal(int(EstadoDeInimigoIA.Fase.EXECUCAO))
	assert_int(e.timer).is_equal(6)


func test_ac_ia_04_09_22_charger_fenda_avanco_ignora_selo_e_cambaleio_e_fere_1x() -> void:
	var ctx := FixtureIA.ContextoTeste.new()
	ctx.ia.definir_jogador(0, Vector2.ZERO, 27.0)
	var fenda := FixtureTelegrafos.fenda_errante() # 126 px/s = 2.1 px/passo; avanço = 7.56 px/passo
	var id1 := ctx.ia.criar_inimigo(fenda, Vector2(500.0, 0.0))
	var e := ctx.ia.estado_de(id1)
	e.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	e.timer = 10

	# A 500 px (> 456): avança 2.1 px/passo
	ctx.ia.passo(id1)
	assert_float(e.posicao.x).is_equal_approx(497.9, 1e-4)

	# A 400 px (<= 456) com timer > 0: fica parada
	e.posicao = Vector2(400.0, 0.0)
	ctx.ia.passo(id1)
	assert_float(e.posicao.x).is_equal_approx(400.0, 1e-4)

	# A 120 px (<= 570) com timer <= 0: inicia preparo (42 passos)
	e.posicao = Vector2(120.0, 0.0)
	e.timer = 0
	ctx.ia.passo(id1)
	assert_int(int(e.fase)).is_equal(int(EstadoDeInimigoIA.Fase.PREPARO))

	# Liga Selo e cambaleio: o avanço deve ignorar ambos e andar 7.56 px/passo por 26 passos (196.56 px), ferindo 1x
	e.ref.no_selo = true
	e.ref.impacto_passos = 10
	for p in 42:
		ctx.ia.executar_item_7()
	# O 42º passo já executou o 1º passo do avanço; faltam 25 passos
	for p in 25:
		ctx.ia.executar_item_7()
	assert_float(e.posicao.x).is_equal_approx(120.0 - 196.56, 0.1)
	assert_int(ctx.combate.danos_jogador.size()).is_equal(1)
	assert_float(float(ctx.combate.danos_jogador[0]["dano"])).is_equal_approx(13.0, 1e-5)

	# AC-IA-22: ciclos mínimos (Eco 96, Anomalia 142, Fenda 158)
	assert_int(ValidadorIA.ciclo_minimo_passos(FixtureTelegrafos.eco_perdido())).is_equal(96)
	assert_int(ValidadorIA.ciclo_minimo_passos(FixtureTelegrafos.anomalia_menor())).is_equal(142)
	assert_int(ValidadorIA.ciclo_minimo_passos(fenda)).is_equal(158)
