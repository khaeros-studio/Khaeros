extends GdUnitTestSuite
## Story run-e-regioes/006: Vitória — câmara do chefe, crédito e run_encerrada.
## Cobre AC-RN-08, AC-RN-10, AC-RN-31, AC-RN-32 e AC-RN-33.


func test_ac_rn_08_31_32_vitoria_por_abate_com_lamina_e_indice_5_comum() -> void:
	var sessao := SessaoDeJogo.new()
	sessao.iniciar_escolha()
	sessao.confirmar_arma(&"lamina")

	# AC-RN-08: Santuário no índice 3 não encerra a run
	sessao.run.ao_camara_limpa(2, &"santuario", 3)
	assert_bool(sessao.run.ativa()).is_true()

	# AC-RN-31: índice 5 comum concede recompensa da porta escolhida depois do 4 (Fragmentos: +3) e abre 1 porta `chefe`
	sessao.escopo_run.portas.iniciar_camara(&"fragmentos")
	sessao.run.ao_camara_limpa(4, &"combate", 5)
	assert_bool(sessao.run.ativa()).is_true()
	assert_int(sessao.conta.coletados_run()).is_equal(3)
	assert_array(sessao.escopo_run.portas.portas_atuais()).is_equal([&"chefe"])

	# AC-RN-32: adiciona +2 para ter coletados = 5 antes do chefe; Chefes credita +6 (coletados = 11) e emite camara_limpa(4, chefe) no índice 6
	sessao.conta.creditar(ContaFragmentos.PORTA, 2)
	sessao.conta.creditar(ContaFragmentos.CHEFE, 6)
	sessao.run.ao_camara_limpa(4, &"chefe", 6)

	assert_int(sessao.run.fase()).is_equal(Run.Fase.ENCERRADA)
	var res := sessao.run.resumo()
	assert_str(String(res.motivo())).is_equal("vitoria")
	assert_int(res.fragmentos_coletados()).is_equal(11)
	assert_int(res.bonus_vitoria()).is_equal(15)
	assert_int(res.total()).is_equal(26)
	assert_str(String(res.desfecho_chefe())).is_equal("abatido")


func test_ac_rn_33_vitoria_em_pactos_pactuar_25_e_exorcizar_31() -> void:
	# Caso 1: Pactos com máximo de portas (10) e escolhe PACTUAR (0 do chefe + 15 de vitória = 25)
	var s1 := SessaoDeJogo.new()
	s1.iniciar_escolha()
	s1.confirmar_arma(&"pactos")
	s1.conta.creditar(ContaFragmentos.PORTA, 10)

	assert_bool(s1.run.ao_chefe_subjugado(&"soberano_do_limiar")).is_true()
	assert_bool(s1.run.ativa()).is_true()
	assert_bool(s1.run.ao_chefe_escolhido(&"soberano_do_limiar", &"pactuar")).is_true()
	s1.run.ao_camara_limpa(4, &"chefe", 6)

	assert_str(String(s1.run.resumo().desfecho_chefe())).is_equal("pactuado")
	assert_int(s1.run.resumo().fragmentos_coletados()).is_equal(10)
	assert_int(s1.run.resumo().bonus_vitoria()).is_equal(15)
	assert_int(s1.run.resumo().total()).is_equal(25)

	# Caso 2: Pactos com máximo de portas (10) e escolhe EXORCIZAR (+6 do chefe + 15 de vitória = 31)
	var s2 := SessaoDeJogo.new()
	s2.iniciar_escolha()
	s2.confirmar_arma(&"pactos")
	s2.conta.creditar(ContaFragmentos.PORTA, 10)

	assert_bool(s2.run.ao_chefe_subjugado(&"soberano_do_limiar")).is_true()
	assert_bool(s2.run.ao_chefe_escolhido(&"soberano_do_limiar", &"exorcizar")).is_true()
	s2.conta.creditar(ContaFragmentos.CHEFE, 6)
	s2.run.ao_camara_limpa(4, &"chefe", 6)

	assert_str(String(s2.run.resumo().desfecho_chefe())).is_equal("exorcizado")
	assert_int(s2.run.resumo().fragmentos_coletados()).is_equal(16)
	assert_int(s2.run.resumo().bonus_vitoria()).is_equal(15)
	assert_int(s2.run.resumo().total()).is_equal(31)
