extends GdUnitTestSuite
## Story run-e-regioes/009 e 010: Gravação do perfil no fim da run, bloqueio em JOGO e saída do jogo (R10, V20b).
## Cobre AC-RN-36 (persistência), TR-run-012 e Validation Criteria do ADR-0015 §7.


func test_gravacao_recusada_em_jogo_e_executada_no_fim_da_run_e_na_saida() -> void:
	var armazem := ArmazemEmMemoria.new()
	var sessao := SessaoDeJogo.new(armazem)

	sessao.iniciar_escolha()
	assert_bool(sessao.confirmar_arma(&"pactos")).is_true()
	# O 1º pacto (Vulto Mudo) marcou o Save como pendente
	assert_bool(sessao.save.pendente()).is_true()

	# Em estado JOGO, gravar_se_pendente devolve ERR_BUSY e NÃO toca o armazém!
	var gravacoes_antes: int = armazem.contar(&"gravar_atomico")
	assert_int(sessao.gravar_se_pendente(EstadoDeJogo.Valor.JOGO)).is_equal(ERR_BUSY)
	assert_int(armazem.contar(&"gravar_atomico")).is_equal(gravacoes_antes)

	# Em estado seguro (BENCAO ou MENU), grava o pacto!
	assert_int(sessao.gravar_se_pendente(EstadoDeJogo.Valor.BENCAO)).is_equal(OK)
	assert_int(armazem.contar(&"gravar_atomico")).is_equal(gravacoes_antes + 1)

	# Soma 12 pontos de vínculo durante a run e chama sair_do_jogo() com a run ativa (V20b, R10):
	sessao.vinculo.adicionar_pontos_diretos_na_run(&"vulto_mudo", 12)
	assert_int(sessao.sair_do_jogo()).is_equal(OK)
	assert_int(sessao.run.fase()).is_equal(Run.Fase.ENCERRADA)
	assert_str(String(sessao.run.resumo().motivo())).is_equal("abandono")
	assert_int(sessao.perfil_vinculo.estado_de(&"vulto_mudo").vinculo_pontos).is_equal(12)
	assert_int(armazem.contar(&"gravar_atomico")).is_equal(gravacoes_antes + 2)

	# Recarrega numa nova sessão sobre o mesmo armazém: pacto e pontos estão persistidos!
	var sessao_nova := SessaoDeJogo.new(armazem)
	assert_bool(sessao_nova.perfil_vinculo.estado_de(&"vulto_mudo").pactuada).is_true()
	assert_int(sessao_nova.perfil_vinculo.estado_de(&"vulto_mudo").vinculo_pontos).is_equal(12)
