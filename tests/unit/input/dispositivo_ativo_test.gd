## Story input-002: dispositivo ativo (R3, F5; AC-13, AC-14).
extends GdUnitTestSuite

const ZM := 0.2
const ZE := 0.05
const LIMIAR_MOUSE := 4.0
const BUFFER := 10
const RAIO := 1350.0
const GATILHO_APERTA := 0.5
const GATILHO_SOLTA := 0.4


func _montar() -> Array:
	var adaptador: AdaptadorDeEntradaGodot = auto_free(AdaptadorDeEntradaGodot.new())
	adaptador.configurar_limiares(ZM, GATILHO_APERTA, GATILHO_SOLTA)
	var provedor := ProvedorDeEntrada.new(adaptador.drenar)
	provedor.configurar_ajustes(ZM, ZE, LIMIAR_MOUSE, BUFFER, RAIO)
	return [adaptador, provedor]


func _ativar_gamepad(adaptador: AdaptadorDeEntradaGodot, provedor: ProvedorDeEntrada, pad: int) -> void:
	var botao := DescritorDeEntrada.new(DescritorDeEntrada.BOTAO_GAMEPAD, JOY_BUTTON_X, 0, pad)
	adaptador.registrar_botao(botao, true)
	adaptador.registrar_botao(botao, false)
	provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)


func test_f5_movimentos_3_4_e_menos1_0_trocam_para_mouse() -> void:
	var partes := _montar()
	var adaptador: AdaptadorDeEntradaGodot = partes[0]
	var provedor: ProvedorDeEntrada = partes[1]
	_ativar_gamepad(adaptador, provedor, 0)
	adaptador.registrar_movimento_mouse(Vector2(3, 4).length())
	adaptador.registrar_movimento_mouse(Vector2(-1, 0).length())
	provedor.amostrar(1, Acoes.CONTEXTO_JOGO, false)
	assert_str(String(provedor.dispositivo_ativo())).is_equal(String(Acoes.DISPOSITIVO_TECLADO))


func test_f5_tremor_1_1_nao_troca() -> void:
	var partes := _montar()
	var adaptador: AdaptadorDeEntradaGodot = partes[0]
	var provedor: ProvedorDeEntrada = partes[1]
	_ativar_gamepad(adaptador, provedor, 0)
	adaptador.registrar_movimento_mouse(Vector2(1, 1).length())
	provedor.amostrar(1, Acoes.CONTEXTO_JOGO, false)
	assert_str(String(provedor.dispositivo_ativo())).is_equal(String(Acoes.DISPOSITIVO_GAMEPAD))


func test_mouse_e_analogico_significativos_no_mesmo_passo_mantem_atual() -> void:
	var partes := _montar()
	var adaptador: AdaptadorDeEntradaGodot = partes[0]
	var provedor: ProvedorDeEntrada = partes[1]
	_ativar_gamepad(adaptador, provedor, 0)
	adaptador.registrar_movimento_mouse(Vector2(30, 40).length())
	adaptador.registrar_eixo(0, JOY_AXIS_LEFT_X, 0.9)
	provedor.amostrar(1, Acoes.CONTEXTO_JOGO, false)
	assert_str(String(provedor.dispositivo_ativo())).is_equal(String(Acoes.DISPOSITIVO_GAMEPAD))


func test_camera_anda_com_cursor_parado_nao_troca() -> void:
	var partes := _montar()
	var adaptador: AdaptadorDeEntradaGodot = partes[0]
	var provedor: ProvedorDeEntrada = partes[1]
	_ativar_gamepad(adaptador, provedor, 0)
	# A câmera move o mundo sob o cursor, mas nenhum evento de mouse chega: Δ = 0 em px de tela.
	for passo: int in range(1, 10):
		provedor.amostrar(passo, Acoes.CONTEXTO_JOGO, false)
	assert_str(String(provedor.dispositivo_ativo())).is_equal(String(Acoes.DISPOSITIVO_GAMEPAD))


func test_dois_gamepads_ultimo_significativo_ignora_analogico_do_outro() -> void:
	var partes := _montar()
	var adaptador: AdaptadorDeEntradaGodot = partes[0]
	var provedor: ProvedorDeEntrada = partes[1]
	adaptador.registrar_eixo(0, JOY_AXIS_LEFT_X, 0.9)
	var botao_1 := DescritorDeEntrada.new(DescritorDeEntrada.BOTAO_GAMEPAD, JOY_BUTTON_X, 0, 1)
	adaptador.registrar_botao(botao_1, true)
	adaptador.registrar_botao(botao_1, false)
	var amostra := provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	assert_int(provedor.gamepad_ativo()).is_equal(1)
	assert_vector(amostra.mover).is_equal(Vector2.ZERO)
	# O analógico do 0 continua parado em 0,9: ignorado até ser usado de novo.
	assert_vector(provedor.amostrar(1, Acoes.CONTEXTO_JOGO, false).mover).is_equal(Vector2.ZERO)
	adaptador.registrar_eixo(0, JOY_AXIS_LEFT_X, 0.95)
	amostra = provedor.amostrar(2, Acoes.CONTEXTO_JOGO, false)
	assert_int(provedor.gamepad_ativo()).is_equal(0)
	assert_float(amostra.mover.x).is_equal_approx(1.0, 1e-6)


func test_dois_gamepads_no_mesmo_passo_vence_o_de_maior_ordem() -> void:
	var dispositivo := DispositivoAtivo.new()
	dispositivo.atualizar(false, {0: 3, 1: 7})
	assert_int(dispositivo.gamepad).is_equal(1)
	assert_str(String(dispositivo.atual)).is_equal(String(Acoes.DISPOSITIVO_GAMEPAD))
