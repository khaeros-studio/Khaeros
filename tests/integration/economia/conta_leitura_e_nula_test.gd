## Story economia-004: LeituraDaConta, ContaFragmentosNula e injeção
## (AC-EF-06, AC-EF-26, TR-economia-007). Run/Portas/Combate são dublês (épicos não implementados).
extends GdUnitTestSuite


## Evento de morte de inimigo do Combate (dublê do contrato ADR-0010).
class _EvInimigoMorreuFalso:
	extends EventoDoPasso
	func tipo() -> StringName:
		return &"inimigo_morreu"


## Consumidor de leitura (HUD ou Telemetria): guarda só a ordem dos saldo_mudou e o saldo lido.
class _LeitorFalso:
	extends ConsumidorDeEventos
	var _conta: LeituraDaConta
	var vistos: PackedStringArray = PackedStringArray()
	var saldo_lido: int = -1

	func _init(conta: LeituraDaConta) -> void:
		_conta = conta

	func consumir(eventos: Array[EventoDoPasso]) -> void:
		vistos.append_array(FabricasDaEconomia.resumo_das_mudancas(eventos))
		saldo_lido = _conta.saldo()


## Dublê das Portas: credita porta se a Run está ativa; null vira Nula (ADR-0015 §9).
class _PortasFalsas:
	extends RefCounted
	var _conta: ContaFragmentos

	func _init(conta: ContaFragmentos, relator: RelatorDaEconomia) -> void:
		_conta = ContaFragmentosNula.ou_nula(conta, relator, "Portas")

	func camara_limpa(run_ativa: bool, n: int) -> int:
		return _conta.creditar(ContaFragmentos.PORTA, n) if run_ativa else 0


## Dublê da Run: vitória lê coletados e credita a vitória (ADR-0015 §4.6).
class _RunFalsa:
	extends RefCounted
	var _conta: ContaFragmentos
	var total: int = -1

	func _init(conta: ContaFragmentos, relator: RelatorDaEconomia) -> void:
		_conta = ContaFragmentosNula.ou_nula(conta, relator, "Run")

	func vencer(fragmentos_vitoria: int) -> void:
		var coletados := _conta.coletados_run()
		total = coletados + _conta.creditar(ContaFragmentos.VITORIA, fragmentos_vitoria)


var _canal: EventosDoPasso
var _relator: FabricasDaEconomia.RelatorFalso


func before_test() -> void:
	_canal = EventosDoPasso.new()
	_relator = FabricasDaEconomia.RelatorFalso.new()


func test_morte_de_inimigo_do_combate_nao_altera_saldo() -> void:
	var conta := ContaFragmentos.new(FabricasDaEconomia.rates(), _canal, _relator)
	_canal.emitir(_EvInimigoMorreuFalso.new())
	assert_int(conta.saldo()).is_equal(0)
	assert_bool(_canal.ha(EvSaldoMudou.TIPO)).is_false()
	assert_bool(ContaFragmentos.ORIGENS_VALIDAS.has(&"abate")).is_false()


func test_hud_e_telemetria_recebem_saldo_mudou_em_ordem_so_lendo() -> void:
	var conta := ContaFragmentos.new(FabricasDaEconomia.rates(), _canal, _relator)
	var hud := _LeitorFalso.new(conta)
	var tele := _LeitorFalso.new(conta)
	var consumidores: Array[ConsumidorDeEventos] = [tele, hud]
	conta.creditar(ContaFragmentos.PORTA, 2)
	conta.creditar(ContaFragmentos.PORTA, 3)
	_canal.entregar(_canal.esvaziar(), consumidores)
	var esperado := PackedStringArray(["2|2|porta", "5|3|porta"])
	assert_array(hud.vistos).is_equal(esperado)
	assert_array(tele.vistos).is_equal(esperado)
	assert_int(hud.saldo_lido).is_equal(5)


func test_interface_de_leitura_nao_expoe_creditar_nem_gastar() -> void:
	var leitura := LeituraDaConta.new()
	for m: String in ["creditar", "gastar", "nova_run", "importar"]:
		assert_bool(leitura.has_method(m)).is_false()
	assert_bool(leitura.has_method("saldo")).is_true()
	assert_bool(leitura.has_method("coletados_run")).is_true()


func test_run_e_portas_com_conta_nula_completam_fluxo_sem_emitir() -> void:
	var nula := ContaFragmentosNula.new()
	var portas := _PortasFalsas.new(nula, _relator)
	var run := _RunFalsa.new(nula, _relator)
	assert_int(portas.camara_limpa(true, 2)).is_equal(0)
	run.vencer(15)
	assert_int(run.total).is_equal(0)
	assert_int(nula.saldo()).is_equal(0)
	assert_bool(nula.gastar(1)).is_false()
	assert_int(nula.exportar()).is_equal(0)
	assert_array(_canal.todos()).is_empty()
	assert_array(_relator.codigos).is_empty()


func test_null_no_construtor_vira_nula_com_aviso_unico() -> void:
	var portas := _PortasFalsas.new(null, _relator)
	assert_int(portas.camara_limpa(true, 2)).is_equal(0)
	assert_int(portas.camara_limpa(true, 3)).is_equal(0)
	assert_array(_relator.codigos).is_equal([ContaFragmentos.CONTA_AUSENTE])


func test_conta_real_injetada_como_escrita_e_leitura_e_a_mesma() -> void:
	var conta := ContaFragmentos.new(FabricasDaEconomia.rates(), _canal, _relator)
	var leitura: LeituraDaConta = conta
	_PortasFalsas.new(conta, _relator).camara_limpa(true, 2)
	assert_int(leitura.saldo()).is_equal(2)
