extends GdUnitTestSuite
## AC-11 (GDD Cena R5): ordenação por pé e registro de criação visual.


func test_ordenar_pe_520_contra_500_o_de_520_fica_na_frente() -> void:
	var ord := OrdenacaoPorPe.new()
	ord.definir(0, Vector2(300, 520), 0)
	ord.definir(1, Vector2(300, 500), 1)
	ord.ordenar(2)
	assert_array(ord.ordem()).is_equal([1, 0])


func test_ordenar_empate_em_500_quem_nasceu_depois_fica_na_frente() -> void:
	var reg := RegistroDeCriacaoVisual.new()
	var ord_antigo := reg.registrar_criacao(&"antigo")
	var ord_novo := reg.registrar_criacao(&"novo")
	var ord := OrdenacaoPorPe.new()
	ord.definir(0, Vector2(200, 500), ord_novo)
	ord.definir(1, Vector2(900, 500), ord_antigo)
	ord.ordenar(2)
	assert_array(ord.ordem()).is_equal([1, 0])


func test_ordenar_empate_estavel_por_100_quadros_nao_muda() -> void:
	var reg := RegistroDeCriacaoVisual.new()
	var ord := OrdenacaoPorPe.new()
	var ids: Array[StringName] = [&"a", &"b", &"c", &"d"]
	for id in ids:
		reg.registrar_criacao(id)
	# Ordem de definição propositalmente diferente da de criação.
	var definidos: Array[StringName] = [&"c", &"a", &"d", &"b"]
	for i in definidos.size():
		ord.definir(i, Vector2(100.0 * i, 500), reg.ordinal_de(definidos[i]))
	ord.ordenar(4)
	var primeira := ord.ordem()
	for _q in 100:
		for i in definidos.size():
			ord.definir(i, Vector2(100.0 * i, 500), reg.ordinal_de(definidos[i]))
		assert_bool(ord.ordenar(4)).is_false()
		assert_array(ord.ordem()).is_equal(primeira)
	assert_array(primeira).is_equal([1, 3, 0, 2])


func test_ordenar_projetil_sombra_480_com_voo_menos_80_fica_atras_do_inimigo_500() -> void:
	var ord := OrdenacaoPorPe.new()
	var pe_proj := OrdenacaoPorPe.pe_de_projetil(Vector2(400, 480), Vector2(0, -80))
	ord.definir(0, pe_proj, 5, Vector2(0, -80))
	ord.definir(1, Vector2(400, 500), 1)
	ord.ordenar(2)
	assert_array(ord.ordem()).is_equal([0, 1])


func test_pe_de_objeto_grande_usa_o_centro_da_base() -> void:
	var pe := OrdenacaoPorPe.pe_de_objeto_grande(Rect2(100, 300, 200, 120))
	assert_vector(pe).is_equal(Vector2(200, 420))


func test_ordenar_objeto_grande_com_base_abaixo_do_jogador_fica_na_frente() -> void:
	var ord := OrdenacaoPorPe.new()
	# Topo do sprite muito acima do jogador, mas a base (y 420) está abaixo dele (y 400).
	ord.definir(0, OrdenacaoPorPe.pe_de_objeto_grande(Rect2(100, 300, 200, 120)), 0)
	ord.definir(1, Vector2(200, 400), 1)
	ord.ordenar(2)
	assert_array(ord.ordem()).is_equal([1, 0])


func test_ordenar_quando_a_ordem_muda_devolve_true() -> void:
	var ord := OrdenacaoPorPe.new()
	ord.definir(0, Vector2(0, 500), 0)
	ord.definir(1, Vector2(0, 510), 1)
	assert_bool(ord.ordenar(2)).is_true()
	assert_bool(ord.ordenar(2)).is_false()
	ord.definir(0, Vector2(0, 520), 0)
	assert_bool(ord.ordenar(2)).is_true()
	assert_array(ord.ordem()).is_equal([1, 0])


func test_registro_reassociar_mesma_identidade_preserva_o_ordinal() -> void:
	var reg := RegistroDeCriacaoVisual.new()
	var o := reg.registrar_criacao(7)
	reg.registrar_criacao(8)
	assert_int(reg.ordinal_de(7)).is_equal(o)
	assert_int(reg.ordinal_de(7)).is_equal(o)


func test_registro_novo_spawn_no_mesmo_slot_recebe_ordinal_maior() -> void:
	var reg := RegistroDeCriacaoVisual.new()
	var primeiro := reg.registrar_criacao(3)
	reg.registrar_criacao(4)
	reg.liberar(3)
	assert_int(reg.ordinal_de(3)).is_equal(RegistroDeCriacaoVisual.SEM_ORDINAL)
	var respawn := reg.registrar_criacao(3)
	assert_int(respawn).is_greater(primeiro)
	assert_int(respawn).is_greater(reg.ordinal_de(4))


func test_ordenar_empate_apos_reuso_de_slot_o_respawn_fica_na_frente() -> void:
	var reg := RegistroDeCriacaoVisual.new()
	reg.registrar_criacao(1)
	reg.registrar_criacao(2)
	reg.liberar(1)
	reg.registrar_criacao(1)
	var ord := OrdenacaoPorPe.new()
	ord.definir(0, Vector2(0, 500), reg.ordinal_de(1))
	ord.definir(1, Vector2(0, 500), reg.ordinal_de(2))
	ord.ordenar(2)
	assert_array(ord.ordem()).is_equal([1, 0])
