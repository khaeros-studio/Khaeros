class_name RegrasRn
extends ValidadorDoDono
## RN1–RN3 (Run e regiões, erros; GDD de Conteúdo R9-P emendado):
## RN1 [code]arma_padrao[/code] não é uma arma do catálogo; RN2 a última câmara
## jogável não é [code]combate[/code] nem [code]chefe[/code]; RN3
## [code]camaras_jogaveis[/code] 0 ou maior que a região, ou região sem câmara de
## combate jogável.
##
## Exemplo:
## [codeblock]
## var diags := RegrasRn.new().validar(itens)
## [/codeblock]

const SALA_COMBATE := &"combate"
const SALA_CHEFE := &"chefe"


func prefixo() -> StringName:
	return &"RN"


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var item_rt := primeiro_da_classe(itens, "RunTuning")
	if item_rt == null:
		return out
	var rt := item_rt.definicao as RunTuning
	if rt.fragmentos_vitoria < 0 or rt.fragmentos_vitoria > 35:
		out.append(Diagnostico.de_item(item_rt, &"RN1", "fragmentos_vitoria", rt.fragmentos_vitoria,
			"RunTuning: fragmentos_vitoria %d fora de 0–35" % rt.fragmentos_vitoria))
	var armas: Array[StringName] = []
	for i in itens_do_tipo(itens, &"weapon"):
		armas.append(i.definicao.id)
	if not armas.has(rt.arma_padrao):
		out.append(Diagnostico.de_item(item_rt, &"RN1", "arma_padrao", rt.arma_padrao,
			"RunTuning: arma_padrao %s fora de %s" % [rt.arma_padrao, armas]))
	var regioes: Dictionary[StringName, RegionDef] = {}
	for i in itens_do_tipo(itens, &"region"):
		regioes[i.definicao.id] = i.definicao as RegionDef
	for rid: StringName in rt.camaras_jogaveis:
		var n: int = rt.camaras_jogaveis[rid]
		var r: RegionDef = regioes.get(rid, null)
		if r == null:
			continue
		var campo := "camaras_jogaveis.%s" % rid
		if n <= 0 or n > r.camaras.size():
			out.append(Diagnostico.de_item(item_rt, &"RN3", campo, n,
				"RunTuning: camaras_jogaveis %s %d fora de 1–%d" % [rid, n, r.camaras.size()]))
			continue
		var jogaveis := r.camaras.slice(0, n)
		if not jogaveis.has(SALA_COMBATE):
			out.append(Diagnostico.de_item(item_rt, &"RN3", campo, n, "RunTuning: região %s sem câmara de combate jogável" % rid))
		var ultima: StringName = jogaveis[n - 1]
		if ultima != SALA_COMBATE and ultima != SALA_CHEFE:
			out.append(Diagnostico.de_item(item_rt, &"RN2", campo, ultima,
				"RunTuning: última câmara jogável de %s é %s (exige combate ou chefe)" % [rid, ultima]))
	return out
