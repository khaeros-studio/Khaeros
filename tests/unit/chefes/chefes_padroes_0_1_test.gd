extends GdUnitTestSuite


func test_ac_ch_04_padrao_0_garra_do_veu_rasgado_setor_fere_alvo_travado() -> void:
	var amb := FixtureChefes.criar_ambiente(&"lamina", Vector2(960.0, 400.0), true)
	var est := amb.ia.estado_de(amb.id_chefe)
	est.estado_chefe.padrao = 0

	# Passo 1 inicia o preparo de P0; após os passos de preparo, dispara o golpe de setor
	amb.avancar_passo()
	assert_int(int(est.fase)).is_equal(int(EstadoDeInimigoIA.Fase.PREPARO))
	var passos_prep := est.timer
	for _i in range(passos_prep):
		amb.avancar_passo()

	assert_int(amb.ctx_ia.combate.danos_jogador.size()).is_equal(1)
	assert_str(String(amb.ctx_ia.combate.danos_jogador[0]["ataque_id"])).is_equal("soberano_p0_garra")


func test_ac_ch_05_06_11_padrao_1_irrupcao_avanca_fere_no_maximo_1_vez_e_respeita_alvo_travado() -> void:
	var amb := FixtureChefes.criar_ambiente(&"pactos", Vector2(960.0, 450.0), true)
	var est := amb.ia.estado_de(amb.id_chefe)
	est.estado_chefe.padrao = 1

	# Ativa Maldição em campo e atrai o chefe para que o alvo travado seja ALIADO (Maldição)
	amb.ctx_ia.maldicao.id_campo = 10
	amb.ctx_ia.maldicao.pos = Vector2(960.0, 420.0)
	amb.ctx_ia.maldicao.raio = 24.0
	assert_bool(amb.ia.atrair(amb.id_chefe, 90, 30, 0)).is_true()

	amb.avancar_passo()
	assert_int(int(est.fase)).is_equal(int(EstadoDeInimigoIA.Fase.PREPARO))
	var passos_prep := est.timer
	# Mesmo com o jogador exatamente no caminho do avanço, o alvo travado é a Maldição (AC-CH-11)
	amb.ia.definir_jogador(0, Vector2(960.0, 360.0), 27.0)

	for _i in range(passos_prep + 24):
		amb.avancar_passo()

	# Fere a Maldição no máximo 1 única vez durante todo o avanço e nunca fere o jogador (AC-CH-05, AC-CH-06, AC-CH-11)
	assert_int(amb.ctx_ia.combate.danos_maldicao.size()).is_equal(1)
	assert_int(amb.ctx_ia.combate.danos_jogador.size()).is_equal(0)
	assert_float(est.posicao.y).is_greater(285.0)
