class_name V7Arte
extends ValidadorDeRegra
## V7: toda arte referenciada existe ([VerificadorDeArte], via
## [code]ResourceLoader.exists[/code]) e está dentro de [code]assets/art/export/[/code].
##
## Exemplo:
## [codeblock]
## var diags := V7Arte.new(VerificadorDeArte.new()).validar(itens)
## [/codeblock]

## Única pasta de arte aceita numa definição (R5, Art Bible §8.8).
const PREFIXO_ARTE := "res://assets/art/export/"

var _arte: VerificadorDeArte


func _init(arte: VerificadorDeArte) -> void:
	_arte = arte


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	for item in itens:
		EsquemaDeDefinicao.percorrer(item.definicao, func(r: EsquemaDeDefinicao.RegraDeCampo, valor: Variant, caminho: String, _d: DadoDeConteudo) -> void:
			if not r.arte:
				return
			for v: Variant in como_lista(valor):
				var c := str(v)
				if c.is_empty():
					continue
				if not c.begins_with(PREFIXO_ARTE):
					out.append(Diagnostico.de_item(item, &"V7", caminho, c, "%s: %s fora de assets/art/export/" % [rotulo(item), caminho]))
				elif not _arte.existe(c):
					out.append(Diagnostico.de_item(item, &"V7", caminho, c, "%s: %s não encontrado" % [rotulo(item), caminho])))
	return out
