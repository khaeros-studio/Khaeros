extends GdUnitTestSuite
## Story input-009: foco único (`grab_focus()` no hover fora de Texto), navegação completa sem mouse
## (AC-33) e campo de texto de debug em contexto Texto (AC-36).

var _adaptador: AdaptadorDeEntradaGodot
var _provedor: ProvedorDeEntrada
var _roteador_ctx: RoteadorDeContexto
var _foco: RoteadorDeFoco
var _pedidos_estado: Array[StringName] = []
var _id_passo: int = 0


func before_test() -> void:
	_pedidos_estado.clear()
	_id_passo = 0
	_adaptador = auto_free(AdaptadorDeEntradaGodot.new())
	_provedor = ProvedorDeEntrada.new(_adaptador.drenar)
	_provedor.configurar_ajustes(0.2, 0.05, 4.0, 10, 1350.0)
	_roteador_ctx = RoteadorDeContexto.new(_pedir_estado, _provedor.trocar_contexto)
	_foco = RoteadorDeFoco.new(_roteador_ctx)


func _pedir_estado(pedido: StringName) -> bool:
	_pedidos_estado.append(pedido)
	return true


func _amostrar() -> AmostraDeEntrada:
	var a := _provedor.amostrar(_id_passo, _roteador_ctx.contexto(), false)
	_roteador_ctx.processar_amostra(a)
	_provedor.encerrar_passo(_id_passo)
	_id_passo += 1
	return a


func _tocar_tecla(codigo: int) -> AmostraDeEntrada:
	var d := DescritorDeEntrada.new(DescritorDeEntrada.TECLA_FISICA, codigo)
	_adaptador.registrar_botao(d, true)
	_adaptador.registrar_botao(d, false)
	return _amostrar()


func _tocar_gamepad(botao: int) -> AmostraDeEntrada:
	var d := DescritorDeEntrada.new(DescritorDeEntrada.BOTAO_GAMEPAD, botao, 0, 0)
	_adaptador.registrar_botao(d, true)
	_adaptador.registrar_botao(d, false)
	return _amostrar()


func _criar_controles(n: int) -> Array[Control]:
	var raiz: Control = auto_free(Control.new())
	add_child(raiz)
	var lista: Array[Control] = []
	for i in n:
		var c := Control.new()
		c.name = "Item_%d" % i
		raiz.add_child(c)
		lista.append(c)
	return lista


# --- AC-33: Foco inicial, navegação sem mouse, hover com grab_focus() e Tela de bênção ---

func test_foco_inicial_e_navegacao_alcanca_todos_os_controles_E_hover_move_foco_unico() -> void:
	# Arrange: 8 telas do inventário R9 (menu principal, pausa, bênção, morte, vitória, opções, erros, debug)
	var telas_r9: Array[Dictionary] = [
		{"nome": "menu_principal", "ctx": Acoes.CONTEXTO_MENU, "n": 4, "ini": 0},
		{"nome": "pausa", "ctx": Acoes.CONTEXTO_PAUSA, "n": 3, "ini": 0},
		{"nome": "bencao", "ctx": Acoes.CONTEXTO_BENCAO, "n": 3, "ini": 1},
		{"nome": "morte", "ctx": Acoes.CONTEXTO_MENU, "n": 3, "ini": 0},
		{"nome": "vitoria", "ctx": Acoes.CONTEXTO_MENU, "n": 3, "ini": 0},
		{"nome": "opcoes", "ctx": Acoes.CONTEXTO_MENU, "n": 5, "ini": 0},
		{"nome": "erros_catalogo", "ctx": Acoes.CONTEXTO_MENU, "n": 2, "ini": 0},
		{"nome": "debug", "ctx": Acoes.CONTEXTO_MENU, "n": 4, "ini": 0},
	]
	for info: Dictionary in telas_r9:
		_roteador_ctx.definir_base(info["ctx"])
		var n: int = info["n"]
		var ini: int = info["ini"]
		var ctrls := _criar_controles(n)
		_foco.configurar_tela(n, ini, true, ctrls)

		# Assert: foco inicial presente e Control com grab_focus() e MOUSE_FILTER_IGNORE
		assert_int(_foco.focado()).is_equal(ini)
		assert_bool(ctrls[ini].has_focus()).is_true()
		for c: Control in ctrls:
			assert_int(c.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)

		# Act: ui_navegar alcança todos os controles focáveis
		var visitados: Dictionary = {_foco.focado(): true}
		for _i in n:
			_foco.navegar(Acoes.DIRECAO_BAIXO)
			visitados[_foco.focado()] = true
		assert_int(visitados.size()).is_equal(n)

		# Act: mouse parado (mouse_moveu = false) não rouba o foco
		var alvo_hover := (ini + 1) % n
		assert_bool(_foco.aplicar_hover(alvo_hover, false)).is_false()

		# Act: mouse em movimento sobre outro controle move o foco único e chama grab_focus()
		assert_bool(_foco.aplicar_hover(alvo_hover, true)).is_true()
		assert_int(_foco.focado()).is_equal(alvo_hover)
		assert_bool(ctrls[alvo_hover].has_focus()).is_true()

		# Assert: o ui_navegar seguinte parte do controle focado pelo hover
		var esperado_apos_hover := (alvo_hover + 1) % n
		assert_int(_foco.navegar(Acoes.DIRECAO_BAIXO)).is_equal(esperado_apos_hover)
		assert_bool(ctrls[esperado_apos_hover].has_focus()).is_true()


func test_tela_de_bencao_atalhos_1_2_3_so_focam_aceitar_confirma_r_troca_e_travas() -> void:
	# Arrange
	_roteador_ctx.definir_base(Acoes.CONTEXTO_BENCAO)
	_amostrar()
	var ctrls := _criar_controles(3)
	_foco.configurar_tela(3, 1, false, ctrls, RoteadorDeFoco.PoliticaDeClique.SO_FOCAR_SE_NAO_FOCADO)
	_foco.armar_trava_ms(500.0)

	# Act / Assert: durante a trava de 500 ms, Enter não confirma; atalhos 1/2/3 apenas movem o foco
	var a_travado := _tocar_tecla(KEY_ENTER)
	assert_int(_foco.processar_passo_ui(a_travado)).is_equal(-1)

	var a_c1 := _tocar_tecla(KEY_1)
	assert_int(_foco.processar_passo_ui(a_c1)).is_equal(-1)
	assert_int(_foco.focado()).is_equal(0)
	assert_int(_foco.confirmacoes_no_passo()).is_equal(0)

	var a_c3 := _tocar_tecla(KEY_3)
	assert_int(_foco.processar_passo_ui(a_c3)).is_equal(-1)
	assert_int(_foco.focado()).is_equal(2)

	var a_c2 := _tocar_tecla(KEY_2)
	assert_int(_foco.processar_passo_ui(a_c2)).is_equal(-1)
	assert_int(_foco.focado()).is_equal(1)

	# Zera a trava de 500 ms: Enter, Espaço, E e A do gamepad confirmam (no máximo 1 por passo)
	_foco.avancar_trava_ms(500.0)
	assert_bool(_foco.trava_ativa()).is_false()

	for tecla_aceitar: int in [KEY_ENTER, KEY_SPACE, KEY_E]:
		var am := _tocar_tecla(tecla_aceitar)
		assert_int(_foco.processar_passo_ui(am)).is_equal(1)
		assert_int(_foco.confirmacoes_no_passo()).is_equal(1)

	# Gamepad navega e confirma com A
	_foco.navegar(Acoes.DIRECAO_DIREITA)
	assert_int(_foco.focado()).is_equal(2)
	var am_pad := _tocar_gamepad(JOY_BUTTON_A)
	assert_int(_foco.processar_passo_ui(am_pad, &"", DescritorDeEntrada.ORIGEM_GAMEPAD)).is_equal(2)

	# R (ui_trocar_ofertas) troca as ofertas e arma a trava de 300 ms
	var am_r := _tocar_tecla(KEY_R)
	assert_int(_foco.processar_passo_ui(am_r, &"", DescritorDeEntrada.ORIGEM_TECLADO, -1, 300.0)).is_equal(-1)
	assert_int(_foco.trocas_solicitadas()).is_equal(1)
	assert_bool(_foco.trava_ativa()).is_true()
	_foco.avancar_trava_ms(300.0)
	assert_bool(_foco.trava_ativa()).is_false()


# --- AC-36: Campo de seed do debug em contexto Texto ---

func _validador_seed(texto: String) -> Dictionary:
	var r := TextoDaSeed.interpretar(texto)
	return {"aceito": r.aceito, "mensagem": r.mensagem}


func test_campo_de_texto_debug_fluxo_completo_ac36() -> void:
	# Arrange: Menu de debug com 3 controles (0 = campo de seed, 1 = botão vizinho, 2 = voltar)
	_roteador_ctx.definir_base(Acoes.CONTEXTO_MENU)
	_amostrar()
	var ctrls := _criar_controles(3)
	_foco.configurar_tela(3, 0, true, ctrls)
	_foco.configurar_campo_texto(0, "3F9A-07C2", _validador_seed)

	# 1. A do gamepad NÃO entra em edição (AC-36)
	var am_gamepad_a := _tocar_gamepad(JOY_BUTTON_A)
	_foco.processar_passo_ui(am_gamepad_a, &"", DescritorDeEntrada.ORIGEM_GAMEPAD)
	assert_bool(_foco.em_edicao_de_texto()).is_false()
	assert_str(String(_roteador_ctx.contexto())).is_equal(String(Acoes.CONTEXTO_MENU))

	# 2. ui_aceitar de teclado entra em edição (contexto Texto)
	var am_enter := _tocar_tecla(KEY_ENTER)
	_foco.processar_passo_ui(am_enter, &"", DescritorDeEntrada.ORIGEM_TECLADO)
	assert_bool(_foco.em_edicao_de_texto()).is_true()
	assert_str(String(_roteador_ctx.contexto())).is_equal(String(Acoes.CONTEXTO_TEXTO))

	# 3. Digitar "A1D3" grava "A1D3" e o foco não se move; Enter confirma e volta ao Menu
	_foco.definir_texto_em_edicao("")
	_foco.digitar_texto("A1D3")
	assert_int(_foco.focado()).is_equal(0)
	assert_bool(_foco.navegar(Acoes.DIRECAO_BAIXO) == 0).is_true()
	assert_bool(_foco.processar_tecla_em_texto(KEY_ENTER)).is_true()
	assert_bool(_foco.em_edicao_de_texto()).is_false()
	assert_str(String(_roteador_ctx.contexto())).is_equal(String(Acoes.CONTEXTO_MENU))
	assert_str(_foco.valor_confirmado_texto()).is_equal("A1D3")

	# 4. Esc sai sem mudar o valor e NÃO abre a Pausa
	_foco.entrar_edicao_texto(DescritorDeEntrada.ORIGEM_TECLADO)
	_foco.definir_texto_em_edicao("BBBB")
	assert_bool(_foco.processar_tecla_em_texto(KEY_ESCAPE)).is_true()
	assert_bool(_foco.em_edicao_de_texto()).is_false()
	assert_str(String(_roteador_ctx.contexto())).is_equal(String(Acoes.CONTEXTO_MENU))
	assert_str(_foco.valor_confirmado_texto()).is_equal("A1D3")
	assert_bool(_pedidos_estado.is_empty()).is_true()

	# 5. "XYZ" + Enter -> continua em Texto com a mensagem do RNG e mantém o texto digitado
	_foco.entrar_edicao_texto(DescritorDeEntrada.ORIGEM_TECLADO)
	_foco.definir_texto_em_edicao("XYZ")
	assert_bool(_foco.processar_tecla_em_texto(KEY_ENTER)).is_false()
	assert_bool(_foco.em_edicao_de_texto()).is_true()
	assert_str(_foco.texto_atual_do_campo()).is_equal("XYZ")
	assert_str(_foco.mensagem_erro_texto()).contains("XYZ")

	# 6. Com ui_aceitar/ui_voltar remapeados para F1/F2, em edição só Enter e Esc confirmam/cancelam,
	#    e Espaço e E viram texto
	_foco.definir_texto_em_edicao("12")
	assert_bool(_foco.processar_tecla_em_texto(KEY_F1)).is_false()
	assert_bool(_foco.processar_tecla_em_texto(KEY_F2)).is_false()
	assert_bool(_foco.em_edicao_de_texto()).is_true()
	_foco.processar_tecla_em_texto(KEY_SPACE, " ")
	_foco.processar_tecla_em_texto(KEY_E, "E")
	assert_str(_foco.texto_atual_do_campo()).is_equal("12 E")

	# 7. Mouse sobre o botão vizinho mantém a edição; clique no botão vizinho sai da edição sem acioná-lo
	assert_bool(_foco.aplicar_hover(1, true)).is_false()
	assert_int(_foco.focado()).is_equal(0)
	assert_bool(_foco.em_edicao_de_texto()).is_true()

	var acao := _foco.processar_passo_ui(null, &"", DescritorDeEntrada.ORIGEM_MOUSE, 1)
	assert_int(acao).is_equal(-1)
	assert_int(_foco.confirmacoes_no_passo()).is_equal(0)
	assert_bool(_foco.em_edicao_de_texto()).is_false()
	assert_str(String(_roteador_ctx.contexto())).is_equal(String(Acoes.CONTEXTO_MENU))
	assert_str(_foco.valor_confirmado_texto()).is_equal("A1D3")
