## Story economia-002: teto do saldo e EconomyRates (AC-EF-08, 09, 29, 30).
extends GdUnitTestSuite

const CAMINHO_FABRICA := "res://assets/data/economy_rates/economy_rates.tres"
## Teto curto de teste (borda inferior da faixa do GDD).
const TETO_CURTO := 9999


class _HudFalso:
	extends ConsumidorDeEventos
	var tetos: int = 0
	var deltas: Array[int] = []

	func consumir(eventos: Array[EventoDoPasso]) -> void:
		for e: EventoDoPasso in eventos:
			if e.tipo() == EvSaldoNoTeto.TIPO:
				tetos += 1
			elif e.tipo() == EvSaldoMudou.TIPO:
				deltas.append((e as EvSaldoMudou).delta)


var _canal: EventosDoPasso
var _relator: FabricasDaEconomia.RelatorFalso
var _conta: ContaFragmentos


func before_test() -> void:
	_canal = EventosDoPasso.new()
	_relator = FabricasDaEconomia.RelatorFalso.new()
	_conta = ContaFragmentos.new(FabricasDaEconomia.rates(), _canal, _relator)


func test_creditar_saldo_999998_por_tres_corta_no_teto_pela_f1() -> void:
	# AC-EF-08: saldo 999 998, creditar(porta, 3) -> saldo 999 999 e saldo_no_teto.
	# F1 dá efetivo = min(3, 1) = 1 (o "+2" do AC/F1-exemplo é erro aritmético do GDD).
	_conta.importar(FabricasDaEconomia.SALDO_MAX - 1)
	assert_int(_conta.creditar(ContaFragmentos.PORTA, 3)).is_equal(1)
	assert_int(_conta.saldo()).is_equal(FabricasDaEconomia.SALDO_MAX)
	assert_int(_conta.coletados_run()).is_equal(1)
	assert_array(FabricasDaEconomia.resumo_das_mudancas(_canal.todos())).is_equal(
		PackedStringArray(["%d|1|porta" % FabricasDaEconomia.SALDO_MAX]))
	var teto := _canal.do_tipo(EvSaldoNoTeto.TIPO)
	assert_int(teto.size()).is_equal(1)
	assert_int((teto[0] as EvSaldoNoTeto).pedido).is_equal(3)
	assert_int((teto[0] as EvSaldoNoTeto).efetivo).is_equal(1)


func test_creditar_saldo_999997_por_tres_efetivo_dois_delta_mais_dois() -> void:
	# Variante com delta +2 e coletados +2 (o que o AC-EF-08 descreve) segundo a F1.
	_conta.importar(FabricasDaEconomia.SALDO_MAX - 2)
	assert_int(_conta.creditar(ContaFragmentos.PORTA, 3)).is_equal(2)
	assert_int(_conta.saldo()).is_equal(FabricasDaEconomia.SALDO_MAX)
	assert_int(_conta.coletados_run()).is_equal(2)
	assert_int((_canal.do_tipo(EvSaldoMudou.TIPO)[0] as EvSaldoMudou).delta).is_equal(2)
	assert_bool(_canal.ha(EvSaldoNoTeto.TIPO)).is_true()


func test_creditar_com_saldo_no_teto_so_emite_saldo_no_teto() -> void:
	_conta.importar(FabricasDaEconomia.SALDO_MAX)
	assert_int(_conta.creditar(ContaFragmentos.PORTA, 2)).is_equal(0)
	assert_int(_conta.saldo()).is_equal(FabricasDaEconomia.SALDO_MAX)
	assert_bool(_canal.ha(EvSaldoMudou.TIPO)).is_false()
	assert_int(_canal.do_tipo(EvSaldoNoTeto.TIPO).size()).is_equal(1)
	assert_array(_relator.codigos).is_empty()


func test_saldo_no_teto_dos_dois_casos_chega_ao_ouvinte_do_hud() -> void:
	var hud := _HudFalso.new()
	var consumidores: Array[ConsumidorDeEventos] = [hud]
	_conta.importar(FabricasDaEconomia.SALDO_MAX - 1)
	_conta.creditar(ContaFragmentos.PORTA, 3)
	_canal.entregar(_canal.esvaziar(), consumidores)
	_conta.creditar(ContaFragmentos.PORTA, 2)
	_canal.entregar(_canal.esvaziar(), consumidores)
	assert_int(hud.tetos).is_equal(2)
	assert_array(hud.deltas).is_equal([1])


func test_conta_monta_so_com_economy_rates_sem_cena_e_sem_fragmentos_base() -> void:
	var nomes := FabricasDeCatalogo.campos_exportados(EconomyRates.new())
	assert_bool(nomes.has("fragmentos_provacao")).is_true()
	assert_bool(nomes.has("saldo_max")).is_true()
	assert_bool(nomes.has("fragmentos_base")).is_false()
	assert_bool("fragmentos_base" in _conta).is_false()
	assert_int(_conta.creditar(ContaFragmentos.CHEFE, 6)).is_equal(6)
	assert_array(_relator.codigos).is_empty()


func test_teto_vem_do_economy_rates_injetado() -> void:
	var c := ContaFragmentos.new(FabricasDaEconomia.rates(TETO_CURTO), EventosDoPasso.new(), _relator)
	c.importar(TETO_CURTO + 5)
	assert_int(c.saldo()).is_equal(TETO_CURTO)
	assert_int(c.saldo_max()).is_equal(TETO_CURTO)


func test_conta_sem_rates_nem_canal_avisa_config_ausente_e_nao_quebra() -> void:
	var c := ContaFragmentos.new(null, null, _relator)
	assert_int(c.creditar(ContaFragmentos.PORTA, 2)).is_equal(0)
	assert_array(_relator.codigos).is_equal([ContaFragmentos.CONFIG_AUSENTE, ContaFragmentos.CONFIG_AUSENTE])


func test_recurso_de_fabrica_tem_os_valores_do_gdd() -> void:
	var r := load(CAMINHO_FABRICA) as EconomyRates
	assert_object(r).is_not_null()
	assert_int(r.saldo_max).is_equal(FabricasDaEconomia.SALDO_MAX)
	assert_int(r.fragmentos_provacao).is_equal(FabricasDaEconomia.FRAGMENTOS_PROVACAO)
	assert_str(String(r.tipo_do_catalogo())).is_equal("economy_rates")


func test_esquema_recusa_saldo_max_abaixo_da_faixa() -> void:
	var regra := EsquemaDeDefinicao.de(EconomyRates.new()).regra(&"saldo_max")
	assert_bool(regra.tem_minimo and regra.tem_maximo).is_true()
	assert_float(regra.minimo).is_equal(float(TETO_CURTO))
