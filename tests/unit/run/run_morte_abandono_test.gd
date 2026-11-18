extends GdUnitTestSuite
## Story run-e-regioes/007: Morte, abandono e regras da pausa.
## Cobre AC-RN-11, AC-RN-12, AC-RN-13, AC-RN-14, AC-RN-15, AC-RN-16, AC-RN-34 e AC-RN-35.


func test_ac_rn_12_13_16_35_morte_recusa_de_morte_e_prioridade_sobre_limpeza_no_chefe() -> void:
	var sessao := SessaoDeJogo.new()
	sessao.iniciar_escolha()
	sessao.confirmar_arma(&"lamina")
	sessao.conta.creditar(ContaFragmentos.PORTA, 7)

	# AC-RN-13: recusa de morte mantém a run Ativa
	assert_bool(sessao.run.ao_jogador_morreu(true)).is_false()
	assert_bool(sessao.run.ativa()).is_true()

	# AC-RN-16 e AC-RN-35: morte e camara_limpa do chefe no mesmo passo -> vale a morte!
	sessao.run.ao_camara_limpa(4, &"chefe", 6, true)
	assert_int(sessao.run.fase()).is_equal(Run.Fase.ENCERRADA)
	assert_str(String(sessao.run.resumo().motivo())).is_equal("morte")
	assert_str(String(sessao.run.resumo().desfecho_chefe())).is_equal("nenhum")
	assert_int(sessao.run.resumo().total()).is_equal(7)
	assert_int(sessao.conta.saldo()).is_equal(7)
	assert_int(sessao.run.tela_final_aberta_vezes()).is_equal(1)


func test_ac_rn_14_15_34_abandono_e_bloqueio_em_bencao_e_subjugado() -> void:
	var sessao := SessaoDeJogo.new()
	sessao.iniciar_escolha()
	sessao.confirmar_arma(&"pactos")
	sessao.conta.creditar(ContaFragmentos.PORTA, 4)

	# Cancelar abandono não encerra
	assert_bool(sessao.abandonar(false)).is_false()
	assert_bool(sessao.run.ativa()).is_true()

	# Em Bênção (veio_de_bencao = true), "Abandonar run" está desabilitado e confirmar não encerra (AC-RN-15)
	assert_bool(sessao.run.abandono_permitido(EstadoDeJogo.Valor.PAUSA, true)).is_false()
	assert_bool(sessao.abandonar(true, true)).is_false()
	assert_bool(sessao.run.ativa()).is_true()

	# Depois de chefe_subjugado, "Abandonar run" fica desabilitado (AC-RN-34)
	sessao.run.ao_chefe_subjugado(&"soberano_do_limiar")
	assert_bool(sessao.run.abandono_permitido(EstadoDeJogo.Valor.PAUSA, false)).is_false()
	assert_bool(sessao.abandonar(true, false)).is_false()
	assert_bool(sessao.run.ativa()).is_true()

	# Em Jogo normal (sem Subjugado pendente), confirmar abandono encerra com motivo `abandono` e mantém o saldo (AC-RN-14)
	var sessao2 := SessaoDeJogo.new()
	sessao2.iniciar_escolha()
	sessao2.confirmar_arma(&"lamina")
	sessao2.conta.creditar(ContaFragmentos.PORTA, 4)
	assert_bool(sessao2.abandonar(true, false)).is_true()
	assert_int(sessao2.run.fase()).is_equal(Run.Fase.ENCERRADA)
	assert_str(String(sessao2.run.resumo().motivo())).is_equal("abandono")
	assert_int(sessao2.run.resumo().total()).is_equal(4)
	assert_int(sessao2.conta.saldo()).is_equal(4)
