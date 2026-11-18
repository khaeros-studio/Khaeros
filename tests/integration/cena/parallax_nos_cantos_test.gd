extends GdUnitTestSuite
## AC-33 (GDD Cena R4/F7): câmara 2880×1620, câmera levada aos quatro cantos com
## chute de 40 px para fora → o primeiro plano nunca se afasta do mundo além da
## deriva da F7; camadas com p = 1,0 têm deslocamento 0. Usa a câmera real, o
## compositor real e um SubViewport (o canvas escrito é o dele).

const Fabrica := preload("res://tests/unit/cena/doubles/fabrica_cena.gd")
const TuningFalso := preload("res://tests/unit/cena/doubles/camera_tuning_falso.gd")

const JOGAVEL := Rect2(0, 0, 2880, 1620)
const P_PRIMEIRO_PLANO := 1.2
const TOL := 1e-3


func test_quatro_cantos_com_chute_para_fora_primeiro_plano_dentro_da_deriva() -> void:
	var teto: float = TuningFalso.new().teto_deslocamento
	var deriva := ParallaxManual.deriva(P_PRIMEIRO_PLANO, JOGAVEL.size, teto)
	var vp: SubViewport = auto_free(SubViewport.new())
	vp.size = Vector2i(1920, 1080)
	add_child(vp)
	var camadas: CamadasDoMundo = auto_free(CamadasDoMundo.new())
	vp.add_child(camadas)
	camadas.definir_parallax(CamadasDoMundo.Camada.PRIMEIRO_PLANO, P_PRIMEIRO_PLANO)
	var comp: CompositorDeCena = auto_free(CompositorDeCena.new())
	add_child(comp)
	var cantos: Array[Vector2] = [JOGAVEL.position, Vector2(JOGAVEL.end.x, 0), Vector2(0, JOGAVEL.end.y), JOGAVEL.end]
	var maior := Vector2.ZERO
	for canto in cantos:
		var cam := Fabrica.camera_em(JOGAVEL, canto)
		comp.configurar(cam, camadas, vp)
		comp.definir_camara(JOGAVEL)
		var fora := (canto - JOGAVEL.get_center()).normalized()
		cam.receber_impulso(PedidoImpulso.new(&"chefe", 1.0, fora, 1, 0.0))
		var t := 0.0
		for _q in 60:
			var v := comp.compor(Fabrica.parado(canto, t))
			var d := camadas.deslocamento_de(CamadasDoMundo.Camada.PRIMEIRO_PLANO)
			maior = Vector2(maxf(maior.x, absf(d.x)), maxf(maior.y, absf(d.y)))
			assert_float(absf(d.x)).is_less_equal(deriva.x + TOL)
			assert_float(absf(d.y)).is_less_equal(deriva.y + TOL)
			for i in CamadasDoMundo.CAMADAS_DE_MUNDO - 1:
				assert_vector(camadas.deslocamento_de(i)).is_equal(Vector2.ZERO)
			assert_object(vp.canvas_transform).is_equal(v.transformacao)
			t += 1.0 / 60.0
	# O canto encosta na excursão máxima da F4 (480, 270) com o chute somado.
	assert_float(maior.x).is_greater(0.2 * 480.0 - TOL)
	assert_float(maior.y).is_greater(0.2 * 270.0 - TOL)


func test_compor_escreve_canvas_transform_da_formula_do_adr() -> void:
	var vp: SubViewport = auto_free(SubViewport.new())
	add_child(vp)
	var camadas: CamadasDoMundo = auto_free(CamadasDoMundo.new())
	vp.add_child(camadas)
	var comp: CompositorDeCena = auto_free(CompositorDeCena.new())
	add_child(comp)
	var cam := Fabrica.camera_em(JOGAVEL, Vector2(1000, 900))
	comp.configurar(cam, camadas, vp)
	comp.definir_camara(JOGAVEL)
	var v := comp.compor(Fabrica.parado(Vector2(1000, 900), 0.1))
	# Ponto de mundo no centro visual vai ao centro da vista lógica (W/2, 540).
	var centro := v.pos + v.deslocamento
	assert_vector(vp.canvas_transform * centro).is_equal_approx(Vector2(v.largura / 2.0, 540.0), Vector2(TOL, TOL))
	assert_int(comp.physics_interpolation_mode).is_equal(Node.PHYSICS_INTERPOLATION_MODE_OFF)
