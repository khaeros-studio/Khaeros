extends GdUnitTestSuite


func test_ac_ch_07_e_27_padrao_2_pulso_de_soberania_anel_empurrao_e_12_projeteis_radiais() -> void:
	var amb := FixtureChefes.criar_ambiente(&"lamina", Vector2(960.0, 450.0), true)
	var est := amb.ia.estado_de(amb.id_chefe)
	est.estado_chefe.padrao = 2

	amb.avancar_passo()
	assert_int(int(est.fase)).is_equal(int(EstadoDeInimigoIA.Fase.PREPARO))
	var passos_prep := est.timer
	for _i in range(passos_prep):
		amb.avancar_passo()

	# Dispara o golpe circular/anel no alvo travado + empurrão 900 px/s + 12 projéteis radiais a cada 30°
	assert_int(amb.ctx_ia.combate.danos_jogador.size()).is_equal(1)
	assert_int(amb.ctx_ia.combate.empurroes_alvo.size()).is_equal(1)
	assert_float(float(amb.ctx_ia.combate.empurroes_alvo[0]["velocidade_pxs"])).is_equal_approx(900.0, 0.01)

	assert_int(amb.ctx_ia.combate.projeteis_disparados.size()).is_equal(12)
	var dir_0: Vector2 = amb.ctx_ia.combate.projeteis_disparados[0]["dir"]
	var dir_3: Vector2 = amb.ctx_ia.combate.projeteis_disparados[3]["dir"]
	# 3 * 30° = 90° -> produto escalar próximo de 0
	assert_float(absf(dir_0.dot(dir_3))).is_less(0.001)
