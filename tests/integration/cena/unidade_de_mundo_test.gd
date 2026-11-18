extends GdUnitTestSuite
## AC-07 (GDD Cena F1), parte que cabe à Cena: o valor importado em px de mundo é
## usado sem segunda conversão 1,5. O script de importação real (Conteúdo F4) é do
## épico conteudo; aqui um dublê do importador prova o contrato da constante.

const TuningFalso := preload("res://tests/unit/cena/doubles/camera_tuning_falso.gd")

## Fixture do cânone (unidades).
const ARENA_CANONE := Vector2(1280, 720)
const RAIO_CANONE := 18.0
const UNIT_TO_PX := 1.5


## Dublê do importador: `px = u × unit_to_px`, com a constante injetada.
static func _importar(u: float, unit_to_px: float) -> float:
	return u * unit_to_px


func test_importar_fixture_do_canone_grava_1920x1080_e_raio_27() -> void:
	assert_float(_importar(ARENA_CANONE.x, UNIT_TO_PX)).is_equal(1920.0)
	assert_float(_importar(ARENA_CANONE.y, UNIT_TO_PX)).is_equal(1080.0)
	assert_float(_importar(RAIO_CANONE, UNIT_TO_PX)).is_equal(27.0)
	assert_float(_importar(0.0, UNIT_TO_PX)).is_equal(0.0)


func test_importar_com_constante_2_grava_raio_36() -> void:
	assert_float(_importar(RAIO_CANONE, 2.0)).is_equal(36.0)


func test_cena_com_camara_importada_1920x1080_usa_px_sem_multiplicar_de_novo() -> void:
	# Câmara gravada já em px (1920×1080 = uma tela): a F7 dá só o chute (8, 8) e a
	# F4 centraliza; se houvesse ×1,5 de novo, a câmara teria 2880 e a deriva 104.
	var jogavel := Rect2(Vector2.ZERO, Vector2(_importar(ARENA_CANONE.x, UNIT_TO_PX), _importar(ARENA_CANONE.y, UNIT_TO_PX)))
	var teto: float = TuningFalso.new().teto_deslocamento
	assert_vector(ParallaxManual.deriva(1.2, jogavel.size, teto)).is_equal_approx(Vector2(8, 8), Vector2(1e-3, 1e-3))
	var centro := LimitesDaCamera.prender(Vector2(5000, 5000), jogavel, GeometriaDeViewport.LARGURA_BASE, 370.0)
	assert_vector(centro).is_equal(Vector2(960, 540))


func test_cena_com_raio_importado_27_ordena_e_colide_com_27() -> void:
	# O raio lido do .tres (27) é usado tal qual: dois corpos a 54 px se tocam.
	var raio := _importar(RAIO_CANONE, UNIT_TO_PX)
	var a := Vector2(100, 500)
	var b := a + Vector2(2.0 * raio, 0)
	assert_float(a.distance_to(b)).is_equal(54.0)
	assert_bool(a.distance_to(b) <= 2.0 * raio).is_true()
