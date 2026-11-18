## Contrato do relator de erros injetado na [ContaFragmentos] (GDD economia-de-fragmentos,
## Edge Cases: [code]EC1[/code], [code]EC2[/code], [code]saldo_insuficiente[/code]).
##
## Uma chamada recusada nunca usa [code]assert[/code] nem trava o jogo: gera um
## registro aqui e deixa a conta intacta. O jogo usa [RelatorDaEconomiaPadrao];
## os testes usam um dublê que acumula.
##
## Exemplo:
## [codeblock]
## class_name RelatorFalso extends RelatorDaEconomia
## var codigos: Array[StringName] = []
## func registrar(codigo: StringName, _mensagem: String) -> void:
##     codigos.append(codigo)
## [/codeblock]
@abstract
class_name RelatorDaEconomia
extends RefCounted


## Recebe uma recusa ou aviso. [param codigo] é uma das constantes de [ContaFragmentos]
## ([constant ContaFragmentos.EC1], [constant ContaFragmentos.EC2],
## [constant ContaFragmentos.SALDO_INSUFICIENTE], [constant ContaFragmentos.CONTA_AUSENTE],
## [constant ContaFragmentos.CONFIG_AUSENTE]).
@abstract func registrar(codigo: StringName, mensagem: String) -> void
