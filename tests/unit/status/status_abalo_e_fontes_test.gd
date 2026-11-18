class_name StatusAbaloEFontesTest
extends GdUnitTestSuite
## Testes das Stories 004 e 005 (`efeitos-de-status`): Abalo (`-30%` dano causado pelo inimigo
## via fonte `status:abalo` no `Portador`), regra `max(restante, D)`, projétil já em voo,
## chefe abalável e fontes de status da arma vs Maldição (`AC-ST-09..11, 17, 18, 27..30`).


func test_ac_st_09_10_11_abalo_preserva_maior_duracao_entre_240_90_e_30_passos() -> void:
	var mod_tuning := ModifiersTuning.new()
	var portador := Portador.new(301, -1, Atributos.Especie.INIMIGO,
			{Atributos.VIDA_MAX: 100.0}, mod_tuning)
	var m := ModuloDeStatus.new()
	m.registrar_combatente(301, &"inimigo", portador)

	# AC-ST-09: aplica abalo padrão (4s = 240 passos) -> fonte status:abalo ativa no Portador
	assert_bool(m.aplicar_status(301, &"abalo", 1.0)).is_true()
	assert_bool(m.abalado(301)).is_true()
	assert_int(m.estado(301)[&"abalo"][&"restante"]).is_equal(240)
	assert_bool(portador.tem_fonte(&"status:abalo")).is_true()
	assert_float(m.multiplicador_dano_inimigo(301)).is_equal_approx(0.70, 0.0001)

	# Avança 60 passos -> restante 180
	for _i in range(60):
		m.tick(301)
	assert_int(m.estado(301)[&"abalo"][&"restante"]).is_equal(180)

	# AC-ST-10: Eco de Muralha (1,5s = 90 passos) com restante=180 -> max(180, 90) = 180 (não encurta!)
	m.aplicar_eco_de_muralha(301)
	assert_int(m.estado(301)[&"abalo"][&"restante"]).is_equal(180)

	# Selo de Cinza (0,5s = 30 passos) com restante=180 -> max(180, 30) = 180
	m.aplicar_abalo_do_selo(301)
	assert_int(m.estado(301)[&"abalo"][&"restante"]).is_equal(180)

	# Avança até restar 40 passos, então Eco de Muralha (90 passos) -> max(40, 90) = 90
	for _i in range(140):
		m.tick(301)
	assert_int(m.estado(301)[&"abalo"][&"restante"]).is_equal(40)
	m.aplicar_eco_de_muralha(301)
	assert_int(m.estado(301)[&"abalo"][&"restante"]).is_equal(90)

	# AC-ST-11: após os 90 passos restantes, abalo expira e remove a fonte status:abalo
	for _i in range(90):
		m.tick(301)
	assert_bool(m.abalado(301)).is_false()
	assert_bool(portador.tem_fonte(&"status:abalo")).is_false()
	assert_float(m.multiplicador_dano_inimigo(301)).is_equal_approx(1.0, 0.0001)


func test_ac_st_17_18_reducao_30_pct_vale_para_corpo_a_corpo_projetil_em_voo_e_chefe() -> void:
	var mod_tuning := ModifiersTuning.new()
	var p_inimigo := Portador.new(302, -1, Atributos.Especie.INIMIGO,
			{Atributos.VIDA_MAX: 75.0}, mod_tuning)
	var p_chefe := Portador.new(303, -1, Atributos.Especie.INIMIGO,
			{Atributos.VIDA_MAX: 900.0}, mod_tuning)

	var m := ModuloDeStatus.new()
	m.registrar_combatente(302, &"inimigo", p_inimigo)
	m.registrar_combatente(303, &"inimigo", p_chefe)

	# Sem abalo: dano 20 -> 20
	assert_int(m.calcular_dano_causado_pelo_inimigo(302, 20)).is_equal(20)

	# AC-ST-17: Projétil disparado antes do abalo, mas o autor 302 recebe abalo antes do impacto ->
	# na hora do impacto consulta o autor 302 e reduz 20 * 0,70 = 14
	m.aplicar_status(302, &"abalo", 1.0)
	assert_int(m.calcular_dano_causado_pelo_inimigo(302, 20)).is_equal(14)

	# Piso de 1 quando dano_base > 0 (F4): dano 1 * 0,70 = 0,7 -> round 1
	assert_int(m.calcular_dano_causado_pelo_inimigo(302, 1)).is_equal(1)

	# AC-ST-18: Chefe Carcereiro recebe sangramento, queimadura e abalo normalmente
	assert_bool(m.aplicar_status(303, &"sangramento", 4.0)).is_true()
	assert_bool(m.aplicar_status(303, &"queimadura", 3.0)).is_true()
	assert_bool(m.aplicar_status(303, &"abalo", 1.0)).is_true()
	assert_int(m.calcular_dano_causado_pelo_inimigo(303, 30)).is_equal(21)


func test_ac_st_27_28_29_30_fontes_da_arma_somam_com_bencao_e_maldicao_nao_herda_gatilhos_da_arma() -> void:
	var mod_tuning := ModifiersTuning.new()
	var p_jogador := Portador.new(1, 0, Atributos.Especie.JOGADOR,
			{Atributos.VIDA_MAX: 130.0}, mod_tuning)

	# Arma base com gatilho acerto_ataque de sangramento (+1) + bênção Toque Carmesim (comum +2,0 -> +2)
	var g_arma := GatilhoAtivo.new(&"acerto_ataque", 1.0, {"status": "sangramento"})
	var g_bencao := GatilhoAtivo.new(&"acerto_ataque", 2.0, {"status": "sangramento"})
	p_jogador.aplicar_fonte(FonteDeModificador.new(&"arma:base", [], [g_arma]))
	p_jogador.aplicar_fonte(FonteDeModificador.new(&"bencao:ferro_1", [], [g_bencao]))

	var m := ModuloDeStatus.new()
	m.registrar_combatente(304, &"inimigo")
	m.registrar_combatente(305, &"inimigo")

	# AC-ST-27 / F1: Golpe de ataque da arma soma 1 + 2 = 3 acúmulos de sangramento em uma única chamada
	m.aplicar_fontes_no_acerto(304, &"arma", &"ataque", p_jogador)
	assert_int(m.estado(304)[&"sangramento"][&"acumulos"]).is_equal(3)

	# AC-ST-28 / 29 / 30 (R3a): Golpe da Maldição NÃO dispara Toque Carmesim nem gatilhos da arma!
	# Vulto Mudo aplica apenas seu sangramento nativo (+1); Espreitador aplica queimadura (+1); Baluarte abalo (+1).
	m.aplicar_fontes_no_acerto(305, &"maldicao", &"ataque", p_jogador, &"sangramento", 1)
	assert_int(m.estado(305)[&"sangramento"][&"acumulos"]).is_equal(1)

	m.aplicar_fontes_no_acerto(305, &"maldicao", &"ataque", p_jogador, &"queimadura", 1)
	assert_int(m.estado(305)[&"queimadura"][&"acumulos"]).is_equal(1)

	m.aplicar_fontes_no_acerto(305, &"maldicao", &"ataque", p_jogador, &"abalo", 1)
	assert_bool(m.abalado(305)).is_true()
