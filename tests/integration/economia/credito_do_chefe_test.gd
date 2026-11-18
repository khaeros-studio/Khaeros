## Story economia-006: crédito do chefe (AC-EF-31 a 35; ADR-0015 §4.5–4.6).
## Chefes, Run e Câmaras são dublês do contrato (épicos chefes e run-e-regioes não implementados).
## Guarda da duplicação: a Economia aceita créditos duplicados; o teste conta 1 só crédito chefe.
extends GdUnitTestSuite

## Fixtures (valores de fábrica dos GDDs donos, só para teste).
const FRAGMENTOS_CHEFE := 6           # RegionDef.fragmentos_chefe
const FRAGMENTOS_VITORIA := 15        # RunTuning.fragmentos_vitoria


## camara_limpa(4, chefe) emitido pelas Câmaras (dublê do contrato).
class _EvCamaraLimpaFalso:
	extends EventoDoPasso
	func tipo() -> StringName:
		return &"camara_limpa"


## Dublê de Run + Chefes + Câmaras no índice 6.
class _CenaDoChefe:
	extends RefCounted
	var conta: ContaFragmentos
	var canal: EventosDoPasso
	var ativa: bool = true
	var total: int = 0

	func _init(p_conta: ContaFragmentos, p_canal: EventosDoPasso) -> void:
		conta = p_conta
		canal = p_canal

	func jogador_morreu() -> void:
		ativa = false

	## Fora de Pactos: no 1º passo vivo após o hitstop, crédito do chefe e depois camara_limpa.
	func abate() -> void:
		if not ativa:
			return
		conta.creditar(ContaFragmentos.CHEFE, FRAGMENTOS_CHEFE)
		_limpar_e_vencer()

	## Pactos: Exorcizar credita; Pactuar não chama creditar.
	func escolher(exorcizar: bool) -> void:
		if not ativa:
			return
		if exorcizar:
			conta.creditar(ContaFragmentos.CHEFE, FRAGMENTOS_CHEFE)
		_limpar_e_vencer()

	func _limpar_e_vencer() -> void:
		canal.emitir(_EvCamaraLimpaFalso.new())
		var coletados := conta.coletados_run()
		total = coletados + conta.creditar(ContaFragmentos.VITORIA, FRAGMENTOS_VITORIA)
		ativa = false


var _canal: EventosDoPasso
var _conta: ContaFragmentos
var _cena: _CenaDoChefe


func before_test() -> void:
	_canal = EventosDoPasso.new()
	_conta = ContaFragmentos.new(FabricasDaEconomia.rates(), _canal, FabricasDaEconomia.RelatorFalso.new())
	_cena = _CenaDoChefe.new(_conta, _canal)


## Saldo 11 com coletados 5 (saldo anterior 6 + 5 desta run).
func _saldo_11_coletados_5() -> void:
	_conta.importar(6)
	_conta.creditar(ContaFragmentos.PORTA, 5)
	_canal.esvaziar()


func _creditos_chefe() -> PackedStringArray:
	var r := PackedStringArray()
	for linha: String in FabricasDaEconomia.resumo_das_mudancas(_canal.todos()):
		if linha.ends_with("|chefe"):
			r.append(linha)
	return r


func test_abate_credita_chefe_antes_de_camara_limpa_e_total_26() -> void:
	_saldo_11_coletados_5()
	_cena.abate()
	var tipos: Array[StringName] = []
	for e: EventoDoPasso in _canal.todos():
		tipos.append(e.tipo())
	assert_array(tipos).is_equal([EvSaldoMudou.TIPO, &"camara_limpa", EvSaldoMudou.TIPO])
	assert_array(_creditos_chefe()).is_equal(PackedStringArray(["17|6|chefe"]))
	assert_int(_conta.saldo()).is_equal(32)
	assert_int(_cena.total).is_equal(26)


func test_pactuar_nao_credita_chefe_saldo_26() -> void:
	_saldo_11_coletados_5()
	_cena.escolher(false)
	assert_array(_creditos_chefe()).is_empty()
	assert_int(_conta.saldo()).is_equal(26)


func test_exorcizar_credita_chefe_exatamente_uma_vez_saldo_32() -> void:
	_saldo_11_coletados_5()
	_cena.escolher(true)
	assert_array(_creditos_chefe()).is_equal(PackedStringArray(["17|6|chefe"]))
	assert_int(_conta.saldo()).is_equal(32)


func test_morte_no_passo_do_abate_sem_chefe_nem_vitoria() -> void:
	_saldo_11_coletados_5()
	_cena.jogador_morreu()
	_cena.abate()
	assert_array(_canal.todos()).is_empty()
	assert_int(_conta.saldo()).is_equal(11)


func test_extremos_indice_5_recompensado_31_e_25() -> void:
	# 4 portas de Fragmentos (p 1..4) = 2+2+3+3 = 10.
	for exorcizar: bool in [true, false]:
		before_test()
		for q: int in [2, 2, 3, 3]:
			_conta.creditar(ContaFragmentos.PORTA, q)
		_cena.escolher(exorcizar)
		assert_int(_cena.total).is_equal(31 if exorcizar else 25)


func test_creditar_chefe_zero_recusado_ec1() -> void:
	var relator := FabricasDaEconomia.RelatorFalso.new()
	var c := ContaFragmentos.new(FabricasDaEconomia.rates(), _canal, relator)
	assert_int(c.creditar(ContaFragmentos.CHEFE, 0)).is_equal(0)
	assert_array(relator.codigos).is_equal([ContaFragmentos.EC1])
