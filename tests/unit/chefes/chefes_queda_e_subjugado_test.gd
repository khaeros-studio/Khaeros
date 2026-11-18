extends GdUnitTestSuite


func test_ac_ch_15_16_17_18_24_25_queda_em_pactos_subjugado_e_decisao_pactuar_vs_exorcizar() -> void:
	# 1. Caminho Pactos -> Pactuar (não credita +6 Fragmentos nem cura_ao_abater, e chama resolver_subjugado antes de limpar_camara_chefe)
	var amb_p := FixtureChefes.criar_ambiente(&"pactos", Vector2(960.0, 450.0), true)
	var id_lac := amb_p.ia.criar_inimigo(CatalogoChefes.criar_eco_perdido_padrao(), Vector2(825.0, 285.0), OpcoesDeNascimento.lacaio_do_chefe())
	assert_bool(amb_p.ia.vivo(id_lac)).is_true()

	amb_p.modulo.chefe_vencido(amb_p.id_chefe, true)
	# No passo da queda: hitstop de 36 passos, projéteis descartados, lacaios limpos e chefe em SUBJUGADO
	assert_array(amb_p.combate_spy.pausas_registradas).is_equal([36])
	assert_int(amb_p.combate_spy.descartes_projeteis).is_equal(1)
	assert_bool(amb_p.ia.vivo(id_lac)).is_false()
	assert_int(int(amb_p.ia.estado_de(amb_p.id_chefe).fase)).is_equal(int(EstadoDeInimigoIA.Fase.SUBJUGADO))

	# Avança 36 passos do hitstop; no 37º passo emite EvChefeSubjugado sem chamar limpar_camara_chefe()
	for _i in range(36):
		amb_p.modulo.atualizar_passo()
	assert_int(amb_p.modulo.drenar_eventos_subjugado().size()).is_equal(0)

	amb_p.modulo.atualizar_passo()
	var evs_sub := amb_p.modulo.drenar_eventos_subjugado()
	assert_int(evs_sub.size()).is_equal(1)
	assert_str(String(evs_sub[0].especie_id)).is_equal("soberano_do_limiar")
	assert_int(amb_p.camaras_spy.limpezas_camara).is_equal(0)

	# Jogador escolhe `pactuar`: ordem R9b -> resolver_subjugado e depois limpar_camara_chefe, sem creditar +6 Fragmentos
	amb_p.log_compartilhado.clear()
	amb_p.modulo.escolha(amb_p.id_chefe, &"pactuar")
	assert_array(amb_p.log_compartilhado).is_equal([
		"resolver_subjugado:pactuar",
		"limpar_camara_chefe",
	])
	assert_int(amb_p.vinculo_spy.creditos.size()).is_equal(0)
	assert_int(amb_p.combate_spy.curas_ao_abater_disparadas).is_equal(0)

	# AC-CH-18: Segunda chamada a escolha() é ignorada (idempotência)
	amb_p.modulo.escolha(amb_p.id_chefe, &"exorcizar")
	assert_int(amb_p.vinculo_spy.creditos.size()).is_equal(0)

	# 2. Caminho Pactos -> Exorcizar (credita +6 Fragmentos, dispara cura_ao_abater em resolver_subjugado e limpa câmara por último)
	var amb_ex := FixtureChefes.criar_ambiente(&"pactos", Vector2(960.0, 450.0), true)
	amb_ex.modulo.chefe_vencido(amb_ex.id_chefe, true)
	for _i in range(37):
		amb_ex.modulo.atualizar_passo()
	amb_ex.log_compartilhado.clear()
	amb_ex.modulo.escolha(amb_ex.id_chefe, &"exorcizar")
	assert_array(amb_ex.log_compartilhado).is_equal([
		"resolver_subjugado:exorcizar",
		"creditar:chefe:6",
		"limpar_camara_chefe",
	])
	assert_int(amb_ex.combate_spy.curas_ao_abater_disparadas).is_equal(1)
	assert_int(amb_ex.modulo.drenar_eventos_exorcizado().size()).is_equal(1)


func test_ac_ch_15_20_23_queda_fora_de_pactos_credita_6_fragmentos_e_limpa_camara_em_s_mais_37() -> void:
	var amb := FixtureChefes.criar_ambiente(&"lamina", Vector2(960.0, 450.0), true)
	amb.modulo.chefe_vencido(amb.id_chefe, false)

	for _i in range(36):
		amb.modulo.atualizar_passo()
	assert_int(amb.vinculo_spy.creditos.size()).is_equal(0)
	assert_int(amb.camaras_spy.limpezas_camara).is_equal(0)

	amb.modulo.atualizar_passo()
	assert_int(amb.vinculo_spy.creditos.size()).is_equal(1)
	assert_int(int(amb.vinculo_spy.creditos[0]["quantidade"])).is_equal(6)
	assert_int(amb.camaras_spy.limpezas_camara).is_equal(1)


func test_ac_ch_19_morte_simultanea_do_jogador_prevalece_sobre_queda_do_chefe() -> void:
	var amb := FixtureChefes.criar_ambiente(&"lamina", Vector2(960.0, 450.0), true)
	amb.combate_spy.jogador_morreu = true
	amb.modulo.chefe_vencido(amb.id_chefe, false)

	assert_int(amb.modulo.drenar_eventos_vencido().size()).is_equal(0)
	assert_int(amb.vinculo_spy.creditos.size()).is_equal(0)
