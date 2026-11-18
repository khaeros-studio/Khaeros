## Story cena-e-camera 004 — F6 tela → mundo, snapshot sem impulsos (AC-05/06/37).
extends GdUnitTestSuite

const Fabrica := preload("res://tests/unit/cena/doubles/fabrica_cena.gd")
const CameraFalsa := preload("res://tests/unit/cena/doubles/camera_falsa.gd")
const EPS := Vector2(1e-3, 1e-3)
const C := Vector2(1500, 800)


func _f6(janela: Vector2i, cursor: Vector2) -> Vector2:
	return ConversorTelaMundo.converter(cursor, GeometriaDeViewport.calcular(janela), C)


func test_f6_1280x720_mouse_960_180_da_1980_530() -> void:
	assert_vector(_f6(Vector2i(1280, 720), Vector2(960, 180))).is_equal_approx(Vector2(1980, 530), EPS)


func test_f6_3840x1080_centro_da_c_e_faixa_lateral_presa_na_borda() -> void:
	assert_vector(_f6(Vector2i(3840, 1080), Vector2(1920, 540))).is_equal_approx(C, EPS)
	assert_float(_f6(Vector2i(3840, 1080), Vector2(100, 540)).x).is_equal_approx(C.x - 1290.0, 1e-3)


func test_f6_1440x1080_centro_da_c_e_faixa_superior_presa_na_borda() -> void:
	assert_vector(_f6(Vector2i(1440, 1080), Vector2(720, 540))).is_equal_approx(C, EPS)
	assert_float(_f6(Vector2i(1440, 1080), Vector2(720, 50)).y).is_equal_approx(C.y - 540.0, 1e-3)


func test_chute_tremor_e_zoom_nao_alteram_tela_para_mundo() -> void:
	var camara := Rect2(0, 0, 2880, 1620)
	var com_impulso := Fabrica.camera_em(camara, Vector2(1440, 810))
	var sem_impulso := Fabrica.camera_em(camara, Vector2(1440, 810))
	com_impulso.injetar_ruido(func(_i: int) -> Vector2: return Vector2(1, -1))
	com_impulso.receber_impulso(PedidoImpulso.new(&"chefe", 1.0, Vector2.RIGHT, 1, 0.0))
	com_impulso.receber_impulso(PedidoImpulso.new(&"chefe", 1.0, Vector2.RIGHT, 1, 0.0))
	var e := Fabrica.parado(Vector2(1440, 810), 0.0)
	var v := com_impulso.atualizar_quadro(e)
	sem_impulso.atualizar_quadro(e)
	assert_float(v.deslocamento.length()).is_equal_approx(40.0, 1e-3)
	assert_float(v.zoom).is_equal_approx(1.15, 1e-6)
	for cursor: Vector2 in [Vector2(0, 0), Vector2(960, 540), Vector2(1919, 1079)]:
		assert_vector(com_impulso.tela_para_mundo(cursor)).is_equal(sem_impulso.tela_para_mundo(cursor))


func test_input_recebe_mira_bruta_a_partir_de_p_atual_927_540() -> void:
	var falsa := CameraFalsa.new(Vector2(960, 540), GeometriaDeViewport.calcular(Vector2i(1920, 1080)))
	var p_atual := Vector2(33, 0)
	var p_render := CameraDeApresentacao.interpolar(Vector2.ZERO, p_atual, 0.5)
	var mira := falsa.tela_para_mundo(Vector2(960, 540)) - p_atual
	assert_vector(mira).is_equal_approx(Vector2(927, 540), EPS)
	assert_bool(mira.is_equal_approx(Vector2(960, 540) - p_render)).is_false()


func test_tela_para_mundo_usa_snapshot_do_ultimo_render_sem_recalcular() -> void:
	var cam := Fabrica.camera_em(Rect2(0, 0, 2880, 1620), Vector2(1440, 810))
	var antes := cam.tela_para_mundo(Vector2(960, 540))
	assert_vector(cam.tela_para_mundo(Vector2(960, 540))).is_equal(antes)
	assert_vector(antes).is_equal_approx(cam.pos, EPS)
