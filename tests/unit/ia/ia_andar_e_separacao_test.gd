extends GdUnitTestSuite
## Story ia-004: Andar com Selo e cambaleio, conter e separação par a par (AC-IA-12, AC-IA-13, AC-IA-14).


func test_ac_ia_12_velocidade_de_andar_com_selo_e_cambaleio() -> void:
	var ctx := FixtureIA.ContextoTeste.new()
	var id1 := ctx.ia.criar_inimigo(FixtureTelegrafos.eco_perdido(), Vector2(300.0, 0.0))
	var e := ctx.ia.estado_de(id1)
	e.fase = EstadoDeInimigoIA.Fase.APROXIMACAO

	assert_float(ctx.ia.velocidade_andar_passo(e)).is_equal_approx(2.55, 1e-5)
	e.ref.no_selo = true
	assert_float(ctx.ia.velocidade_andar_passo(e)).is_equal_approx(1.275, 1e-5) # 76.5 px/s
	e.ref.no_selo = false
	e.ref.impacto_passos = 5
	assert_float(ctx.ia.velocidade_andar_passo(e)).is_equal_approx(1.02, 1e-5) # 61.2 px/s
	e.ref.no_selo = true
	assert_float(ctx.ia.velocidade_andar_passo(e)).is_equal_approx(0.51, 1e-5) # 30.6 px/s


func test_ac_ia_13_14_separacao_par_a_par_e_contencao_em_obstaculo_e_parede() -> void:
	var obs := [ObstaculoCircular.new(Vector2(500.0, 500.0), 50.0)] as Array[ObstaculoCircular]
	var ctx := FixtureIA.ContextoTeste.new(Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0)))
	ctx.ia.definir_geometria(GeometriaDeMovimento.new(Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0)), obs))

	var eco := FixtureTelegrafos.eco_perdido() # raio 24
	var id1 := ctx.ia.criar_inimigo(eco, Vector2(200.0, 200.0))
	var id2 := ctx.ia.criar_inimigo(eco, Vector2(220.0, 200.0)) # distância 20 px, soma raios 48 -> sobreposição 28
	ctx.ia.estado_de(id1).fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	ctx.ia.estado_de(id2).fase = EstadoDeInimigoIA.Fase.APROXIMACAO

	ctx.ia.fim_do_item_7()
	assert_float(ctx.ia.estado_de(id1).posicao.x).is_equal_approx(186.0, 1e-4) # -14 px
	assert_float(ctx.ia.estado_de(id2).posicao.x).is_equal_approx(234.0, 1e-4) # +14 px

	# AC-IA-14: corpo dentro de obstáculo ou além da parede volta ao limite
	var p_parede := ctx.ia.conter(Vector2(5.0, 200.0), 24.0)
	assert_float(p_parede.x).is_equal_approx(24.0, 1e-4)
	var p_obs := ctx.ia.conter(Vector2(510.0, 500.0), 24.0)
	assert_float(p_obs.x).is_equal_approx(574.0, 1e-4) # 500 + 50 + 24
