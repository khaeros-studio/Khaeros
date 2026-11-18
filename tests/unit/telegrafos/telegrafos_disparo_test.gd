extends GdUnitTestSuite
## Story telegrafos-004: Disparo resolvido no mesmo passo (AC-TG-10, AC-TG-14, AC-TG-17, AC-TG-18).


func test_ac_tg_10_disparo_de_faixa_chama_projetil_com_jogador_dentro_ou_fora() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(1, Vector2.ZERO)
	c.definir_jogador(0, Vector2(0.0, 400.0)) # Fora da faixa (mira antes era para (100,0))
	c.definir_jogador(0, Vector2(100.0, 0.0))
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c, FixtureTelegrafos.camara_livre())
	tel.iniciar_telegrafo(1, FixtureTelegrafos.anomalia_menor())
	c.definir_jogador(0, Vector2(0.0, 500.0)) # Jogador sai da faixa
	var disparos_proj := 0
	var mira_disparada := Vector2.ZERO
	for i in 36:
		tel.varrer()
		tel.avancar(1)
		if tel.disparou_neste_passo(1):
			disparos_proj += 1
			mira_disparada = tel.mira_de(1)
	assert_int(disparos_proj).is_equal(1)
	assert_vector(mira_disparada).is_equal_approx(Vector2.RIGHT, Vector2(1e-5, 1e-5))


func test_ac_tg_14_17_invulnerabilidade_e_sobreposicao_de_dois_telegrafos() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(1, Vector2.ZERO)
	c.definir_dono(2, Vector2(0.0, 10.0))
	c.definir_jogador(0, Vector2(60.0, 0.0))
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c, FixtureTelegrafos.camara_livre())
	tel.iniciar_telegrafo(1, FixtureTelegrafos.eco_perdido())
	tel.iniciar_telegrafo(2, FixtureTelegrafos.eco_perdido())

	var vida_jogador := 100
	var invuln_passos := 0
	for passo in 26:
		tel.varrer()
		if invuln_passos > 0:
			invuln_passos -= 1
		for id_in in [1, 2]:
			tel.avancar(id_in)
			if tel.disparou_neste_passo(id_in) and tel.acerta_alvo_travado(id_in):
				if invuln_passos == 0:
					vida_jogador -= 9
					invuln_passos = 40
	# Dois Ecos acertam no mesmo passo -> jogador perde Vida de um golpe só (9) e ganha invuln de 40 passos
	assert_int(vida_jogador).is_equal(91)
	assert_int(int(tel.estado_de(1))).is_equal(int(TelegrafoTipos.Estado.DISPARO))
	assert_int(int(tel.estado_de(2))).is_equal(int(TelegrafoTipos.Estado.DISPARO))


func test_ac_tg_18_folgas_de_leitura_f6() -> void:
	assert_int(FormasDeTelegrafo.folga_de_leitura(26, 0.25)).is_equal(11)
	assert_int(FormasDeTelegrafo.folga_de_leitura(36, 0.25)).is_equal(21)
	assert_int(FormasDeTelegrafo.folga_de_leitura(42, 0.25)).is_equal(27)
