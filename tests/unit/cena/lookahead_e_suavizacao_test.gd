## Story cena-e-camera 003 — F2 (lookahead), F3 (suavização) e interpolação (AC-19/20/21/34).
extends GdUnitTestSuite

const Fabrica := preload("res://tests/unit/cena/doubles/fabrica_cena.gd")
const EPS := Vector2(1e-3, 1e-3)
const L := 120.0
const R := 480.0
const H := 0.12
const P := Vector2(1000, 600)


func _alvo_mouse(m: Vector2) -> Vector2:
	return CameraDeApresentacao.alvo_f2(P, m, L, CameraDeApresentacao.intensidade_mouse(m, R))


func test_f2_mouse_longe_lookahead_cheio_1072_696() -> void:
	assert_vector(_alvo_mouse(Vector2(300, 400))).is_equal_approx(Vector2(1072, 696), EPS)


func test_f2_mouse_perto_lookahead_escalado_1015_620() -> void:
	assert_vector(_alvo_mouse(Vector2(60, 80))).is_equal_approx(Vector2(1015, 620), EPS)


func test_f2_mira_nula_alvo_igual_p() -> void:
	assert_vector(_alvo_mouse(Vector2.ZERO)).is_equal(P)


func test_f2_360_direcoes_limitado_a_l_e_nao_decresce_com_distancia() -> void:
	var violacoes := 0
	for grau in 360:
		var dir := Vector2.RIGHT.rotated(deg_to_rad(float(grau)))
		var anterior := 0.0
		for d in range(0, 2001, 25):
			var modulo := (_alvo_mouse(dir * float(d)) - P).length()
			if modulo > L + 1e-3 or modulo + 1e-3 < anterior:
				violacoes += 1
			anterior = modulo
	assert_int(violacoes).is_equal(0)


func test_f2_analogico_intensidade_04_da_48_e_05_da_60() -> void:
	assert_float((CameraDeApresentacao.alvo_f2(P, Vector2(0, 1), L, 0.4) - P).length()).is_equal_approx(48.0, 1e-4)
	assert_float((CameraDeApresentacao.alvo_f2(P, Vector2(1, 0), L, 0.5) - P).length()).is_equal_approx(60.0, 1e-4)


func test_camera_reducao_de_movimento_e_mira_automatica_lookahead_zero() -> void:
	var cam := Fabrica.camera_em(Rect2(0, 0, 2880, 1620), Vector2(1440, 810))
	var e := Fabrica.com_mouse(Vector2(1440, 810), 0.1, Vector2(1900, 100))
	e.reducao_movimento = true
	assert_vector(cam.atualizar_quadro(e).lookahead).is_equal(Vector2.ZERO)
	var auto := Fabrica.parado(Vector2(1440, 810), 0.2)
	assert_vector(cam.atualizar_quadro(auto).lookahead).is_equal(Vector2.ZERO)


func test_duas_cameras_mesma_pos_seguir_lookahead_diferente_mesma_direcao() -> void:
	var a := Fabrica.camera_em(Rect2(0, 0, 2880, 1620), Vector2(1440, 810))
	var b := Fabrica.camera_em(Rect2(0, 0, 2880, 1620), Vector2(1440, 810))
	var curto := Fabrica.tuning()
	curto.lookahead_max = 60.0
	b.configurar_tuning(curto)
	var e := Fabrica.com_mouse(Vector2(1440, 810), 0.05, Vector2(1500, 300))
	var va := a.atualizar_quadro(e)
	var vb := b.atualizar_quadro(e)
	assert_vector(va.pos_seguir).is_equal_approx(vb.pos_seguir, EPS)
	assert_vector(va.lookahead.normalized()).is_equal_approx(vb.lookahead.normalized(), Vector2(1e-6, 1e-6))
	assert_bool(va.lookahead.length() > vb.lookahead.length()).is_true()


func test_f3_meia_vida_012_valores_do_gdd() -> void:
	var casos := {0.10: 43.88, 0.12: 50.0, 0.24: 75.0, 1.0: 99.69}
	for dt: float in casos:
		var x := CameraDeApresentacao.suavizar_f3(Vector2.ZERO, Vector2(100, 0), dt, H).x
		assert_float(x).is_equal_approx(casos[dt], 0.01)


func test_f3_duas_fatias_de_005_iguais_a_uma_de_010() -> void:
	var meio := CameraDeApresentacao.suavizar_f3(Vector2.ZERO, Vector2(100, 0), 0.05, H)
	var duas := CameraDeApresentacao.suavizar_f3(meio, Vector2(100, 0), 0.05, H)
	var uma := CameraDeApresentacao.suavizar_f3(Vector2.ZERO, Vector2(100, 0), 0.10, H)
	assert_float(duas.x).is_equal_approx(uma.x, 1e-6)


func test_f3_dt_de_0001_a_5_nunca_passa_do_alvo() -> void:
	var passou := 0
	var dt := 0.001
	while dt <= 5.0:
		if CameraDeApresentacao.suavizar_f3(Vector2.ZERO, Vector2(100, 0), dt, H).x > 100.0:
			passou += 1
		dt *= 1.1
	assert_int(passou).is_equal(0)


func test_interpolacao_fracao_025_da_2_5_e_teleporte_da_p_atual() -> void:
	assert_vector(CameraDeApresentacao.interpolar(Vector2.ZERO, Vector2(10, 0), 0.25)).is_equal_approx(Vector2(2.5, 0), EPS)
	assert_vector(CameraDeApresentacao.interpolar(Vector2(7, 7), Vector2(7, 7), 0.6)).is_equal(Vector2(7, 7))
