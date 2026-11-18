class_name V11Efeitos
extends ValidadorDeRegra
## V11: entre definições, todos os [EffectDef] do mesmo tipo (de bênçãos e de
## melhorias) têm os mesmos [code]params[/code] (GDD de Conteúdo R9; Modificadores,
## Edge Cases). Um erro por definição divergente da primeira, citando as duas e os
## dois valores.
##
## Exemplo:
## [codeblock]
## var diags := V11Efeitos.new().validar(itens)
## [/codeblock]


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var primeiro: Dictionary[StringName, EffectDef] = {}
	var dono: Dictionary[StringName, String] = {}
	for item in itens:
		if not (item.definicao is BoonDef or item.definicao is UpgradeDef):
			continue
		var lista: Array = item.definicao.get(&"efeitos")
		for ef: Variant in lista:
			var e := ef as EffectDef
			if e == null:
				continue
			if not primeiro.has(e.tipo):
				primeiro[e.tipo] = e
				dono[e.tipo] = rotulo(item)
				continue
			var diff := _diferenca(primeiro[e.tipo].params, e.params)
			if diff != "":
				out.append(Diagnostico.de_item(item, &"V11", "efeitos", e.tipo,
					"%s: params.%s em %s ≠ %s em %s" % [e.tipo, diff.get_slice("|", 0), dono[e.tipo] + " (" + diff.get_slice("|", 1) + ")", diff.get_slice("|", 2), rotulo(item)]))
	return out


## "nome|valor_a|valor_b" do primeiro param divergente; vazio se iguais.
static func _diferenca(a: Dictionary, b: Dictionary) -> String:
	var nomes: Array = a.keys()
	for k: Variant in b.keys():
		if not nomes.has(k):
			nomes.append(k)
	nomes.sort()
	for k: Variant in nomes:
		var va: Variant = a.get(k, null)
		var vb: Variant = b.get(k, null)
		if va == null or vb == null or not is_equal_approx(float(va), float(vb)):
			return "%s|%s|%s" % [k, str(va), str(vb)]
	return ""
