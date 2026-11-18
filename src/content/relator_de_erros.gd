@abstract
class_name RelatorDeErros
extends RefCounted
## Contrato do relator de erros injetado na consulta do catálogo (GDD de Conteúdo
## R10). A consulta nunca chama [code]push_error[/code] nem [code]assert[/code]:
## entrega a [RelatorDeErros.Entrada] ao relator, que reage.
## Implementações: [RelatorPadrao] (jogo) e [RelatorAcumulador] (testes).
##
## Exemplo:
## [codeblock]
## var relator := RelatorAcumulador.new()
## var catalogo := Catalogo.new(relator)
## catalogo.obter(&"enemy", &"nao_existe", "ia")   # null; relator.entradas.size() == 1
## [/codeblock]


## Pedido de conteúdo que não resolveu.
class Entrada:
	extends RefCounted
	var tipo: StringName
	var id: StringName
	## Quem pediu (nome do sistema/módulo).
	var solicitante: String

	func _init(p_tipo: StringName, p_id: StringName, p_solicitante: String) -> void:
		tipo = p_tipo
		id = p_id
		solicitante = p_solicitante

	## Linha de log com tipo, id e solicitante.
	func texto() -> String:
		return "conteúdo inexistente: tipo=%s id=%s solicitante=%s" % [tipo, id, solicitante]


## Recebe um pedido que não resolveu.
@abstract func relatar(entrada: RelatorDeErros.Entrada) -> void
