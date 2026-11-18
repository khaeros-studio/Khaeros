extends GdUnitTestSuite
## Story telegrafos-003: Adaptador FormaDeTelegrafo e testes geométricos de acerto (AC-TG-08, AC-TG-09, AC-TG-12, AC-TG-27).


func test_ac_tg_08_teste_do_setor_do_eco() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(1, Vector2.ZERO)
	c.definir_jogador(0, Vector2(100.0, 0.0))
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c, FixtureTelegrafos.camara_livre())
	tel.iniciar_telegrafo(1, FixtureTelegrafos.eco_perdido())

	assert_bool(tel.dentro(1, Vector2(80.0, 20.0))).is_true()
	assert_bool(tel.dentro(1, Vector2(-10.0, 0.0))).is_false()
	assert_bool(tel.dentro(1, Vector2(89.9, 0.0))).is_true()
	assert_bool(tel.dentro(1, Vector2(90.1, 0.0))).is_false()
	var p_dentro_ang := Vector2.RIGHT.rotated(deg_to_rad(78.40)) * 90.0
	var p_fora_ang := Vector2.RIGHT.rotated(deg_to_rad(78.52)) * 90.0
	assert_bool(tel.dentro(1, p_dentro_ang)).is_true()
	assert_bool(tel.dentro(1, p_fora_ang)).is_false()


func test_ac_tg_09_comprimento_da_faixa_livre_parede_e_obstaculo() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(1, Vector2.ZERO)
	c.definir_jogador(0, Vector2(100.0, 0.0))
	var tel := Telegrafos.new()
	var vistas := FixtureTelegrafos.vistas_pre_alocadas(2)

	# Câmara livre -> 1728 px
	tel.configurar(TelegraphTuning.de_fabrica(), c, FixtureTelegrafos.camara_livre())
	tel.iniciar_telegrafo(1, FixtureTelegrafos.anomalia_menor())
	tel.publicar(vistas)
	assert_float(vistas[0].comprimento).is_equal_approx(1728.0, 0.01)

	# Parede a 600 px na mira -> 600 px
	tel.definir_camara(GeometriaDeMovimento.new(Rect2(Vector2(-100.0, -500.0), Vector2(700.0, 1000.0))))
	tel.publicar(vistas)
	assert_float(vistas[0].comprimento).is_equal_approx(600.0, 0.01)

	# Obstáculo com superfície a 400 px (centro em 450, raio 50) -> 400 px
	var obs := [ObstaculoCircular.new(Vector2(450.0, 0.0), 50.0)] as Array[ObstaculoCircular]
	tel.definir_camara(GeometriaDeMovimento.new(Rect2(Vector2(-100.0, -500.0), Vector2(2000.0, 1000.0)), obs))
	tel.publicar(vistas)
	assert_float(vistas[0].comprimento).is_equal_approx(400.0, 0.01)


func test_ac_tg_12_contato_do_avanco_da_fenda() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(1, Vector2.ZERO)
	c.definir_jogador(0, Vector2(100.0, 0.0))
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c, FixtureTelegrafos.camara_livre())
	tel.iniciar_telegrafo(1, FixtureTelegrafos.fenda_errante())

	# Distância 56 px < 57 px acerta; 58 px não acerta; logo atrás a -30 px acerta
	assert_bool(tel.dentro(1, Vector2(56.0, 0.0))).is_true()
	assert_bool(tel.dentro(1, Vector2(58.0, 0.0))).is_false()
	assert_bool(tel.dentro(1, Vector2(-30.0, 0.0))).is_true()


func test_ac_tg_27_eixo_local_do_retangulo_da_faixa() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(1, Vector2.ZERO)
	c.definir_jogador(0, Vector2(100.0, 0.0))
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c, FixtureTelegrafos.camara_livre())
	tel.iniciar_telegrafo(1, FixtureTelegrafos.anomalia_menor())

	assert_bool(tel.dentro(1, Vector2(500.0, 30.0))).is_true()
	assert_bool(tel.dentro(1, Vector2(500.0, 41.0))).is_false()
	assert_bool(tel.dentro(1, Vector2(1730.0, 0.0))).is_false()
