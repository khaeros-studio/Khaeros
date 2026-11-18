extends GdUnitTestSuite
## Story camaras-e-ondas/006: Montagem na Transição — teleporte, Maldição, acuada e 1ª onda.
## Cobre AC-CO-02, AC-CO-35, AC-CO-36 e AC-CO-41.


func _criar_camaras(seed_val: int) -> Dictionary:
	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte.iniciar_run(seed_val, true)
	var wr := FabricasDeCatalogo.wave_rules()
	var rt := FabricasDeCatalogo.room_tuning()
	var reg := Run._regiao_limiar_padrao()
	var eco := FabricasDeCatalogo.inimigo(&"eco_perdido")
	var cam := Camaras.new(wr, rt, reg, FluxosDeCamaras.new(fonte), EventosDoPasso.new(), [eco], FabricasDeCatalogo.chefe_soberano(), null, FluxosDeIa.new(fonte))
	return {"camaras": cam, "fonte": fonte, "rt": rt}


func test_ac_co_02_e_35_montagem_posiciona_jogador_maldicao_e_primeira_onda() -> void:
	var ctx := _criar_camaras(0x3F9A07C2)
	var cam: Camaras = ctx["camaras"]
	var pos_jog := Vector2(100.0, 200.0)
	var pos_mald := Vector2(400.0, 300.0)

	cam.configurar_jogador(null, func() -> Vector2: return pos_jog, func(np: Vector2) -> void: pos_jog = np)
	cam.configurar_pactos(
		Callable(), Callable(), Callable(),
		func(np: Vector2) -> void: pos_mald = np,
		func() -> float: return 30.0, # Baluarte de Cinza (raio 30)
		105.0
	)
	cam.trocar(0, &"bencao", 0, true)

	assert_that(pos_jog).is_equal(Vector2(960.0, 930.0))
	assert_that(pos_mald).is_equal(Vector2(960.0, 1035.0))
	assert_int(cam.fase()).is_equal(Camaras.Fase.COMBATE)
	assert_bool(cam.inimigos_vivos().size() >= 2).is_true()

	# Com distancia_seguir_px = 150 -> min(930 + 150, 1080 - 30) = 1050
	cam.configurar_pactos(
		Callable(), Callable(), Callable(),
		func(np: Vector2) -> void: pos_mald = np,
		func() -> float: return 30.0,
		150.0
	)
	cam.trocar(1, &"fragmentos", 0, true)
	assert_that(pos_mald).is_equal(Vector2(960.0, 1050.0))


func test_ac_co_36_e_41_encontro_nao_altera_layout_ondas_elites_nem_consumo_de_fluxos() -> void:
	# Run A: sem encontro no índice 2
	var ctx_a := _criar_camaras(0xABCDEF01)
	var cam_a: Camaras = ctx_a["camaras"]
	var fonte_a: FonteDeFluxos = ctx_a["fonte"]
	cam_a.trocar(2, &"fragmentos", 0, true)

	# Run B: com encontro no índice 2
	var ctx_b := _criar_camaras(0xABCDEF01)
	var cam_b: Camaras = ctx_b["camaras"]
	var fonte_b: FonteDeFluxos = ctx_b["fonte"]
	var pedras_recebidas_pelo_vinculo: Array = []
	cam_b.configurar_pactos(
		func(idx: int) -> StringName: return &"espreitador_da_fenda" if idx == 2 else &"",
		func(_idx: int, _esp: StringName, pedras: Array[ObstaculoCircular]) -> Vector2:
			pedras_recebidas_pelo_vinculo = pedras.duplicate()
			return Vector2(960.0, 540.0),
		func() -> bool: return true
	)
	cam_b.trocar(2, &"fragmentos", 0, true)

	assert_int(pedras_recebidas_pelo_vinculo.size()).is_equal(cam_a.obstaculos().size())
	assert_int(cam_a.conteudo().ondas_compostas.size()).is_equal(cam_b.conteudo().ondas_compostas.size())

	# Estado final dos fluxos layout, ondas, elites e spawn é idêntico (consumo fixo)
	var fc_a := FluxosDeCamaras.new(fonte_a)
	var fc_b := FluxosDeCamaras.new(fonte_b)
	assert_int(fc_a.layout(0, 2).estado()).is_equal(fc_b.layout(0, 2).estado())
	assert_int(fc_a.ondas(0, 2).estado()).is_equal(fc_b.ondas(0, 2).estado())
	assert_int(fc_a.spawn(0, 2).estado()).is_equal(fc_b.spawn(0, 2).estado())
