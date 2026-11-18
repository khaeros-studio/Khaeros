extends GdUnitTestSuite
## Story portas-e-recompensas/001: RewardTable no catálogo e validação PV1–PV8.
## Cobre AC-PR-18, AC-PR-19 e AC-PR-37.


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


func test_ac_pr_18_erros_pv1_pv2_e_pv7() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"reward_table", &"reward_table") as RewardTable).chance_tres_portas = 1.5
	assert_bool(_codigos(ValidacaoRewardTable.validar_tudo(itens)).has(&"PV1")).is_true()

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"reward_table", &"reward_table") as RewardTable).fragmentos_porta_passo = 0
	assert_bool(_codigos(ValidacaoRewardTable.validar_tudo(itens)).has(&"PV1")).is_true()

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"reward_table", &"reward_table") as RewardTable).primeira_recompensa = &"provacao"
	assert_bool(_codigos(ValidacaoRewardTable.validar_tudo(itens)).has(&"PV2")).is_true()

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"reward_table", &"reward_table") as RewardTable).pesos_portas[&"provacao"] = 1.0
	assert_bool(_codigos(ValidacaoRewardTable.validar_tudo(itens)).has(&"PV7")).is_true()


func test_ac_pr_19_avisos_pv3_a_pv6_e_fabrica_sem_avisos() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	assert_array(ValidacaoRewardTable.validar_tudo(itens)).is_empty()

	# PV3: cura = 0 com chance_tres_portas = 0,3 -> menos de 3 tipos com peso > 0
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"reward_table", &"reward_table") as RewardTable).pesos_portas[&"cura"] = 0.0
	assert_bool(_codigos(ValidacaoRewardTable.validar_tudo(itens)).has(&"PV3")).is_true()

	# PV4: cura_porta = 0,45 (>= santuario_cura 0,40)
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"reward_table", &"reward_table") as RewardTable).cura_porta = 0.45
	assert_bool(_codigos(ValidacaoRewardTable.validar_tudo(itens)).has(&"PV4")).is_true()

	# PV5: pesos 1 / 1 / 4 -> P(bênção na escolha) = 0,673 < 0,80
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"reward_table", &"reward_table") as RewardTable).pesos_portas = {
		&"bencao": 1.0, &"fragmentos": 1.0, &"cura": 4.0, &"provacao": 0.0
	}
	assert_bool(_codigos(ValidacaoRewardTable.validar_tudo(itens)).has(&"PV5")).is_true()

	# PV6: chance_tres_portas = 0,8 (fora da faixa 0..0,6)
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"reward_table", &"reward_table") as RewardTable).chance_tres_portas = 0.8
	assert_bool(_codigos(ValidacaoRewardTable.validar_tudo(itens)).has(&"PV6")).is_true()


func test_ac_pr_37_aviso_pv8_quando_pool_menor_que_1_mais_k() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	for i in 4:
		var b := BoonDef.new()
		b.id = StringName("boon_%d" % i)
		itens.append(ItemDoCatalogo.new(&"boon", "res://t/b%d.tres" % i, itens.size(), b))
	# Limiar tem k = 4 escolhas livres -> 1 + 4 = 5 > 4 bênçãos no pool -> PV8!
	assert_bool(_codigos(ValidacaoRewardTable.validar_tudo(itens)).has(&"PV8")).is_true()

	# Com 5 bênçãos no pool -> sem PV8
	var b5 := BoonDef.new()
	b5.id = &"boon_4"
	itens.append(ItemDoCatalogo.new(&"boon", "res://t/b4.tres", itens.size(), b5))
	assert_bool(_codigos(ValidacaoRewardTable.validar_tudo(itens)).has(&"PV8")).is_false()
