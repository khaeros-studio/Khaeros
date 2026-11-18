extends GdUnitTestSuite


func test_ac_ml_01_apenas_uma_maldicao_ativa_em_campo_e_reserva_fora() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"espreitador_da_fenda")
	var est: EstadoPactoLeitura = amb.modulo.estado_pacto(0)

	assert_object(est.campo).is_not_null()
	assert_object(est.reserva).is_not_null()
	assert_str(String(est.campo.especie_id)).is_equal("vulto_mudo")
	assert_str(String(est.reserva.especie_id)).is_equal("espreitador_da_fenda")
	assert_str(String(est.campo.estado)).is_equal("Ativa")
	assert_str(String(est.reserva.estado)).is_equal("Pronta")

	var id_campo: int = amb.modulo.maldicao_em_campo(0)
	assert_bool(id_campo != -1).is_true()
	assert_bool(amb.modulo.maldicao_atingivel(id_campo)).is_true()


func test_ac_ml_02_sem_reserva_troca_eh_recusada_com_evento() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"")
	var est_antes: EstadoPactoLeitura = amb.modulo.estado_pacto(0)
	assert_object(est_antes.reserva).is_null()
	assert_bool(est_antes.troca_disponivel).is_false()

	amb.r_troca = true
	amb.avancar_passo(false)

	var est_depois: EstadoPactoLeitura = amb.modulo.estado_pacto(0)
	assert_str(String(est_depois.campo.especie_id)).is_equal("vulto_mudo")
	assert_int(est_depois.recarga_troca_passos).is_equal(0)

	var evs_rec: Array = amb.eventos.filtrar(EventosMaldicoes.EvTrocaIndisponivel.TIPO)
	assert_int(evs_rec.size()).is_equal(1)
	assert_str(String((evs_rec[0] as EventosMaldicoes.EvTrocaIndisponivel).motivo)).is_equal("sem_reserva")


func test_ac_ml_03_faccao_aliada_nao_fere_jogador_e_nao_entra_em_atingiveis_da_ia() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"baluarte_de_cinza")
	var id_inimigo := FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(430.0, 505.0))

	# A lista atingiveis() do ModuloDeIA nunca inclui a Maldição aliada
	var atingiveis: Array[VistaDeInimigo] = amb.ia.atingiveis()
	assert_int(atingiveis.size()).is_equal(1)
	assert_int(atingiveis[0].id).is_equal(id_inimigo)

	# Quando a Maldição conclui o ataque básico sobre o inimigo próximo, o jogador não sofre dano
	var vida_jog_antes: int = amb.combate_aliado.vida_jogador
	for _i in range(20):
		amb.avancar_passo(false)
	assert_int(amb.combate_aliado.vida_jogador).is_equal(vida_jog_antes)
	assert_int(amb.combate_aliado.golpes_registrados.size()).is_greater_equal(1)
	assert_array(amb.combate_aliado.golpes_registrados[0]["alvos"]).contains([id_inimigo])
