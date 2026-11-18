extends GdUnitTestSuite
## Story camaras-e-ondas/003: Layout de pedras, retângulo jogável e obstáculos.
## Cobre AC-CO-03, AC-CO-04, AC-CO-05, AC-CO-06 e AC-CO-11 (parte layout).


class _FluxoLayoutDuble:
	extends FluxoRng
	var inteiros: Array[int] = []
	var reais: Array[float] = []
	var chamadas: int = 0
	var _idx_i: int = 0
	var _idx_r: int = 0

	func _init() -> void:
		super(1, RelatorDeErrosRng.new(), null)

	func inteiro(n: int) -> int:
		chamadas += 1
		if _idx_i < inteiros.size():
			var v: int = inteiros[_idx_i]
			_idx_i += 1
			return clampi(v, 0, n - 1)
		return 0

	func real_entre(a: float, b: float) -> float:
		chamadas += 1
		if _idx_r < reais.size():
			var v: float = reais[_idx_r]
			_idx_r += 1
			return clampf(v, a, b)
		return a


func test_ac_co_03_retangulo_jogavel_prende_jogador_de_raio_27() -> void:
	var rt := FabricasDeCatalogo.room_tuning()
	var rect := LayoutDaCamara.retangulo_jogavel(rt)
	assert_that(rect).is_equal(Rect2(0.0, 0.0, 1920.0, 1080.0))
	var pedras_vazias: Array[ObstaculoCircular] = []
	var geom: GeometriaDeMovimento = LayoutDaCamara.construir_geometria(rt, pedras_vazias)
	var p1: Vector2 = Colisao.resolver_colisao(Vector2(-10.0, -5.0), 27.0, geom)
	var p2: Vector2 = Colisao.resolver_colisao(Vector2(2000.0, 1100.0), 27.0, geom)
	assert_that(p1).is_equal(Vector2(27.0, 27.0))
	assert_that(p2).is_equal(Vector2(1893.0, 1053.0))


func test_ac_co_04_e_05_consumo_fixo_91_folga_105_e_omissao() -> void:
	var rt := FabricasDeCatalogo.room_tuning()
	var f := _FluxoLayoutDuble.new()
	# n = 2 + 1 = 3 pedras; cada pedra tenta 10 candidatos (1 inteiro de raio + 2 reais x, y = 3 números -> 30 por pedra -> 91 total)
	f.inteiros.append(1) # var = 1 -> 3 pedras
	# Pedra 0: todos os 10 candidatos em (500, 400), passo_r = 0 (raio = 42)
	for _t in 10:
		f.inteiros.append(0)
		f.reais.append(500.0)
		f.reais.append(400.0)
	# Pedra 1: 1º candidato a distância 42 + 42 + 104.9 = 188.9 (recusado!); 2º a 42 + 42 + 105.0 = 189.0 (aceito!)
	f.inteiros.append(0)
	f.reais.append(500.0 + 188.9)
	f.reais.append(400.0)
	for _t in 9:
		f.inteiros.append(0)
		f.reais.append(500.0 + 189.0)
		f.reais.append(400.0)
	# Pedra 2: todos os 10 candidatos sobre (500, 400) -> nenhum respeita folga -> omitida!
	for _t in 10:
		f.inteiros.append(0)
		f.reais.append(500.0)
		f.reais.append(400.0)

	var pedras := LayoutDaCamara.sortear_obstaculos_combate(rt, f)
	assert_int(f.chamadas).is_equal(91)
	assert_int(pedras.size()).is_equal(2)
	assert_that(pedras[0].centro).is_equal(Vector2(500.0, 400.0))
	assert_float(pedras[1].centro.x).is_equal_approx(689.0, 1e-4)


func test_ac_co_06_e_11_faixas_de_raio_posicao_e_independencia_do_jogador() -> void:
	var rt := FabricasDeCatalogo.room_tuning()
	var fonte1 := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte1.iniciar_run(0xCAFEBABE, false)
	var fl1 := FluxosDeCamaras.new(fonte1).layout(0, 0)
	var pedras := LayoutDaCamara.sortear_obstaculos_combate(rt, fl1)
	for p: ObstaculoCircular in pedras:
		assert_bool(p.raio >= 42.0 and p.raio <= 79.5).is_true()
		assert_bool(p.centro.x >= 270.0 and p.centro.x <= 1650.0).is_true()
		assert_bool(p.centro.y >= 255.0 and p.centro.y <= 765.0).is_true()
		# Nenhuma pedra cobre a entrada (960, 930) com raio do jogador 27 (y_max + r = 844,5 < 903)
		assert_bool(p.centro.y + p.raio < 903.0).is_true()

	var fonte2 := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte2.iniciar_run(0xCAFEBABE, false)
	var fl2 := FluxosDeCamaras.new(fonte2).layout(0, 0)
	LayoutDaCamara.sortear_obstaculos_combate(rt, fl2)
	assert_int(fl1.estado()).is_equal(fl2.estado())
