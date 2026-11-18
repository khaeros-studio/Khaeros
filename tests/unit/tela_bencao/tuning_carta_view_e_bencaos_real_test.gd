class_name TuningCartaViewEBencaosRealTest
extends GdUnitTestSuite
## Testes unitários de `TelaBencaoTuning`, `CartaView` (`offset_transform_*`) e integração com `PortaDaBencaoReal` (`story-004`, `story-005` e `story-006`).


func test_carta_view_usa_offset_transform_visual_only_sem_deslocar_layout() -> void:
	var cv: CartaView = auto_free(CartaView.new())
	var tuning: TelaBencaoTuning = TelaBencaoTuning.new()
	var dados: DadosDaCarta = DadosDaCarta.criar_de_bencao(&"eco_ferro", &"ferro", 1, 0)
	cv.configurar_carta(dados, tuning, false, false)

	cv.position = Vector2(460.0, 290.0)
	cv.aplicar_estado_foco(true)
	assert_that(cv.offset_transform_enabled).is_true()
	assert_that(cv.offset_transform_visual_only).is_true()
	assert_that(cv.offset_transform_scale.x).is_equal_approx(tuning.foco_escala, 0.001)
	assert_that(cv.offset_transform_offset.y).is_equal_approx(-tuning.foco_subida_px, 0.001)
	# A posição de layout permanece intacta
	assert_that(cv.position).is_equal(Vector2(460.0, 290.0))


func test_porta_da_bencao_real_sincroniza_ids_raridades_e_trocas() -> void:
	var porta: PortasDaBencao.PortaDaBencaoReal = PortasDaBencao.PortaDaBencaoReal.new(null, 1, {})
	porta.sincronizar_de_evento([&"sede_rubra", &"pele_ferro", &"passo_sombra"], [0, 1, 2], 2)

	assert_that(porta.trocas_restantes()).is_equal(2)
	assert_that(porta.cartas_atuais().size()).is_equal(3)
	assert_that(porta.cartas_atuais()[2].raridade).is_equal(2)
	assert_that(porta.trocar_oferta()).is_true()
	assert_that(porta.trocas_restantes()).is_equal(1)
	assert_that(porta.escolher_carta(1)).is_true()
