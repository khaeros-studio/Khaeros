class_name ValidacaoRun
extends RefCounted
## Validação RN1–RN6 do [RunTuning] e das [RegionDef] (GDD run-e-regioes.md §Tuning Knobs,
## §Edge Cases "Dados"; ADR-0004).
## Envolve [RegrasRn] (RN1–RN3) e acrescenta as validações RN4–RN6 sobre `fragmentos_chefe`,
## sequência vazia e limites de `fragmentos_vitoria`.

const FRAGMENTOS_VITORIA_MAX_DESIGN: int = 35


## Executa as regras RN1–RN6 sobre [param itens].
static func validar_tudo(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var rn := RegrasRn.new()
	var out: Array[Diagnostico] = rn.validar(itens)
	out.append_array(_validar_extras(itens, out))
	return out


static func _validar_extras(itens: Array[ItemDoCatalogo], existentes: Array[Diagnostico]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var item_rt: ItemDoCatalogo = null
	var regioes: Array[ItemDoCatalogo] = []
	for it in itens:
		if it.definicao is RunTuning and item_rt == null:
			item_rt = it
		elif it.definicao is RegionDef:
			regioes.append(it)

	for item_r in regioes:
		var reg := item_r.definicao as RegionDef
		if reg == null:
			continue
		# RN4: região sem câmaras declaradas
		if reg.camaras.is_empty():
			out.append(Diagnostico.de_item(item_r, &"RN4", "camaras", reg.camaras,
				"RegionDef: região %s com lista de câmaras vazia" % reg.id))
		# RN5: região com câmara chefe mas sem id de chefe válido
		if reg.camaras.has(&"chefe") and reg.chefe == &"":
			out.append(Diagnostico.de_item(item_r, &"RN5", "chefe", reg.chefe,
				"RegionDef: região %s tem câmara chefe mas campo chefe vazio" % reg.id))
		# RN6: fragmentos_chefe negativo
		if reg.fragmentos_chefe < 0:
			out.append(Diagnostico.de_item(item_r, &"RN6", "fragmentos_chefe", reg.fragmentos_chefe,
				"RegionDef: fragmentos_chefe %d negativo" % reg.fragmentos_chefe))

	if item_rt != null and existentes.is_empty():
		var rt := item_rt.definicao as RunTuning
		if rt.camaras_jogaveis.is_empty():
			out.append(Diagnostico.de_item(item_rt, &"RN3", "camaras_jogaveis", rt.camaras_jogaveis,
				"RunTuning: camaras_jogaveis vazio"))
	return out
