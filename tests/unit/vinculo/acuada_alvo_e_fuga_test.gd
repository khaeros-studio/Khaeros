extends GdUnitTestSuite
## Story vinculo-e-pactos/005: A acuada — nascimento, neutralidade, alvo por paridade, ferir_acuada e fuga.
## Cobre AC-VP-02, AC-VP-07, AC-VP-08, AC-VP-09, AC-VP-10 e AC-VP-11.


func test_ac_vp_07_e_08_nascimento_espreitador_vida_114_e_sem_fogo_amigo() -> void:
	var eventos := EventosDoPasso.new()
	var p := PerfilVinculo.new()
	var v := Vinculo.new(p, FabricasDeCatalogo.vinculo_tuning(), eventos)
	v.pedir_dupla(&"pactos")

	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte.iniciar_run(0x11112222, true)
	v.planejar_encontro(&"pactos", FluxosDeVinculo.new(fonte).pactos(0))

	# AC-VP-07: montagem do índice 1 sem pedras em (960, 540)
	var pos := v.ao_montar_camara(1, [])
	assert_that(pos).is_equal(Vector2(960.0, 540.0))
	assert_int(v.acuada().vida).is_equal(114)
	assert_int(p.estado_de(&"espreitador_da_fenda").encontros_vistos).is_equal(1)
	assert_bool(p.primeiro_encontro_visto).is_true()

	# AC-VP-08: Virote, Selo e Chamado (facção != inimigo) não ferem a acuada
	assert_bool(v.ferir_acuada(50.0, 1.0, &"jogador")).is_false()
	assert_bool(v.ferir_acuada(50.0, 1.0, &"aliado")).is_false()
	assert_int(v.acuada().vida).is_equal(114)


func test_ac_vp_09_e_10_alvo_por_paridade_e_prioridade_de_atracao() -> void:
	var ac := MaldicaoAcuada.new()
	ac.nascer(FabricasDeCatalogo.maldicao(&"espreitador_da_fenda", &"refinado"), [], 1.2)

	# AC-VP-09: ordem 0 e 2 miram a acuada; ordem 1 mira o jogador
	assert_str(String(ac.alvo_padrao_por_ordem(0))).is_equal("acuada")
	assert_str(String(ac.alvo_padrao_por_ordem(1))).is_equal("jogador")
	assert_str(String(ac.alvo_padrao_por_ordem(2))).is_equal("acuada")

	# AC-VP-10: Eco 0 atraído pelo Chamado mira a Maldição enquanto atraído, e volta à acuada depois
	assert_str(String(ac.alvo_efetivo_inimigo(0, true))).is_equal("maldicao")
	assert_str(String(ac.alvo_efetivo_inimigo(0, false))).is_equal("acuada")


func test_ac_vp_11_fuga_da_acuada_marca_pendente_e_redireciona_alvos_no_mesmo_passo() -> void:
	var eventos := EventosDoPasso.new()
	var p := PerfilVinculo.new()
	var v := Vinculo.new(p, FabricasDeCatalogo.vinculo_tuning(), eventos)
	v.pedir_dupla(&"pactos")
	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte.iniciar_run(0x11112222, true)
	v.planejar_encontro(&"pactos", FluxosDeVinculo.new(fonte).pactos(0))
	v.ao_montar_camara(1, [])

	v.acuada().vida = 5
	var fugiu: bool = v.ferir_acuada(9.0, 1.0, &"inimigo")
	assert_bool(fugiu).is_true()
	assert_int(v.acuada().estado).is_equal(MaldicaoAcuada.Estado.FUGIU)
	assert_int(v.acuada().passos_fuga_restantes).is_equal(12)
	assert_bool(v.acuada_atingivel()).is_false()
	assert_str(String(v.acuada().alvo_efetivo_inimigo(0, false))).is_equal("jogador")
	assert_array(p.encontro_pendente).is_equal(["espreitador_da_fenda"])
	assert_bool(v.encontro_aguardando()).is_false()
	assert_int(eventos.do_tipo(&"encontro_falhou").size()).is_equal(1)
