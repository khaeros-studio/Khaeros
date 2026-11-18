extends GdUnitTestSuite
## Story telegrafos-006: Quebrar, cancelar, troca de câmara e TransicaoFase (AC-TG-15, AC-TG-16, AC-TG-38).


func test_ac_tg_15_quebrar_em_crescendo_dura_2_passos_e_impede_disparo() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(1, Vector2.ZERO)
	c.definir_jogador(0, Vector2(50.0, 0.0))
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c)
	tel.iniciar_telegrafo(1, FixtureTelegrafos.eco_perdido())
	for i in 20:
		tel.varrer()
		tel.avancar(1)
	assert_bool(tel.quebrar(1)).is_true()
	assert_int(int(tel.estado_de(1))).is_equal(int(TelegrafoTipos.Estado.QUEBRADO))
	assert_bool(tel.disparou_neste_passo(1)).is_false()
	tel.varrer()
	assert_int(tel.ativos()).is_equal(1)
	tel.varrer()
	assert_int(tel.ativos()).is_equal(0)


func test_ac_tg_16_dono_morto_cancela_e_troca_de_camara_libera_na_hora() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(1, Vector2.ZERO, true)
	c.definir_dono(2, Vector2(100.0, 0.0), true)
	c.definir_jogador(0, Vector2(50.0, 0.0))
	var eventos := EventosDoPasso.new()
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c, FixtureTelegrafos.camara_livre(),
		eventos, TelegrafoTipos.PoliticaDeTroca.LIBERAR_JA)
	tel.iniciar_telegrafo(1, FixtureTelegrafos.eco_perdido())
	tel.iniciar_telegrafo(2, FixtureTelegrafos.eco_perdido())

	# Dono 1 morre antes do disparo -> cancelado por 2 passos
	c.definir_dono(1, Vector2.ZERO, false)
	tel.varrer()
	assert_int(int(tel.estado_de(1))).is_equal(int(TelegrafoTipos.Estado.CANCELADO))
	assert_bool(tel.disparou_neste_passo(1)).is_false()

	# Troca de câmara com LIBERAR_JA: zera ativos na hora sem emitir evento
	eventos.esvaziar()
	tel.cancelar_todos()
	assert_int(tel.ativos()).is_equal(0)
	assert_bool(eventos.todos().is_empty()).is_true()


func test_ac_tg_38_transicao_de_fase_e_queda_do_chefe_com_lacaios() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(100, Vector2(960.0, 285.0))
	c.definir_dono(101, Vector2(825.0, 285.0))
	c.definir_dono(102, Vector2(1095.0, 285.0))
	c.definir_jogador(0, Vector2(960.0, 500.0))
	var chefe := FixtureTelegrafos.soberano_do_limiar()
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c)
	tel.iniciar_telegrafo_chefe(100, chefe.padroes[2], chefe.raio_px)
	for i in 20:
		tel.varrer()
		tel.avancar(100)
	# Chefe cruza 350 HP -> cancelar_telegrafo na TransicaoFase
	assert_bool(tel.cancelar(100, TelegrafoTipos.CausaCancelamento.TRANSICAO_FASE)).is_true()
	assert_int(int(tel.estado_de(100))).is_equal(int(TelegrafoTipos.Estado.CANCELADO))
	tel.varrer()
	tel.varrer()
	assert_int(tel.ativos()).is_equal(0)

	# Chefe e 2 lacaios em preparo quando chefe cai a Vida <= 0
	tel.iniciar_telegrafo_chefe(100, chefe.padroes[0], chefe.raio_px)
	tel.iniciar_telegrafo(101, FixtureTelegrafos.eco_perdido())
	tel.iniciar_telegrafo(102, FixtureTelegrafos.eco_perdido())
	assert_bool(tel.cancelar(100, TelegrafoTipos.CausaCancelamento.QUEDA_CHEFE)).is_true()
	assert_bool(tel.cancelar(101, TelegrafoTipos.CausaCancelamento.QUEDA_CHEFE)).is_true()
	assert_bool(tel.cancelar(102, TelegrafoTipos.CausaCancelamento.QUEDA_CHEFE)).is_true()
	assert_int(int(tel.estado_de(100))).is_equal(int(TelegrafoTipos.Estado.CANCELADO))
	assert_int(int(tel.estado_de(101))).is_equal(int(TelegrafoTipos.Estado.CANCELADO))
	assert_int(int(tel.estado_de(102))).is_equal(int(TelegrafoTipos.Estado.CANCELADO))
