## Story cena-e-camera 002 — AC-14 (cantos numa câmara de uma tela) e AC-17 (Investida na vista).
extends GdUnitTestSuite

const Fabrica := preload("res://tests/unit/cena/doubles/fabrica_cena.gd")
const DT := 1.0 / 60.0


func test_camara_uma_tela_jogador_nos_cantos_mirando_pos_fixa_600_quadros() -> void:
	var cam := Fabrica.camera_em(Rect2(0, 0, 1920, 1080), Vector2(960, 540))
	var cantos: Array[Vector2] = [Vector2(30, 30), Vector2(1890, 30), Vector2(1890, 1050), Vector2(30, 1050)]
	var p_ant := Vector2(960, 540)
	var falhas := 0
	for q in 600:
		var alvo := cantos[(q / 150) % 4]
		var p := p_ant.move_toward(alvo, 20.0)
		var e := Fabrica.com_mouse(p, (q + 1) * DT, Vector2(float(q * 37 % 1920), float(q * 53 % 1080)))
		e.p_anterior = p_ant
		var v := cam.atualizar_quadro(e)
		if not v.pos.is_equal_approx(Vector2(960, 540)):
			falhas += 1
		p_ant = p
	assert_int(falhas).is_equal(0)


func test_investida_330px_em_10_passos_pe_nunca_sai_da_vista() -> void:
	var camara := Rect2(0, 0, 2880, 1620)
	var inicio := Vector2(1440, 810)
	var cam := Fabrica.camera_em(camara, inicio)
	var p_ant := inicio
	var fora := 0
	for passo in 10:
		var p := p_ant + Vector2(33, 0)
		# Mira para trás: pior caso, lookahead contra a Investida.
		var e := Fabrica.com_mouse(p, (passo + 1) * DT, Vector2(0, 540))
		e.p_anterior = p_ant
		var v := cam.atualizar_quadro(e)
		var meia := Vector2(v.largura / 2.0, 540.0)
		if absf(p.x - v.pos.x) > meia.x or absf(p.y - v.pos.y) > meia.y:
			fora += 1
		p_ant = p
	assert_int(fora).is_equal(0)
