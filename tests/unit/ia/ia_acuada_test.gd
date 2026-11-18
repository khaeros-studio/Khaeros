extends GdUnitTestSuite
## Story ia-008: Alvo padrão acuada por paridade no encontro de pacto (AC-IA-50..57).


func test_ac_ia_50_51_52_alvo_por_paridade_de_ordem_e_alcance_da_acuada() -> void:
	var ctx := FixtureIA.ContextoTeste.new()
	ctx.ia.definir_jogador(0, Vector2(960.0, 930.0), 27.0)
	ctx.acuada.ativa = true
	ctx.acuada.pos = Vector2(960.0, 540.0)
	ctx.acuada.raio = 22.5 # Espreitador da Fenda -> alcance_total = 51 + 22.5 = 73.5 px

	var eco := FixtureTelegrafos.eco_perdido()
	var id0 := ctx.ia.criar_inimigo(eco, Vector2(960.0, 400.0), OpcoesDeNascimento.comum(0))
	var id1 := ctx.ia.criar_inimigo(eco, Vector2(960.0, 400.0), OpcoesDeNascimento.comum(1))
	var id2 := ctx.ia.criar_inimigo(eco, Vector2(960.0, 400.0), OpcoesDeNascimento.comum(2))
	var id_lac := ctx.ia.criar_inimigo(eco, Vector2(960.0, 400.0), OpcoesDeNascimento.lacaio_do_chefe())

	assert_int(int(ctx.ia.alvo_efetivo(id0).faccao)).is_equal(int(TelegrafoTipos.FaccaoAlvo.ACUADA))
	assert_int(int(ctx.ia.alvo_efetivo(id1).faccao)).is_equal(int(TelegrafoTipos.FaccaoAlvo.JOGADOR))
	assert_int(int(ctx.ia.alvo_efetivo(id2).faccao)).is_equal(int(TelegrafoTipos.FaccaoAlvo.ACUADA))
	assert_int(int(ctx.ia.alvo_efetivo(id_lac).faccao)).is_equal(int(TelegrafoTipos.FaccaoAlvo.JOGADOR))

	# AC-IA-52: alcance pela acuada (73.5 entra, 74 não)
	var e0 := ctx.ia.estado_de(id0)
	e0.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	e0.timer = 0
	e0.posicao = Vector2(960.0, 540.0 - 74.0 - 2.55)
	ctx.ia.passo(id0) # anda 2.55 -> fica a 74.0 px -> não entra
	assert_int(int(e0.fase)).is_equal(int(EstadoDeInimigoIA.Fase.APROXIMACAO))
	ctx.ia.passo(id0) # anda para 71.45 px (<= 73.5) -> entra em PREPARO travado na acuada!
	assert_int(int(e0.fase)).is_equal(int(EstadoDeInimigoIA.Fase.PREPARO))

	# AC-IA-51: disparo com jogador e acuada dentro do setor -> fere apenas a acuada!
	ctx.ia.definir_jogador(0, Vector2(960.0, 540.0), 27.0)
	for p in 26:
		ctx.ia.executar_item_7()
	assert_int(ctx.combate.danos_acuada.size()).is_equal(1)
	assert_bool(ctx.combate.danos_jogador.is_empty()).is_true()


func test_ac_ia_53_54_55_57_saida_da_acuada_no_mesmo_passo_respiro_e_ranged() -> void:
	var ctx := FixtureIA.ContextoTeste.new()
	ctx.ia.definir_jogador(0, Vector2(960.0, 930.0), 27.0)
	ctx.acuada.ativa = true
	ctx.acuada.pos = Vector2(960.0, 540.0)
	ctx.acuada.raio = 22.5
	ctx.maldicao.id_campo = 10
	ctx.maldicao.pos = Vector2(200.0, 540.0)

	var eco := FixtureTelegrafos.eco_perdido()
	var id0 := ctx.ia.criar_inimigo(eco, Vector2(960.0, 480.0), OpcoesDeNascimento.comum(0))
	var id2 := ctx.ia.criar_inimigo(eco, Vector2(960.0, 300.0), OpcoesDeNascimento.comum(2))
	ctx.ia.estado_de(id0).fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	ctx.ia.estado_de(id2).fase = EstadoDeInimigoIA.Fase.APROXIMACAO

	# AC-IA-55: Eco de ordem 0 atraído mira a Maldição; no respiro volta para a acuada (se ativa)
	assert_bool(ctx.ia.atrair(id0, 90, 30)).is_true()
	for p in 90:
		assert_int(int(ctx.ia.alvo_efetivo(id0).faccao)).is_equal(int(TelegrafoTipos.FaccaoAlvo.ALIADO))
		ctx.ia.passo(id0)
	assert_int(ctx.ia.estado_de(id0).restante_respiro).is_equal(30)
	assert_int(int(ctx.ia.alvo_efetivo(id0).faccao)).is_equal(int(TelegrafoTipos.FaccaoAlvo.ACUADA))

	# AC-IA-53: quando a acuada passa a Fugiu (ativa = false), Eco 2 já lê o jogador imediatamente
	ctx.acuada.ativa = false
	assert_int(int(ctx.ia.alvo_efetivo(id2).faccao)).is_equal(int(TelegrafoTipos.FaccaoAlvo.JOGADOR))

	# AC-IA-57: Anomalia de ordem 0 com acuada ativa recua da acuada e dispara projétil com alvo = ACUADA
	ctx.acuada.ativa = true
	var id_anom := ctx.ia.criar_inimigo(FixtureTelegrafos.anomalia_menor(), Vector2(960.0 + 300.0, 540.0), OpcoesDeNascimento.comum(0))
	var e_anom := ctx.ia.estado_de(id_anom)
	e_anom.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	e_anom.timer = 0
	ctx.ia.passo(id_anom)
	assert_float(e_anom.posicao.x).is_equal_approx(960.0 + 301.95, 1e-4)
	for p in 36:
		ctx.ia.executar_item_7()
	assert_int(ctx.combate.projeteis_disparados.size()).is_equal(1)
	assert_int(int(ctx.combate.projeteis_disparados[0]["alvo_faccao"])).is_equal(int(TelegrafoTipos.FaccaoAlvo.ACUADA))
