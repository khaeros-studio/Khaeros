extends GdUnitTestSuite
## Story bencaos-tradicoes-004: troca e raridade_bonus (AC-BN-04, 11, 12, 13, 14).

const REGIAO := &"limiar"


func _bencaos(trocas: int, pool: Array[BoonDef], bonus: float = 0.0) -> Bencaos:
	var fonte := FonteDeFluxos.new(RelatorGravadorRng.new())
	fonte.iniciar_run(4242, false)
	var regioes: Dictionary[StringName, int] = {REGIAO: 0}
	return Bencaos.new(RegistroDeBencaos.new(pool), SorteioDeOferta.new(FixtureBn.tabela(), FixtureBn.tuning(bonus)),
		FluxosDeBencaos.new(fonte), ConsultaFalsaBn.new(trocas), FixtureBn.tuning(bonus), regioes, EventosDoPasso.new())


## Estado dos fluxos depois de [param reais] reais a partir da mesma seed/chave.
func _estado_apos(reais: int, finalidade_bencaos: bool) -> int:
	var fonte := FonteDeFluxos.new(RelatorGravadorRng.new())
	fonte.iniciar_run(4242, false)
	var f := FluxosDeBencaos.new(fonte)
	var fluxo: FluxoRng = f.bencaos(0, 1) if finalidade_bencaos else f.raridade(0, 1)
	for _i: int in reais:
		fluxo.real_unitario()
	return fluxo.estado()


func _fluxos_de(b: Bencaos) -> FluxosDeBencaos:
	return b._fluxos


func test_troca_com_1_resorteia_gasta_e_consome_mais_6() -> void:
	var b := _bencaos(1, FixtureBn.boons())
	b.pedir_oferta(REGIAO, 1)
	assert_bool(b.trocar()).is_true()
	assert_int(b.trocas_restantes()).is_equal(0)
	assert_int(_fluxos_de(b).bencaos(0, 1).estado()).is_equal(_estado_apos(6, true))
	assert_int(_fluxos_de(b).raridade(0, 1).estado()).is_equal(_estado_apos(6, false))
	assert_int(b.cartas().size()).is_equal(3)


func test_troca_sem_cargas_recusada_sem_consumir() -> void:
	var b := _bencaos(0, FixtureBn.boons())
	b.pedir_oferta(REGIAO, 1)
	assert_bool(b.trocar()).is_false()
	assert_int(_fluxos_de(b).bencaos(0, 1).estado()).is_equal(_estado_apos(3, true))
	assert_int(_fluxos_de(b).raridade(0, 1).estado()).is_equal(_estado_apos(3, false))


func test_troca_sorteia_do_pool_inteiro_e_pode_repetir() -> void:
	var s := SorteioDeOferta.new(FixtureBn.tabela(), FixtureBn.tuning())
	var fb := FluxoRoteirizado.new([0.5, 0.0, 0.99, 0.5, 0.0, 0.99] as Array[float])
	var fr := FluxoRoteirizado.new([0.1, 0.1, 0.1, 0.1, 0.1, 0.1] as Array[float])
	var livres := FixtureBn.boons()
	var antes := s.sortear(livres, fb, fr)
	var depois := s.sortear(livres, fb, fr)
	assert_int(depois[0].indice_livre).is_equal(antes[0].indice_livre)


func test_troca_mantem_raridade_bonus() -> void:
	var s := SorteioDeOferta.new(FixtureBn.tabela(), FixtureBn.tuning(1.0))
	var fb := FluxoRoteirizado.new([0.5, 0.0, 0.99, 0.5, 0.0, 0.99] as Array[float])
	var fr := FluxoRoteirizado.new([0.1, 0.1, 0.1, 0.1, 0.1, 0.1] as Array[float])
	s.sortear(FixtureBn.boons(), fb, fr)
	var troca := s.sortear(FixtureBn.boons(), fb, fr)
	for c: CartaDaOferta in troca:
		assert_int(c.raridade).is_equal(SorteioDeOferta.RARA)


func test_pool_1_com_1_troca_aceita_e_resorteia_raridade() -> void:
	var b := _bencaos(1, FixtureBn.boons_ate(1))
	assert_str(String(b.pedir_oferta(REGIAO, 1))).is_equal("aberta")
	assert_bool(b.trocar()).is_true()
	var cartas := b.cartas()
	assert_int(cartas.size()).is_equal(1)
	assert_str(String(cartas[0].id)).is_equal(String(FixtureBn.IDS[0]))
	var esperado := SorteioDeOferta.new(FixtureBn.tabela(), FixtureBn.tuning())
	var fonte := FonteDeFluxos.new(RelatorGravadorRng.new())
	fonte.iniciar_run(4242, false)
	var fr := FluxosDeBencaos.new(fonte).raridade(0, 1)
	for _i: int in 3:
		fr.real_unitario()
	assert_int(cartas[0].raridade).is_equal(esperado.raridade_de(fr.real_unitario()))


func test_bonus_1_sobe_uma_raridade_com_teto_epica() -> void:
	var s := SorteioDeOferta.new(FixtureBn.tabela(), FixtureBn.tuning(1.0))
	assert_int(s.aplicar_bonus(SorteioDeOferta.COMUM)).is_equal(SorteioDeOferta.RARA)
	assert_int(s.aplicar_bonus(SorteioDeOferta.RARA)).is_equal(SorteioDeOferta.EPICA)
	assert_int(s.aplicar_bonus(SorteioDeOferta.EPICA)).is_equal(SorteioDeOferta.EPICA)
	assert_int(s.raridade_de(0.59)).is_equal(SorteioDeOferta.RARA)


func test_troca_emite_oferta_trocada() -> void:
	var b := _bencaos(1, FixtureBn.boons())
	b.pedir_oferta(REGIAO, 1)
	b.trocar()
	var ev: EventosDoPasso = b._eventos
	assert_bool(ev.ha(EvOfertaTrocada.TIPO)).is_true()
	assert_int((ev.do_tipo(EvOfertaTrocada.TIPO)[0] as EvOfertaTrocada).trocas).is_equal(0)
