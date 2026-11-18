extends GdUnitTestSuite
## Story RNG-007: exibição do texto completo da seed (`XXXX-XXXX · vX.Y.Z · cXXXX`)
## na pausa, morte, vitória e debug (AC-22), cópia para a área de transferência (R8)
## e edição no campo de debug preservando entrada inválida com mensagem de erro.

var _area_transferencia: String = ""
var _ctrl: ControladorDaSeedNaUi


func before_test() -> void:
	_area_transferencia = ""
	_ctrl = ControladorDaSeedNaUi.new(func(t: String) -> void: _area_transferencia = t)


func test_exibe_rotulo_completo_em_pausa_morte_vitoria_e_debug() -> void:
	# Arrange
	var fonte := FonteDeFluxos.new(RelatorGravadorRng.new())
	assert_str(_ctrl.rotulo_visivel()).is_equal(TextoDaSeed.TEXTO_SEM_SEED)

	# Act: run iniciada (visível em pausa e debug) e depois encerrada (visível em morte e vitória)
	fonte.iniciar_run(0x3F9A07C2, false)
	_ctrl.atualizar_da_fonte(fonte, "0.1.0", "1B4E")
	var rotulo_em_pausa := _ctrl.rotulo_visivel()

	fonte.encerrar_run()
	_ctrl.atualizar_da_fonte(fonte, "0.1.0", "1B4E")
	var rotulo_em_fim := _ctrl.rotulo_visivel()

	# Assert
	assert_str(rotulo_em_pausa).is_equal("3F9A-07C2 · v0.1.0 · c1B4E")
	assert_str(rotulo_em_fim).is_equal("3F9A-07C2 · v0.1.0 · c1B4E")


func test_copiar_coloca_texto_completo_na_area_de_transferencia() -> void:
	# Arrange: sem seed não copia
	assert_bool(_ctrl.copiar_seed()).is_false()
	assert_str(_area_transferencia).is_empty()

	# Act: com seed ativa copia o rótulo completo e registra aviso SEED_COPIADA
	_ctrl.atualizar_da_seed(0x3F9A07C2, "0.1.0", "1B4E")
	assert_bool(_ctrl.copiar_seed()).is_true()

	# Assert
	assert_str(_area_transferencia).is_equal("3F9A-07C2 · v0.1.0 · c1B4E")
	assert_int(_ctrl.copias_realizadas()).is_equal(1)
	assert_str(String(_ctrl.ultimo_aviso_ui())).is_equal(String(ControladorDaSeedNaUi.CHAVE_SEED_COPIADA))


func test_campo_debug_entrada_invalida_mantem_texto_digitado_e_mostra_mensagem() -> void:
	# Arrange
	_ctrl.atualizar_da_seed(0x3F9A07C2, "0.1.0", "1B4E")

	# Act: digita entrada inválida ("XYZ") e submete
	_ctrl.digitar_no_campo_debug("XYZ")
	var aceito := _ctrl.submeter_campo_debug("0.1.0", "1B4E")

	# Assert: recusa, mantém "XYZ" no campo, mostra mensagem citando "XYZ" e não muda o rótulo ativo
	assert_bool(aceito).is_false()
	assert_str(_ctrl.texto_campo_debug()).is_equal("XYZ")
	assert_str(_ctrl.mensagem_erro_debug()).contains("\"XYZ\"")
	assert_str(_ctrl.rotulo_visivel()).is_equal("3F9A-07C2 · v0.1.0 · c1B4E")

	# Act: corrige para "a1d3" e submete
	_ctrl.digitar_no_campo_debug("a1d3")
	assert_bool(_ctrl.submeter_campo_debug("0.1.0", "1B4E")).is_true()
	assert_str(_ctrl.mensagem_erro_debug()).is_empty()
	assert_int(_ctrl.seed_debug_aceita()).is_equal(0x0000A1D3)
	assert_str(_ctrl.texto_campo_debug()).is_equal("0000-A1D3")
	assert_str(_ctrl.rotulo_visivel()).is_equal("0000-A1D3 · v0.1.0 · c1B4E")


func test_integracao_campo_debug_com_roteador_de_foco_em_contexto_texto() -> void:
	# Arrange: liga o ControladorDaSeedNaUi ao RoteadorDeFoco (story input-009 + rng-007)
	var ctx := RoteadorDeContexto.new(func(_p: StringName) -> bool: return true)
	ctx.definir_base(Acoes.CONTEXTO_MENU)
	var foco := RoteadorDeFoco.new(ctx)
	foco.configurar_tela(2, 0)
	_ctrl.atualizar_da_seed(0x3F9A07C2, "0.1.0", "1B4E")
	foco.configurar_campo_texto(
		0,
		_ctrl.texto_campo_debug(),
		func(t: String) -> Dictionary:
			_ctrl.digitar_no_campo_debug(t)
			var ok := _ctrl.submeter_campo_debug("0.1.0", "1B4E")
			return {"aceito": ok, "mensagem": _ctrl.mensagem_erro_debug()}
	)

	# Act / Assert: entra em edição, digita "G123" + Enter -> fica em Texto com mensagem
	assert_bool(foco.entrar_edicao_texto(DescritorDeEntrada.ORIGEM_TECLADO)).is_true()
	foco.definir_texto_em_edicao("G123")
	assert_bool(foco.processar_tecla_em_texto(KEY_ENTER)).is_false()
	assert_bool(foco.em_edicao_de_texto()).is_true()
	assert_str(foco.texto_atual_do_campo()).is_equal("G123")
	assert_str(foco.mensagem_erro_texto()).contains("\"G123\"")

	# Digita "3F9A-07C2" + Enter -> confirma e volta ao Menu
	foco.definir_texto_em_edicao("3F9A-07C2")
	assert_bool(foco.processar_tecla_em_texto(KEY_ENTER)).is_true()
	assert_bool(foco.em_edicao_de_texto()).is_false()
	assert_int(_ctrl.seed_debug_aceita()).is_equal(0x3F9A07C2)


func test_guardrail_escala_ui_85_a_150_nao_corta_texto_da_seed() -> void:
	# Arrange
	_ctrl.atualizar_da_seed(0xFFFFFFFF, "0.1.0", "1B4E")
	var caixa_padrao_px := 450.0
	# Act / Assert
	for escala: float in [0.85, 1.0, 1.25, 1.50]:
		var min_px := _ctrl.largura_minima_sem_corte_px(escala)
		assert_float(min_px).is_greater(0.0)
		assert_bool(_ctrl.cabe_sem_corte(caixa_padrao_px, escala)).is_true()
