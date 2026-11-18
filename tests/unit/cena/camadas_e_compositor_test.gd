extends GdUnitTestSuite
## Story cena-e-camera/008: testes unitários puros de CamadasDoMundo e CompositorDeCena
## (11 camadas, z_index absoluto, registro, âncoras, ordenação por pé, parallax F7,
## cor de fundo da região e composição do quadro sem Camera2D concorrente).

const Fabrica := preload("res://tests/unit/cena/doubles/fabrica_cena.gd")
const TuningFalso := preload("res://tests/unit/cena/doubles/camera_tuning_falso.gd")

const JOGAVEL := Rect2(0, 0, 2880, 1620)
const Z_ESPERADOS: Array[int] = [-30, -25, -20, -10, -6, -5, 0, 5, 10, 50, 100]
const TOL := 1e-3


func _criar_camadas(reg: RegistroDeCriacaoVisual = null) -> CamadasDoMundo:
	var c: CamadasDoMundo = auto_free(CamadasDoMundo.new(reg))
	add_child(c)
	return c


func test_onze_camadas_criadas_com_nomes_z_e_interpolacao_off() -> void:
	# Arrange / Act
	var c := _criar_camadas()
	# Assert
	assert_int(c.physics_interpolation_mode).is_equal(Node.PHYSICS_INTERPOLATION_MODE_OFF)
	for i in CamadasDoMundo.Camada.size():
		var r := c.raiz(i)
		assert_object(r).is_not_null()
		assert_str(String(r.name)).is_equal(CamadasDoMundo.NOMES[i])
		if i < CamadasDoMundo.CAMADAS_DE_MUNDO:
			var n2d := r as Node2D
			assert_object(n2d).is_not_null()
			assert_int(n2d.z_index).is_equal(Z_ESPERADOS[i])
			assert_bool(n2d.z_as_relative).is_false()
			assert_bool(n2d.y_sort_enabled).is_false()
			assert_int(n2d.physics_interpolation_mode).is_equal(Node.PHYSICS_INTERPOLATION_MODE_OFF)
			assert_float(c.parallax_de(i)).is_equal(1.0)
		else:
			var cl := r as CanvasLayer
			assert_object(cl).is_not_null()
			assert_int(cl.layer).is_equal(Z_ESPERADOS[i])
			assert_bool(cl.follow_viewport_enabled).is_false()


func test_registrar_trocar_e_recusar_item_invalido_ou_duplicado() -> void:
	# Arrange
	var c := _criar_camadas()
	var item := Node2D.new()
	# Act / Assert
	assert_bool(c.registrar(null, CamadasDoMundo.Camada.CHAO)).is_false()
	assert_bool(c.registrar(item, CamadasDoMundo.Camada.TELEGRAFO_PREENCHIMENTO)).is_true()
	assert_int(c.camada_de(item)).is_equal(CamadasDoMundo.Camada.TELEGRAFO_PREENCHIMENTO)
	assert_bool(c.registrar(item, CamadasDoMundo.Camada.PRIMEIRO_PLANO)).is_false()
	assert_bool(c.trocar_camada(item, CamadasDoMundo.Camada.TELEGRAFO_CONTORNO)).is_true()
	assert_int(c.camada_de(item)).is_equal(CamadasDoMundo.Camada.TELEGRAFO_CONTORNO)
	var solto: Node2D = auto_free(Node2D.new())
	assert_int(c.camada_de(solto)).is_equal(-1)
	assert_bool(c.trocar_camada(solto, CamadasDoMundo.Camada.CHAO)).is_false()


func test_ancoras_ordenacao_por_pe_e_remocao() -> void:
	# Arrange
	var reg := RegistroDeCriacaoVisual.new()
	var c := _criar_camadas(reg)
	reg.registrar_criacao(&"inimigo_a")
	reg.registrar_criacao(&"inimigo_b")
	var a := c.registrar_ancora(&"inimigo_a")
	var b := c.registrar_ancora(&"inimigo_b")
	var auto_ord := c.registrar_ancora(&"sem_registro_previo")
	# Act
	c.definir_pe(a, Vector2(100, 620))
	c.definir_pe(b, Vector2(100, 580))
	c.definir_pe(auto_ord, Vector2(100, 580))
	var mudou := c.atualizar_ordem()
	# Assert: b (580, ord 1) atrás de auto_ord (580, ord 2) atrás de a (620, ord 0)
	assert_bool(mudou).is_true()
	assert_array(c.ancoras_em_ordem()).is_equal([b, auto_ord, a])
	assert_bool(c.atualizar_ordem()).is_false()
	c.remover_ancora(auto_ord)
	assert_array(c.ancoras_em_ordem()).is_equal([b, a])


func test_definir_cor_de_fundo_cobre_jogavel_com_margem_no_fundo() -> void:
	# Arrange
	var c := _criar_camadas()
	var cor := Color(0.12, 0.14, 0.18, 1.0)
	# Act
	c.definir_cor_de_fundo(cor, JOGAVEL)
	var fundo := c.raiz(CamadasDoMundo.Camada.FUNDO)
	var pol := fundo.get_node(NodePath(CamadasDoMundo.NOME_COR_DE_FUNDO)) as Polygon2D
	# Assert
	assert_object(pol).is_not_null()
	assert_bool(pol.visible).is_true()
	assert_that(pol.color).is_equal(cor)
	assert_int(pol.polygon.size()).is_equal(4)
	assert_vector(pol.polygon[0]).is_equal(Vector2(-CamadasDoMundo.MARGEM_COR_DE_FUNDO, -CamadasDoMundo.MARGEM_COR_DE_FUNDO))
	assert_vector(pol.polygon[2]).is_equal(JOGAVEL.end + Vector2(CamadasDoMundo.MARGEM_COR_DE_FUNDO, CamadasDoMundo.MARGEM_COR_DE_FUNDO))


func test_compositor_aplica_geometria_pendente_tuning_transformacao_e_parallax() -> void:
	# Arrange
	var vp: SubViewport = auto_free(SubViewport.new())
	vp.size = Vector2i(1920, 1080)
	add_child(vp)
	var camadas: CamadasDoMundo = auto_free(CamadasDoMundo.new())
	vp.add_child(camadas)
	var comp: CompositorDeCena = auto_free(CompositorDeCena.new())
	add_child(comp)
	assert_object(comp.compor(Fabrica.parado(Vector2.ZERO, 0.0))).is_null()

	var cam := Fabrica.camera_em(JOGAVEL, Vector2(1000, 900))
	comp.configurar(cam, camadas, vp)
	comp.definir_camara(JOGAVEL)
	var tuning := TuningFalso.new()
	tuning.parallax_primeiro_plano = 1.2
	comp.configurar_tuning(tuning)
	assert_float(camadas.parallax_de(CamadasDoMundo.Camada.PRIMEIRO_PLANO)).is_equal_approx(1.2, 1e-6)

	var geo := GeometriaDeViewport.calcular(Vector2i(2560, 1080))
	comp.agendar_geometria(geo)

	# Act
	var estado := comp.compor(Fabrica.parado(Vector2(1000, 900), 0.1))

	# Assert
	assert_object(estado).is_not_null()
	assert_object(comp.ultimo_estado()).is_same(estado)
	assert_float(estado.largura).is_equal_approx(2560.0, TOL)
	assert_object(vp.canvas_transform).is_equal(estado.transformacao)
	var centro_visual := estado.pos + estado.deslocamento
	var d_esperado := ParallaxManual.deslocamento(1.2, centro_visual, JOGAVEL.get_center())
	assert_vector(camadas.deslocamento_de(CamadasDoMundo.Camada.PRIMEIRO_PLANO)).is_equal_approx(d_esperado, Vector2(TOL, TOL))
	assert_vector(camadas.deslocamento_de(CamadasDoMundo.Camada.POS)).is_equal(Vector2.ZERO)
