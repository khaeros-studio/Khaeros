## Story cena-e-camera 002 — F4, validação de tamanho e retângulo envolvente.
extends GdUnitTestSuite

const EPS := Vector2(1e-4, 1e-4)
const B := 370.0  # sangria de teste (b ≥ 370, GDD F4)
const CAMARA_1_TELA := Rect2(0, 0, 1920, 1080)
const MIN := Vector2(1920, 1080)
const MAX := Vector2(2880, 1620)


func test_f4_16_9_camara_uma_tela_fica_parada_no_centro() -> void:
	assert_vector(LimitesDaCamera.prender(Vector2(5000, -300), CAMARA_1_TELA, 1920.0, B)).is_equal_approx(Vector2(960, 540), EPS)


func test_f4_2520x1080_sangria_300_vista_de_menos_300_a_2220() -> void:
	var w := GeometriaDeViewport.calcular(Vector2i(2520, 1080)).largura_logica
	assert_float(LimitesDaCamera.sangria_visivel(w, B)).is_equal_approx(300.0, 1e-4)
	var c := LimitesDaCamera.prender(Vector2(0, 0), CAMARA_1_TELA, w, B)
	assert_float(c.x - w / 2.0).is_equal_approx(-300.0, 1e-4)
	assert_float(c.x + w / 2.0).is_equal_approx(2220.0, 1e-4)


func test_f4_3440x1440_sangria_330() -> void:
	var w := GeometriaDeViewport.calcular(Vector2i(3440, 1440)).largura_logica
	assert_float(LimitesDaCamera.sangria_visivel(w, B)).is_equal_approx(330.0, 1e-4)


func test_f4_camara_2880_alvo_fora_preso_aos_extremos() -> void:
	var camara := Rect2(0, 0, 2880, 1080)
	assert_float(LimitesDaCamera.prender(Vector2(100, 540), camara, 1920.0, B).x).is_equal_approx(960.0, 1e-4)
	assert_float(LimitesDaCamera.prender(Vector2(5000, 540), camara, 1920.0, B).x).is_equal_approx(1920.0, 1e-4)


func test_f4_camara_1620_de_altura_alvo_preso_vertical() -> void:
	var camara := Rect2(0, 0, 1920, 1620)
	assert_float(LimitesDaCamera.prender(Vector2(960, 0), camara, 1920.0, B).y).is_equal_approx(540.0, 1e-4)
	assert_float(LimitesDaCamera.prender(Vector2(960, 2000), camara, 1920.0, B).y).is_equal_approx(1080.0, 1e-4)


func test_validacao_cruzada_rejeita_fora_e_nomeia_camara() -> void:
	var erro1 := LimitesDaCamera.validar_tamanho_camara(&"limiar_03", Vector2(1919, 1080), MIN, MAX)
	var erro2 := LimitesDaCamera.validar_tamanho_camara(&"limiar_04", Vector2(2881, 1620), MIN, MAX)
	assert_str(erro1).contains("limiar_03")
	assert_str(erro2).contains("limiar_04")


func test_validacao_cruzada_aceita_limites_exatos() -> void:
	assert_str(LimitesDaCamera.validar_tamanho_camara(&"a", MIN, MIN, MAX)).is_empty()
	assert_str(LimitesDaCamera.validar_tamanho_camara(&"b", MAX, MIN, MAX)).is_empty()


func test_jogavel_poligonal_produz_retangulo_envolvente() -> void:
	var poligono := PackedVector2Array([Vector2(100, 200), Vector2(2500, 150), Vector2(2700, 1300), Vector2(300, 1400)])
	assert_object(LimitesDaCamera.retangulo_envolvente(poligono)).is_equal(Rect2(100, 150, 2600, 1250))
	assert_object(LimitesDaCamera.retangulo_envolvente(PackedVector2Array())).is_equal(Rect2())
