## Story cena-e-camera 005 — AC-28 (impulso corre no hitstop) e AC-29 (pausa limpa impulsos).
extends GdUnitTestSuite

const Fabrica := preload("res://tests/unit/cena/doubles/fabrica_cena.gd")
const CAMARA := Rect2(0, 0, 1920, 1080)
const P := Vector2(960, 540)


func test_pesado_durante_hitstop_t_apres_avanca_01_decaimento_05_com_jogo_parado() -> void:
	var cam := Fabrica.camera_em(CAMARA, P)
	assert_bool(cam.receber_impulso(PedidoImpulso.new(&"pesado", 1.0, Vector2.RIGHT, 1, 0.0))).is_true()
	# Hitstop: o jogador não anda (P_anterior = P_atual); só t_apres corre.
	var v := cam.atualizar_quadro(Fabrica.parado(P, 0.1))
	assert_vector(v.deslocamento).is_equal_approx(Vector2(10, 0), Vector2(1e-4, 1e-4))  # Ak 20 × d 0,5
	assert_float(v.zoom).is_equal_approx(1.02, 1e-6)
	assert_vector(v.pos).is_equal_approx(P, Vector2(1e-4, 1e-4))


func test_pausa_zera_impulso_e_ao_despausar_ele_nao_volta() -> void:
	var cam := Fabrica.camera_em(CAMARA, P)
	cam.receber_impulso(PedidoImpulso.new(&"chefe", 1.0, Vector2.RIGHT, 1, 0.0))
	cam.atualizar_quadro(Fabrica.parado(P, 0.01))
	assert_bool(cam.mudar_estado(EstadosDaCamera.Estado.PAUSA)).is_true()
	var v := cam.atualizar_quadro(Fabrica.parado(P, 0.01))
	assert_vector(v.deslocamento).is_equal(Vector2.ZERO)
	assert_float(v.zoom).is_equal(1.0)
	assert_bool(cam.receber_impulso(PedidoImpulso.new(&"pesado", 1.0, Vector2.RIGHT, 1, 0.01))).is_false()
	cam.retomar()
	var depois := cam.atualizar_quadro(Fabrica.parado(P, 0.02))
	assert_int(cam.quantidade_impulsos()).is_equal(0)
	assert_vector(depois.deslocamento).is_equal(Vector2.ZERO)
	assert_vector(depois.pos).is_equal_approx(P, Vector2(1e-4, 1e-4))
