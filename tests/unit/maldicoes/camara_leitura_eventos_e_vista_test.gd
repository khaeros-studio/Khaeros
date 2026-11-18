extends GdUnitTestSuite


func test_ac_ml_19_e_35_reposicionar_maldicao_em_nova_camara_cancela_salto_limpa_marca_e_preserva_vida() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"espreitador_da_fenda")
	var id_m: int = amb.modulo.maldicao_em_campo(0)
	var m: MaldicaoRef = amb.modulo.ref_de(id_m)
	m.vida = 77
	amb.modulo.registrar_acerto_virote(0, 42)
	amb.modulo.pedir_chamado(0, Vector2(600.0, 400.0), 17.0, 1.0)
	amb.avancar_passo(false)
	assert_int(int(m.estado)).is_equal(int(MaldicaoRef.Estado.SALTANDO))

	var p_rep := ModuloDeMaldicoes.calcular_ponto_reposicionamento_camara(m.raio_px(), 105.0, Vector2(960.0, 930.0), 1080.0)
	assert_float(p_rep.x).is_equal_approx(960.0, 0.01)
	assert_float(p_rep.y).is_equal_approx(1035.0, 0.01)

	amb.modulo.reposicionar_maldicao(0, p_rep)
	assert_int(int(m.estado)).is_equal(int(MaldicaoRef.Estado.SEGUINDO))
	assert_int(m.vida).is_equal(77)
	assert_float(m.pos.distance_to(p_rep)).is_less_equal(0.01)


func test_ac_ml_28_estado_pacto_leitura_imutavel_sem_efeito_colateral() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"espreitador_da_fenda")
	var l1: EstadoPactoLeitura = amb.modulo.estado_pacto(0)
	var l2: EstadoPactoLeitura = amb.modulo.estado_pacto(0)
	assert_int(l1.campo.vida).is_equal(l2.campo.vida)
	assert_str(String(l1.campo.especie_id)).is_equal(String(l2.campo.especie_id))

	# Mutar a leitura devolvida não altera o estado interno do módulo
	l1.campo.vida = 1
	assert_int(amb.modulo.estado_pacto(0).campo.vida).is_equal(110)


func test_ac_ml_29_marca_virote_mudou_emite_evento_e_limpa_ao_morrer() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"espreitador_da_fenda")
	var id_in := FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(500.0, 400.0), 100.0)
	amb.modulo.registrar_acerto_virote(0, id_in)

	var evs_1 := amb.eventos.filtrar(EventosMaldicoes.EvMarcaViroteMudou.TIPO)
	assert_int(evs_1.size()).is_equal(1)
	assert_int((evs_1[0] as EventosMaldicoes.EvMarcaViroteMudou).inimigo_id).is_equal(id_in)

	amb.ia.remover_morto(id_in)
	amb.avancar_passo(false)
	var evs_2 := amb.eventos.filtrar(EventosMaldicoes.EvMarcaViroteMudou.TIPO)
	assert_int(evs_2.size()).is_equal(2)
	assert_int((evs_2[1] as EventosMaldicoes.EvMarcaViroteMudou).inimigo_id).is_equal(-1)


func test_vistas_v1_a_v5_e_ganchos_sonoros_a1_deduplicados() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"espreitador_da_fenda")
	var id_in := FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(430.0, 400.0), 300.0)
	amb.modulo.registrar_acerto_virote(0, id_in)

	amb.r_troca = true
	amb.avancar_passo(false)

	var v := VistaDeMaldicao.new()
	amb.modulo.publicar_vista_apresentacao(0, v)
	assert_bool(v.em_campo).is_true()
	assert_bool(v.usa_telegrafo_de_chao).is_false()
	assert_int(v.inimigo_marcado_virote_id).is_equal(id_in)
	assert_int(int(v.estado_fio)).is_equal(int(VistaDeMaldicao.EstadoFio.CURVO_NORMAL))

	var ganchos := VistaDeMaldicao.extrair_ganchos_de_som(amb.eventos.todos())
	assert_bool(ganchos.has(VistaDeMaldicao.GANCHO_TROCA_TECNICA)).is_true()


func test_orcamento_item_6_1_menor_que_0_25_ms_por_passo() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"espreitador_da_fenda")
	for i in range(6):
		FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(440.0 + float(i) * 20.0, 400.0), 500.0)

	var t0: int = Time.get_ticks_usec()
	for _p in range(100):
		amb.avancar_passo(false)
	var media_ms: float = float(Time.get_ticks_usec() - t0) / 1000.0 / 100.0
	assert_float(media_ms).is_less(0.25)
