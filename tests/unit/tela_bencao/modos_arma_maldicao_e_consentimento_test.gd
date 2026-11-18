class_name ModosArmaMaldicaoEConsentimentoTest
extends GdUnitTestSuite
## Testes unitários de `modo arma`, `modo maldicao` e `TelaDeConsentimentoDoPacto` (`story-007`, `story-008` e `story-009`).


func test_modo_arma_foca_ultima_arma_ou_lamina_e_exibe_aviso_besta_do_vinculo() -> void:
	var tela: TelaDeBencaoView = auto_free(TelaDeBencaoView.new())
	tela.abrir_modo_arma(&"besta_do_vinculo", 0, true)

	assert_that(tela.grupo().modo()).is_equal(&"arma")
	assert_that(tela.grupo().foco().foco_atual()).is_equal(2)
	assert_that(tela.grupo().cartas()[2].aviso_texto).is_equal(&"ARMA_AVISO_SEM_PACTOS_NO_PERFIL")

	# Se ultima_arma for desconhecida, cai em lamina (índice 0)
	tela.abrir_modo_arma(&"inexistente", 2, true)
	assert_that(tela.grupo().foco().foco_atual()).is_equal(0)


func test_modo_maldicao_pula_quando_zero_especies_e_permite_esc_em_cascata() -> void:
	var tela: TelaDeBencaoView = auto_free(TelaDeBencaoView.new())
	var duplas: Array[Array] = []
	tela.dupla_maldicoes_escolhida.connect(func(c: StringName, r: StringName) -> void: duplas.append([c, r]))

	# 0 espécies pactuadas -> pula imediatamente
	assert_that(tela.abrir_modo_maldicao([], true)).is_false()
	assert_that(duplas.size()).is_equal(1)
	assert_that(duplas[0][0]).is_equal(&"")

	# 2 espécies pactuadas -> escolhe Campo, depois Esc desfaz Campo, depois escolhe Campo + Reserva
	assert_that(tela.abrir_modo_maldicao([&"brasas", &"eco"], true)).is_true()
	tela.avancar_tempo(0.55)

	var cmd: ComandosDeTela = ComandosDeTela.new()
	cmd.aceitar = true
	tela.processar_comandos(cmd, true)
	assert_that(tela.maldicao_campo_escolhida()).is_equal(&"brasas")

	# Destrava etapa 1 e aperta voltar (Esc) -> desfaz Campo
	tela.avancar_tempo(0.55)
	cmd.limpar()
	cmd.voltar = true
	var res_esc: Dictionary = tela.processar_comandos(cmd, true)
	assert_that(bool(res_esc.get("desfez_campo", false))).is_true()
	assert_that(tela.maldicao_campo_escolhida()).is_equal(&"")


func test_tela_consentimento_do_pacto_encontro_vs_chefe_subjugado_e_bloqueio_de_voltar() -> void:
	var cons: TelaDeConsentimentoDoPacto = auto_free(TelaDeConsentimentoDoPacto.new())
	var resultados: Array[Array] = []
	cons.decisao_tomada.connect(func(p: bool, b: int) -> void: resultados.append([p, b]))

	cons.abrir(&"soberano", TelaDeConsentimentoDoPacto.MODO_CHEFE_SUBJUGADO, false)
	assert_that(cons.chave_opcao_esquerda()).is_equal(&"PACTO_OFERECER_VINCULO")
	assert_that(cons.chave_opcao_direita()).is_equal(&"PACTO_EXORCIZAR_CHEFE")
	assert_that(cons.travada()).is_true()

	# Botão B / voltar nunca resolve a escolha
	var cmd: ComandosDeTela = ComandosDeTela.new()
	cmd.voltar = true
	cons.processar_comandos(cmd)
	assert_that(resultados.is_empty()).is_true()

	# Após os 500 ms de trava, navega para Exorcizar (direita) e confirma -> +6 Fragmentos
	cons.avancar_tempo(0.55)
	cmd.limpar()
	cmd.navegar = Vector2i(1, 0)
	cmd.aceitar = true
	cons.processar_comandos(cmd)
	assert_that(resultados.size()).is_equal(1)
	assert_that(bool(resultados[0][0])).is_false()
	assert_that(int(resultados[0][1])).is_equal(6)
