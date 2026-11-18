extends GdUnitTestSuite
## Story ia-001: ModuloDeIA — lista estável, ciclo do item 7 e consultas de alvos (AC-IA-20, AC-IA-21, AC-IA-41, AC-IA-56).


func test_ac_ia_41_56_atingiveis_mais_perto_e_ids_crescentes_sem_acuada() -> void:
	var ctx := FixtureIA.ContextoTeste.new()
	ctx.ia.definir_jogador(0, Vector2.ZERO)
	ctx.acuada.ativa = true
	ctx.acuada.pos = Vector2(50.0, 0.0) # Acuada nunca entra em atingiveis() nem mais_perto()

	var eco := FixtureTelegrafos.eco_perdido()
	var id1 := ctx.ia.criar_inimigo(eco, Vector2(200.0, 0.0))
	var id2 := ctx.ia.criar_inimigo(eco, Vector2(100.0, 0.0))
	var id3 := ctx.ia.criar_inimigo(eco, Vector2(200.0, 0.0))
	assert_int(id1).is_equal(1)
	assert_int(id2).is_equal(2)
	assert_int(id3).is_equal(3)

	# Tira 1 e 3 do surgimento; deixa 2 em surgimento
	ctx.ia.estado_de(id1).fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	ctx.ia.estado_de(id3).fase = EstadoDeInimigoIA.Fase.APROXIMACAO

	var lista := ctx.ia.atingiveis()
	assert_int(lista.size()).is_equal(2)
	assert_int(lista[0].id).is_equal(1)
	assert_int(lista[1].id).is_equal(3)

	# Empate a 200 px: vence o menor id (1)
	assert_int(ctx.ia.mais_perto(Vector2.ZERO, 480.0)).is_equal(1)

	# 1 a 481 px e 3 a 480 px -> devolve 3 (inclusivo)
	ctx.ia.estado_de(id1).posicao = Vector2(481.0, 0.0)
	ctx.ia.estado_de(id3).posicao = Vector2(480.0, 0.0)
	assert_int(ctx.ia.mais_perto(Vector2.ZERO, 480.0)).is_equal(3)

	# Ambos além de 480 px -> -1
	ctx.ia.estado_de(id3).posicao = Vector2(481.0, 0.0)
	assert_int(ctx.ia.mais_perto(Vector2.ZERO, 480.0)).is_equal(-1)

	# Troca de câmara não reinicia ids
	ctx.ia.camara_nova()
	var id4 := ctx.ia.criar_inimigo(eco, Vector2.ZERO)
	assert_int(id4).is_equal(4)


func test_ac_ia_20_21_morto_nao_age_e_parada_apos_morte_do_jogador() -> void:
	var ctx := FixtureIA.ContextoTeste.new()
	ctx.ia.definir_jogador(0, Vector2.ZERO)
	var id1 := ctx.ia.criar_inimigo(FixtureTelegrafos.eco_perdido(), Vector2(300.0, 0.0))
	var e := ctx.ia.estado_de(id1)
	e.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	e.timer = 10

	# Vida <= 0 não age
	e.vida = 0.0
	ctx.ia.passo(id1)
	assert_float(e.posicao.x).is_equal_approx(300.0, 1e-5)

	# Jogador morre: no passo seguinte nada avança
	e.vida = 30.0
	ctx.ia.definir_jogador_morto(true)
	ctx.ia.executar_item_7()
	assert_float(e.posicao.x).is_equal_approx(300.0, 1e-5)
