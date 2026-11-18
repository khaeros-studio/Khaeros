## Story cena-e-camera 004 — AC-04: resize ultrawide → 16:9 publica W e pos presa no
## mesmo quadro, sem suavização. A parte [M] (alternar tela cheia) exige janela real.
extends GdUnitTestSuite

const Fabrica := preload("res://tests/unit/cena/doubles/fabrica_cena.gd")


func test_ultrawide_encostada_a_esquerda_resize_para_16_9_prende_no_mesmo_quadro() -> void:
	var camara := Rect2(0, 0, 2880, 1080)
	var cam := Fabrica.camera_em(camara, Vector2(0, 540), Vector2i(3440, 1440))
	assert_float(cam.geometria.largura_logica).is_equal_approx(2580.0, 1e-4)
	var nova := GeometriaDeViewport.atualizar(Vector2i(1920, 1080), cam.geometria)
	cam.definir_geometria(nova)
	var esperado := LimitesDaCamera.prender(Vector2(0, 540), camara, 1920.0, 370.0)
	assert_float(cam.geometria.largura_logica).is_equal_approx(1920.0, 1e-4)
	assert_vector(cam.pos).is_equal_approx(esperado, Vector2(1e-4, 1e-4))
	assert_vector(cam.pos_seguir).is_equal_approx(esperado, Vector2(1e-4, 1e-4))
	# A consulta do Input já usa a geometria nova (cursor no centro → pos).
	assert_vector(cam.tela_para_mundo(Vector2(960, 540))).is_equal_approx(esperado, Vector2(1e-4, 1e-4))


func test_resize_em_pausa_tambem_prende_e_janela_zero_nao_muda_nada() -> void:
	var camara := Rect2(0, 0, 2880, 1620)
	var cam := Fabrica.camera_em(camara, Vector2(2880, 1620), Vector2i(2560, 1080))
	cam.mudar_estado(EstadosDaCamera.Estado.PAUSA)
	cam.definir_geometria(GeometriaDeViewport.calcular(Vector2i(1280, 720)))
	assert_vector(cam.pos).is_equal_approx(Vector2(1920, 1080), Vector2(1e-4, 1e-4))
	var antes := cam.geometria
	cam.definir_geometria(GeometriaDeViewport.atualizar(Vector2i(0, 0), cam.geometria))
	assert_object(cam.geometria).is_same(antes)
