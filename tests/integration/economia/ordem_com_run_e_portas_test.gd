## Story economia-005: ordem de crédito com Run e Portas; morte vence a limpeza
## (AC-EF-22, 23, 24, 25, 28; ADR-0015 §3 e §4). Run e Portas são dublês que seguem o
## contrato do ADR (épicos run-e-regioes e portas-e-recompensas ainda não implementados).
extends GdUnitTestSuite

## Fixtures (valores de fábrica dos GDDs donos, só para teste).
const FRAGMENTOS_VITORIA := 15        # RunTuning.fragmentos_vitoria
const CAMARAS_JOGAVEIS := 7           # RunTuning (Limiar com chefe)
const BASE_PORTA := 2                 # RewardTable: 2 + floor(p/3)
const PASSO_PORTA := 3


## Dublê da Run (ADR-0015 §3/§4.6): ativa até morrer ou vencer; vitória lê coletados antes.
class _RunFalsa:
	extends RefCounted
	var _conta: ContaFragmentos
	var _ativa: bool = true
	var coletados: int = 0
	var bonus: int = 0
	var total: int = 0

	func _init(conta: ContaFragmentos) -> void:
		_conta = conta

	func ativa() -> bool:
		return _ativa

	func jogador_morreu() -> void:
		if not _ativa:
			return
		_ativa = false
		coletados = _conta.coletados_run()
		total = coletados

	func vencer() -> void:
		if not _ativa:
			return
		coletados = _conta.coletados_run()
		bonus = _conta.creditar(ContaFragmentos.VITORIA, FRAGMENTOS_VITORIA)
		total = coletados + bonus
		_ativa = false


## Dublê das Portas (R2-P): consulta run.ativa() antes de conceder.
class _PortasFalsas:
	extends RefCounted
	var _conta: ContaFragmentos
	var _run: _RunFalsa

	func _init(conta: ContaFragmentos, run: _RunFalsa) -> void:
		_conta = conta
		_run = run

	static func fragmentos(p: int) -> int:
		return BASE_PORTA + floori(float(p) / PASSO_PORTA)

	func camara_limpa_com_fragmentos(p: int) -> void:
		if _run.ativa():
			_conta.creditar(ContaFragmentos.PORTA, fragmentos(p))

	## Bênção sem pool vira Fragmentos com o p da câmara (Portas R3).
	func camara_limpa_bencao_sem_pool(p: int) -> void:
		camara_limpa_com_fragmentos(p)


var _conta: ContaFragmentos
var _run: _RunFalsa
var _portas: _PortasFalsas


func before_test() -> void:
	_conta = ContaFragmentos.new(FabricasDaEconomia.rates(), EventosDoPasso.new(), FabricasDaEconomia.RelatorFalso.new())
	_run = _RunFalsa.new(_conta)
	_portas = _PortasFalsas.new(_conta, _run)


func _com_saldo_inicial(saldo: int) -> void:
	_conta.importar(saldo)


func test_vitoria_le_coletados_antes_do_bonus_e_soma_31() -> void:
	_com_saldo_inicial(11)
	_portas.camara_limpa_com_fragmentos(1)   # 2
	_portas.camara_limpa_com_fragmentos(3)   # 3
	_run.vencer()
	assert_int(_conta.saldo()).is_equal(31)
	assert_int(_run.coletados).is_equal(5)
	assert_int(_run.bonus).is_equal(FRAGMENTOS_VITORIA)
	assert_int(_run.total).is_equal(20)


func test_morte_no_indice_2_apos_porta_de_2_sem_bonus() -> void:
	_com_saldo_inicial(11)
	_portas.camara_limpa_com_fragmentos(1)
	_run.jogador_morreu()
	_run.vencer()
	assert_int(_conta.saldo()).is_equal(13)
	assert_int(_run.total).is_equal(2)
	assert_int(_run.bonus).is_equal(0)


func test_morte_e_camara_limpa_no_mesmo_passo_portas_nao_creditam() -> void:
	_com_saldo_inicial(11)
	_run.jogador_morreu()                    # item 9 do passo
	_portas.camara_limpa_com_fragmentos(3)   # item 10 do mesmo passo
	assert_int(_conta.saldo()).is_equal(11)
	assert_int(_conta.coletados_run()).is_equal(0)


func test_porta_p3_credita_3_e_bencao_sem_pool_credita_como_porta() -> void:
	_portas.camara_limpa_com_fragmentos(3)
	assert_int(_conta.saldo()).is_equal(3)
	_portas.camara_limpa_bencao_sem_pool(2)
	assert_int(_conta.saldo()).is_equal(5)


func test_extremos_do_limiar_com_indice_5_recompensado() -> void:
	# Índices recompensáveis com Fragmentos: 1, 2, 4, 5 (p 1, 2, 3, 4) -> 2+2+3+3 = 10.
	var ps: Array[int] = [1, 2, 3, 4]
	var casos := {
		"max_vitoria": [true, true],
		"min_vitoria": [false, true],
		"min_morte": [false, false],
		"max_morte": [true, false],
	}
	var esperado := {"max_vitoria": 25, "min_vitoria": 15, "min_morte": 0, "max_morte": 10}
	for nome: String in casos:
		before_test()
		var c: Array = casos[nome]
		if c[0]:
			for p: int in ps:
				_portas.camara_limpa_com_fragmentos(p)
		if c[1]:
			_run.vencer()
		else:
			_run.jogador_morreu()
		assert_int(_run.total).override_failure_message(nome).is_equal(esperado[nome])
	assert_int(CAMARAS_JOGAVEIS).is_equal(7)
