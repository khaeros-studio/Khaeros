## Story input-003: mira (R5, F4, R1b; AC-09, AC-10, AC-11, AC-12, AC-37, AC-45). Conversão tela → mundo e
## consulta de alvos são dublês injetados.
extends GdUnitTestSuite

const ZM := 0.2
const ZE := 0.05
const LIMIAR_MOUSE := 4.0
const BUFFER := 10
const RAIO := 1350.0
const GATILHO_APERTA := 0.5
const GATILHO_SOLTA := 0.4
const JANELA := Vector2(1920, 1080)
const TOL := 1e-4

var _alvos: Array = []
var _jogador: Dictionary = {"pos": Vector2.ZERO, "olhar": Vector2.ZERO}
var _deslocamento_camera: Vector2 = Vector2.ZERO


func before_test() -> void:
	_alvos = []
	_jogador = {"pos": Vector2.ZERO, "olhar": Vector2.ZERO}
	_deslocamento_camera = Vector2.ZERO


func _janela_para_mundo(janela: Vector2) -> Vector2:
	return janela + _deslocamento_camera


func _montar(gamepad: bool) -> Array:
	var adaptador: AdaptadorDeEntradaGodot = auto_free(AdaptadorDeEntradaGodot.new())
	adaptador.tamanho_janela = func() -> Vector2: return JANELA
	adaptador.configurar_limiares(ZM, GATILHO_APERTA, GATILHO_SOLTA)
	var provedor := ProvedorDeEntrada.new(adaptador.drenar)
	provedor.configurar_ajustes(ZM, ZE, LIMIAR_MOUSE, BUFFER, RAIO)
	provedor.configurar_mira(_janela_para_mundo, func() -> Array: return _alvos,
			func() -> Dictionary: return _jogador)
	if gamepad:
		var botao := DescritorDeEntrada.new(DescritorDeEntrada.BOTAO_GAMEPAD, JOY_BUTTON_X, 0, 0)
		adaptador.registrar_botao(botao, true)
		adaptador.registrar_botao(botao, false)
	return [adaptador, provedor]


func _alvo(pos: Vector2, surgindo: bool = false) -> Dictionary:
	return {"pos": pos, "surgindo": surgindo}


func _mira_gamepad(alvos: Array, direito: Vector2 = Vector2.ZERO, mover: Vector2 = Vector2.ZERO,
		olhar: Vector2 = Vector2.ZERO) -> Mira:
	var mira := Mira.new()
	mira.calcular_gamepad(direito, alvos, Vector2.ZERO, RAIO, mover, olhar)
	return mira


func _proximo(atual: Vector2, esperado: Vector2) -> void:
	assert_float(atual.x).is_equal_approx(esperado.x, TOL)
	assert_float(atual.y).is_equal_approx(esperado.y, TOL)


func test_f4_empate_vence_o_primeiro_da_lista() -> void:
	var a := _alvo(Vector2(300, 400))
	var b := _alvo(Vector2(400, 300))
	var c := _alvo(Vector2(0, 1400))
	_proximo(_mira_gamepad([a, b, c]).mirar, Vector2(0.6, 0.8))
	_proximo(_mira_gamepad([b, a, c]).mirar, Vector2(0.8, 0.6))


func test_f4_raio_inclusivo_no_limite_mira_no_inimigo() -> void:
	_proximo(_mira_gamepad([_alvo(Vector2(1350, 0))], Vector2.ZERO, Vector2(0, 1)).mirar, Vector2(1, 0))


func test_f4_fora_do_raio_usa_movimento() -> void:
	_proximo(_mira_gamepad([_alvo(Vector2(1350.01, 0))], Vector2.ZERO, Vector2(0, 1)).mirar, Vector2(0, 1))


func test_f4_distancia_zero_e_surgindo_ignorados_usa_movimento() -> void:
	var alvos := [_alvo(Vector2.ZERO), _alvo(Vector2(100, 0), true), _alvo(Vector2(0, 50), true)]
	_proximo(_mira_gamepad(alvos, Vector2.ZERO, Vector2(-1, 0)).mirar, Vector2(-1, 0))


func test_f4_analogico_direito_ativo_vence_inimigo() -> void:
	var mira := _mira_gamepad([_alvo(Vector2(100, 0))], Vector2(0, -0.5))
	_proximo(mira.mirar, Vector2(0, -1))
	assert_str(String(mira.fonte_mira)).is_equal(String(AmostraDeEntrada.FONTE_ANALOGICO))


func test_f4_tudo_zero_usa_olhar_e_sem_direcao_usa_cima() -> void:
	_proximo(_mira_gamepad([], Vector2.ZERO, Vector2.ZERO, Vector2(1, 0)).mirar, Vector2(1, 0))
	_proximo(_mira_gamepad([]).mirar, Vector2(0, -1))


func test_alvo_some_no_passo_seguinte_mira_vai_ao_proximo() -> void:
	var partes := _montar(true)
	var provedor: ProvedorDeEntrada = partes[1]
	_alvos = [_alvo(Vector2(100, 0)), _alvo(Vector2(0, 200))]
	_proximo(provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false).mirar, Vector2(1, 0))
	_alvos = [_alvo(Vector2(0, 200))]
	_proximo(provedor.amostrar(1, Acoes.CONTEXTO_JOGO, false).mirar, Vector2(0, 1))


func test_mouse_sobre_o_personagem_mantem_mira_anterior() -> void:
	var partes := _montar(false)
	var adaptador: AdaptadorDeEntradaGodot = partes[0]
	var provedor: ProvedorDeEntrada = partes[1]
	_jogador = {"pos": Vector2(500, 500), "olhar": Vector2.ZERO}
	adaptador.registrar_cursor(Vector2(600, 500))
	_proximo(provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false).mirar, Vector2(1, 0))
	adaptador.registrar_cursor(Vector2(500, 500))
	_proximo(provedor.amostrar(1, Acoes.CONTEXTO_JOGO, false).mirar, Vector2(1, 0))


func test_cursor_fora_da_janela_usa_ultima_posicao_reconvertida_no_passo() -> void:
	var partes := _montar(false)
	var adaptador: AdaptadorDeEntradaGodot = partes[0]
	var provedor: ProvedorDeEntrada = partes[1]
	adaptador.registrar_cursor(Vector2(960, 540))
	provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	adaptador.registrar_cursor(Vector2(-50, 2000))
	_deslocamento_camera = Vector2(100, 0)
	var amostra := provedor.amostrar(1, Acoes.CONTEXTO_JOGO, false)
	assert_vector(amostra.ponto_mira).is_equal(Vector2(1060, 540))


func test_fonte_mouse_intensidade_zero() -> void:
	var partes := _montar(false)
	var adaptador: AdaptadorDeEntradaGodot = partes[0]
	adaptador.registrar_cursor(Vector2(100, 100))
	var amostra := (partes[1] as ProvedorDeEntrada).amostrar(0, Acoes.CONTEXTO_JOGO, false)
	assert_str(String(amostra.fonte_mira)).is_equal(String(AmostraDeEntrada.FONTE_MOUSE))
	assert_float(amostra.intensidade_mira).is_equal(0.0)


func test_fonte_analogico_intensidade_apos_f2() -> void:
	var partes := _montar(true)
	var adaptador: AdaptadorDeEntradaGodot = partes[0]
	adaptador.registrar_eixo(0, JOY_AXIS_RIGHT_X, 0.3)
	adaptador.registrar_eixo(0, JOY_AXIS_RIGHT_Y, 0.4)
	var amostra := (partes[1] as ProvedorDeEntrada).amostrar(0, Acoes.CONTEXTO_JOGO, false)
	assert_str(String(amostra.fonte_mira)).is_equal(String(AmostraDeEntrada.FONTE_ANALOGICO))
	assert_float(amostra.intensidade_mira).is_equal_approx(0.4, TOL)


func test_fonte_automatica_com_inimigo_e_sem_nada_intensidade_zero() -> void:
	var partes := _montar(true)
	var adaptador: AdaptadorDeEntradaGodot = partes[0]
	var provedor: ProvedorDeEntrada = partes[1]
	adaptador.registrar_eixo(0, JOY_AXIS_RIGHT_X, 0.1)  # dentro da zona morta
	_alvos = [_alvo(Vector2(300, 0))]
	var amostra := provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	assert_str(String(amostra.fonte_mira)).is_equal(String(AmostraDeEntrada.FONTE_AUTOMATICA))
	assert_float(amostra.intensidade_mira).is_equal(0.0)
	_alvos = []
	amostra = provedor.amostrar(1, Acoes.CONTEXTO_JOGO, false)
	assert_str(String(amostra.fonte_mira)).is_equal(String(AmostraDeEntrada.FONTE_AUTOMATICA))
	assert_float(amostra.intensidade_mira).is_equal(0.0)


func test_consulta_de_cursor_conserva_posicao_quando_sai_da_janela() -> void:
	var adaptador: AdaptadorDeEntradaGodot = auto_free(AdaptadorDeEntradaGodot.new())
	adaptador.tamanho_janela = func() -> Vector2: return JANELA
	adaptador.registrar_cursor(Vector2(960, 540))
	assert_vector(adaptador.consultar_cursor()).is_equal(Vector2(960, 540))
	adaptador.registrar_cursor(Vector2(2500, 540))
	assert_vector(adaptador.consultar_cursor()).is_equal(Vector2(960, 540))


func test_ponto_mira_mouse_e_cursor_em_mundo() -> void:
	var partes := _montar(false)
	(partes[0] as AdaptadorDeEntradaGodot).registrar_cursor(Vector2(1000, 500))
	var amostra := (partes[1] as ProvedorDeEntrada).amostrar(0, Acoes.CONTEXTO_JOGO, false)
	assert_bool(amostra.tem_ponto_mira).is_true()
	assert_vector(amostra.ponto_mira).is_equal(Vector2(1000, 500))


func test_ponto_mira_automatica_e_posicao_do_inimigo() -> void:
	var partes := _montar(true)
	_jogador = {"pos": Vector2(500, 500), "olhar": Vector2.ZERO}
	_alvos = [_alvo(Vector2(900, 500))]
	var amostra := (partes[1] as ProvedorDeEntrada).amostrar(0, Acoes.CONTEXTO_JOGO, false)
	assert_bool(amostra.tem_ponto_mira).is_true()
	assert_vector(amostra.ponto_mira).is_equal(Vector2(900, 500))


func test_ponto_mira_vazio_com_analogico_direito_ativo() -> void:
	var partes := _montar(true)
	_alvos = [_alvo(Vector2(300, 0))]
	(partes[0] as AdaptadorDeEntradaGodot).registrar_eixo(0, JOY_AXIS_RIGHT_X, 0.8)
	var amostra := (partes[1] as ProvedorDeEntrada).amostrar(0, Acoes.CONTEXTO_JOGO, false)
	assert_bool(amostra.tem_ponto_mira).is_false()
