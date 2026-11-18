extends GdUnitTestSuite
## Story ia-007: Imobilizar, puxar (Convergência) e Maldição fora da separação (AC-IA-37..40, AC-IA-42, AC-IA-58 / TR-ia-019).


func test_ac_ia_37_38_39_40_imobilizar_comuns_imunes_e_separacao() -> void:
	var ctx := FixtureIA.ContextoTeste.new()
	ctx.ia.definir_jogador(0, Vector2.ZERO)
	ctx.maldicao.id_campo = 10
	var eco := FixtureTelegrafos.eco_perdido()

	var id_comum := ctx.ia.criar_inimigo(eco, Vector2(50.0, 0.0))
	var e := ctx.ia.estado_de(id_comum)
	e.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	e.timer = 0

	# AC-IA-37: imobilizar(eco, 90) em s -> parado s..s+89 sem preparo; em s+90 inicia preparo
	assert_bool(ctx.ia.imobilizar(id_comum, 90)).is_true()
	for p in 90:
		ctx.ia.passo(id_comum)
		assert_float(e.posicao.x).is_equal_approx(50.0, 1e-5)
		assert_int(int(e.fase)).is_equal(int(EstadoDeInimigoIA.Fase.APROXIMACAO))
	ctx.ia.passo(id_comum)
	assert_int(int(e.fase)).is_equal(int(EstadoDeInimigoIA.Fase.PREPARO))

	# AC-IA-38: imobilizar no meio do preparo não cancela o disparo no 26º passo
	assert_bool(ctx.ia.imobilizar(id_comum, 90)).is_true()
	for p in 26:
		ctx.ia.executar_item_7()
	assert_int(int(e.fase)).is_equal(int(EstadoDeInimigoIA.Fase.EXECUCAO))

	# AC-IA-39: elite e chefe recusam imobilizar, mas aceitam atrair
	var id_el := ctx.ia.criar_inimigo(eco, Vector2(200.0, 0.0), OpcoesDeNascimento.de_elite(-1, 3))
	ctx.ia.estado_de(id_el).fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	assert_bool(ctx.ia.imobilizar(id_el, 90)).is_false()
	assert_bool(ctx.ia.esta_imobilizado(id_el)).is_false()
	assert_bool(ctx.ia.atrair(id_el, 90, 30)).is_true()


func test_ac_ia_42_58_maldicao_fora_da_separacao_e_pedido_puxar_tr_ia_019() -> void:
	var ctx := FixtureIA.ContextoTeste.new(Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0)))
	var eco := FixtureTelegrafos.eco_perdido()

	# AC-IA-42: Maldição sobreposta a um Eco não é separada pela IA
	ctx.maldicao.id_campo = 10
	ctx.maldicao.pos = Vector2(200.0, 200.0)
	var id1 := ctx.ia.criar_inimigo(eco, Vector2(220.0, 200.0))
	ctx.ia.estado_de(id1).fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	ctx.ia.fim_do_item_7()
	assert_float(ctx.ia.estado_de(id1).posicao.x).is_equal_approx(220.0, 1e-5)

	# AC-IA-58 / TR-ia-019: puxar aceita comum e elite atingíveis, desloca min(dist_px, d - parar_a_px), chefe recusa
	var centro := Vector2(960.0, 540.0)
	ctx.ia.estado_de(id1).posicao = Vector2(960.0 + 180.0, 540.0)
	var id_el := ctx.ia.criar_inimigo(eco, Vector2(960.0 + 70.0, 540.0), OpcoesDeNascimento.de_elite(-1, 3))
	ctx.ia.estado_de(id_el).fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	var id_ch := ctx.ia.criar_inimigo(FixtureTelegrafos.soberano_do_limiar(), Vector2(960.0 + 180.0, 540.0), OpcoesDeNascimento.de_chefe())
	ctx.ia.estado_de(id_ch).fase = EstadoDeInimigoIA.Fase.APROXIMACAO

	assert_bool(ctx.ia.puxar(id1, centro, 60.0, 36.0)).is_true()
	assert_float((ctx.ia.estado_de(id1).posicao - centro).length()).is_equal_approx(120.0, 1e-4)

	assert_bool(ctx.ia.puxar(id_el, centro, 60.0, 36.0)).is_true()
	assert_float((ctx.ia.estado_de(id_el).posicao - centro).length()).is_equal_approx(36.0, 1e-4) # avançou 70 - 36 = 34 px

	assert_bool(ctx.ia.puxar(id_ch, centro, 60.0, 36.0)).is_false()
