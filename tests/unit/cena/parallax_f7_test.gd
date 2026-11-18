extends GdUnitTestSuite
## AC-32 (GDD Cena F7): deriva e deslocamento do parallax manual.

const TuningFalso := preload("res://tests/unit/cena/doubles/camera_tuning_falso.gd")

const P_PRIMEIRO_PLANO := 1.2
const CAMARA_MAXIMA := Vector2(2880, 1620)
const CAMARA_MINIMA := Vector2(1920, 1080)
const TOL := Vector2(1e-3, 1e-3)

var _teto: float


func before_test() -> void:
	_teto = TuningFalso.new().teto_deslocamento


func test_deriva_p_1_2_camara_2880x1620_vale_104_62() -> void:
	assert_vector(ParallaxManual.deriva(P_PRIMEIRO_PLANO, CAMARA_MAXIMA, _teto)).is_equal_approx(Vector2(104, 62), TOL)


func test_deriva_p_1_2_camara_1920x1080_vale_so_o_chute_8_8() -> void:
	assert_vector(ParallaxManual.deriva(P_PRIMEIRO_PLANO, CAMARA_MINIMA, _teto)).is_equal_approx(Vector2(8, 8), TOL)


func test_deriva_p_1_vale_zero() -> void:
	assert_vector(ParallaxManual.deriva(1.0, CAMARA_MAXIMA, _teto)).is_equal(Vector2.ZERO)


func test_deslocamento_camera_480_a_direita_do_centro_vale_menos_96_0() -> void:
	var centro := Rect2(Vector2.ZERO, CAMARA_MAXIMA).get_center()
	var d := ParallaxManual.deslocamento(P_PRIMEIRO_PLANO, centro + Vector2(480, 0), centro)
	assert_vector(d).is_equal_approx(Vector2(-96, 0), TOL)


func test_deslocamento_camera_no_centro_vale_zero() -> void:
	var centro := Rect2(Vector2.ZERO, CAMARA_MAXIMA).get_center()
	assert_vector(ParallaxManual.deslocamento(P_PRIMEIRO_PLANO, centro, centro)).is_equal(Vector2.ZERO)


func test_deslocamento_p_1_vale_zero_em_qualquer_posicao() -> void:
	assert_vector(ParallaxManual.deslocamento(1.0, Vector2(9999, -50), Vector2(1440, 810))).is_equal(Vector2.ZERO)


func test_deslocamento_repetido_nao_acumula() -> void:
	var centro := Vector2(1440, 810)
	var a := ParallaxManual.deslocamento(P_PRIMEIRO_PLANO, centro + Vector2(100, 50), centro)
	var b := ParallaxManual.deslocamento(P_PRIMEIRO_PLANO, centro + Vector2(100, 50), centro)
	assert_vector(a).is_equal(b)
