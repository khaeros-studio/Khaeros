## Story input-005: perda de foco e desconexão do gamepad (AC-23, AC-24), com adaptador, provedor, roteador e
## monitor de dispositivos reais; só o orquestrador (pedir_estado) e a UI (avisos) são dublês.
extends GdUnitTestSuite

var _adaptador: AdaptadorDeEntradaGodot
var _provedor: ProvedorDeEntrada
var _roteador: RoteadorDeContexto
var _monitor: MonitorDeDispositivos
var _pedidos: Array[StringName] = []
var _avisos: Array[StringName] = []
var _id: int = 0


func before_test() -> void:
	_pedidos.clear()
	_avisos.clear()
	_id = 0
	_adaptador = auto_free(AdaptadorDeEntradaGodot.new())
	_provedor = ProvedorDeEntrada.new(_adaptador.drenar)
	_provedor.configurar_ajustes(0.2, 0.05, 1000.0, 10, 100.0)
	_roteador = RoteadorDeContexto.new(_aceitar, _provedor.trocar_contexto)
	_monitor = MonitorDeDispositivos.new(_roteador, _provedor.dispositivo_ativo, _provedor.gamepad_ativo,
			func(c: StringName) -> void: _avisos.append(c))


func _aceitar(pedido: StringName) -> bool:
	_pedidos.append(pedido)
	return true


func _passo() -> AmostraDeEntrada:
	var amostra := _provedor.amostrar(_id, _roteador.contexto(), false)
	_roteador.processar_amostra(amostra)
	_id += 1
	return amostra


func _ativar_gamepad(dispositivo: int) -> void:
	_passo()
	var a := DescritorDeEntrada.new(DescritorDeEntrada.BOTAO_GAMEPAD, JOY_BUTTON_X, 0, dispositivo)
	_adaptador.registrar_botao(a, true)
	_adaptador.registrar_botao(a, false)
	_passo()


# --- AC-23 ---

func test_perda_de_foco_em_jogo_pausa_solta_segurados_e_esvazia_buffer() -> void:
	_roteador.definir_base(Acoes.CONTEXTO_JOGO)
	_passo()
	_adaptador.registrar_botao(DescritorDeEntrada.new(DescritorDeEntrada.TECLA_FISICA, KEY_J), true)
	assert_bool(_passo().esta_segurado(Acoes.ATAQUE)).is_true()

	_roteador.perder_foco()
	_adaptador.soltar_tudo()
	var sem_foco := _passo()
	assert_array(_pedidos).is_equal([RoteadorDeContexto.PEDIDO_PAUSA])
	assert_bool(sem_foco.segurados().is_empty()).is_true()
	assert_bool(sem_foco.buffer().is_empty()).is_true()

	_roteador.recuperar_foco()
	assert_str(String(_roteador.contexto())).is_equal(String(Acoes.CONTEXTO_PAUSA))


func test_perda_de_foco_em_bencao_ou_menu_nao_pausa() -> void:
	for contexto: StringName in [Acoes.CONTEXTO_BENCAO, Acoes.CONTEXTO_MENU]:
		_roteador.definir_base(contexto)
		_passo()
		_roteador.perder_foco()
		assert_str(String(_roteador.contexto())).is_equal(String(Acoes.CONTEXTO_SEM_FOCO))
		_roteador.recuperar_foco()
		assert_str(String(_roteador.contexto())).is_equal(String(contexto))
	assert_bool(_pedidos.is_empty()).is_true()


func test_perda_de_foco_na_transicao_pausa_no_primeiro_passo_de_jogo() -> void:
	_roteador.definir_base(Acoes.CONTEXTO_TRANSICAO)
	_passo()
	_roteador.perder_foco()
	_roteador.recuperar_foco()
	assert_bool(_pedidos.is_empty()).is_true()
	assert_bool(_roteador.pausa_memorizada()).is_true()

	_roteador.definir_base(Acoes.CONTEXTO_JOGO)
	assert_str(String(_roteador.contexto())).is_equal(String(Acoes.CONTEXTO_PAUSA))
	assert_array(_pedidos).is_equal([RoteadorDeContexto.PEDIDO_PAUSA])


# --- AC-24 ---

func test_gamepad_ativo_desconecta_pausa_e_avisa_reconectar_segue_pausado() -> void:
	_roteador.definir_base(Acoes.CONTEXTO_JOGO)
	_ativar_gamepad(0)
	assert_bool(_monitor.ao_mudar_conexao(0, false)).is_true()
	assert_str(String(_roteador.contexto())).is_equal(String(Acoes.CONTEXTO_PAUSA))
	assert_array(_avisos).is_equal([MonitorDeDispositivos.AVISO_DESCONECTADO])
	_monitor.ao_mudar_conexao(0, true)
	assert_str(String(_roteador.contexto())).is_equal(String(Acoes.CONTEXTO_PAUSA))


func test_teclado_ativo_desconexao_nao_pausa() -> void:
	_roteador.definir_base(Acoes.CONTEXTO_JOGO)
	_ativar_gamepad(0)
	_adaptador.registrar_botao(DescritorDeEntrada.new(DescritorDeEntrada.TECLA_FISICA, KEY_J), true)
	_passo()
	assert_bool(_monitor.ao_mudar_conexao(0, false)).is_false()
	assert_str(String(_roteador.contexto())).is_equal(String(Acoes.CONTEXTO_JOGO))
	assert_bool(_avisos.is_empty()).is_true()


func test_gamepad_nao_ativo_desconecta_nada() -> void:
	_roteador.definir_base(Acoes.CONTEXTO_JOGO)
	_ativar_gamepad(0)
	assert_bool(_monitor.ao_mudar_conexao(1, false)).is_false()
	assert_str(String(_roteador.contexto())).is_equal(String(Acoes.CONTEXTO_JOGO))
	assert_bool(_avisos.is_empty()).is_true()


func test_desconexao_em_bencao_so_avisa() -> void:
	_roteador.definir_base(Acoes.CONTEXTO_BENCAO)
	_ativar_gamepad(0)
	assert_bool(_monitor.ao_mudar_conexao(0, false)).is_false()
	assert_str(String(_roteador.contexto())).is_equal(String(Acoes.CONTEXTO_BENCAO))
	assert_array(_avisos).is_equal([MonitorDeDispositivos.AVISO_DESCONECTADO])
	assert_bool(_pedidos.is_empty()).is_true()
