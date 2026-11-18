extends GdUnitTestSuite
## Story run-e-regioes/002: RunTuning e RegionDef no catálogo, validação RN1–RN6.
## Cobre AC-RN-24 e AC-RN-38.


func _def(itens: Array[ItemDoCatalogo], id: StringName, tipo: StringName) -> DefinicaoBase:
	for i in itens:
		if i.definicao.id == id and i.tipo == tipo:
			return i.definicao
	return null


func _codigos(diags: Array[Diagnostico]) -> Array[StringName]:
	var r: Array[StringName] = []
	for d in diags:
		r.append(d.regra)
	return r


func test_ac_rn_24_e_38_validacao_rn1_a_rn6() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	var rt := _def(itens, &"run_tuning", &"tuning") as RunTuning
	assert_str(String(rt.arma_padrao)).is_equal("pactos")
	assert_array(ValidacaoRun.validar_tudo(itens)).is_empty()

	# RN1: arma_padrao inválida
	rt.arma_padrao = &"arco_inexistente"
	assert_bool(_codigos(ValidacaoRun.validar_tudo(itens)).has(&"RN1")).is_true()
	rt.arma_padrao = &"lamina"
	assert_array(ValidacaoRun.validar_tudo(itens)).is_empty()

	# RN2: última câmara jogável que é santuário (índice 3 -> camaras_jogaveis = 4)
	rt.camaras_jogaveis[&"limiar"] = 4
	assert_bool(_codigos(ValidacaoRun.validar_tudo(itens)).has(&"RN2")).is_true()

	# RN3: camaras_jogaveis = 0 ou 8 (> 7)
	rt.camaras_jogaveis[&"limiar"] = 0
	assert_bool(_codigos(ValidacaoRun.validar_tudo(itens)).has(&"RN3")).is_true()
	rt.camaras_jogaveis[&"limiar"] = 8
	assert_bool(_codigos(ValidacaoRun.validar_tudo(itens)).has(&"RN3")).is_true()

	# Última jogável `chefe` (7) ou `combate` (6): válido!
	rt.camaras_jogaveis[&"limiar"] = 6
	assert_array(ValidacaoRun.validar_tudo(itens)).is_empty()
	rt.camaras_jogaveis[&"limiar"] = 7
	assert_array(ValidacaoRun.validar_tudo(itens)).is_empty()
