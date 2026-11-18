extends GdUnitTestSuite


func test_ac_ml_17_e_18_chamado_salto_12_passos_imobiliza_comum_mais_perto_e_atrai_90_passos() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"espreitador_da_fenda")
	# Dois inimigos comuns dentro do raio do Chamado (135 px) do ponto (600, 400):
	# id_1 a 20 px do impacto e id_2 a 80 px do impacto
	var id_1 := FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(620.0, 400.0), 500.0)
	var id_2 := FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(680.0, 400.0), 500.0)

	# Pede o Chamado com M_chamado = 1.20 e dano_golpe = 17.0 -> round(17 * 1.20) = 20
	amb.modulo.pedir_chamado(0, Vector2(600.0, 400.0), 17.0, 1.20)
	amb.avancar_passo(false) # Sub-passo 4 inicia o salto (12 passos)

	assert_str(String(amb.modulo.estado_pacto(0).campo.estado)).is_equal("Saltando")
	assert_int(amb.eventos.filtrar(EventosMaldicoes.EvChamadoSalto.TIPO).size()).is_equal(1)

	for _i in range(11):
		amb.avancar_passo(false)
	assert_int(amb.eventos.filtrar(EventosMaldicoes.EvChamadoPouso.TIPO).size()).is_equal(0)

	# No 12º passo após o início, pousa em (600, 400), causa 20 de dano nos 2, imobiliza só id_1 e atrai ambos por 90 passos
	amb.avancar_passo(false)
	assert_int(amb.eventos.filtrar(EventosMaldicoes.EvChamadoPouso.TIPO).size()).is_equal(1)
	assert_int(amb.combate_aliado.golpes_registrados.size()).is_equal(1)
	assert_int(int(amb.combate_aliado.golpes_registrados[0]["dano_int"])).is_equal(20)

	assert_bool(amb.ia.esta_imobilizado(id_1)).is_true()
	assert_bool(amb.ia.esta_imobilizado(id_2)).is_false()
	assert_bool(amb.ia.esta_atraido(id_1)).is_true()
	assert_bool(amb.ia.esta_atraido(id_2)).is_true()


func test_ac_ml_24_efeitos_proprios_no_chamado_eco_de_muralha_e_convergencia() -> void:
	# 1. Baluarte de Cinza: aplica Abalo por 1,50 s no Chamado (Eco de Muralha)
	var amb_bal := FixtureMaldicoes.criar_ambiente(&"baluarte_de_cinza", &"vulto_mudo")
	var id_in_bal := FixtureMaldicoes.nascer_inimigo_padrao(amb_bal, Vector2(620.0, 400.0), 500.0)
	amb_bal.modulo.pedir_chamado(0, Vector2(600.0, 400.0), 17.0, 1.0)
	for _i in range(13):
		amb_bal.avancar_passo(false)
	assert_bool(amb_bal.status_aliado.tem_abalo(id_in_bal)).is_true()

	# 2. Soberano do Limiar: puxa inimigos em <= 210 px por 60 px até parar a 36 px (Convergência)
	var amb_sob := FixtureMaldicoes.criar_ambiente(&"soberano_do_limiar", &"vulto_mudo")
	var id_in_sob := FixtureMaldicoes.nascer_inimigo_padrao(amb_sob, Vector2(750.0, 400.0), 500.0)
	amb_sob.modulo.pedir_chamado(0, Vector2(600.0, 400.0), 17.0, 1.0)
	for _i in range(13):
		amb_sob.avancar_passo(false)
	# De 750 px (distância 150 px de 600), foi puxado 60 px para 690 px
	assert_float(amb_sob.ia.estado_de(id_in_sob).posicao.x).is_equal_approx(690.0, 0.1)


func test_ac_ml_25_chamado_bloqueado_quando_campo_vazio_ou_ja_saltando() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"")
	var id_m: int = amb.modulo.maldicao_em_campo(0)
	amb.modulo.ferir_maldicao(id_m, 250.0, 1.0)
	assert_bool(amb.modulo.pode_chamar(0)).is_false()


func test_ac_ml_32_troca_no_mesmo_passo_do_chamado_eh_recusada_com_motivo_saltando() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"espreitador_da_fenda")
	# No mesmo passo 6.1: sub-passo 4 inicia o salto e sub-passo 5 recusa a troca manual com motivo `saltando`
	amb.modulo.pedir_chamado(0, Vector2(600.0, 400.0), 17.0, 1.0)
	amb.r_troca = true
	amb.avancar_passo(false)

	assert_str(String(amb.modulo.estado_pacto(0).campo.especie_id)).is_equal("vulto_mudo")
	assert_int(amb.modulo.estado_pacto(0).recarga_troca_passos).is_equal(0)
	var evs_rec: Array = amb.eventos.filtrar(EventosMaldicoes.EvTrocaIndisponivel.TIPO)
	assert_int(evs_rec.size()).is_equal(1)
	assert_str(String((evs_rec[0] as EventosMaldicoes.EvTrocaIndisponivel).motivo)).is_equal("saltando")
