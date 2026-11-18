class_name V3Ids
extends ValidadorDeRegra
## V3: id único dentro do tipo, no formato snake_case ASCII de R2, e tipo de efeito
## único dentro de uma definição. O mesmo id em tipos diferentes não é erro (R2, R2-P).
##
## Exemplo:
## [codeblock]
## assert(V3Ids.formato_valido(&"eco_perdido") and not V3Ids.formato_valido(&"Lamina-1"))
## [/codeblock]

static var _re: RegEx


## Id em snake_case ASCII (minúsculas, dígitos e _ entre partes).
static func formato_valido(id: StringName) -> bool:
	if _re == null:
		_re = RegEx.create_from_string("^[a-z][a-z0-9]*(_[a-z0-9]+)*$")
	return _re.search(String(id)) != null


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var vistos: Dictionary[StringName, Dictionary] = {}
	for item in itens:
		var id := item.definicao.id
		if not formato_valido(id):
			out.append(Diagnostico.de_item(item, &"V3", "id", id, "%s: id %s fora do formato snake_case" % [item.definicao.nome_da_classe(), id]))
		if not vistos.has(item.tipo):
			vistos[item.tipo] = {}
		if vistos[item.tipo].has(id):
			out.append(Diagnostico.de_item(item, &"V3", "id", id, "%s: id duplicado %s em %s e %s" % [item.definicao.nome_da_classe(), id, vistos[item.tipo][id], item.caminho]))
		else:
			vistos[item.tipo][id] = item.caminho
		var efeitos: Variant = item.definicao.get(&"efeitos")
		if efeitos is Array:
			var tipos: Array[StringName] = []
			for ef: Variant in efeitos:
				var e := ef as EffectDef
				if e == null:
					continue
				if tipos.has(e.tipo):
					out.append(Diagnostico.de_item(item, &"V3", "efeitos", e.tipo, "%s: tipo de efeito %s repetido na definição" % [rotulo(item), e.tipo]))
				tipos.append(e.tipo)
	return out
