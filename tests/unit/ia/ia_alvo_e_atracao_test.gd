extends GdUnitTestSuite
## Story ia-006: Alvo efetivo, atração sem renovação e respiro (AC-IA-31..36, AC-IA-43, AC-IA-44, AC-IA-47).


func test_ac_ia_31_36_atracao_90_passos_respiro_30_e_sem_renovacao() -> void:
	var ctx := FixtureIA.ContextoTeste.new()
	ctx.ia.definir_jogador(0, Vector2.ZERO)
	ctx.maldicao.id_campo = 10
	ctx.maldicao.pos = Vector2(600.0, 0.0)
	ctx.maldicao.raio = 24.0

	var id_eco := ctx.ia.criar_inimigo(FixtureTelegrafos.eco_perdido(), Vector2(300.0, 300.0))
	var e := ctx.ia.estado_de(id_eco)
	e.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	e.timer = 500

	# Sem atração, alvo é o jogador (0, 0)
	assert_int(int(ctx.ia.alvo_efetivo(id_eco).faccao)).is_equal(int(TelegrafoTipos.FaccaoAlvo.JOGADOR))

	# Aplica atrair(id, 90, 30); tentativa de renovar durante a atração é recusada (AC-IA-36)
	assert_bool(ctx.ia.atrair(id_eco, 90, 30)).is_true()
	assert_bool(ctx.ia.atrair(id_eco, 60, 30)).is_false()
	assert_int(e.restante_atracao).is_equal(90)

	# Nos passos 0..89 (90 passos vivos) anda para a Maldição; no fim do 90º passo abre respiro de 30
	for p in 90:
		assert_int(int(ctx.ia.alvo_efetivo(id_eco).faccao)).is_equal(int(TelegrafoTipos.FaccaoAlvo.ALIADO))
		ctx.ia.passo(id_eco)
	assert_bool(ctx.ia.esta_atraido(id_eco)).is_false()
	assert_int(e.restante_respiro).is_equal(30)

	# Durante os 30 passos de respiro mira o jogador e recusa novo atrair
	for p in 30:
		assert_int(int(ctx.ia.alvo_efetivo(id_eco).faccao)).is_equal(int(TelegrafoTipos.FaccaoAlvo.JOGADOR))
		assert_bool(ctx.ia.atrair(id_eco, 90, 30)).is_false()
		ctx.ia.passo(id_eco)
	assert_int(e.restante_respiro).is_equal(0)
	# No passo s + 120 é aceito novamente
	assert_bool(ctx.ia.atrair(id_eco, 90, 30)).is_true()


func test_ac_ia_32_33_34_35_alcance_pelo_alvo_saida_de_campo_e_falha_no_vazio() -> void:
	var ctx := FixtureIA.ContextoTeste.new()
	ctx.ia.definir_jogador(0, Vector2(60.0, 0.0), 27.0)
	ctx.maldicao.id_campo = 10
	ctx.maldicao.pos = Vector2(76.0, 0.0)
	ctx.maldicao.raio = 24.0 # Vulto Mudo: alcance_total = 51 + 24 = 75 px

	var id_eco := ctx.ia.criar_inimigo(FixtureTelegrafos.eco_perdido(), Vector2.ZERO)
	var e := ctx.ia.estado_de(id_eco)
	e.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	e.timer = 0
	e.restante_imob = 1 # trava o andar para testar limiar exato de distância
	ctx.ia.atrair(id_eco, 90, 30)

	# A 76 px do Vulto Mudo não entra; a 75 px (sem imob) entra em preparo
	e.restante_imob = 0
	e.posicao = Vector2.ZERO
	ctx.maldicao.pos = Vector2(78.55, 0.0) # Após andar 2.55 px fica a 76.0 px -> não entra!
	ctx.ia.passo(id_eco)
	assert_int(int(e.fase)).is_equal(int(EstadoDeInimigoIA.Fase.APROXIMACAO))

	# No passo seguinte anda para 73.45 (<= 75 px) -> entra em PREPARO travado na Maldição
	ctx.ia.passo(id_eco)
	assert_int(int(e.fase)).is_equal(int(EstadoDeInimigoIA.Fase.PREPARO))

	# AC-IA-33 e AC-IA-34: Maldição sai de campo no meio do preparo -> zera atração, abre respiro 30,
	# e no disparo o golpe falha no vazio (não fere nem jogador nem Maldição)
	ctx.ia.maldicao_saiu_de_campo(0)
	ctx.maldicao.id_campo = -1
	assert_int(e.restante_atracao).is_equal(0)
	assert_int(e.restante_respiro).is_equal(30)
	for p in 26:
		ctx.ia.executar_item_7()
	assert_bool(ctx.combate.danos_jogador.is_empty()).is_true()
	assert_bool(ctx.combate.danos_maldicao.is_empty()).is_true()


func test_ac_ia_43_44_47_ranged_e_charger_atraidos_e_fator_andar_atraido() -> void:
	var ctx := FixtureIA.ContextoTeste.new()
	ctx.ia.definir_jogador(0, Vector2(800.0, 0.0))
	ctx.maldicao.id_campo = 10
	ctx.maldicao.pos = Vector2.ZERO
	ctx.maldicao.raio = 28.5
	ctx.maldicao.fator_andar = 0.80 # Presença do Limiar (Soberano)

	# AC-IA-44: Eco atraído com fator 0.80 anda 2.04 px/passo; no Selo 1.02 px/passo
	var id_eco := ctx.ia.criar_inimigo(FixtureTelegrafos.eco_perdido(), Vector2(300.0, 0.0))
	var e_eco := ctx.ia.estado_de(id_eco)
	e_eco.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	ctx.ia.atrair(id_eco, 90, 30)
	assert_float(ctx.ia.velocidade_andar_passo(e_eco)).is_equal_approx(2.04, 1e-5)
	e_eco.ref.no_selo = true
	assert_float(ctx.ia.velocidade_andar_passo(e_eco)).is_equal_approx(1.02, 1e-5)

	# AC-IA-43: Anomalia atraída a 300 px da Maldição recua dela
	ctx.maldicao.fator_andar = 1.0
	var id_anom := ctx.ia.criar_inimigo(FixtureTelegrafos.anomalia_menor(), Vector2(300.0, 0.0))
	var e_anom := ctx.ia.estado_de(id_anom)
	e_anom.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	e_anom.timer = 10
	ctx.ia.atrair(id_anom, 90, 30)
	ctx.ia.passo(id_anom)
	assert_float(e_anom.posicao.x).is_equal_approx(301.95, 1e-4)
