## Relator da Economia usado no jogo: registra cada recusa no log com
## [code]push_warning[/code] (não trava, não usa [code]assert[/code]).
##
## Exemplo:
## [codeblock]
## var conta := ContaFragmentos.new(rates, eventos, RelatorDaEconomiaPadrao.new())
## [/codeblock]
class_name RelatorDaEconomiaPadrao
extends RelatorDaEconomia


func registrar(codigo: StringName, mensagem: String) -> void:
	push_warning("Economia [%s]: %s" % [codigo, mensagem])
