extends GdUnitTestSuite
## Story run-e-regioes/001: Máquina de estados da Run (com Escolha da dupla).
## Cobre AC-RN-01, AC-RN-17 e AC-RN-29 (parte de estados).


func test_ac_rn_01_e_17_transicoes_de_estado_nova_run_e_fim_repetido_ignorado() -> void:
	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	var run := Run.new(null, null, fonte)

	assert_int(run.fase()).is_equal(Run.Fase.SEM_RUN)
	assert_bool(run.nova_run()).is_false() # nova_run fora de ENCERRADA é recusado

	assert_bool(run.iniciar_escolha_de_arma()).is_true()
	assert_int(run.fase()).is_equal(Run.Fase.ESCOLHA_DE_ARMA)

	assert_bool(run.confirmar_arma(&"lamina")).is_true()
	assert_int(run.fase()).is_equal(Run.Fase.ATIVA)
	assert_bool(fonte.tem_seed()).is_true()

	# Encerra por morte -> estado ENCERRADA; segundo fim (morte ou vitória) é ignorado e o resumo não muda (AC-RN-17)
	assert_bool(run.ao_jogador_morreu()).is_true()
	assert_int(run.fase()).is_equal(Run.Fase.ENCERRADA)
	var resumo_1 := run.resumo()
	assert_bool(run.ao_jogador_morreu()).is_false()
	run.ao_camara_limpa(4, &"chefe", 6)
	assert_object(run.resumo()).is_same(resumo_1)

	# nova_run leva ENCERRADA -> ESCOLHA_DE_ARMA e descarta a seed e os fluxos
	assert_bool(run.nova_run()).is_true()
	assert_int(run.fase()).is_equal(Run.Fase.ESCOLHA_DE_ARMA)
	assert_bool(fonte.tem_seed()).is_false()


func test_ac_rn_29_pulos_da_tela_de_dupla_0_1_e_2_pactuadas_e_esc() -> void:
	var p := PerfilVinculo.new()
	var v := Vinculo.new(p)
	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	var run := Run.new(null, null, fonte)
	run.configurar_vinculo(v)

	# 0 pactuadas -> V3 concede Vulto Mudo e vai direto a ATIVA sem tela de dupla
	run.iniciar_escolha_de_arma()
	assert_bool(run.confirmar_arma(&"pactos")).is_true()
	assert_int(run.fase()).is_equal(Run.Fase.ATIVA)
	assert_array(run.dupla()).is_equal([&"vulto_mudo", &""])

	# 2 pactuadas -> entra em ESCOLHA_DA_DUPLA sem criar seed; Esc volta a ESCOLHA_DE_ARMA sem seed
	run.ao_jogador_morreu()
	run.nova_run()
	p.registrar_pacto_novo(&"espreitador_da_fenda")
	assert_bool(run.confirmar_arma(&"pactos")).is_true()
	assert_int(run.fase()).is_equal(Run.Fase.ESCOLHA_DA_DUPLA)
	assert_bool(fonte.tem_seed()).is_false()

	assert_bool(run.voltar_da_escolha_da_dupla()).is_true()
	assert_int(run.fase()).is_equal(Run.Fase.ESCOLHA_DE_ARMA)
	assert_bool(fonte.tem_seed()).is_false()

	# Confirma novamente e escolhe a dupla -> vai a ATIVA e cria a seed
	assert_bool(run.confirmar_arma(&"pactos")).is_true()
	assert_bool(run.confirmar_dupla(&"vulto_mudo", &"espreitador_da_fenda")).is_true()
	assert_int(run.fase()).is_equal(Run.Fase.ATIVA)
	assert_bool(fonte.tem_seed()).is_true()
