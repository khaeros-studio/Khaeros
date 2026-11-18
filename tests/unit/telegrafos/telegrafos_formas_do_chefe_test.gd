extends GdUnitTestSuite
## Story telegrafos-007: Formas do chefe (setor, avanço, anel, círculo e contorno secundário; AC-TG-36, AC-TG-37, AC-TG-39).


func test_ac_tg_36_quatro_padroes_do_soberano_do_limiar_e_contorno_secundario() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(100, Vector2.ZERO)
	c.definir_jogador(0, Vector2(100.0, 0.0), 27.0)
	var chefe := FixtureTelegrafos.soberano_do_limiar()
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c, FixtureTelegrafos.camara_livre())
	var vistas := FixtureTelegrafos.vistas_pre_alocadas(4)

	# Padrão 0: setor 165 px, 78.46°, centro_a_borda, preparo 30
	assert_bool(tel.iniciar_telegrafo_chefe(100, chefe.padroes[0], chefe.raio_px)).is_true()
	assert_bool(tel.iniciar_telegrafo_chefe(100, chefe.padroes[1], chefe.raio_px)).is_false() # máx 1 ativo
	tel.publicar(vistas)
	assert_int(int(vistas[0].forma)).is_equal(int(TelegrafoTipos.Forma.SETOR))
	assert_float(vistas[0].raio).is_equal_approx(165.0, 0.01)
	assert_float(vistas[0].meio_angulo_graus).is_equal_approx(78.46, 0.01)
	assert_int(tel.restante_de(100)).is_equal(30)
	tel.cancelar_todos()

	# Padrão 1: retângulo 414 x 144 desde -72, ao_longo_do_eixo, preparo 36
	assert_bool(tel.iniciar_telegrafo_chefe(100, chefe.padroes[1], chefe.raio_px)).is_true()
	tel.publicar(vistas)
	assert_int(int(vistas[0].forma)).is_equal(int(TelegrafoTipos.Forma.RETANGULO))
	assert_float(vistas[0].comprimento).is_equal_approx(414.0, 0.01)
	assert_float(vistas[0].largura).is_equal_approx(144.0, 0.01)
	assert_float(vistas[0].x_min).is_equal_approx(-72.0, 0.01)
	assert_int(tel.restante_de(100)).is_equal(36)
	tel.cancelar_todos()

	# Padrão 2: anel 0..210, borda_ao_centro, preparo 36
	assert_bool(tel.iniciar_telegrafo_chefe(100, chefe.padroes[2], chefe.raio_px)).is_true()
	tel.publicar(vistas)
	assert_int(int(vistas[0].forma)).is_equal(int(TelegrafoTipos.Forma.ANEL))
	assert_float(vistas[0].r_int).is_equal_approx(0.0, 0.01)
	assert_float(vistas[0].r_ext).is_equal_approx(210.0, 0.01)
	assert_int(int(vistas[0].modo)).is_equal(int(TelegrafoTipos.Modo.BORDA_AO_CENTRO))
	assert_int(tel.restante_de(100)).is_equal(36)
	tel.cancelar_todos()

	# Padrão 3: círculo 225, borda_ao_centro, preparo 42, contorno secundário 420
	assert_bool(tel.iniciar_telegrafo_chefe(100, chefe.padroes[3], chefe.raio_px)).is_true()
	tel.publicar(vistas)
	assert_int(int(vistas[0].forma)).is_equal(int(TelegrafoTipos.Forma.CIRCULO))
	assert_float(vistas[0].raio).is_equal_approx(225.0, 0.01)
	assert_float(vistas[0].contorno_secundario_raio).is_equal_approx(420.0, 0.01)
	assert_int(tel.restante_de(100)).is_equal(42)


func test_ac_tg_37_padroes_do_chefe_testam_so_o_alvo_travado() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(100, Vector2.ZERO)
	c.definir_jogador(0, Vector2(200.0, 0.0), 27.0)
	c.definir_maldicao(10, Vector2(200.0, 0.0), 24.0, true)
	var chefe := FixtureTelegrafos.soberano_do_limiar()
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c, FixtureTelegrafos.camara_livre())

	# P2 travado no jogador: acerta o alvo travado (jogador a 200 <= 210)
	tel.iniciar_telegrafo_chefe(100, chefe.padroes[2], chefe.raio_px, 0, TelegrafoTipos.FaccaoAlvo.JOGADOR)
	assert_bool(tel.acerta_alvo_travado(100)).is_true()
	assert_int(tel.alvo_de(100).x).is_equal(int(TelegrafoTipos.FaccaoAlvo.JOGADOR))
	tel.cancelar_todos()

	# P3 travado na Maldição: após puxão de 75 px (280 -> 205 <= 225), só a Maldição é o alvo travado
	c.definir_jogador(0, Vector2(205.0, 0.0), 27.0)
	c.definir_maldicao(10, Vector2(205.0, 0.0), 24.0, true)
	tel.iniciar_telegrafo_chefe(100, chefe.padroes[3], chefe.raio_px, 10, TelegrafoTipos.FaccaoAlvo.ALIADO)
	assert_bool(tel.acerta_alvo_travado(100)).is_true()
	assert_int(tel.alvo_de(100).x).is_equal(int(TelegrafoTipos.FaccaoAlvo.ALIADO))
	assert_int(tel.alvo_de(100).y).is_equal(10)
