## Story input-005: contextos, barreira de troca e retorno explícito (AC-22, AC-35, AC-40).
## Orquestração mínima do teste: amostra com `roteador.contexto()` e passa a amostra ao roteador.
extends GdUnitTestSuite

var _adaptador: AdaptadorDeEntradaGodot
var _provedor: ProvedorDeEntrada
var _roteador: RoteadorDeContexto
var _pedidos: Array[StringName] = []
var _id: int = 0


func before_test() -> void:
	_pedidos.clear()
	_id = 0
	_adaptador = auto_free(AdaptadorDeEntradaGodot.new())
	_provedor = ProvedorDeEntrada.new(_adaptador.drenar)
	_provedor.configurar_ajustes(0.2, 0.05, 1000.0, 10, 100.0)
	_roteador = RoteadorDeContexto.new(_aceitar_pedido, _provedor.trocar_contexto)


func _aceitar_pedido(pedido: StringName) -> bool:
	_pedidos.append(pedido)
	return true


func _passo() -> AmostraDeEntrada:
	var amostra := _provedor.amostrar(_id, _roteador.contexto(), false)
	_roteador.processar_amostra(amostra)
	_provedor.encerrar_passo(_id)
	_id += 1
	return amostra


func _tecla(codigo: int) -> DescritorDeEntrada:
	return DescritorDeEntrada.new(DescritorDeEntrada.TECLA_FISICA, codigo)


func _botao(codigo: int) -> DescritorDeEntrada:
	return DescritorDeEntrada.new(DescritorDeEntrada.BOTAO_GAMEPAD, codigo, 0, 0)


func _tocar(descritor: DescritorDeEntrada) -> AmostraDeEntrada:
	_adaptador.registrar_botao(descritor, true)
	_adaptador.registrar_botao(descritor, false)
	return _passo()


# --- AC-22 ---

func test_jogo_para_bencao_com_espaco_segurado_nao_aceita_ate_soltar() -> void:
	_roteador.definir_base(Acoes.CONTEXTO_JOGO)
	_passo()
	_adaptador.registrar_botao(_tecla(KEY_SPACE), true)
	_adaptador.registrar_botao(_tecla(KEY_J), true)
	var em_jogo := _passo()
	assert_bool(em_jogo.buffer().is_empty()).is_false()

	_roteador.definir_base(Acoes.CONTEXTO_BENCAO)
	var na_bencao := _passo()
	assert_bool(na_bencao.buffer().is_empty()).is_true()
	assert_bool(na_bencao.foi_apertado(Acoes.UI_ACEITAR)).is_false()
	assert_bool(na_bencao.esta_segurado(Acoes.UI_ACEITAR)).is_false()

	_adaptador.registrar_botao(_tecla(KEY_SPACE), false)
	_passo()
	assert_bool(_tocar(_tecla(KEY_SPACE)).foi_apertado(Acoes.UI_ACEITAR)).is_true()


func test_bencao_para_jogo_com_botao_segurado_ataque_falso_ate_soltar() -> void:
	_roteador.definir_base(Acoes.CONTEXTO_BENCAO)
	_adaptador.registrar_botao(_tecla(KEY_J), true)
	_passo()
	_roteador.definir_base(Acoes.CONTEXTO_JOGO)
	var a1 := _passo()
	var a2 := _passo()
	assert_bool(a1.esta_segurado(Acoes.ATAQUE) or a1.foi_apertado(Acoes.ATAQUE)).is_false()
	assert_bool(a2.esta_segurado(Acoes.ATAQUE)).is_false()

	_adaptador.registrar_botao(_tecla(KEY_J), false)
	_passo()
	_adaptador.registrar_botao(_tecla(KEY_J), true)
	assert_bool(_passo().foi_apertado(Acoes.ATAQUE)).is_true()


func test_toque_no_mesmo_passo_da_troca_ignorado() -> void:
	_roteador.definir_base(Acoes.CONTEXTO_BENCAO)
	_passo()
	_adaptador.registrar_botao(_tecla(KEY_J), true)
	_adaptador.registrar_botao(_tecla(KEY_J), false)
	_roteador.definir_base(Acoes.CONTEXTO_JOGO)
	var amostra := _passo()
	assert_bool(amostra.foi_apertado(Acoes.ATAQUE)).is_false()
	assert_bool(amostra.buffer().is_empty()).is_true()


func test_transicao_esvazia_buffer_e_nao_aceita_nenhuma_acao() -> void:
	_roteador.definir_base(Acoes.CONTEXTO_JOGO)
	_passo()
	assert_bool(_tocar(_tecla(KEY_J)).buffer().has(Acoes.ATAQUE)).is_true()

	_roteador.definir_base(Acoes.CONTEXTO_TRANSICAO)
	assert_bool(_passo().buffer().is_empty()).is_true()
	for codigo: int in [KEY_J, KEY_K, KEY_SPACE, KEY_ESCAPE]:
		var amostra := _tocar(_tecla(codigo))
		assert_bool(amostra.apertados().is_empty()).is_true()
	assert_str(String(_roteador.contexto())).is_equal(String(Acoes.CONTEXTO_TRANSICAO))
	assert_bool(_pedidos.is_empty()).is_true()

	_roteador.definir_base(Acoes.CONTEXTO_JOGO)
	assert_bool(_passo().buffer().is_empty()).is_true()


# --- AC-35 ---

func test_jogo_esc_pausa_e_esc_volta_ao_jogo() -> void:
	_roteador.definir_base(Acoes.CONTEXTO_JOGO)
	_passo()
	_tocar(_tecla(KEY_ESCAPE))
	assert_str(String(_roteador.contexto())).is_equal(String(Acoes.CONTEXTO_PAUSA))
	_passo()
	_tocar(_tecla(KEY_ESCAPE))
	assert_str(String(_roteador.contexto())).is_equal(String(Acoes.CONTEXTO_JOGO))
	assert_array(_pedidos).is_equal([RoteadorDeContexto.PEDIDO_PAUSA, RoteadorDeContexto.PEDIDO_RETOMAR])


func test_jogo_start_pausa_e_start_volta_ao_jogo() -> void:
	_roteador.definir_base(Acoes.CONTEXTO_JOGO)
	_passo()
	_tocar(_botao(JOY_BUTTON_START))
	assert_str(String(_roteador.contexto())).is_equal(String(Acoes.CONTEXTO_PAUSA))
	_passo()
	_tocar(_botao(JOY_BUTTON_START))
	assert_str(String(_roteador.contexto())).is_equal(String(Acoes.CONTEXTO_JOGO))


func test_bencao_esc_pausa_por_cima_e_fechar_volta_a_mesma_bencao() -> void:
	_roteador.definir_base(Acoes.CONTEXTO_BENCAO)
	_passo()
	_tocar(_botao(JOY_BUTTON_B))
	assert_str(String(_roteador.contexto())).is_equal(String(Acoes.CONTEXTO_BENCAO))
	_tocar(_tecla(KEY_ESCAPE))
	assert_array(_roteador.pilha()).is_equal([Acoes.CONTEXTO_BENCAO, Acoes.CONTEXTO_PAUSA])
	_passo()
	_tocar(_tecla(KEY_ESCAPE))
	# A base Bênção nunca foi redefinida: a mesma oferta continua embaixo.
	assert_array(_roteador.pilha()).is_equal([Acoes.CONTEXTO_BENCAO])


func test_opcoes_da_pausa_esc_ou_b_voltam_e_start_nao_muda() -> void:
	_roteador.definir_base(Acoes.CONTEXTO_JOGO)
	_roteador.pausar()
	_roteador.abrir(Acoes.CONTEXTO_MENU)
	_passo()
	_tocar(_tecla(KEY_ESCAPE))
	assert_str(String(_roteador.contexto())).is_equal(String(Acoes.CONTEXTO_PAUSA))

	_roteador.abrir(Acoes.CONTEXTO_MENU)
	_tocar(_botao(JOY_BUTTON_A))
	_passo()
	_tocar(_botao(JOY_BUTTON_B))
	assert_str(String(_roteador.contexto())).is_equal(String(Acoes.CONTEXTO_PAUSA))

	_roteador.abrir(Acoes.CONTEXTO_MENU)
	_passo()
	_tocar(_botao(JOY_BUTTON_START))
	assert_str(String(_roteador.contexto())).is_equal(String(Acoes.CONTEXTO_MENU))


func test_pedido_de_pausa_recusado_nao_muda_contexto() -> void:
	var roteador := RoteadorDeContexto.new(func(_p: StringName) -> bool: return false)
	roteador.definir_base(Acoes.CONTEXTO_JOGO)
	assert_bool(roteador.pausar()).is_false()
	assert_str(String(roteador.contexto())).is_equal(String(Acoes.CONTEXTO_JOGO))


# --- AC-40 ---

func test_passe_de_morte_ignora_esc_e_aceitar_e_tela_final_vale_menu() -> void:
	_roteador.definir_base(Acoes.CONTEXTO_JOGO)
	_passo()
	_roteador.definir_base(Acoes.CONTEXTO_TRANSICAO) # jogador_morreu: passe de morte
	_passo()
	assert_bool(_tocar(_tecla(KEY_ESCAPE)).apertados().is_empty()).is_true()
	assert_bool(_tocar(_tecla(KEY_ENTER)).apertados().is_empty()).is_true()
	assert_bool(_pedidos.is_empty()).is_true()

	_roteador.definir_base(Acoes.CONTEXTO_MENU) # tela final
	_passo()
	assert_bool(_tocar(_tecla(KEY_ENTER)).foi_apertado(Acoes.UI_ACEITAR)).is_true()
