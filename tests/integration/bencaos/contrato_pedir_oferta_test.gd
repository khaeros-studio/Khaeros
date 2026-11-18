extends GdUnitTestSuite
## Story bencaos-tradicoes-005: contrato pedir_oferta, estados e BencaosNula
## (AC-BN-17, AC-BN-20). Tudo em memória, sem SceneTree; dublês de Modificadores e
## Portas (o "dublê de Portas" é o próprio teste, que trata a resposta).

const REGIAO := &"limiar"
const SEED := 777


func _montar(pool: Array[BoonDef], trocas: int, fonte: FonteDeFluxos, eventos: EventosDoPasso) -> Bencaos:
	var regioes: Dictionary[StringName, int] = {REGIAO: 0}
	return Bencaos.new(RegistroDeBencaos.new(pool), SorteioDeOferta.new(FixtureBn.tabela(), FixtureBn.tuning()),
		FluxosDeBencaos.new(fonte), ConsultaFalsaBn.new(trocas), FixtureBn.tuning(), regioes, eventos)


func _fonte_ativa(relator: RelatorGravadorRng) -> FonteDeFluxos:
	var fonte := FonteDeFluxos.new(relator)
	fonte.iniciar_run(SEED, false)
	return fonte


func _estado_apos(reais: int, profundidade: int) -> int:
	var f := FluxosDeBencaos.new(_fonte_ativa(RelatorGravadorRng.new()))
	var fluxo := f.bencaos(0, profundidade)
	for _i: int in reais:
		fluxo.real_unitario()
	return fluxo.estado()


func test_pool_0_responde_sem_bencao_e_consome_6() -> void:
	var fonte := _fonte_ativa(RelatorGravadorRng.new())
	var eventos := EventosDoPasso.new()
	var b := _montar([] as Array[BoonDef], 0, fonte, eventos)
	var resposta := b.pedir_oferta(REGIAO, 2)
	# Dublê de Portas: sem_bencao vira Fragmentos.
	var recompensa := &"fragmentos" if resposta == Bencaos.SEM_BENCAO else &"bencao"
	assert_str(String(resposta)).is_equal("sem_bencao")
	assert_str(String(recompensa)).is_equal("fragmentos")
	assert_int(b.estado()).is_equal(Bencaos.Estado.SEM_OFERTA)
	assert_int(FluxosDeBencaos.new(fonte).bencaos(0, 2).estado()).is_equal(_estado_apos(3, 2))
	assert_bool(eventos.ha(EvOfertaAberta.TIPO)).is_false()


func test_pedido_com_oferta_aberta_responde_ja_aberta_e_mantem() -> void:
	var fonte := _fonte_ativa(RelatorGravadorRng.new())
	var b := _montar(FixtureBn.boons(), 0, fonte, EventosDoPasso.new())
	assert_str(String(b.pedir_oferta(REGIAO, 0))).is_equal("aberta")
	var ids_antes := b.cartas().map(func(c: CartaDaOferta) -> StringName: return c.id)
	assert_str(String(b.pedir_oferta(REGIAO, 1))).is_equal("oferta_ja_aberta")
	assert_int(b.estado()).is_equal(Bencaos.Estado.OFERTA_ABERTA)
	assert_array(b.cartas().map(func(c: CartaDaOferta) -> StringName: return c.id)).is_equal(ids_antes)
	assert_int(fonte.fluxos_abertos()).is_equal(2)


func test_abrir_emite_oferta_aberta_com_cartas_e_trocas() -> void:
	var eventos := EventosDoPasso.new()
	var b := _montar(FixtureBn.boons(), 2, _fonte_ativa(RelatorGravadorRng.new()), eventos)
	b.pedir_oferta(REGIAO, 4)
	var ev := eventos.do_tipo(EvOfertaAberta.TIPO)[0] as EvOfertaAberta
	assert_int(ev.ids.size()).is_equal(3)
	assert_int(ev.trocas).is_equal(2)


func test_fora_de_run_ignorado_sem_consumir_rng() -> void:
	var relator := RelatorGravadorRng.new()
	var fonte := FonteDeFluxos.new(relator)
	var b := _montar(FixtureBn.boons(), 0, fonte, EventosDoPasso.new())
	assert_str(String(b.pedir_oferta(REGIAO, 0))).is_equal("fora_de_run")
	assert_int(b.estado()).is_equal(Bencaos.Estado.SEM_OFERTA)
	assert_int(fonte.fluxos_abertos()).is_equal(0)


func test_injecao_com_trocas_positivas_roda_sem_scene_tree() -> void:
	var b := _montar(FixtureBn.boons(), 3, _fonte_ativa(RelatorGravadorRng.new()), EventosDoPasso.new())
	b.pedir_oferta(REGIAO, 0)
	assert_int(b.trocas_restantes()).is_equal(3)
	assert_bool(b.trocar()).is_true()
	assert_int(b.trocas_restantes()).is_equal(2)
	assert_int(b.estado()).is_equal(Bencaos.Estado.OFERTA_ABERTA)
	assert_int(b.restantes()).is_equal(18)


func test_bencaos_nula_responde_sem_bencao() -> void:
	var n := BencaosNula.new()
	assert_str(String(n.pedir_oferta(REGIAO, 0))).is_equal("sem_bencao")
	assert_bool(n.trocar()).is_false()
	assert_int(n.restantes()).is_equal(0)
	assert_array(n.tomadas()).is_empty()
