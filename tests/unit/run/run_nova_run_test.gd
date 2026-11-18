extends GdUnitTestSuite
## Story run-e-regioes/005: Composição da sessão, EscopoDaRun e nova_run por recriação.
## Cobre AC-RN-19, AC-RN-20, AC-RN-26 e AC-RN-36.


func test_ac_rn_19_20_26_36_recriacao_do_escopo_da_run_mantem_saldo_e_pactos_e_libera_antigo() -> void:
	var sessao := SessaoDeJogo.new()
	sessao.iniciar_escolha()
	assert_bool(sessao.confirmar_arma(&"pactos")).is_true()

	var escopo_1: EscopoDaRun = sessao.escopo_run
	var weak_1 := weakref(escopo_1)
	var seed_1: int = sessao.run.seed_valor()

	# Simula estado sujo na run 1: saldo 30, Fluxo gasto, selos, status, abates e pacto com o Soberano
	sessao.conta.creditar(ContaFragmentos.PORTA, 30)
	escopo_1.fluxo_selo = 25.0
	escopo_1.selos_ativos.append("selo_1")
	escopo_1.status_ativos.append("queimadura")
	escopo_1.chefe_presente = true
	sessao.run.registrar_abate(5)
	sessao.run.avancar_passos_em_jogo(600)
	sessao.vinculo.ao_chefe_subjugado(&"soberano_do_limiar")
	sessao.vinculo.escolher_destino_chefe(&"pactuar", &"soberano_do_limiar")

	# Encerra a run 1 e chama nova_run()
	sessao.run.ao_jogador_morreu()
	escopo_1 = null
	assert_bool(sessao.nova_run()).is_true()
	assert_object(sessao.escopo_run).is_null()
	assert_object(weak_1.get_ref()).is_null() # WeakRef nulo: EscopoDaRun antigo foi liberado!

	# Saldo continua 30, coletados_run zerou e o Soberano continua pactuado no perfil!
	assert_int(sessao.conta.saldo()).is_equal(30)
	assert_int(sessao.conta.coletados_run()).is_equal(0)
	assert_bool(sessao.perfil_vinculo.estado_de(&"soberano_do_limiar").pactuada).is_true()

	# Inicia a 2ª run -> novo EscopoDaRun com tudo limpo e seed nova!
	assert_bool(sessao.confirmar_arma(&"lamina")).is_true()
	var escopo_2: EscopoDaRun = sessao.escopo_run
	assert_object(escopo_2).is_not_null()
	assert_int(sessao.run.seed_valor()).is_not_equal(seed_1)
	assert_float(escopo_2.fluxo_selo).is_equal(100.0)
	assert_bool(escopo_2.selos_ativos.is_empty()).is_true()
	assert_bool(escopo_2.status_ativos.is_empty()).is_true()
	assert_bool(escopo_2.chefe_presente).is_false()
	assert_int(sessao.run.indice()).is_equal(0)
