extends GdUnitTestSuite
## Story bencaos-tradicoes-001: pool de 18 BoonDef, RarityTable, BencaosTuning, BN1/BN2.


func _codigos(t: BencaosTuning, r: RarityTable, codigo: StringName) -> int:
	var n: int = 0
	for d: Diagnostico in RegrasBn.new().validar(FixtureBn.itens(t, r)):
		if d.regra == codigo and d.eh_erro():
			n += 1
	return n


func test_fabrica_passa_bn_sem_erros() -> void:
	var diags := RegrasBn.new().validar(FixtureBn.itens(FixtureBn.tuning(), FixtureBn.tabela()))
	assert_array(diags).is_empty()


func test_tamanho_oferta_0_6_ou_4_da_bn1() -> void:
	for tamanho: int in [0, 6, 4]:
		var t := FixtureBn.tuning()
		t.tamanho_oferta = tamanho
		assert_int(_codigos(t, FixtureBn.tabela(), &"BN1")).is_equal(1)


func test_trocas_iniciais_negativa_da_bn1() -> void:
	var t := FixtureBn.tuning()
	t.trocas_iniciais = -1
	assert_int(_codigos(t, FixtureBn.tabela(), &"BN1")).is_equal(1)


func test_pesos_zerados_da_bn2() -> void:
	var r := FixtureBn.tabela()
	r.pesos = PackedFloat64Array([0.0, 0.0, 0.0])
	assert_int(_codigos(FixtureBn.tuning(), r, &"BN2")).is_equal(1)


func test_escalas_nao_crescentes_da_bn2() -> void:
	var r := FixtureBn.tabela()
	r.escalas = PackedFloat64Array([1.0, 1.0, 2.0])
	assert_int(_codigos(FixtureBn.tuning(), r, &"BN2")).is_equal(1)


func test_bn_registrado_no_validador_do_catalogo_entra_no_relatorio() -> void:
	var t := FixtureBn.tuning()
	t.tamanho_oferta = 0
	var itens := FixtureBn.itens(t, FixtureBn.tabela())
	var v := ValidadorDeCatalogo.new(FabricasDeCatalogo.registros(), FabricasDeCatalogo.textos_para(itens), null)
	v.acrescentar(RegrasBn.new())
	var codigos := v.validar(itens).map(func(d: Diagnostico) -> StringName: return d.regra)
	assert_bool(codigos.has(&"BN1")).is_true()


func test_pool_tem_18_trad_na_ordem_estavel() -> void:
	var a := FixtureBn.boons()
	var b := FixtureBn.boons()
	assert_int(a.size()).is_equal(18)
	for i: int in a.size():
		assert_bool(String(a[i].id).begins_with("trad_")).is_true()
		assert_str(String(a[i].id)).is_equal(String(b[i].id))
		assert_str(a[i].tipo_do_catalogo()).is_equal("boon")


func test_padroes_de_fabrica() -> void:
	var r := FixtureBn.tabela()
	var t := FixtureBn.tuning()
	assert_array(Array(r.pesos)).is_equal([0.6, 0.3, 0.1])
	assert_array(Array(r.escalas)).is_equal([1.0, 1.5, 2.0])
	assert_int(t.tamanho_oferta).is_equal(3)
	assert_int(t.trocas_iniciais).is_equal(0)
	assert_float(t.raridade_bonus).is_equal(0.0)
