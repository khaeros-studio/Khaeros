class_name RegrasEc
extends ValidadorDoDono
## EC1–EC2 (Economia de Fragmentos, erros; GDD economia-de-fragmentos.md e GDD de
## Conteúdo R1/R9): faixas de [EconomyRates] ([code]fragmentos_provacao[/code] 0–10,
## [code]saldo_max[/code] 9999–2147483647).
##
## Exemplo:
## [codeblock]
## var diags := RegrasEc.new().validar(itens)
## [/codeblock]

const PROVACAO_MIN: int = 0
const PROVACAO_MAX: int = 10
const SALDO_MAX_MIN: int = 9999
const SALDO_MAX_MAX: int = 2147483647


func prefixo() -> StringName:
	return &"EC"


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	for item in itens_do_tipo(itens, &"economy_rates"):
		var e := item.definicao as EconomyRates
		if e == null:
			continue
		if e.fragmentos_provacao < PROVACAO_MIN or e.fragmentos_provacao > PROVACAO_MAX:
			out.append(Diagnostico.de_item(item, &"EC1", "fragmentos_provacao", e.fragmentos_provacao,
				"EconomyRates: fragmentos_provacao %d fora da faixa %d–%d" % [e.fragmentos_provacao, PROVACAO_MIN, PROVACAO_MAX]))
		if e.saldo_max < SALDO_MAX_MIN or e.saldo_max > SALDO_MAX_MAX:
			out.append(Diagnostico.de_item(item, &"EC2", "saldo_max", e.saldo_max,
				"EconomyRates: saldo_max %d fora da faixa %d–%d" % [e.saldo_max, SALDO_MAX_MIN, SALDO_MAX_MAX]))
	return out
