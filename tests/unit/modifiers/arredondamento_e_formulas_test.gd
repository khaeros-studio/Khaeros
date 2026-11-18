extends GdUnitTestSuite
## Story modificadores-002: ordem canônica, arredondamento próprio, F1/F2/F3
## (AC-04b, AC-05, AC-10, AC-24, determinismo).

const F := preload("res://tests/unit/modifiers/fabrica_de_portadores.gd")
const OP := Modificador.Operacao


func test_arredondar_22_5_da_23_e_22_4_da_22() -> void:
	assert_int(FormulasDeModificadores.arredondar_meio_longe_do_zero(22.5)).is_equal(23)
	assert_int(FormulasDeModificadores.arredondar_meio_longe_do_zero(22.4)).is_equal(22)


func test_arredondar_negativo_e_quase_meio_vai_longe_do_zero_sem_erro() -> void:
	assert_int(FormulasDeModificadores.arredondar_meio_longe_do_zero(-22.5)).is_equal(-23)
	assert_int(FormulasDeModificadores.arredondar_meio_longe_do_zero(0.49999999999999994)).is_equal(0)


func test_formatar_137_5_mostra_138() -> void:
	assert_str(FormulasDeModificadores.formatar_numero_arredondado(137.5)).is_equal("138")


func test_inteiros_devolvem_int_e_velocidade_fica_float() -> void:
	var p := F.jogador(130.0, {Atributos.VELOCIDADE: 10.0, Atributos.CARGAS_ESQUIVA: 2.0})
	for a: StringName in Atributos.INTEIROS:
		assert_int(typeof(p.inteiro(a))).is_equal(TYPE_INT)
	assert_int(typeof(p.valor(Atributos.VELOCIDADE))).is_equal(TYPE_FLOAT)


func test_teto_m_14_08_vira_4() -> void:
	var p := _portador_m_14_08(F.tuning())
	var m := p.congelar_dano(Modificador.Slot.ATAQUE, ContextoDeDano.new(100.0, true)).m_no_impacto(4)
	assert_float(m).is_equal_approx(4.0, F.TOL)


func test_teto_8_m_14_08_vira_8() -> void:
	var t := F.tuning()
	t.teto_multiplicador_dano = 8.0
	var p := _portador_m_14_08(t)
	var m := p.congelar_dano(Modificador.Slot.ATAQUE, ContextoDeDano.new(100.0, true)).m_no_impacto(4)
	assert_float(m).is_equal_approx(8.0, F.TOL)


func test_teto_m_3_20_fica_intacto_e_4_exato_fica_4() -> void:
	var p := F.jogador(100.0)
	p.aplicar_fonte(F.fonte(&"x:p", [F.mod(Atributos.DANO_TODO, OP.PERCENTUAL, 2.2)]))
	assert_float(p.multiplicador_de_dano(Modificador.Slot.ATAQUE, ContextoDeDano.new(100.0))).is_equal_approx(3.2, F.TOL)
	p.aplicar_fonte(F.fonte(&"x:p", [F.mod(Atributos.DANO_TODO, OP.PERCENTUAL, 3.0)]))
	assert_float(p.multiplicador_de_dano(Modificador.Slot.ATAQUE, ContextoDeDano.new(100.0))).is_equal_approx(4.0, F.TOL)


func test_f2_oraculo_2_00_depois_3_20_depois_4_80_sem_teto() -> void:
	var t := F.tuning()
	t.teto_multiplicador_dano = 8.0
	var p := F.jogador(100.0, {}, t)
	for fo: FonteDeModificador in [F.traco_unico(), F.preco_com_nome(), F.impeto(), F.fundo_do_poco(),
			F.linha_contada(), F.penumbra()]:
		p.aplicar_fonte(fo)
	var vida_baixa := 40.0
	var sem_esquiva := p.congelar_dano(Modificador.Slot.ATAQUE, ContextoDeDano.new(vida_baixa, false))
	assert_float(sem_esquiva.m_no_impacto(1)).is_equal_approx(2.0, F.TOL)
	assert_float(sem_esquiva.m_no_impacto(4)).is_equal_approx(3.2, F.TOL)
	var com_esquiva := p.congelar_dano(Modificador.Slot.ATAQUE, ContextoDeDano.new(vida_baixa, true))
	assert_float(com_esquiva.m_no_impacto(4)).is_equal_approx(4.8, F.TOL)
	assert_bool(absf(sem_esquiva.m_no_impacto(1) - 2.36) > F.TOL).is_true()


func test_f2_abalo_da_0_7_e_dois_abalos_continuam_0_7() -> void:
	var p := F.inimigo(30.0)
	p.aplicar_fonte(F.abalo())
	assert_float(p.multiplicador_de_dano(Modificador.Slot.NENHUM, ContextoDeDano.new())).is_equal_approx(0.7, F.TOL)
	p.aplicar_fonte(F.abalo())
	assert_float(p.multiplicador_de_dano(Modificador.Slot.NENHUM, ContextoDeDano.new())).is_equal_approx(0.7, F.TOL)


func test_f2_p_todo_menos_1_5_da_0() -> void:
	var p := F.jogador()
	p.aplicar_fonte(F.fonte(&"x:p", [F.mod(Atributos.DANO_TODO, OP.PERCENTUAL, -1.5)]))
	assert_float(p.multiplicador_de_dano(Modificador.Slot.ATAQUE, ContextoDeDano.new(130.0))).is_equal_approx(0.0, F.TOL)


func test_f3_oraculos() -> void:
	assert_int(FormulasDeModificadores.dano_recebido(20.0 * 0.7, 0.12, 0.6, 1.0)).is_equal(12)
	assert_int(FormulasDeModificadores.dano_recebido(20.0 * 0.7, 0.12, 0.6, 0.5)).is_equal(6)
	assert_int(FormulasDeModificadores.dano_recebido(20.0, 0.9, 0.6, 1.0)).is_equal(8)
	assert_int(FormulasDeModificadores.dano_recebido(20.0 * 0.7, 0.9, 0.6, 1.0)).is_equal(6)
	assert_int(FormulasDeModificadores.dano_recebido(1.0, 0.6, 0.6, 1.0)).is_equal(1)
	assert_int(FormulasDeModificadores.dano_recebido(10.0, -0.2, 0.6, 1.0)).is_equal(10)
	assert_int(FormulasDeModificadores.dano_recebido(10.0 * 1.25, 0.0, 0.6, 1.0)).is_equal(13)


func test_f3_dano_12_com_escudo_15_perde_0_e_sobra_3() -> void:
	assert_int(FormulasDeModificadores.vida_perdida(12, 15)).is_equal(0)
	assert_int(FormulasDeModificadores.escudo_restante(12, 15)).is_equal(3)


func test_ordem_de_insercao_nas_24_permutacoes_da_resultado_identico_bit_a_bit() -> void:
	var fontes: Array[FonteDeModificador] = [F.muro_de_pedras(), F.preco_com_nome(), F.vigor(20.0), F.impeto()]
	var referencia_vida := -1
	var referencia_m := -1.0
	for perm: Array in _permutacoes([0, 1, 2, 3]):
		var p := F.jogador(130.0)
		for i: int in perm:
			p.aplicar_fonte(fontes[i])
		var vida := p.inteiro(Atributos.VIDA_MAX)
		var m := p.multiplicador_de_dano(Modificador.Slot.ATAQUE, ContextoDeDano.new(165.0))
		if referencia_vida < 0:
			referencia_vida = vida
			referencia_m = m
		assert_int(vida).is_equal(165)
		assert_bool(m == referencia_m).is_true()


func _portador_m_14_08(t: ModifiersTuning) -> Portador:
	# 1 + P = 3,2; × 4º acerto 2,2; × pós-esquiva 2,0 = 14,08.
	var p := F.jogador(100.0, {}, t)
	p.aplicar_fonte(F.fonte(&"x:todo", [F.mod(Atributos.DANO_TODO, OP.PERCENTUAL, 1.7)]))
	p.aplicar_fonte(F.traco_unico(0.5))
	p.aplicar_fonte(F.linha_contada(2.2))
	p.aplicar_fonte(F.penumbra(2.0))
	return p


func _permutacoes(itens: Array) -> Array:
	if itens.size() <= 1:
		return [itens]
	var saida: Array = []
	for i: int in itens.size():
		var resto := itens.duplicate()
		var x: Variant = resto.pop_at(i)
		for p: Array in _permutacoes(resto):
			saida.append([x] + p)
	return saida
