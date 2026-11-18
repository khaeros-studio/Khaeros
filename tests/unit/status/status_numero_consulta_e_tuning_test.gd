class_name StatusNumeroConsultaETuningTest
extends GdUnitTestSuite
## Testes das Stories 006 e 007 (`efeitos-de-status`): número agregado `EvNumeroDeStatus` a cada
## `30` passos vivos com transporte de resto (`F5`), descarga final ao expirar, consulta pura
## `estado(inimigo_id)`, limite visual `> 9` inimigos marcados e validação `ST1–ST11` (`AC-ST-19..23, 26`).


func test_ac_st_19_20_21_22_numero_agregado_a_cada_30_passos_com_transporte_de_resto_e_descarga_final() -> void:
	var estado_vida := [500.0]
	var m := ModuloDeStatus.new()
	m.registrar_combatente(401, &"inimigo")
	m.configurar_callbacks(func(_id: int, dp: float) -> bool:
		estado_vida[0] -= dp
		return float(estado_vida[0]) <= 0.0
	)

	# AC-ST-19 & AC-ST-20: 1 acúmulo de sangramento (2,4/s = 1,2 por janela de 0,5s / 30 passos)
	# Em 240 passos (8 janelas de 30 passos):
	# Janela 1: acum = 1,2 -> exibe 1, resto 0,2
	# Janela 2: acum = 0,2 + 1,2 = 1,4 -> exibe 1, resto 0,4
	# Janela 3: acum = 0,4 + 1,2 = 1,6 -> exibe 2, resto -0,4
	# Janela 4: acum = -0,4 + 1,2 = 0,8 -> exibe 1, resto -0,2
	# Janela 5: acum = -0,2 + 1,2 = 1,0 -> exibe 1, resto 0,0
	# Janela 6: acum = 1,2 -> exibe 1, resto 0,2
	# Janela 7: acum = 1,4 -> exibe 1, resto 0,4
	# Janela 8: acum = 1,6 -> exibe 2, resto -0,4 (expira em 240: round(-0,4) = 0 -> sem descarga extra)
	# Soma exibida = 1+1+2+1+1+1+1+2 = 10 == round(9,6)
	m.aplicar_status(401, &"sangramento", 1.0)
	var valores: Array[int] = []
	for _i in range(240):
		m.tick(401)
		for ev: EventoDoPasso in m.drenar_eventos():
			if ev is EvNumeroDeStatus:
				valores.append((ev as EvNumeroDeStatus).valor)

	assert_array(valores).is_equal([1, 1, 2, 1, 1, 1, 1, 2])
	var soma: int = 0
	for v: int in valores:
		soma += v
	assert_int(soma).is_equal(10)

	# AC-ST-21: Sangramento + Queimadura juntos emitem 1 único número combinado por janela de 30 passos
	m.aplicar_status(401, &"sangramento", 2.0) # 2,4 na janela
	m.aplicar_status(401, &"queimadura", 1.0)  # 2,4 na janela -> total 4,8 -> exibe 5
	for _i in range(30):
		m.tick(401)
	var evs_comb := m.drenar_eventos()
	assert_int(evs_comb.size()).is_equal(1)
	assert_int((evs_comb[0] as EvNumeroDeStatus).valor).is_equal(5)

	# AC-ST-22: Descarga final quando o último DoT expira antes de fechar janela de 30 passos
	var m2 := ModuloDeStatus.new()
	m2.registrar_combatente(402, &"inimigo")
	m2.configurar_callbacks(func(_id: int, _dp: float) -> bool: return false)
	# Duração customizada de 0,25s (15 passos) com 5 acúmulos de sangramento:
	# 15 passos * (5 * 2,4 / 60) = 15 * 0,20 = 3,0 de dano acumulado quando expira no passo 15
	m2.aplicar_status(402, &"sangramento", 5.0, 0.25)
	for _i in range(15):
		m2.tick(402)
	var evs_descarga := m2.drenar_eventos()
	assert_int(evs_descarga.size()).is_equal(1)
	assert_int((evs_descarga[0] as EvNumeroDeStatus).valor).is_equal(3)


func test_ac_st_23_consulta_estado_e_reducao_visual_acima_de_9_inimigos() -> void:
	var m := ModuloDeStatus.new()
	for id_in in range(501, 512): # 11 inimigos
		m.registrar_combatente(id_in, &"inimigo")

	m.aplicar_status(501, &"sangramento", 2.0)
	m.aplicar_status(501, &"queimadura", 5.0)
	m.aplicar_status(501, &"abalo", 1.0)

	# Apenas 1 inimigo marcado (<= 9): devolve os 3 sinais visuais
	assert_int(m.sinais_visuais(501).size()).is_equal(3)

	# Marca mais 9 inimigos (total = 10 > 9): reduz sinais_visuais(501) para 1 (o de maior acúmulo = queimadura com 5)
	for id_in in range(502, 511):
		m.aplicar_status(id_in, &"sangramento", 1.0)
	assert_int(m.contar_inimigos_marcados()).is_equal(10)
	var sinais_sob_carga := m.sinais_visuais(501)
	assert_int(sinais_sob_carga.size()).is_equal(1)
	assert_that(sinais_sob_carga[0][&"id"]).is_equal(&"queimadura")
	assert_int(sinais_sob_carga[0][&"acumulos"]).is_equal(5)


func test_ac_st_26_validacao_st1_a_st11_e_relatorio_st9() -> void:
	var padrao := ValidadorStatus.fabrica()
	var diags_ok := ValidadorStatus.validar_tuning(padrao)
	assert_int(diags_ok.size()).is_equal(0)

	# ST9 informativo: passos inteiros nos alvos de referência
	var rel := ValidadorStatus.relatorio_st9(padrao)
	assert_int(rel[&"sangramento_eco_75_passos"]).is_equal(188)
	assert_int(rel[&"sangramento_anomalia_60_passos"]).is_equal(150)
	assert_int(rel[&"sangramento_fenda_115_passos"]).is_equal(288)
	assert_int(rel[&"queimadura_anomalia_50_passos"]).is_equal(105)

	# ST1..ST4 erros
	var invalido := ValidadorStatus.fabrica()
	invalido.duracao_sangramento_s = 0.0
	invalido.dano_queimadura_s = -1.0
	invalido.max_acumulos_queimadura = 0
	invalido.reducao_dano_causado = 1.0
	var diags_err := ValidadorStatus.validar_tuning(invalido)
	assert_int(Diagnostico.contar_erros(diags_err)).is_greater_equal(4)
