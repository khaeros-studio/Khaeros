## Fixtures do épico Economia de Fragmentos (dados de teste, não tuning do jogo).
## Os números são os valores de fábrica do GDD economia-de-fragmentos (Tuning Knobs).
class_name FabricasDaEconomia
extends RefCounted

## Teto de fábrica (GDD, Tuning Knobs).
const SALDO_MAX := 999999
## Provação de fábrica (GDD, Tuning Knobs).
const FRAGMENTOS_PROVACAO := 3


## Relator que só acumula os códigos e mensagens recebidos.
class RelatorFalso:
	extends RelatorDaEconomia
	var codigos: Array[StringName] = []
	var mensagens: PackedStringArray = PackedStringArray()

	func registrar(codigo: StringName, mensagem: String) -> void:
		codigos.append(codigo)
		mensagens.append(mensagem)


## [EconomyRates] em memória com os valores de fábrica (ou o teto dado).
static func rates(saldo_max: int = SALDO_MAX) -> EconomyRates:
	var r := EconomyRates.new()
	r.id = &"economy_rates"
	r.saldo_max = saldo_max
	r.fragmentos_provacao = FRAGMENTOS_PROVACAO
	return r


## Saldos, deltas e origens dos [EvSaldoMudou] de [param lista], como texto "saldo|delta|origem".
static func resumo_das_mudancas(lista: Array[EventoDoPasso]) -> PackedStringArray:
	var r := PackedStringArray()
	for e: EventoDoPasso in lista:
		if e.tipo() == EvSaldoMudou.TIPO:
			var m := e as EvSaldoMudou
			r.append("%d|%d|%s" % [m.saldo, m.delta, m.origem])
	return r
