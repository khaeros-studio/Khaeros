extends GdUnitTestSuite


func test_ac_ml_05_e_06_fio_estoura_acima_de_480_px_e_retorna_com_histerese_ate_105_px() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"espreitador_da_fenda")
	var id_m: int = amb.modulo.maldicao_em_campo(0)
	var m: MaldicaoRef = amb.modulo.ref_de(id_m)

	# Posiciona a Maldição a 495 px do jogador (> alcance_fio_px = 480 px) e um inimigo colado nela
	m.pos = Vector2(895.0, 400.0)
	FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(905.0, 400.0), 500.0)

	amb.avancar_passo(false)
	assert_bool(m.estourou_fio).is_true()
	assert_int(m.alvo_id).is_equal(-1)
	assert_int(int(m.estado)).is_equal(int(MaldicaoRef.Estado.SEGUINDO))
	assert_int(amb.eventos.filtrar(EventosMaldicoes.EvFioEstourou.TIPO).size()).is_equal(1)

	# Enquanto d_jog > 105 px (distancia_seguir_px), mantém estourou_fio = true (histerese F1)
	for _i in range(15):
		amb.avancar_passo(false)
	assert_float(m.pos.distance_to(amb.pos_jogador)).is_greater(105.0)
	assert_bool(m.estourou_fio).is_true()

	# Ao entrar em <= 105 px do jogador, libera o fio no mesmo passo
	for _i in range(60):
		amb.avancar_passo(false)
	assert_float(m.pos.distance_to(amb.pos_jogador)).is_less_equal(105.0 + 0.01)
	assert_bool(m.estourou_fio).is_false()


func test_ac_ml_05_prioriza_inimigo_com_marca_do_virote_dentro_do_fio_e_desempata_por_id() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"espreitador_da_fenda", &"vulto_mudo")
	var id_m: int = amb.modulo.maldicao_em_campo(0)
	var m: MaldicaoRef = amb.modulo.ref_de(id_m)
	m.pos = Vector2(400.0, 400.0)

	# Dois inimigos equidistantes do jogador (100 px): sem marca, escolhe o menor id
	var id_1 := FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(400.0, 300.0), 300.0)
	var id_2 := FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(400.0, 500.0), 300.0)
	assert_bool(id_1 < id_2).is_true()

	amb.avancar_passo(false)
	assert_int(m.alvo_id).is_equal(id_1)

	# Marca o inimigo 2 com o Virote: no próximo passo prioriza id_2
	amb.modulo.registrar_acerto_virote(0, id_2)
	amb.avancar_passo(false)
	assert_int(m.alvo_id).is_equal(id_2)


func test_ac_ml_31_faro_do_vinculo_aplica_mais_15_porcento_velocidade_perseguindo_marcado() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"espreitador_da_fenda", &"vulto_mudo")
	var id_m: int = amb.modulo.maldicao_em_campo(0)
	var m: MaldicaoRef = amb.modulo.ref_de(id_m)
	m.pos = Vector2(400.0, 400.0)

	var vel_base := m.velocidade_pxs()
	assert_float(vel_base).is_equal_approx(435.0, 0.01)

	var id_in := FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(650.0, 400.0), 300.0)
	amb.modulo.registrar_acerto_virote(0, id_in)
	amb.avancar_passo(false)

	assert_int(int(m.estado)).is_equal(int(MaldicaoRef.Estado.PERSEGUINDO))
	assert_float(m.velocidade_pxs()).is_equal_approx(435.0 * 1.15, 0.01)
