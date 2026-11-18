## Story cena-e-camera 006 — estados da câmera (AC-30, AC-30b, AC-39).
extends GdUnitTestSuite

const Fabrica := preload("res://tests/unit/cena/doubles/fabrica_cena.gd")
const E := EstadosDaCamera.Estado
const CAMARA := Rect2(0, 0, 2880, 1620)
const P := Vector2(1440, 810)
const EPS := Vector2(1e-4, 1e-4)


func _pesado(t: float = 0.0, epoca: int = 1) -> PedidoImpulso:
	return PedidoImpulso.new(&"pesado", 1.0, Vector2.RIGHT, epoca, t)


func test_seguindo_troca_corte_no_mesmo_quadro_e_seguindo_no_seguinte() -> void:
	var cam := Fabrica.camera_em(CAMARA, P)
	cam.receber_impulso(_pesado())
	var nova := Rect2(0, 0, 1920, 1080)
	cam.cortar(CorteDeCamera.new(2, nova, 370.0, Vector2(100, 100)))
	var v := cam.atualizar_quadro(Fabrica.parado(Vector2(100, 100), 0.0))
	assert_int(v.estado).is_equal(E.CORTE)
	assert_vector(v.pos).is_equal_approx(Vector2(960, 540), EPS)
	assert_int(cam.quantidade_impulsos()).is_equal(0)
	assert_int(cam.atualizar_quadro(Fabrica.parado(Vector2(100, 100), 0.016)).estado).is_equal(E.SEGUINDO)


func test_pausa_pos_constante_60_quadros_e_retoma_sem_impulso() -> void:
	var cam := Fabrica.camera_em(CAMARA, P)
	cam.receber_impulso(_pesado())
	cam.mudar_estado(E.PAUSA)
	var pos0 := cam.pos
	var mudou := 0
	for q in 60:
		var e := Fabrica.com_mouse(P + Vector2(q * 10, 0), (q + 1) / 60.0, Vector2(1800, 900))
		var v := cam.atualizar_quadro(e)
		if v.pos != pos0 or v.deslocamento != Vector2.ZERO or v.zoom != 1.0:
			mudou += 1
	assert_int(mudou).is_equal(0)
	cam.retomar()
	assert_int(cam.estado).is_equal(E.SEGUINDO)
	assert_int(cam.quantidade_impulsos()).is_equal(0)


func test_intro_de_chefe_zoom_total_limitado_e_combinado() -> void:
	var cam := Fabrica.camera_em(CAMARA, P)
	assert_bool(cam.mudar_estado(E.INTRO_CHEFE)).is_true()
	var e := Fabrica.parado(P, 0.0)
	e.zoom_intro = 1.3
	assert_float(cam.atualizar_quadro(e).zoom).is_equal_approx(1.15, 1e-6)
	e.zoom_intro = 1.10
	cam.receber_impulso(_pesado())
	assert_float(cam.atualizar_quadro(e).zoom).is_equal_approx(1.144, 1e-6)
	e.zoom_intro = 1.15
	assert_float(cam.atualizar_quadro(e).zoom).is_equal_approx(1.15, 1e-6)
	e.reducao_movimento = true
	assert_float(cam.atualizar_quadro(e).zoom).is_equal(1.0)


func test_bencao_morte_transicao_zeram_impulsos_param_e_descartam() -> void:
	var congelados: Array[EstadosDaCamera.Estado] = [E.BENCAO, E.MORTE, E.TRANSICAO]
	for congelado in congelados:
		var cam := Fabrica.camera_em(CAMARA, P)
		cam.receber_impulso(_pesado())
		assert_bool(cam.mudar_estado(congelado)).is_true()
		assert_int(cam.quantidade_impulsos()).is_equal(0)
		var pos0 := cam.pos
		var v := cam.atualizar_quadro(Fabrica.parado(P + Vector2(300, 0), 0.5))
		assert_vector(v.pos).is_equal(pos0)
		assert_vector(v.deslocamento).is_equal(Vector2.ZERO)
		assert_bool(cam.receber_impulso(_pesado(0.5))).is_false()


func test_pausa_sobre_bencao_volta_a_bencao_parada() -> void:
	var cam := Fabrica.camera_em(CAMARA, P)
	cam.mudar_estado(E.BENCAO)
	cam.mudar_estado(E.PAUSA)
	var pos0 := cam.pos
	cam.retomar()
	assert_int(cam.estado).is_equal(E.BENCAO)
	var v := cam.atualizar_quadro(Fabrica.parado(P + Vector2(200, 0), 0.3))
	assert_vector(v.pos).is_equal(pos0)
	assert_int(cam.quantidade_impulsos()).is_equal(0)


func test_seguindo_sai_para_os_seis_estados_do_gdd() -> void:
	var sai: Array = EstadosDaCamera.SAI_PARA[E.SEGUINDO]
	assert_array(sai).contains_exactly_in_any_order([E.CORTE, E.PAUSA, E.BENCAO, E.MORTE, E.TRANSICAO, E.INTRO_CHEFE])
	var maquina := EstadosDaCamera.new()
	maquina.entrar(E.MORTE)
	assert_bool(maquina.entrar(E.SEGUINDO)).is_false()


func test_sem_tuning_60_quadros_parada_e_reinjecao_volta_lookahead_e_corte() -> void:
	var cam := Fabrica.camera_em(CAMARA, P)
	cam.configurar_tuning(null)
	var pos0 := cam.pos
	var mudou := 0
	for q in 60:
		var e := Fabrica.com_mouse(P + Vector2(q, q), (q + 1) / 60.0, Vector2(1900, 100))
		if cam.receber_impulso(_pesado((q + 1) / 60.0)):
			mudou += 1
		var v := cam.atualizar_quadro(e)
		if v.pos != pos0 or v.deslocamento != Vector2.ZERO or v.zoom != 1.0 or cam.quantidade_impulsos() != 0:
			mudou += 1
	assert_int(mudou).is_equal(0)
	cam.configurar_tuning(Fabrica.tuning())
	var depois := cam.atualizar_quadro(Fabrica.com_mouse(P, 61.0 / 60.0, Vector2(1900, 100)))
	assert_bool(depois.lookahead.length() > 0.0).is_true()
	cam.cortar(CorteDeCamera.new(2, Rect2(0, 0, 1920, 1080), 370.0, Vector2(50, 50)))
	assert_vector(cam.pos).is_equal_approx(Vector2(960, 540), EPS)
