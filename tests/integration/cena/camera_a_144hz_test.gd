## Story cena-e-camera 003 — AC-35 (simulação lógica 60 Hz física / 144 Hz render).
## Não prova suavidade visual (ADR-0007: fluidez não se mede headless); a parte
## [M] do AC-38 exige gravação em monitor de 144 Hz.
extends GdUnitTestSuite

const Fabrica := preload("res://tests/unit/cena/doubles/fabrica_cena.gd")
const FISICA := 60
const RENDER := 144
const VELOCIDADE := 300.0


func _p(passos: int) -> Vector2:
	return Vector2(1000.0 + VELOCIDADE * float(passos) / float(FISICA), 540.0)


func test_reducao_de_movimento_300px_s_avanco_por_quadro_varia_menos_de_1_porcento() -> void:
	var camara := Rect2(0, 0, 2880, 1080)
	var cam := Fabrica.camera_em(camara, _p(0))
	var xs: Array[float] = []
	for n in range(1, RENDER + 1):
		var passos := (n * FISICA) / RENDER
		var e := Fabrica.parado(_p(passos), float(n) / float(RENDER))
		e.p_anterior = _p(maxi(0, passos - 1))
		e.fracao = float((n * FISICA) % RENDER) / float(RENDER)
		e.reducao_movimento = true
		xs.append(cam.atualizar_quadro(e).pos.x)
	var pior := 0.0
	var encostou := false
	for i in range(RENDER / 2 + 1, RENDER):
		var a0 := xs[i - 1] - xs[i - 2]
		var a1 := xs[i] - xs[i - 1]
		pior = maxf(pior, absf(a1 - a0) / a0)
		if xs[i] <= 960.0 + 1e-3 or xs[i] >= 1920.0 - 1e-3:
			encostou = true
	assert_float(pior).is_less(0.01)
	assert_bool(encostou).is_false()
