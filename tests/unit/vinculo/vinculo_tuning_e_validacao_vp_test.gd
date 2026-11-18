extends GdUnitTestSuite
## Story vinculo-e-pactos/001: VinculoTuning, memórias do CurseDef e validação VP1–VP9.
## Cobre AC-VP-21, F5 e VP1–VP9.


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


func test_ac_vp_21_catalogo_mvp_sem_avisos_vp5_vp6_vp7_e_gatilhos() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	assert_array(ValidadorVinculo.validar_tudo(itens)).is_empty()

	# bonus_vida = 0,06 -> VP5 (135 * 1,06 = 143 / 95 = 1,505 > 1,50)
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"vinculo_tuning", &"tuning") as VinculoTuning).bonus_vida = 0.06
	assert_bool(_codigos(ValidadorVinculo.validar_tudo(itens)).has(&"VP5")).is_true()

	# bonus_dano_basico = 0,08 -> VP7 (paridade com técnica 5,08% > 5,00%) e VP9 (fora de 0..0,07)
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"vinculo_tuning", &"tuning") as VinculoTuning).bonus_dano_basico = 0.08
	var cods := _codigos(ValidadorVinculo.validar_tudo(itens))
	assert_bool(cods.has(&"VP7")).is_true()
	assert_bool(cods.has(&"VP9")).is_true()


func test_vp1_a_vp4_e_vp8_recusam_fixtures_invalidas() -> void:
	# VP1: limiares não crescentes
	var itens := FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"vinculo_tuning", &"tuning") as VinculoTuning).limiares_nivel = PackedInt64Array([20, 20, 90, 140])
	assert_bool(_codigos(ValidadorVinculo.validar_tudo(itens)).has(&"VP1")).is_true()

	# VP2: especie_primeiro_pacto não é Comum regular
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"vinculo_tuning", &"tuning") as VinculoTuning).especie_primeiro_pacto = &"baluarte_de_cinza"
	assert_bool(_codigos(ValidadorVinculo.validar_tudo(itens)).has(&"VP2")).is_true()

	# VP3: indices_encontro com 0 ou >= camaras_jogaveis - 2 (5 ou 6)
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"vinculo_tuning", &"tuning") as VinculoTuning).indices_encontro = PackedInt64Array([1, 5])
	assert_bool(_codigos(ValidadorVinculo.validar_tudo(itens)).has(&"VP3")).is_true()

	# VP4: chance_encontro fora de [0, 1]
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"vinculo_tuning", &"tuning") as VinculoTuning).chance_encontro = -0.1
	assert_bool(_codigos(ValidadorVinculo.validar_tudo(itens)).has(&"VP4")).is_true()


func test_f5_memorias_reveladas_por_raridade_e_nivel() -> void:
	var vt := FabricasDeCatalogo.vinculo_tuning()
	# Baluarte (raro, 3 memórias): 1 encontro sem pacto -> 1; 2 encontros e pacto -> 2; nível 5 -> 3
	assert_int(ValidadorVinculo.memorias_reveladas(&"raro", 1, false, 0, vt)).is_equal(1)
	assert_int(ValidadorVinculo.memorias_reveladas(&"raro", 2, true, 1, vt)).is_equal(2)
	assert_int(ValidadorVinculo.memorias_reveladas(&"raro", 2, true, 5, vt)).is_equal(3)
	# Vulto concedido na V3 (0 encontros, pactuada, nível 1) -> 1
	assert_int(ValidadorVinculo.memorias_reveladas(&"comum", 0, true, 1, vt)).is_equal(1)
