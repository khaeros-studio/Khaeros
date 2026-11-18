## Story economia-003: gastar, nova run e exportar/importar sem arquivo
## (AC-EF-10 a 20 do GDD economia-de-fragmentos).
extends GdUnitTestSuite

const MOTIVO := &"teste"


## Dublê da Run: morte e abandono não chamam a conta (Run R5/R6); só leem.
class _RunFalsa:
	extends RefCounted
	var _conta: ContaFragmentos
	var coletados_lidos: int = -1

	func _init(conta: ContaFragmentos) -> void:
		_conta = conta

	func morrer() -> void:
		coletados_lidos = _conta.coletados_run()

	func abandonar() -> void:
		coletados_lidos = _conta.coletados_run()


var _canal: EventosDoPasso
var _relator: FabricasDaEconomia.RelatorFalso
var _conta: ContaFragmentos


func before_test() -> void:
	_canal = EventosDoPasso.new()
	_relator = FabricasDaEconomia.RelatorFalso.new()
	_conta = ContaFragmentos.new(FabricasDaEconomia.rates(), _canal, _relator)


func _conta_com(saldo: int) -> ContaFragmentos:
	_conta.importar(saldo)
	return _conta


func test_gastar_com_saldo_subtrai_e_emite_delta_negativo() -> void:
	_conta.creditar(ContaFragmentos.PORTA, 26)
	_canal.esvaziar()
	assert_bool(_conta.gastar(15, MOTIVO)).is_true()
	assert_int(_conta.saldo()).is_equal(11)
	assert_int(_conta.coletados_run()).is_equal(26)
	assert_array(FabricasDaEconomia.resumo_das_mudancas(_canal.todos())).is_equal(PackedStringArray(["11|-15|teste"]))


func test_gastar_valor_exato_zera_saldo() -> void:
	assert_bool(_conta_com(15).gastar(15)).is_true()
	assert_int(_conta.saldo()).is_equal(0)


func test_gastar_sem_saldo_recusa_saldo_insuficiente_sem_evento() -> void:
	assert_bool(_conta_com(11).gastar(15)).is_false()
	assert_int(_conta.saldo()).is_equal(11)
	assert_array(_canal.todos()).is_empty()
	assert_array(_relator.codigos).is_equal([ContaFragmentos.SALDO_INSUFICIENTE])


func test_gastar_custo_invalido_recusa_ec1() -> void:
	_conta_com(26)
	for c: Variant in [0, -3, 1.5]:
		assert_bool(_conta.gastar(c)).is_false()
	assert_int(_conta.saldo()).is_equal(26)
	assert_array(_canal.todos()).is_empty()
	assert_array(_relator.codigos).is_equal([ContaFragmentos.EC1, ContaFragmentos.EC1, ContaFragmentos.EC1])


func test_gastar_duas_vezes_seguidas_segundo_recusado() -> void:
	_conta_com(20)
	assert_bool(_conta.gastar(15)).is_true()
	assert_int(_conta.saldo()).is_equal(5)
	assert_bool(_conta.gastar(15)).is_false()
	assert_int(_conta.saldo()).is_equal(5)
	assert_int(_canal.do_tipo(EvSaldoMudou.TIPO).size()).is_equal(1)


func test_nova_run_zera_coletados_e_mantem_saldo() -> void:
	_conta.creditar(ContaFragmentos.PORTA, 11)
	_conta.nova_run()
	assert_int(_conta.saldo()).is_equal(11)
	assert_int(_conta.coletados_run()).is_equal(0)


func test_nova_run_sem_ter_jogado_mantem_tudo() -> void:
	_conta_com(7).nova_run()
	assert_int(_conta.saldo()).is_equal(7)
	assert_int(_conta.coletados_run()).is_equal(0)


func test_morte_e_abandono_da_run_nao_mudam_saldo() -> void:
	_conta.creditar(ContaFragmentos.PORTA, 11)
	var run := _RunFalsa.new(_conta)
	run.morrer()
	run.abandonar()
	assert_int(_conta.saldo()).is_equal(11)
	assert_int(run.coletados_lidos).is_equal(11)


func test_exportar_devolve_saldo() -> void:
	assert_int(_conta_com(26).exportar()).is_equal(26)


func test_importar_valido_em_conta_nova_define_saldo_sem_coletados() -> void:
	_conta.importar(40)
	assert_int(_conta.saldo()).is_equal(40)
	assert_int(_conta.coletados_run()).is_equal(0)
	assert_array(_canal.todos()).is_empty()


func test_importar_invalido_mantem_saldo_e_emite_ec2() -> void:
	_conta_com(26)
	for v: Variant in [-5, 1.5, "x"]:
		_conta.importar(v)
	assert_int(_conta.saldo()).is_equal(26)
	assert_array(_relator.codigos).is_equal([ContaFragmentos.EC2, ContaFragmentos.EC2, ContaFragmentos.EC2])


func test_importar_acima_do_teto_corta_no_teto() -> void:
	_conta.importar(2000000)
	assert_int(_conta.saldo()).is_equal(FabricasDaEconomia.SALDO_MAX)


func test_conta_recriada_comeca_com_saldo_zero() -> void:
	_conta.creditar(ContaFragmentos.PORTA, 26)
	var recriada := ContaFragmentos.new(FabricasDaEconomia.rates(), EventosDoPasso.new(), _relator)
	assert_int(recriada.saldo()).is_equal(0)
	assert_int(recriada.coletados_run()).is_equal(0)


func test_conta_nao_usa_arquivo_nem_config_file() -> void:
	# AC-EF-20 / TR-economia-009: nenhuma API de disco no código da Economia.
	for caminho: String in ["res://src/gameplay/economia/conta_fragmentos.gd", "res://src/gameplay/economia/leitura_da_conta.gd"]:
		var texto := (load(caminho) as GDScript).source_code
		assert_bool(texto.contains("FileAccess")).is_false()
		assert_bool(texto.contains("ConfigFile")).is_false()
		assert_bool(texto.contains("user://")).is_false()
