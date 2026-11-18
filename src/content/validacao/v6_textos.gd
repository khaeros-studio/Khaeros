class_name V6Textos
extends ValidadorDeRegra
## V6: toda chave de tradução (e as derivadas, ex.: [code]<chave_nome>_DESC[/code] de
## armas e ataques, ADR-0004) existe na tabela PT-BR com texto não vazio.
##
## Exemplo:
## [codeblock]
## var diags := V6Textos.new(textos).validar(itens)
## [/codeblock]

var _textos: TabelaDeTextos


func _init(textos: TabelaDeTextos) -> void:
	_textos = textos


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	for item in itens:
		EsquemaDeDefinicao.percorrer(item.definicao, func(r: EsquemaDeDefinicao.RegraDeCampo, valor: Variant, caminho: String, _d: DadoDeConteudo) -> void:
			if not r.chave_texto:
				return
			for v: Variant in como_lista(valor):
				var chave := str(v)
				if chave.is_empty():
					continue
				var todas: PackedStringArray = [chave]
				for s in r.sufixos_derivados:
					todas.append(chave + s)
				for k in todas:
					if not _textos.tem(k):
						out.append(Diagnostico.de_item(item, &"V6", caminho, k, "%s: chave %s sem texto" % [rotulo(item), k]))
					elif _textos.texto(k).strip_edges().is_empty():
						out.append(Diagnostico.de_item(item, &"V6", caminho, k, "%s: chave %s com texto vazio" % [rotulo(item), k])))
	return out
