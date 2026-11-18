class_name V8Pesos
extends ValidadorDeRegra
## V8: tabelas de peso têm pesos ≥ 0 e soma > 0 (GDD de Conteúdo R9, R9-P). Um erro
## por tabela.
##
## Exemplo:
## [codeblock]
## assert(V8Pesos.verificar_pesos(PackedFloat64Array([0, 1, 0])) == "")
## [/codeblock]


## Mensagem do problema da tabela; vazio se ok.
static func verificar_pesos(pesos: Array) -> String:
	var soma := 0.0
	for p: Variant in pesos:
		var v := float(p)
		if v < 0.0 or not is_finite(v):
			return "peso %s < 0" % v
		soma += v
	if soma <= 0.0:
		return "todos os pesos 0 (soma ≤ 0)"
	return ""


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	for item in itens:
		EsquemaDeDefinicao.percorrer(item.definicao, func(r: EsquemaDeDefinicao.RegraDeCampo, valor: Variant, caminho: String, _d: DadoDeConteudo) -> void:
			if not r.pesos:
				return
			var msg := verificar_pesos(como_lista(valor, false))
			if msg != "":
				out.append(Diagnostico.de_item(item, &"V8", caminho, valor, "%s: %s %s" % [rotulo(item), caminho, msg])))
	return out
