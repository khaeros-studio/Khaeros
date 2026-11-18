extends GdUnitTestSuite
## Story ia-002: Máquina de fases, surgimento e comportamento melee (AC-IA-01, AC-IA-02, AC-IA-05, AC-IA-06, AC-IA-07, AC-IA-10, AC-IA-22).


func test_ac_ia_01_surgindo_dura_50_passos_e_sorteia_espera_inicial() -> void:
	var ctx := FixtureIA.ContextoTeste.new()
	ctx.fluxo_ia.inteiros_fila.append(15) # 20 + 15 = 35
	var id1 := ctx.ia.criar_inimigo(FixtureTelegrafos.eco_perdido(), Vector2(400.0, 0.0))
	assert_bool(ctx.ia.atingivel(id1)).is_false()
	for p in 49:
		ctx.ia.passo(id1)
		assert_bool(ctx.ia.atingivel(id1)).is_false()
	ctx.ia.passo(id1)
	assert_bool(ctx.ia.atingivel(id1)).is_true()
	assert_int(int(ctx.ia.estado_de(id1).fase)).is_equal(int(EstadoDeInimigoIA.Fase.APROXIMACAO))
	assert_int(ctx.ia.estado_de(id1).timer).is_equal(35)


func test_ac_ia_02_05_07_10_ciclo_completo_melee_do_eco() -> void:
	var ctx := FixtureIA.ContextoTeste.new()
	ctx.ia.definir_jogador(0, Vector2.ZERO, 27.0)
	ctx.fluxo_ia.inteiros_fila.append(5) # fim da recuperação: 10 + 5 = 15
	var id1 := ctx.ia.criar_inimigo(FixtureTelegrafos.eco_perdido(), Vector2(79.0 + 2.55, 0.0))
	var e := ctx.ia.estado_de(id1)
	e.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	e.timer = 1

	# Anda 2,55 px -> fica a 79 px (> 78 px): ainda não entra em preparo
	ctx.ia.executar_item_7()
	assert_float(e.posicao.x).is_equal_approx(79.0, 1e-4)
	assert_int(int(e.fase)).is_equal(int(EstadoDeInimigoIA.Fase.APROXIMACAO))

	# No passo seguinte anda para 76.45 (<= 78 px) e timer <= 0 -> entra em PREPARO (26 passos)
	ctx.ia.executar_item_7()
	assert_int(int(e.fase)).is_equal(int(EstadoDeInimigoIA.Fase.PREPARO))
	assert_int(ctx.telegrafos.ativos()).is_equal(1)
	var pos_prep := e.posicao

	# 26 passos de preparo parado; no 26º dispara e fere o jogador (9 de dano), entrando em EXECUCAO (10)
	for p in 26:
		ctx.ia.executar_item_7()
	assert_vector(e.posicao).is_equal_approx(pos_prep, Vector2(1e-5, 1e-5))
	assert_int(ctx.combate.danos_jogador.size()).is_equal(1)
	assert_float(float(ctx.combate.danos_jogador[0]["dano"])).is_equal_approx(9.0, 1e-5)
	assert_int(int(e.fase)).is_equal(int(EstadoDeInimigoIA.Fase.EXECUCAO))
	assert_int(e.timer).is_equal(10)

	# 10 passos de execução parado -> entra em RECUPERACAO (50 passos)
	for p in 10:
		ctx.ia.executar_item_7()
	assert_int(int(e.fase)).is_equal(int(EstadoDeInimigoIA.Fase.RECUPERACAO))
	assert_int(e.timer).is_equal(50)

	# Se distância > 90 px na recuperação, anda 1.02 px/passo (0.4 * 2.55)
	e.posicao = Vector2(200.0, 0.0)
	ctx.ia.executar_item_7()
	assert_float(e.posicao.x).is_equal_approx(200.0 - 1.02, 1e-4)


func test_ac_ia_06_teto_de_24_telegrafos_mantem_em_aproximacao_e_tenta_no_seguinte() -> void:
	var ctx := FixtureIA.ContextoTeste.new()
	var eco := FixtureTelegrafos.eco_perdido()
	for k in 24:
		var idk := ctx.ia.criar_inimigo(eco, Vector2(float(k + 1) * 100.0, 500.0))
		ctx.ia.estado_de(idk).fase = EstadoDeInimigoIA.Fase.APROXIMACAO
		ctx.telegrafos.iniciar_telegrafo(idk, eco)
	assert_int(ctx.telegrafos.ativos()).is_equal(24)

	var id25 := ctx.ia.criar_inimigo(eco, Vector2(60.0, 0.0))
	var e25 := ctx.ia.estado_de(id25)
	e25.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	e25.timer = 0
	ctx.ia.passo(id25)
	assert_int(int(e25.fase)).is_equal(int(EstadoDeInimigoIA.Fase.APROXIMACAO))

	# Libera uma vaga e tenta no passo seguinte
	ctx.telegrafos.cancelar_todos()
	ctx.ia.passo(id25)
	assert_int(int(e25.fase)).is_equal(int(EstadoDeInimigoIA.Fase.PREPARO))
