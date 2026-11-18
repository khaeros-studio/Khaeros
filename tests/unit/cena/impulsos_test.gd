## Story cena-e-camera 005 — F5 impulsos com ruído fixo injetado (AC-23..27, pedidos inválidos).
extends GdUnitTestSuite

const EPS := Vector2(1e-4, 1e-4)


func _impulsos(ruido: Vector2 = Vector2.ZERO) -> ImpulsosDeCamera:
	var presets: Dictionary[StringName, ImpulsosDeCamera.Preset] = {
		&"leve": ImpulsosDeCamera.Preset.new(0.05, 10.0, 3.0, 0.02),
		&"pesado": ImpulsosDeCamera.Preset.new(0.10, 20.0, 8.0, 0.04),
		&"chefe": ImpulsosDeCamera.Preset.new(0.30, 32.0, 14.0, 0.10),
	}
	var imp := ImpulsosDeCamera.new()
	imp.configurar(presets, 40.0, 1.15, 0.05, 16)
	imp.injetar_ruido(func(_i: int) -> Vector2: return ruido)
	return imp


func _pedido(preset: StringName, dir: Vector2 = Vector2.RIGHT, escala: float = 1.0, t: float = 0.0, epoca: int = 0) -> PedidoImpulso:
	return PedidoImpulso.new(preset, escala, dir, epoca, t)


func test_pesado_t01_tremor_05_ruido_fixo_da_6_menos_2() -> void:
	var imp := _impulsos(Vector2(0.5, -1.0))
	imp.receber(_pedido(&"pesado"), 0, 0.0)
	imp.avaliar(0.1, 0.5, false)
	assert_vector(imp.deslocamento).is_equal_approx(Vector2(6, -2), EPS)
	assert_float(imp.deslocamento.length()).is_equal_approx(6.3246, 1e-3)


func test_dois_de_chefe_t0_limitado_a_40_na_direcao_e_zoom_115() -> void:
	var imp := _impulsos()
	imp.receber(_pedido(&"chefe"), 0, 0.0)
	imp.receber(_pedido(&"chefe"), 0, 0.0)
	imp.avaliar(0.0, 1.0, false)
	assert_vector(imp.deslocamento).is_equal_approx(Vector2(40, 0), EPS)
	assert_float(imp.zoom).is_equal_approx(1.15, 1e-6)


func test_chefe_t06_zoom_1025_reducao_1_e_tremor_zero_preserva_zoom() -> void:
	var imp := _impulsos(Vector2(1, 1))
	imp.receber(_pedido(&"chefe"), 0, 0.0)
	imp.avaliar(0.6, 1.0, false)
	assert_float(imp.zoom).is_equal_approx(1.025, 1e-6)
	imp.avaliar(0.6, 1.0, true)
	assert_float(imp.zoom).is_equal_approx(1.0, 1e-9)
	imp.avaliar(0.6, 0.0, false)
	assert_vector(imp.deslocamento).is_equal(Vector2.ZERO)
	assert_float(imp.zoom).is_equal_approx(1.025, 1e-6)


func test_leve_ativo_em_021_e_descartado_em_022() -> void:
	var imp := _impulsos()
	imp.receber(_pedido(&"leve"), 0, 0.0)
	imp.avaliar(0.21, 1.0, false)
	assert_int(imp.quantidade()).is_equal(1)
	assert_float(imp.decaimento(0, 0.21)).is_equal_approx(0.0544, 1e-3)
	imp.avaliar(0.22, 1.0, false)
	assert_int(imp.quantidade()).is_equal(0)


func test_17_impulsos_ficam_16_e_o_primeiro_saiu() -> void:
	var imp := _impulsos()
	imp.receber(_pedido(&"leve", Vector2.DOWN), 0, 0.0)
	for i in 16:
		imp.receber(_pedido(&"leve", Vector2.RIGHT), 0, 0.0)
	assert_int(imp.quantidade()).is_equal(16)
	for i in 16:
		assert_vector(imp.direcao(i)).is_equal(Vector2.RIGHT)


func test_tremor_025_da_um_quarto_do_deslocamento_de_tremor_1() -> void:
	var imp := _impulsos(Vector2(1, 1))
	imp.receber(_pedido(&"leve"), 0, 0.0)
	imp.avaliar(0.0, 1.0, false)
	var cheio := imp.deslocamento
	imp.avaliar(0.0, 0.25, false)
	assert_bool(cheio.length() < 40.0).is_true()
	assert_vector(imp.deslocamento).is_equal_approx(cheio * 0.25, Vector2(1e-9, 1e-9))


func test_pedidos_invalidos_rejeitados_com_diagnostico_sem_mudar_estado() -> void:
	var imp := _impulsos()
	imp.receber(_pedido(&"leve"), 0, 0.5)
	var invalidos: Array[PedidoImpulso] = [
		_pedido(&"leve", Vector2.RIGHT, -1.0),
		_pedido(&"leve", Vector2.RIGHT, NAN),
		_pedido(&"leve", Vector2.RIGHT, INF),
		_pedido(&"leve", Vector2.RIGHT, 1.0, 0.9),
		_pedido(&"leve", Vector2(2, 0)),
		_pedido(&"leve", Vector2.RIGHT, 1.0, 0.0, 7),
		_pedido(&"inexistente"),
	]
	for p in invalidos:
		assert_bool(imp.receber(p, 0, 0.5)).is_false()
		assert_str(imp.ultimo_diagnostico).is_not_empty()
	assert_int(imp.quantidade()).is_equal(1)
	assert_bool(imp.receber(_pedido(&"leve", Vector2.ZERO), 0, 0.5)).is_true()
