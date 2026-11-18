class_name PausaOpcoesEFimDeRunTest
extends GdUnitTestSuite
## Testes unitários de `MenuDePausa`, `TelaDeOpcoes` e `TelaFimDeRun` (`story-008`, `story-009` e `story-010`).


func test_menu_de_pausa_confirmacao_abandono_padrao_cancelar_e_bloqueio_em_bencao() -> void:
	var copiado: Array[String] = []
	var pausa: MenuDePausa = auto_free(MenuDePausa.new())
	pausa.configurar("SEED-9876", null, func(s: String) -> void: copiado.append(s))

	# Aberto sobre BENCAO: Abandonar fica desabilitado
	pausa.abrir(true, false)
	assert_that(pausa.abandonar_habilitado()).is_false()

	# Aberto sobre JOGO: Abandonar abre modal cujo foco inicial é Cancelar
	pausa.abrir(false, false)
	assert_that(pausa.abandonar_habilitado()).is_true()
	# Navega para Copiar Seed (índice 2) e confirma
	pausa.processar_entrada(1, 0, false, false)
	pausa.processar_entrada(1, 0, true, false)
	assert_that(copiado.size()).is_equal(1)
	assert_that(copiado[0]).is_equal("SEED-9876")
	assert_that(pausa.seed_copiada_visivel()).is_true()

	# Navega para Abandonar (índice 3) e abre confirmação
	pausa.processar_entrada(1, 0, true, false)
	assert_that(pausa.confirmacao_abandono_aberta()).is_true()
	assert_that(pausa.foco_confirmacao_eh_cancelar()).is_true()


func test_tela_de_opcoes_permuta_tecla_em_conflito_e_protege_reset_de_perfil() -> void:
	var tela: TelaDeOpcoes = auto_free(TelaDeOpcoes.new())
	tela.configurar(OpcoesDoHud.new())

	# Atacar (KEY_J) remapeado para KEY_K (que era golpe_pesado) -> permuta as duas teclas
	assert_that(tela.remapear_acao(&"atacar", KEY_K)).is_true()
	assert_that(tela.ultimo_aviso()).is_equal(&"INPUT_CONFLITO_TROCA")
	assert_that(tela.tecla_da_acao(&"atacar")).is_equal(KEY_K)
	assert_that(tela.tecla_da_acao(&"golpe_pesado")).is_equal(KEY_J)

	# Reset de perfil bloqueado durante JOGO; no MENU exige 2 confirmações
	assert_that(tela.solicitar_reset_perfil(EstadoDeJogo.Valor.JOGO)).is_false()
	assert_that(tela.ultimo_aviso()).is_equal(&"PERFIL_RESET_BLOQUEADO_EM_JOGO")
	assert_that(tela.solicitar_reset_perfil(EstadoDeJogo.Valor.MENU)).is_false()
	assert_that(tela.ultimo_aviso()).is_equal(&"PERFIL_CONFIRMAR_SEGUNDA_VEZ")
	assert_that(tela.solicitar_reset_perfil(EstadoDeJogo.Valor.MENU)).is_true()
	assert_that(tela.ultimo_aviso()).is_equal(&"PERFIL_RESET_SUCESSO")


func test_tela_fim_de_run_trava_500ms_painel_vinculo_e_estatisticas() -> void:
	var fim: TelaFimDeRun = auto_free(TelaFimDeRun.new())
	var resumo: TelaFimDeRun.DadosFimDeRun = TelaFimDeRun.DadosFimDeRun.new()
	resumo.desfecho = &"vitoria"
	resumo.tempo_run_s = 725.0
	resumo.salas_limpas = 12
	resumo.inimigos_derrotados = 84
	resumo.dano_total_causado = 14500
	resumo.fragmentos_coletados = 320
	resumo.doutrina_id = &"pactos"
	resumo.pactos_firmados = [&"brasas", &"eco"]
	resumo.chefe_destino_pacto = &"pactuado"
	resumo.seed_texto = "KHAEROS-77"

	var jogou_novamente: Array[bool] = [false]
	fim.jogar_novamente_solicitado.connect(func() -> void: jogou_novamente[0] = true)
	fim.abrir(resumo)

	assert_that(fim.chave_titulo_desfecho()).is_equal(&"RUN_FIM_VITORIA")
	assert_that(fim.painel_vinculo_visivel()).is_true()
	assert_that(fim.travada_para_confirmacao()).is_true()

	# Durante os primeiros 500 ms, aceitar é ignorado
	fim.processar_entrada(0, true)
	assert_that(jogou_novamente[0]).is_false()

	fim.avancar_tempo(0.55)
	assert_that(fim.travada_para_confirmacao()).is_false()
	fim.processar_entrada(0, true)
	assert_that(jogou_novamente[0]).is_true()
