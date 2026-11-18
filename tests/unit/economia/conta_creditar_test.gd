## Story economia-001: ContaFragmentos — saldo, creditar e eventos
## (AC-EF-01, 02, 03, 04, 05, 07, 21 do GDD economia-de-fragmentos).
extends GdUnitTestSuite

var _canal: EventosDoPasso
var _relator: FabricasDaEconomia.RelatorFalso
var _conta: ContaFragmentos


func before_test() -> void:
	_canal = EventosDoPasso.new()
	_relator = FabricasDaEconomia.RelatorFalso.new()
	_conta = ContaFragmentos.new(FabricasDaEconomia.rates(), _canal, _relator)


func test_conta_nova_saldo_e_coletados_zero() -> void:
	assert_int(_conta.saldo()).is_equal(0)
	assert_int(_conta.coletados_run()).is_equal(0)
	assert_array(_canal.todos()).is_empty()


func test_creditar_porta_dois_soma_e_emite_um_saldo_mudou() -> void:
	var efetivo := _conta.creditar(ContaFragmentos.PORTA, 2)
	assert_int(efetivo).is_equal(2)
	assert_int(_conta.saldo()).is_equal(2)
	assert_int(_conta.coletados_run()).is_equal(2)
	assert_array(FabricasDaEconomia.resumo_das_mudancas(_canal.todos())).is_equal(PackedStringArray(["2|2|porta"]))


func test_creditar_tres_vezes_acumula_e_emite_na_ordem() -> void:
	_conta.creditar(ContaFragmentos.PORTA, 2)
	_conta.creditar(ContaFragmentos.PORTA, 3)
	_conta.creditar(ContaFragmentos.VITORIA, 15)
	assert_int(_conta.saldo()).is_equal(20)
	assert_int(_conta.coletados_run()).is_equal(20)
	assert_array(FabricasDaEconomia.resumo_das_mudancas(_canal.todos())).is_equal(
		PackedStringArray(["2|2|porta", "5|3|porta", "20|15|vitoria"]))


func test_creditar_quantidade_invalida_recusa_ec1_sem_mudanca() -> void:
	var invalidas: Array = [0, -1, 2.5, 2.0, NAN]
	for q: Variant in invalidas:
		assert_int(_conta.creditar(ContaFragmentos.PORTA, q)).is_equal(0)
	assert_int(_conta.saldo()).is_equal(0)
	assert_int(_conta.coletados_run()).is_equal(0)
	assert_array(_canal.todos()).is_empty()
	assert_int(_relator.codigos.size()).is_equal(invalidas.size())
	for c: StringName in _relator.codigos:
		assert_str(String(c)).is_equal(String(ContaFragmentos.EC1))


func test_creditar_origem_abate_recusa_ec1_sem_mudanca() -> void:
	assert_int(_conta.creditar(&"abate", 1)).is_equal(0)
	assert_int(_conta.creditar(&"elite", 1)).is_equal(0)
	assert_int(_conta.saldo()).is_equal(0)
	assert_array(_canal.todos()).is_empty()
	assert_array(_relator.codigos).is_equal([ContaFragmentos.EC1, ContaFragmentos.EC1])
	assert_bool(ContaFragmentos.ORIGENS_VALIDAS.has(&"abate")).is_false()
	assert_bool(ContaFragmentos.ORIGENS_VALIDAS.has(&"elite")).is_false()


func test_creditar_chefe_e_provacao_aceitas_como_validas() -> void:
	assert_int(_conta.creditar(ContaFragmentos.CHEFE, 6)).is_equal(6)
	assert_int(_conta.creditar(ContaFragmentos.PROVACAO, 3)).is_equal(3)
	assert_int(_conta.saldo()).is_equal(9)
	assert_int(_canal.do_tipo(EvSaldoMudou.TIPO).size()).is_equal(2)
	assert_array(_relator.codigos).is_empty()


func test_creditar_perto_do_teto_devolve_efetivo_e_soma_so_ele() -> void:
	assert_int(_conta.creditar(ContaFragmentos.PORTA, 2)).is_equal(2)
	var outra := ContaFragmentos.new(FabricasDaEconomia.rates(), EventosDoPasso.new(), _relator)
	outra.importar(FabricasDaEconomia.SALDO_MAX - 1)
	assert_int(outra.creditar(ContaFragmentos.VITORIA, 15)).is_equal(1)
	assert_int(outra.coletados_run()).is_equal(1)


func test_creditar_origem_em_string_aceita_como_stringname() -> void:
	assert_int(_conta.creditar("porta", 2)).is_equal(2)
