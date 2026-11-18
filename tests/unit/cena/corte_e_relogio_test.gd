## Story cena-e-camera 006 — corte atômico na metade do wipe (AC-22) e `reiniciar_relogio`.
extends GdUnitTestSuite

const Fabrica := preload("res://tests/unit/cena/doubles/fabrica_cena.gd")
const E := EstadosDaCamera.Estado
const VELHA := Rect2(0, 0, 2880, 1620)
const NOVA := Rect2(5000, 0, 2880, 1620)
const EPS := Vector2(1e-4, 1e-4)
const M := 10


func test_wipe_2m_quadros_pos_na_velha_ate_m_menos_1_e_no_alvo_novo_em_m() -> void:
	var cam := Fabrica.camera_em(VELHA, Vector2(1440, 810))
	cam.mudar_estado(E.TRANSICAO)
	var velha := cam.pos
	var spawn := Vector2(6500, 1500)
	var mira := Fabrica.com_mouse(spawn, 0.0, Vector2(1900, 540))
	var esperado := LimitesDaCamera.prender(spawn, NOVA, 1920.0, 370.0)
	for q in 2 * M:
		if q == M:
			assert_bool(cam.cortar(CorteDeCamera.new(2, NOVA, 370.0, spawn, mira))).is_true()
		var v := cam.atualizar_quadro(Fabrica.parado(spawn if q >= M else Vector2(1440, 810), q / 60.0))
		if q < M:
			assert_vector(v.pos).is_equal(velha)
		elif q == M:
			# pos_seguir = F4(P); pos = F4(alvo_F2) com a mira capturada (lookahead à direita).
			assert_vector(v.pos_seguir).is_equal_approx(esperado, EPS)
			assert_bool(v.pos.x > esperado.x).is_true()
			assert_int(cam.quantidade_impulsos()).is_equal(0)
		else:
			# Estado global ainda é Transição: a câmera nova fica parada.
			assert_int(v.estado).is_equal(E.TRANSICAO)
	assert_bool(cam.mudar_estado(E.SEGUINDO)).is_true()


func test_corte_repetido_na_mesma_epoca_nao_teleporta() -> void:
	var cam := Fabrica.camera_em(VELHA, Vector2(1440, 810))
	assert_bool(cam.cortar(CorteDeCamera.new(2, NOVA, 370.0, Vector2(6000, 800)))).is_true()
	var pos := cam.pos
	assert_bool(cam.cortar(CorteDeCamera.new(2, NOVA, 370.0, Vector2(7500, 100)))).is_false()
	assert_bool(cam.cortar(CorteDeCamera.new(1, VELHA, 370.0, Vector2(100, 100)))).is_false()
	assert_vector(cam.pos).is_equal(pos)


func test_reiniciar_relogio_so_epoca_atual_e_uma_vez() -> void:
	var cam := Fabrica.camera_em(VELHA, Vector2(1440, 810))
	cam.cortar(CorteDeCamera.new(2, NOVA, 370.0, Vector2(6000, 800)))
	assert_bool(cam.reiniciar_relogio(1, 0.0)).is_false()
	assert_bool(cam.reiniciar_relogio(2, 0.0)).is_true()
	assert_bool(cam.reiniciar_relogio(2, 0.0)).is_false()


func test_relogio_zerado_apos_corte_f3_usa_dt_novo_sem_retroceder() -> void:
	var cam := Fabrica.camera_em(VELHA, Vector2(1440, 810))
	cam.atualizar_quadro(Fabrica.parado(Vector2(1440, 810), 5.0))
	cam.cortar(CorteDeCamera.new(2, NOVA, 370.0, Vector2(6000, 810)))
	cam.reiniciar_relogio(2, 0.0)
	cam.atualizar_quadro(Fabrica.parado(Vector2(6000, 810), 0.0))  # quadro do Corte, sem F3
	var e := Fabrica.parado(Vector2(6100, 810), 0.1)
	var v := cam.atualizar_quadro(e)
	assert_int(v.estado).is_equal(E.SEGUINDO)
	assert_float(v.pos.x).is_equal_approx(6000.0 + 100.0 * (1.0 - pow(2.0, -0.1 / 0.12)), 1e-3)
