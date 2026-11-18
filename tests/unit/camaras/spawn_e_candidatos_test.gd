extends GdUnitTestSuite
## Story camaras-e-ondas/005: Spawn — 14 candidatos, filtros, ordem e distância da acuada.
## Cobre AC-CO-09, AC-CO-10 (parte pedras), AC-CO-11 (parte spawn), AC-CO-37 e AC-CO-38.


class _FluxoSpawnDuble:
	extends FluxoRng
	var pontos: Array[Vector2] = []
	var reais_lidos: int = 0
	var _idx: int = 0
	var _lendo_y: bool = false

	func _init(p_pontos: Array[Vector2] = []) -> void:
		super(1, RelatorDeErrosRng.new(), null)
		pontos = p_pontos

	func real_entre(_a: float, _b: float) -> float:
		reais_lidos += 1
		if _idx < pontos.size():
			var p: Vector2 = pontos[_idx]
			if not _lendo_y:
				_lendo_y = true
				return p.x
			_lendo_y = false
			_idx += 1
			return p.y
		return 500.0


func test_ac_co_09_14_candidatos_sempre_fronteira_390_e_fallback_14() -> void:
	var rt := FabricasDeCatalogo.room_tuning()
	var pos_jog := Vector2(960.0, 930.0)
	var pts: Array[Vector2] = [
		Vector2(960.0, 930.0 - 390.0), # exatos 390,0 px -> recusado!
		Vector2(960.0, 930.0 - 390.1), # 390,1 px -> escolhido!
	]
	while pts.size() < 14:
		pts.append(Vector2(200.0, 200.0))

	var f := _FluxoSpawnDuble.new(pts)
	var escolhido := SpawnCamara.escolher_ponto_spawn(24.0, rt, f, pos_jog, [])
	assert_int(f.reais_lidos).is_equal(28)
	assert_float(escolhido.y).is_equal_approx(930.0 - 390.1, 1e-4)

	# Sem nenhum válido -> escolhe o 14º candidato
	var invalidos: Array[Vector2] = []
	for i in 13:
		invalidos.append(Vector2(960.0, 900.0))
	invalidos.append(Vector2(960.0, 888.0)) # 14º candidato (também perto, mas vira fallback)
	var f2 := _FluxoSpawnDuble.new(invalidos)
	var fb := SpawnCamara.escolher_ponto_spawn(24.0, rt, f2, pos_jog, [])
	assert_int(f2.reais_lidos).is_equal(28)
	assert_that(fb).is_equal(Vector2(960.0, 888.0))


func test_ac_co_10_filtro_de_pedras_fronteira_folga_12() -> void:
	var rt := FabricasDeCatalogo.room_tuning()
	var pos_jog := Vector2(960.0, 930.0)
	var pedra := ObstaculoCircular.new(Vector2(500.0, 400.0), 50.0)
	# raio_inimigo = 24, folga = 12 -> r_pedra + raio + 12 = 50 + 24 + 12 = 86,0 px
	var c_recusado := Vector2(500.0 + 86.0, 400.0)
	var c_aceito := Vector2(500.0 + 86.1, 400.0)
	assert_bool(SpawnCamara.candidato_valido(c_recusado, 24.0, rt, pos_jog, [pedra])).is_false()
	assert_bool(SpawnCamara.candidato_valido(c_aceito, 24.0, rt, pos_jog, [pedra])).is_true()


func test_ac_co_37_e_38_ordem_na_onda_e_distancia_da_acuada_240() -> void:
	var rt := FabricasDeCatalogo.room_tuning()
	var pos_jog := Vector2(960.0, 930.0)
	var pos_acuada := Vector2(960.0, 540.0)

	# Exemplo F3-P / AC-CO-38: C1=(1100, 480) está a 152 px da acuada (<240 -> recusado); C2=(1200, 400) a 278 px -> escolhido
	var pts: Array[Vector2] = [Vector2(1100.0, 480.0), Vector2(1200.0, 400.0)]
	while pts.size() < 14:
		pts.append(Vector2(1200.0, 400.0))
	var escolhido := SpawnCamara.escolher_ponto_spawn(24.0, rt, _FluxoSpawnDuble.new(pts), pos_jog, [], true, pos_acuada)
	assert_that(escolhido).is_equal(Vector2(1200.0, 400.0))

	# Fronteira 240,0 recusado vs 240,1 aceito
	assert_bool(SpawnCamara.candidato_valido(Vector2(960.0, 540.0 - 240.0), 24.0, rt, pos_jog, [], true, pos_acuada)).is_false()
	assert_bool(SpawnCamara.candidato_valido(Vector2(960.0, 540.0 - 240.1), 24.0, rt, pos_jog, [], true, pos_acuada)).is_true()

	# Com a acuada em Fugiu (acuada_presente = false), o (1100, 480) é aceito!
	assert_bool(SpawnCamara.candidato_valido(Vector2(1100.0, 480.0), 24.0, rt, pos_jog, [], false, pos_acuada)).is_true()

	# AC-CO-37: ordem 0, 1 e 2 repassada na instanciação da onda
	var eco := FabricasDeCatalogo.inimigo(&"eco_perdido")
	var onda: Array[ComposicaoDeOndas.EntradaDeOnda] = [
		ComposicaoDeOndas.EntradaDeOnda.new(&"eco_perdido", eco, 1.0, 0),
		ComposicaoDeOndas.EntradaDeOnda.new(&"eco_perdido", eco, 1.0, 1),
		ComposicaoDeOndas.EntradaDeOnda.new(&"eco_perdido", eco, 1.0, 2),
	]
	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte.iniciar_run(0x11223344, true)
	var nascidos := SpawnCamara.instanciar_onda(
		onda, 1, rt, FluxosDeCamaras.new(fonte).spawn(0, 1),
		func(_p: int, _ja: bool) -> bool: return false,
		pos_jog, [], true, pos_acuada
	)
	assert_int(nascidos.size()).is_equal(3)
	assert_int(nascidos[0].ordem).is_equal(0)
	assert_int(nascidos[1].ordem).is_equal(1)
	assert_int(nascidos[2].ordem).is_equal(2)
