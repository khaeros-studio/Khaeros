## Testes unitários da Oficina de Reforja: compra, teto de nível, reembolso e bônus.
extends GdUnitTestSuite

var _oficina: OficinaDeReforja
var _conta: ContaFragmentos


func before_test() -> void:
	_oficina = OficinaDeReforja.new()
	_conta = ContaFragmentos.new(
		FabricasDaEconomia.rates(),
		EventosDoPasso.new(),
		FabricasDaEconomia.RelatorFalso.new()
	)


func test_comprar_com_saldo_suficiente_sobe_nivel_e_desconta() -> void:
	_conta.importar(30)
	assert_int(_oficina.custo_proximo(&"tempera_vital")).is_equal(10)
	assert_bool(_oficina.comprar(&"tempera_vital", _conta)).is_true()
	assert_int(_oficina.nivel(&"tempera_vital")).is_equal(1)
	assert_int(_conta.saldo()).is_equal(20)
	assert_int(_oficina.custo_proximo(&"tempera_vital")).is_equal(15)

	assert_bool(_oficina.comprar(&"tempera_vital", _conta)).is_true()
	assert_int(_oficina.nivel(&"tempera_vital")).is_equal(2)
	assert_int(_conta.saldo()).is_equal(5)
	assert_int(_oficina.custo_proximo(&"tempera_vital")).is_equal(20)


func test_comprar_com_saldo_insuficiente_recusa_sem_alterar() -> void:
	_conta.importar(9)
	assert_bool(_oficina.comprar(&"tempera_vital", _conta)).is_false()
	assert_int(_oficina.nivel(&"tempera_vital")).is_equal(0)
	assert_int(_conta.saldo()).is_equal(9)
	assert_bool(_oficina.comprar(&"inexistente", _conta)).is_false()
	assert_bool(_oficina.comprar(&"tempera_vital", null)).is_false()


func test_teto_de_nivel_impede_compra_extra() -> void:
	_conta.importar(200)
	# reserva_esquiva tem nível máximo 1 e custo 25
	assert_int(_oficina.custo_proximo(&"reserva_esquiva")).is_equal(25)
	assert_bool(_oficina.comprar(&"reserva_esquiva", _conta)).is_true()
	assert_int(_oficina.nivel(&"reserva_esquiva")).is_equal(1)
	assert_int(_oficina.custo_proximo(&"reserva_esquiva")).is_equal(0)
	assert_bool(_oficina.comprar(&"reserva_esquiva", _conta)).is_false()
	assert_int(_oficina.nivel(&"reserva_esquiva")).is_equal(1)
	assert_int(_conta.saldo()).is_equal(175)


func test_reembolsar_tudo_devolve_total_gasto_e_zera_niveis() -> void:
	_conta.importar(100)
	# tempera_vital: 10 + 15 = 25
	assert_bool(_oficina.comprar(&"tempera_vital", _conta)).is_true()
	assert_bool(_oficina.comprar(&"tempera_vital", _conta)).is_true()
	# fio_afiado: 12
	assert_bool(_oficina.comprar(&"fio_afiado", _conta)).is_true()
	# selo_amplificado: 15
	assert_bool(_oficina.comprar(&"selo_amplificado", _conta)).is_true()
	assert_int(_conta.saldo()).is_equal(48)

	var reembolsado := _oficina.reembolsar_tudo(_conta)
	assert_int(reembolsado).is_equal(52)
	assert_int(_conta.saldo()).is_equal(100)
	assert_int(_oficina.nivel(&"tempera_vital")).is_equal(0)
	assert_int(_oficina.nivel(&"fio_afiado")).is_equal(0)
	assert_int(_oficina.nivel(&"selo_amplificado")).is_equal(0)
	assert_int(_oficina.reembolsar_tudo(_conta)).is_equal(0)


func test_calculo_de_bonus() -> void:
	assert_float(_oficina.bonus_vida_plana()).is_equal_approx(0.0, 0.001)
	assert_float(_oficina.multiplicador_dano()).is_equal_approx(1.0, 0.001)
	assert_float(_oficina.multiplicador_velocidade()).is_equal_approx(1.0, 0.001)
	assert_int(_oficina.bonus_cargas_esquiva()).is_equal(0)
	assert_float(_oficina.multiplicador_alcance()).is_equal_approx(1.0, 0.001)

	_conta.importar(500)
	_oficina.comprar(&"tempera_vital", _conta)
	_oficina.comprar(&"tempera_vital", _conta)
	_oficina.comprar(&"fio_afiado", _conta)
	_oficina.comprar(&"passada_firme", _conta)
	_oficina.comprar(&"passada_firme", _conta)
	_oficina.comprar(&"passada_firme", _conta)
	_oficina.comprar(&"reserva_esquiva", _conta)
	_oficina.comprar(&"selo_amplificado", _conta)

	assert_float(_oficina.bonus_vida_plana()).is_equal_approx(20.0, 0.001)
	assert_float(_oficina.multiplicador_dano()).is_equal_approx(1.06, 0.001)
	assert_float(_oficina.multiplicador_velocidade()).is_equal_approx(1.15, 0.001)
	assert_int(_oficina.bonus_cargas_esquiva()).is_equal(1)
	assert_float(_oficina.multiplicador_alcance()).is_equal_approx(1.15, 0.001)


func test_serializar_e_desserializar_respeita_teto() -> void:
	_conta.importar(100)
	_oficina.comprar(&"tempera_vital", _conta)
	_oficina.comprar(&"reserva_esquiva", _conta)
	var dados := _oficina.serializar()

	var outra := OficinaDeReforja.new()
	outra.desserializar(dados)
	assert_int(outra.nivel(&"tempera_vital")).is_equal(1)
	assert_int(outra.nivel(&"reserva_esquiva")).is_equal(1)

	outra.desserializar({"niveis": {"tempera_vital": 99, "reserva_esquiva": -2, "desconhecida": 3}})
	assert_int(outra.nivel(&"tempera_vital")).is_equal(5)
	assert_int(outra.nivel(&"reserva_esquiva")).is_equal(0)
