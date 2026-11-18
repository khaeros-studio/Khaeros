## Story cena-e-camera 001 — GeometriaDeViewport (AC-02, AC-36, janela zero).
extends GdUnitTestSuite

const EPS := 1e-4


func _geo(w: int, h: int) -> GeometriaDeViewport:
	return GeometriaDeViewport.calcular(Vector2i(w, h))


func test_geometria_1280x720_w1920_f_dois_tercos_origem_zero() -> void:
	var g := _geo(1280, 720)
	assert_float(g.largura_logica).is_equal_approx(1920.0, EPS)
	assert_float(g.fator).is_equal_approx(2.0 / 3.0, EPS)
	assert_vector(g.origem).is_equal_approx(Vector2.ZERO, Vector2(EPS, EPS))
	assert_int(g.aspecto).is_equal(GeometriaDeViewport.Aspecto.KEEP_HEIGHT)


func test_geometria_faixa_do_meio_w_igual_largura_f1() -> void:
	for w: int in [2520, 2560]:
		var g := _geo(w, 1080)
		assert_float(g.largura_logica).is_equal_approx(float(w), EPS)
		assert_float(g.fator).is_equal_approx(1.0, EPS)
		assert_vector(g.origem).is_equal_approx(Vector2.ZERO, Vector2(EPS, EPS))


func test_geometria_3440x1440_exato_43_18_w2580_f_quatro_tercos() -> void:
	var g := _geo(3440, 1440)
	assert_float(g.largura_logica).is_equal_approx(2580.0, EPS)
	assert_float(g.fator).is_equal_approx(4.0 / 3.0, EPS)
	assert_int(g.aspecto).is_equal(GeometriaDeViewport.Aspecto.KEEP_HEIGHT)


func test_geometria_3840x1080_ultrawide_faixas_laterais_x630() -> void:
	var g := _geo(3840, 1080)
	assert_float(g.largura_logica).is_equal_approx(2580.0, EPS)
	assert_float(g.fator).is_equal_approx(1.0, EPS)
	assert_vector(g.origem).is_equal_approx(Vector2(630, 0), Vector2(EPS, EPS))
	assert_object(g.retangulo_util).is_equal(Rect2(630, 0, 2580, 1080))


func test_geometria_estreita_letterbox_y_correto() -> void:
	var g1 := _geo(1920, 1200)
	assert_float(g1.largura_logica).is_equal_approx(1920.0, EPS)
	assert_float(g1.fator).is_equal_approx(1.0, EPS)
	assert_float(g1.origem.y).is_equal_approx(60.0, EPS)
	var g2 := _geo(1440, 1080)
	assert_float(g2.largura_logica).is_equal_approx(1920.0, EPS)
	assert_float(g2.fator).is_equal_approx(0.75, EPS)
	assert_float(g2.origem.y).is_equal_approx(135.0, EPS)
	assert_int(g2.aspecto).is_equal(GeometriaDeViewport.Aspecto.KEEP)


func test_geometria_640x360_f_um_terco() -> void:
	var g := _geo(640, 360)
	assert_float(g.largura_logica).is_equal_approx(1920.0, EPS)
	assert_float(g.fator).is_equal_approx(1.0 / 3.0, EPS)


func test_size_changed_3840_vira_keep_2580_e_volta_keep_height_1920() -> void:
	var ultra := _geo(3840, 1080)
	assert_int(ultra.aspecto).is_equal(GeometriaDeViewport.Aspecto.KEEP)
	assert_object(ultra.tamanho_base).is_equal(Vector2i(2580, 1080))
	var volta := GeometriaDeViewport.atualizar(Vector2i(2560, 1080), ultra)
	assert_int(volta.aspecto).is_equal(GeometriaDeViewport.Aspecto.KEEP_HEIGHT)
	assert_object(volta.tamanho_base).is_equal(Vector2i(1920, 1080))


func test_janela_zero_mantem_ultimo_instantaneo_valido() -> void:
	var anterior := _geo(1920, 1080)
	assert_object(GeometriaDeViewport.calcular(Vector2i(0, 0))).is_null()
	assert_object(GeometriaDeViewport.atualizar(Vector2i(0, 0), anterior)).is_same(anterior)
	assert_object(GeometriaDeViewport.atualizar(Vector2i(1920, 1080), anterior)).is_same(anterior)


func test_aplicar_na_janela_idempotente_segunda_chamada_nao_muda() -> void:
	var janela: Window = auto_free(Window.new())
	var g := _geo(3840, 1080)
	assert_bool(g.aplicar_na_janela(janela)).is_true()
	assert_int(janela.content_scale_aspect).is_equal(Window.CONTENT_SCALE_ASPECT_KEEP)
	assert_object(janela.content_scale_size).is_equal(Vector2i(2580, 1080))
	assert_int(janela.content_scale_stretch).is_equal(Window.CONTENT_SCALE_STRETCH_FRACTIONAL)
	assert_bool(g.aplicar_na_janela(janela)).is_false()
