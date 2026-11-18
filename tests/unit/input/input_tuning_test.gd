## Story input-006: InputTuning injetado e modo sem catálogo (AC-04, AC-29 gatilho, AC-38).
extends GdUnitTestSuite

# Fixture (dados de teste, não tuning do jogo).
const ZM := 0.2
const ZE := 0.05
const ZM_NOVA := 0.5
const LIMIAR_MOUSE := 4.0
const BUFFER_CURTO := 5
const RAIO_CURTO := 500.0
const APERTA := 0.5
const SOLTA := 0.4


func _tuning(zm: float = ZM) -> InputTuning:
	var t := InputTuning.new()
	t.buffer_passos = BUFFER_CURTO
	t.zona_morta_interna = zm
	t.zona_morta_externa = ZE
	t.raio_mira_px = RAIO_CURTO
	t.limiar_mouse_px = LIMIAR_MOUSE
	t.gatilho_aperta = APERTA
	t.gatilho_solta = SOLTA
	return t


func _montar(adaptador: AdaptadorDeEntradaGodot) -> ProvedorDeEntrada:
	var provedor := ProvedorDeEntrada.new(adaptador.drenar)
	provedor.vincular_limiares(adaptador.configurar_limiares, adaptador.retirar_limiares)
	return provedor


func _gatilho(adaptador: AdaptadorDeEntradaGodot, valor: float) -> bool:
	adaptador.registrar_eixo(0, JOY_AXIS_TRIGGER_RIGHT, valor)
	for d: DescritorDeEntrada in adaptador.drenar().segurados:
		if d.tipo == DescritorDeEntrada.GATILHO:
			return true
	return false


func test_buffer_curto_toque_vale_cinco_passos() -> void:
	var adaptador: AdaptadorDeEntradaGodot = auto_free(AdaptadorDeEntradaGodot.new())
	var provedor := _montar(adaptador)
	provedor.configurar_tuning(_tuning())
	provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	var j := DescritorDeEntrada.new(DescritorDeEntrada.TECLA_FISICA, KEY_J)
	adaptador.registrar_botao(j, true)
	adaptador.registrar_botao(j, false)
	var vale: Array = []
	for passo: int in range(1, BUFFER_CURTO + 2):
		provedor.amostrar(passo, Acoes.CONTEXTO_JOGO, false)
		vale.append(provedor.comandos_do_passo(passo).quer(Acoes.ATAQUE))
	assert_array(vale).is_equal([true, true, true, true, true, false])


func test_raio_curto_inimigo_a_600_ignorado() -> void:
	var adaptador: AdaptadorDeEntradaGodot = auto_free(AdaptadorDeEntradaGodot.new())
	var provedor := _montar(adaptador)
	provedor.configurar_tuning(_tuning())
	provedor.configurar_mira(func(p: Vector2) -> Vector2: return p,
			func() -> Array: return [{"pos": Vector2(600, 0), "surgindo": false}],
			func() -> Dictionary: return {"pos": Vector2.ZERO, "olhar": Vector2(0, -1)})
	adaptador.registrar_botao(DescritorDeEntrada.new(DescritorDeEntrada.BOTAO_GAMEPAD, JOY_BUTTON_A, 0, 0), true)
	var amostra := provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	assert_str(amostra.dispositivo_ativo).is_equal(Acoes.DISPOSITIVO_GAMEPAD)
	assert_bool(amostra.tem_ponto_mira and amostra.ponto_mira == Vector2(600, 0)).is_false()


func test_gatilho_histerese_aperta_em_050_solta_abaixo_de_040() -> void:
	var adaptador: AdaptadorDeEntradaGodot = auto_free(AdaptadorDeEntradaGodot.new())
	var provedor := _montar(adaptador)
	provedor.configurar_tuning(_tuning())
	assert_bool(_gatilho(adaptador, 0.49)).is_false()
	assert_bool(_gatilho(adaptador, 0.50)).is_true()
	assert_bool(_gatilho(adaptador, 0.45)).is_true()
	assert_bool(_gatilho(adaptador, 0.39)).is_false()


func test_sem_tuning_digital_funciona_analogico_gatilho_e_mouse_inativos() -> void:
	var adaptador: AdaptadorDeEntradaGodot = auto_free(AdaptadorDeEntradaGodot.new())
	var provedor := _montar(adaptador)
	provedor.amostrar(0, Acoes.CONTEXTO_MENU, false)
	adaptador.registrar_botao(DescritorDeEntrada.new(DescritorDeEntrada.BOTAO_GAMEPAD, JOY_BUTTON_DPAD_DOWN, 0, 0), true)
	adaptador.registrar_botao(DescritorDeEntrada.new(DescritorDeEntrada.BOTAO_GAMEPAD, JOY_BUTTON_A, 0, 0), true)
	var a1 := provedor.amostrar(1, Acoes.CONTEXTO_MENU, false)
	assert_bool(a1.apertados().has(Acoes.UI_NAVEGAR) and a1.apertados().has(Acoes.UI_ACEITAR)).is_true()
	adaptador.soltar_tudo()
	adaptador.registrar_eixo(0, JOY_AXIS_LEFT_X, 1.0)
	adaptador.registrar_eixo(0, JOY_AXIS_TRIGGER_RIGHT, 1.0)
	var a2 := provedor.amostrar(2, Acoes.CONTEXTO_JOGO, false)
	assert_array(a2.apertados()).is_empty()
	assert_array(a2.segurados()).is_empty()
	assert_bool(a2.mover == Vector2.ZERO).is_true()
	assert_bool(a2.tem_ponto_mira).is_false()
	var antes := provedor.dispositivo_ativo()
	adaptador.registrar_movimento_mouse(1000.0)
	provedor.amostrar(3, Acoes.CONTEXTO_JOGO, false)
	assert_str(provedor.dispositivo_ativo()).is_equal(antes)


func test_tuning_injetado_depois_analogico_volta_com_zona_morta_nova() -> void:
	var adaptador: AdaptadorDeEntradaGodot = auto_free(AdaptadorDeEntradaGodot.new())
	var provedor := _montar(adaptador)
	provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	provedor.configurar_tuning(_tuning(ZM_NOVA))
	adaptador.registrar_eixo(0, JOY_AXIS_LEFT_X, 0.4)
	assert_bool(provedor.amostrar(1, Acoes.CONTEXTO_JOGO, false).mover == Vector2.ZERO).is_true()
	adaptador.registrar_eixo(0, JOY_AXIS_LEFT_X, 1.0)
	assert_float(provedor.amostrar(2, Acoes.CONTEXTO_JOGO, false).mover.x).is_greater(0.0)


func test_retirar_tuning_limpa_residuo_e_aplica_barreira() -> void:
	var adaptador: AdaptadorDeEntradaGodot = auto_free(AdaptadorDeEntradaGodot.new())
	var provedor := _montar(adaptador)
	provedor.configurar_tuning(_tuning())
	provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	adaptador.registrar_eixo(0, JOY_AXIS_LEFT_X, 1.0)
	adaptador.registrar_botao(DescritorDeEntrada.new(DescritorDeEntrada.TECLA_FISICA, KEY_J), true)
	provedor.amostrar(1, Acoes.CONTEXTO_JOGO, false)
	var epoca := provedor.epoca()
	provedor.configurar_tuning(null)
	var a := provedor.amostrar(2, Acoes.CONTEXTO_JOGO, false)
	assert_int(provedor.epoca()).is_greater(epoca)
	assert_bool(a.mover == Vector2.ZERO).is_true()
	assert_bool(a.segurados().has(Acoes.ATAQUE)).is_false()
	assert_object(provedor.tuning()).is_null()
