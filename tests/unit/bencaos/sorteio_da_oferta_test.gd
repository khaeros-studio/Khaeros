extends GdUnitTestSuite
## Story bencaos-tradicoes-003: F7, raridade e consumo fixo (AC-BN-02, 03, 05, 06, 07).


func _sorteio() -> SorteioDeOferta:
	return SorteioDeOferta.new(FixtureBn.tabela(), FixtureBn.tuning())


func _indices(cartas: Array[CartaDaOferta]) -> Array:
	return cartas.map(func(c: CartaDaOferta) -> int: return c.indice_livre)


func test_pool_18_f5_da_indices_9_1_17_e_consome_3_mais_3() -> void:
	var fb := FluxoRoteirizado.new([0.5, 0.0, 0.99] as Array[float])
	var fr := FluxoRoteirizado.new([0.1, 0.1, 0.1] as Array[float])
	var cartas := _sorteio().sortear(FixtureBn.boons(), fb, fr)
	assert_array(_indices(cartas)).is_equal([9, 1, 17])
	assert_str(String(cartas[0].id)).is_equal(String(FixtureBn.IDS[9]))
	assert_int(fb.consumidos).is_equal(3)
	assert_int(fr.consumidos).is_equal(3)


func test_pool_2_da_indices_1_0_e_descarta_o_terceiro() -> void:
	var fb := FluxoRoteirizado.new([0.5, 0.99, 0.3] as Array[float])
	var fr := FluxoRoteirizado.new([0.1, 0.1, 0.1] as Array[float])
	var cartas := _sorteio().sortear(FixtureBn.boons_ate(2), fb, fr)
	assert_array(_indices(cartas)).is_equal([1, 0])
	assert_int(fb.consumidos).is_equal(3)
	assert_int(fr.consumidos).is_equal(3)


func test_pool_0_sem_cartas_e_consome_3_mais_3() -> void:
	var fb := FluxoRoteirizado.new([] as Array[float])
	var fr := FluxoRoteirizado.new([] as Array[float])
	var cartas := _sorteio().sortear([] as Array[BoonDef], fb, fr)
	assert_array(cartas).is_empty()
	assert_int(fb.consumidos).is_equal(3)
	assert_int(fr.consumidos).is_equal(3)


func test_limites_da_raridade_estritos() -> void:
	var s := _sorteio()
	assert_int(s.raridade_de(0.5999)).is_equal(SorteioDeOferta.COMUM)
	assert_int(s.raridade_de(0.6)).is_equal(SorteioDeOferta.RARA)
	assert_int(s.raridade_de(0.8999)).is_equal(SorteioDeOferta.RARA)
	assert_int(s.raridade_de(0.9)).is_equal(SorteioDeOferta.EPICA)


func test_carta_i_usa_real_i_e_reais_sobrando_descartados() -> void:
	var fb := FluxoRoteirizado.new([0.5, 0.99, 0.3] as Array[float])
	var fr := FluxoRoteirizado.new([0.95, 0.7, 0.1] as Array[float])
	var cartas := _sorteio().sortear(FixtureBn.boons_ate(2), fb, fr)
	assert_int(cartas[0].raridade).is_equal(SorteioDeOferta.EPICA)
	assert_int(cartas[1].raridade).is_equal(SorteioDeOferta.RARA)
	assert_int(fr.consumidos).is_equal(3)


func test_mesma_seed_mesma_oferta_e_estado_independe_do_pool() -> void:
	var fonte_a := _fonte(1234)
	var fonte_b := _fonte(1234)
	var fa := FluxosDeBencaos.new(fonte_a)
	var fb := FluxosDeBencaos.new(fonte_b)
	var reg_b := RegistroDeBencaos.new(FixtureBn.boons())
	reg_b.registrar(FixtureBn.IDS[0], SorteioDeOferta.COMUM)
	var c1 := _sorteio().sortear(FixtureBn.boons(), fa.bencaos(0, 4), fa.raridade(0, 4))
	var c2 := _sorteio().sortear(FixtureBn.boons(), FluxosDeBencaos.new(_fonte(1234)).bencaos(0, 4), FluxosDeBencaos.new(_fonte(1234)).raridade(0, 4))
	assert_array(_indices(c1)).is_equal(_indices(c2))
	_sorteio().sortear(reg_b.livres(), fb.bencaos(0, 4), fb.raridade(0, 4))
	assert_int(fa.bencaos(0, 4).estado()).is_equal(fb.bencaos(0, 4).estado())
	assert_int(fa.raridade(0, 4).estado()).is_equal(fb.raridade(0, 4).estado())


func test_chave_do_indice_isola_camaras() -> void:
	var fonte := _fonte(99)
	var f := FluxosDeBencaos.new(fonte)
	var antes: int = f.bencaos(0, 5).estado()
	for indice: int in [0, 1, 2, 4]:
		_sorteio().sortear(FixtureBn.boons(), f.bencaos(0, indice), f.raridade(0, indice))
	assert_int(f.bencaos(0, 5).estado()).is_equal(antes)
	assert_int(f.bencaos(0, 1).estado()).is_not_equal(f.bencaos(0, 2).estado())


func _fonte(seed_da_run: int) -> FonteDeFluxos:
	var fonte := FonteDeFluxos.new(RelatorGravadorRng.new())
	fonte.iniciar_run(seed_da_run, false)
	return fonte
