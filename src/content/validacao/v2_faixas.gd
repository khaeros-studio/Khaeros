class_name V2Faixas
extends ValidadorDeRegra
## V2: valor dentro da faixa declarada pelo esquema e regras entre campos (GDD de
## Conteúdo R9). Lê só o esquema. Campos de duração (sufixo [code]_s[/code], convenção
## de unidade da R6) passam também pela F7 ([method Unidades.verificar_duracao]): t > 0
## abaixo de meio passo dá aviso (não bloqueia).
##
## Exemplo:
## [codeblock]
## var msg := V2Faixas.verificar_valor(regra, 0.0)   # "0 (mín. > 0)" ou ""
## [/codeblock]


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	for item in itens:
		_verificar(item, item.definicao, "", out)
	return out


func _verificar(item: ItemDoCatalogo, dado: DadoDeConteudo, prefixo: String, out: Array[Diagnostico]) -> void:
	var e := dado.esquema()
	for r in e.regras():
		var valor: Variant = dado.get(r.nome)
		var caminho := prefixo + String(r.nome)
		if valor is DadoDeConteudo:
			_verificar(item, valor as DadoDeConteudo, caminho + ".", out)
			continue
		for v: Variant in como_lista(valor, false):
			if v is DadoDeConteudo:
				continue
			if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
				continue
			var msg := verificar_valor(r, float(v))
			if msg != "":
				out.append(Diagnostico.de_item(item, &"V2", caminho, v, "%s: %s %s" % [rotulo(item), caminho, msg]))
			elif typeof(v) == TYPE_FLOAT and String(r.nome).ends_with("_s"):
				var f7 := Unidades.verificar_duracao(float(v), r.aceita_zero)
				if f7.begins_with("aviso:"):
					out.append(Diagnostico.de_item(item, &"V2", caminho, v, "%s: %s %s" % [rotulo(item), caminho, f7.substr(6)], Diagnostico.Nivel.AVISO))
		if valor is Array:
			var lista: Array = valor
			for i in lista.size():
				if lista[i] is DadoDeConteudo:
					_verificar(item, lista[i] as DadoDeConteudo, "%s[%d]." % [caminho, i], out)
	for rc in e.regras_entre_campos():
		if rc.exceto_se != &"" and bool(dado.get(rc.exceto_se)):
			continue
		var va := float(dado.get(rc.campo_a))
		var vb := float(dado.get(rc.campo_b))
		if not rc.vale(va, vb):
			if rc.operador == &"+<":
				out.append(Diagnostico.de_item(item, &"V2", prefixo + String(rc.campo_a), [va, vb],
					"%s: %s (%s) + %s (%s) = %s (exige < %s)" % [rotulo(item), rc.campo_a, va, rc.campo_b, vb, va + vb, rc.limite]))
			else:
				out.append(Diagnostico.de_item(item, &"V2", prefixo + String(rc.campo_a), [va, vb],
					"%s: %s %s %s %s (exige %s %s %s)" % [rotulo(item), rc.campo_a, va, rc.campo_b, vb, rc.campo_a, rc.operador, rc.campo_b]))


## Mensagem de faixa violada para [param v] segundo [param r]; vazio se ok.
static func verificar_valor(r: EsquemaDeDefinicao.RegraDeCampo, v: float) -> String:
	if not is_finite(v):
		return "não finito"
	if not r.aceita_zero and is_zero_approx(v):
		return "0 (mín. > 0)"
	if r.tem_minimo and (v < r.minimo or (r.minimo_exclusivo and v <= r.minimo)):
		return "%s (mín. %s%s)" % [v, "> " if r.minimo_exclusivo else "", r.minimo]
	if r.tem_maximo and (v > r.maximo or (r.maximo_exclusivo and v >= r.maximo)):
		return "%s (máx. %s%s)" % [v, "< " if r.maximo_exclusivo else "", r.maximo]
	return ""
