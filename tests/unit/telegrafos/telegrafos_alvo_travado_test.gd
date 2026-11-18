extends GdUnitTestSuite
## Story telegrafos-005: Alvo travado e falha no vazio (AC-TG-28, AC-TG-30..35).


func test_ac_tg_28_mira_ao_alvo_travado_nao_muda_quando_atracao_acaba() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(1, Vector2.ZERO)
	c.definir_jogador(0, Vector2(80.0, 0.0))
	c.definir_maldicao(10, Vector2(0.0, 80.0), 24.0, true)
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c, FixtureTelegrafos.camara_livre())
	tel.iniciar_telegrafo(1, FixtureTelegrafos.eco_perdido(), 10, TelegrafoTipos.FaccaoAlvo.ALIADO)
	assert_vector(tel.mira_de(1)).is_equal_approx(Vector2(0.0, 1.0), Vector2(1e-5, 1e-5))
	assert_float(tel.raio_alvo_de(1)).is_equal_approx(24.0, 1e-5)
	assert_int(tel.alvo_de(1).x).is_equal(int(TelegrafoTipos.FaccaoAlvo.ALIADO))
	assert_int(tel.alvo_de(1).y).is_equal(10)
	# Mesmo após 10 passos (ex.: atração acabou na IA), mira, alvo travado e raio continuam idênticos
	for i in 10:
		tel.varrer()
		tel.avancar(1)
	assert_vector(tel.mira_de(1)).is_equal_approx(Vector2(0.0, 1.0), Vector2(1e-5, 1e-5))
	assert_float(tel.raio_alvo_de(1)).is_equal_approx(24.0, 1e-5)
	assert_int(tel.alvo_de(1).y).is_equal(10)


func test_ac_tg_30_31_34_so_testa_alvo_travado_e_falha_no_vazio_se_sair() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(1, Vector2.ZERO)
	c.definir_jogador(0, Vector2(50.0, 0.0))
	c.definir_maldicao(10, Vector2(50.0, 0.0), 24.0, true)
	c.definir_maldicao(11, Vector2(50.0, 0.0), 22.5, false)
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c, FixtureTelegrafos.camara_livre())

	# Travado na Maldição 10 com ambos dentro: acerta apenas o alvo travado (Maldição 10)
	tel.iniciar_telegrafo(1, FixtureTelegrafos.eco_perdido(), 10, TelegrafoTipos.FaccaoAlvo.ALIADO)
	assert_bool(tel.acerta_alvo_travado(1)).is_true()
	assert_int(tel.alvo_de(1).x).is_equal(int(TelegrafoTipos.FaccaoAlvo.ALIADO))

	# AC-TG-31 / AC-TG-34: Maldição 10 sai de campo e Maldição 11 entra no lugar -> falha no vazio!
	c.definir_maldicao(10, Vector2(50.0, 0.0), 24.0, false)
	c.definir_maldicao(11, Vector2(50.0, 0.0), 22.5, true)
	assert_bool(tel.acerta_alvo_travado(1)).is_false()


func test_ac_tg_32_33_35_avanco_no_baluarte_e_maldicao_sem_telegrafo() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(1, Vector2.ZERO)
	c.definir_jogador(0, Vector2(30.0, 0.0))
	c.definir_maldicao(10, Vector2(59.0, 0.0), 30.0, true) # Baluarte raio 30 -> R_c = 30 + 30 = 60
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c, FixtureTelegrafos.camara_livre())
	tel.iniciar_telegrafo(1, FixtureTelegrafos.fenda_errante(), 10, TelegrafoTipos.FaccaoAlvo.ALIADO)

	assert_bool(tel.acerta_alvo_travado(1)).is_true() # 59 px < 60 px fere a Maldição
	c.definir_maldicao(10, Vector2(61.0, 0.0), 30.0, true)
	assert_bool(tel.acerta_alvo_travado(1)).is_false() # 61 px > 60 px não fere (e jogador a 30 px é ignorado)

	# AC-TG-35: Maldição nunca cria telégrafo de chão; capacidade segue 24
	assert_int(tel.capacidade()).is_equal(24)
	assert_int(tel.ativos()).is_equal(1)
