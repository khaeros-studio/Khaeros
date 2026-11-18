extends GdUnitTestSuite
## Story telegrafos-001: pool fixo, teto de 24 e ciclo de vida em passos vivos (AC-TG-01..06, AC-TG-21, AC-TG-25).


func test_ac_tg_01_progresso_linear_e_disparo_no_26_passo() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(1, Vector2.ZERO)
	c.definir_jogador(0, Vector2(100.0, 0.0))
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c)
	assert_bool(tel.iniciar_telegrafo(1, FixtureTelegrafos.eco_perdido())).is_true()
	assert_int(tel.restante_de(1)).is_equal(26)
	assert_float(tel.progresso_de(1)).is_equal_approx(0.0, 1e-6)
	for i in 13:
		tel.varrer()
		tel.avancar(1)
	assert_int(tel.restante_de(1)).is_equal(13)
	assert_float(tel.progresso_de(1)).is_equal_approx(0.5, 1e-6)
	assert_int(int(tel.estado_de(1))).is_equal(int(TelegrafoTipos.Estado.CRESCENDO))
	for i in 13:
		tel.varrer()
		tel.avancar(1)
	assert_int(tel.restante_de(1)).is_equal(0)
	assert_float(tel.progresso_de(1)).is_equal_approx(1.0, 1e-6)
	assert_int(int(tel.estado_de(1))).is_equal(int(TelegrafoTipos.Estado.DISPARO))
	assert_bool(tel.disparou_neste_passo(1)).is_true()


func test_ac_tg_02_mira_travada_nao_rastreia_movimento_do_jogador() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(1, Vector2.ZERO)
	c.definir_jogador(0, Vector2(100.0, 0.0))
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c)
	tel.iniciar_telegrafo(1, FixtureTelegrafos.eco_perdido())
	assert_vector(tel.mira_de(1)).is_equal_approx(Vector2.RIGHT, Vector2(1e-5, 1e-5))
	c.definir_jogador(0, Vector2(100.0, 300.0))
	for i in 10:
		tel.varrer()
		tel.avancar(1)
	assert_vector(tel.mira_de(1)).is_equal_approx(Vector2.RIGHT, Vector2(1e-5, 1e-5))


func test_ac_tg_03_um_por_inimigo_e_teto_de_24_com_reaproveitamento() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c)
	var eco := FixtureTelegrafos.eco_perdido()
	c.definir_dono(1, Vector2.ZERO)
	c.definir_jogador(0, Vector2(100.0, 0.0))
	assert_bool(tel.iniciar_telegrafo(1, eco)).is_true()
	# 2º pedido do mesmo inimigo recusado
	assert_bool(tel.iniciar_telegrafo(1, eco)).is_false()
	for id_in in range(2, 25):
		c.definir_dono(id_in, Vector2(float(id_in), 0.0))
		assert_bool(tel.iniciar_telegrafo(id_in, eco)).is_true()
	assert_int(tel.ativos()).is_equal(24)
	# 25º pedido recusado
	c.definir_dono(25, Vector2(250.0, 0.0))
	assert_bool(tel.iniciar_telegrafo(25, eco)).is_false()
	assert_int(tel.recusas_por_teto()).is_equal(1)
	# Quebra o 1º e avança 2 passos para liberar a vaga
	assert_bool(tel.quebrar(1)).is_true()
	tel.varrer() # passo 1 no estado terminal: ainda ocupa vaga
	assert_bool(tel.iniciar_telegrafo(25, eco)).is_false()
	tel.varrer() # passo 2 no estado terminal: libera no início do item 7!
	assert_int(tel.ativos()).is_equal(23)
	assert_bool(tel.iniciar_telegrafo(25, eco)).is_true()
	assert_int(tel.ativos()).is_equal(24)


func test_ac_tg_04_acompanha_o_dono_empurrado_sem_mudar_mira_ou_dimensoes() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(1, Vector2.ZERO)
	c.definir_jogador(0, Vector2(80.0, 0.0))
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c, FixtureTelegrafos.camara_livre())
	tel.iniciar_telegrafo(1, FixtureTelegrafos.eco_perdido())
	c.definir_dono(1, Vector2(40.0, 0.0))
	var vistas := FixtureTelegrafos.vistas_pre_alocadas(4)
	assert_int(tel.publicar(vistas)).is_equal(1)
	assert_vector(vistas[0].pos).is_equal_approx(Vector2(40.0, 0.0), Vector2(1e-5, 1e-5))
	assert_vector(tel.mira_de(1)).is_equal_approx(Vector2.RIGHT, Vector2(1e-5, 1e-5))
	assert_float(vistas[0].raio).is_equal_approx(90.0, 1e-5)


func test_ac_tg_05_06_congelado_no_hitstop_e_independente_de_lentidao_e_abalo() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(1, Vector2.ZERO)
	c.definir_jogador(0, Vector2(80.0, 0.0))
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c)
	tel.iniciar_telegrafo(1, FixtureTelegrafos.eco_perdido())
	tel.varrer()
	tel.avancar(1)
	var rest_antes := tel.restante_de(1)
	var p_antes := tel.progresso_de(1)
	# Em 6 passos de hitstop/pausa/bênção/transição, varrer e avancar não são chamados
	assert_int(tel.restante_de(1)).is_equal(rest_antes)
	assert_float(tel.progresso_de(1)).is_equal_approx(p_antes, 1e-6)
	assert_int(tel.forma_derivada_de(1).preparo_passos).is_equal(26)


func test_ac_tg_21_25_saida_da_lista_apos_2_passos_e_mira_distancia_zero() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(1, Vector2(50.0, 50.0))
	c.definir_jogador(0, Vector2(50.0, 50.0))
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c)
	assert_bool(tel.iniciar_telegrafo(1, FixtureTelegrafos.eco_perdido())).is_true()
	assert_vector(tel.mira_de(1)).is_equal_approx(Vector2.RIGHT, Vector2(1e-5, 1e-5))
	for i in 26:
		tel.varrer()
		tel.avancar(1)
	assert_int(int(tel.estado_de(1))).is_equal(int(TelegrafoTipos.Estado.DISPARO))
	tel.varrer()
	assert_int(tel.ativos()).is_equal(1)
	tel.varrer()
	assert_int(tel.ativos()).is_equal(0)
