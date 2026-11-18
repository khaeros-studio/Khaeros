extends GdUnitTestSuite
## Story selo-e-fluxo-002: Fluxo — regeneração, acerto de arma e congelamento
## (AC-SF-01 a AC-SF-06, AC-SF-25, AC-SF-26, AC-SF-29, AC-SF-30).

const CAMARA := Rect2(0.0, 0.0, 1920.0, 1080.0)


func test_ac_sf_01_e_02_regeneracao_e_teto() -> void:
	# AC-SF-01: Fluxo 0, 100 passos vivos -> 6,00 (±1e-6)
	var s := Selo.new()
	s.definir_fluxo_para_teste(0.0)
	for _i: int in 100:
		s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA)
	assert_float(s.fluxo()).is_equal_approx(6.0, 1e-6)

	# AC-SF-02: Fluxo 99,97, 1 passo -> 100,00; Onda em 5 alvos a Fluxo 99 -> 100,00 (sobra perdida)
	s.definir_fluxo_para_teste(99.97)
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA)
	assert_float(s.fluxo()).is_equal_approx(100.0, 1e-6)

	s.definir_fluxo_para_teste(99.0)
	s.creditar_acertos_item_5(5, true)
	assert_float(s.fluxo()).is_equal_approx(100.0, 1e-6)


func test_ac_sf_03_e_04_acerto_de_arma_e_por_alvo() -> void:
	# AC-SF-03: Fluxo 10, 1 Corte acerta no item 5 -> +3 + 0,06 = 13,06; fontes sem de_arma não somam
	var s := Selo.new()
	s.definir_fluxo_para_teste(10.0)
	s.creditar_acertos_item_5(1, true) # Corte
	s.creditar_acertos_item_5(3, false) # Corte da esquiva / parede / explosão / reflexo / status / Selo
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA)
	assert_float(s.fluxo()).is_equal_approx(13.06, 1e-6)

	# AC-SF-04: Onda em 3 alvos (Fluxo 0) -> +9; 4º acerto também soma +3
	s.definir_fluxo_para_teste(0.0)
	s.creditar_acertos_item_5(3, true)
	assert_float(s.fluxo()).is_equal_approx(9.0, 1e-6)
	s.creditar_acertos_item_5(1, true)
	assert_float(s.fluxo()).is_equal_approx(12.0, 1e-6)


func test_ac_sf_05_e_06_e_25_congelado_hitstop_e_passa_de_camara() -> void:
	# AC-SF-05 e AC-SF-25: Selo ativo, recarga 20 e Fluxo 50 em 6 passos de hitstop -> nada muda; no 7º anda
	var s := Selo.new()
	var buf := BufferDeComandos.new(10)
	buf.apertar(Acoes.SELO)
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, true)
	s.definir_fluxo_para_teste(50.0)
	s.definir_recarga_para_teste(20)
	var rest_antes: int = s.selos_ativos()[0].restante
	for _i: int in 6:
		s.passo_congelado()
	assert_float(s.fluxo()).is_equal_approx(50.0, 1e-6)
	assert_int(s.recarga()).is_equal(20)
	assert_int(s.selos_ativos()[0].restante).is_equal(rest_antes)

	# 7º passo vivo: avança normalmente
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA)
	assert_float(s.fluxo()).is_equal_approx(50.06, 1e-6)
	assert_int(s.recarga()).is_equal(19)
	assert_int(s.selos_ativos()[0].restante).is_equal(rest_antes - 1)

	# AC-SF-06: Transição na metade do wipe mantém Fluxo 55 e recarga; início da run = 100
	s.definir_fluxo_para_teste(55.0)
	s.definir_recarga_para_teste(12)
	s.ao_camara_nova()
	assert_float(s.fluxo()).is_equal_approx(55.0, 1e-6)
	assert_int(s.recarga()).is_equal(12)
	s.nova_run()
	assert_float(s.fluxo()).is_equal_approx(100.0, 1e-6)


func test_ac_sf_26_e_29_e_30_item_8_pulso_virote_e_maldicao() -> void:
	# AC-SF-26: Fluxo 38,9; Pulso acerta no item 8 do passo 0 -> sai com 41,96 e o Selo só sai no passo 1
	var s := Selo.new()
	s.definir_fluxo_para_teste(38.9)
	var buf := BufferDeComandos.new(10)
	buf.apertar(Acoes.SELO)
	# Passo 0: item 6 roda com 38,9 + 0,06 = 38,96 (< 40, não planta); depois item 8 credita +3 -> 41,96
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, true)
	assert_int(s.quantidade_ativos()).is_equal(0)
	s.creditar_acerto_tardio(0, true)
	assert_float(s.fluxo()).is_equal_approx(41.96, 1e-6)
	# Passo 1: agora o Selo sai do buffer
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, false)
	assert_int(s.quantidade_ativos()).is_equal(1)

	# AC-SF-29: Virote acerta no item 8 com Fluxo 10 -> sai do passo com 13,06
	var s_besta := Selo.new()
	s_besta.definir_fluxo_para_teste(10.0)
	s_besta.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA)
	s_besta.creditar_acerto_tardio(0, true) # Virote (de_arma = true)
	assert_float(s_besta.fluxo()).is_equal_approx(13.06, 1e-6)

	# AC-SF-30: Ataque básico da Maldição, Saída, Entrada e pouso do Chamado têm de_arma = false -> só 10,06
	var s_mald := Selo.new()
	s_mald.definir_fluxo_para_teste(10.0)
	s_mald.creditar_acertos_item_5(4, false)
	s_mald.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA)
	s_mald.creditar_acerto_tardio(0, false)
	assert_float(s_mald.fluxo()).is_equal_approx(10.06, 1e-6)
