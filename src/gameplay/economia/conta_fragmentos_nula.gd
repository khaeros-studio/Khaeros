## Variante Nula da [ContaFragmentos] (ADR-0015 §9; GDD economia R9; TR-economia-007).
##
## Comportamento "Economia ausente": consultas devolvem 0, [code]creditar[/code] devolve 0,
## [code]gastar[/code] devolve [code]false[/code], nada é emitido e nada muda. Run e Portas
## montadas com ela completam o fluxo sem erro (os créditos viram chamadas perdidas).
## Todos os overrides com retorno não-void têm [code]return[/code] explícito (regra 4.7).
##
## Exemplo (construtor de um módulo que recebe a conta):
## [codeblock]
## func _init(conta: ContaFragmentos, relator: RelatorDaEconomia) -> void:
##     _conta = ContaFragmentosNula.ou_nula(conta, relator, "Portas")
## [/codeblock]
class_name ContaFragmentosNula
extends ContaFragmentos


## Sem dependências: monta a base com dados vazios e privados (nunca usados).
func _init() -> void:
	super(EconomyRates.new(), EventosDoPasso.new(), RelatorDaEconomiaPadrao.new())


## Devolve [param conta], ou uma [ContaFragmentosNula] se ela for [code]null[/code]; nesse caso
## registra [constant ContaFragmentos.CONTA_AUSENTE] uma vez em [param relator] (se houver),
## citando [param quem]. É o ponto único do "null vira Nula com aviso" (ADR-0015 §9),
## para que a regra dos módulos nunca precise de [code]if conta != null[/code].
static func ou_nula(conta: ContaFragmentos, relator: RelatorDaEconomia, quem: String) -> ContaFragmentos:
	if conta != null:
		return conta
	if relator != null:
		relator.registrar(CONTA_AUSENTE, "%s recebeu conta nula; usando ContaFragmentosNula" % quem)
	return ContaFragmentosNula.new()


func saldo() -> int:
	return 0


func coletados_run() -> int:
	return 0


func saldo_max() -> int:
	return 0


func creditar(_origem: StringName, _quantidade: Variant) -> int:
	return 0


func gastar(_quantidade: Variant, _motivo: StringName = &"") -> bool:
	return false


func nova_run() -> void:
	pass


func exportar() -> int:
	return 0


func importar(_valor: Variant) -> void:
	pass
