extends GdUnitTestSuite
## Story camaras-e-ondas/007: Próxima onda, "em combate" e câmara limpa no item 10.
## Cobre AC-CO-12, AC-CO-13, AC-CO-14, AC-CO-15, AC-CO-16 e AC-CO-34.


func _criar_camara_combate(indice: int = 4) -> Dictionary:
	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte.iniciar_run(0x55667788, true)
	var eventos := EventosDoPasso.new()
	var wr := FabricasDeCatalogo.wave_rules()
	var rt := FabricasDeCatalogo.room_tuning()
	var reg := Run._regiao_limiar_padrao()
	var eco := FabricasDeCatalogo.inimigo(&"eco_perdido")
	var cam := Camaras.new(wr, rt, reg, FluxosDeCamaras.new(fonte), eventos, [eco], FabricasDeCatalogo.chefe_soberano(), null, FluxosDeIa.new(fonte))
	return {"camaras": cam, "eventos": eventos}


func test_ac_co_12_13_14_15_ciclo_de_ondas_hitstop_e_camara_limpa() -> void:
	var ctx := _criar_camara_combate(4) # índice 4 -> p = 3 -> 2 ondas!
	var cam: Camaras = ctx["camaras"]
	var eventos: EventosDoPasso = ctx["eventos"]
	var hitstop_ativo: Array[bool] = [false]
	var projeteis_removidos: Array[int] = [0]

	cam.configurar_combate(
		func() -> bool: return hitstop_ativo[0],
		func() -> bool: return false,
		func() -> void: projeteis_removidos[0] += 1
	)

	assert_bool(cam.em_combate()).is_false()
	cam.trocar(4, &"fragmentos", 0, true)
	assert_bool(cam.em_combate()).is_true()
	assert_int(cam.conteudo().onda_atual).is_equal(0)

	# Abate todos os inimigos da 1ª onda, mas com hitstop ativo -> não avança para a 2ª onda ainda (AC-CO-13)
	for ini: InimigoRef in cam.inimigos_vivos():
		ini.vida = 0.0
	hitstop_ativo[0] = true
	cam.passo(null)
	assert_int(cam.conteudo().onda_atual).is_equal(0)
	assert_bool(cam.em_combate()).is_true()

	# Hitstop acaba -> nasce a 2ª onda no mesmo passo e "em combate" continua verdadeiro (AC-CO-12)
	hitstop_ativo[0] = false
	cam.passo(null)
	assert_int(cam.conteudo().onda_atual).is_equal(1)
	assert_bool(cam.em_combate()).is_true()
	assert_bool(cam.inimigos_vivos().size() >= 1).is_true()

	# Abate todos os inimigos da 2ª onda com hitstop 0 -> limpa no mesmo passo, remove projéteis e emite camara_limpa 1 vez (AC-CO-14)
	for ini: InimigoRef in cam.inimigos_vivos():
		ini.vida = 0.0
	cam.passo(null)
	assert_int(cam.fase()).is_equal(Camaras.Fase.LIMPA)
	assert_bool(cam.em_combate()).is_false()
	assert_int(projeteis_removidos[0]).is_equal(1)
	var evs := eventos.do_tipo(&"camara_limpa")
	assert_int(evs.size()).is_equal(1)
	var ev_limpa := evs[0] as EventosDeCamaras.EvCamaraLimpa
	assert_int(ev_limpa.profundidade).is_equal(3)
	assert_str(String(ev_limpa.tipo_camara)).is_equal("combate")


func test_ac_co_16_morte_do_jogador_vence_a_limpeza() -> void:
	var ctx := _criar_camara_combate(0) # p = 0 -> 1 onda
	var cam: Camaras = ctx["camaras"]
	var eventos: EventosDoPasso = ctx["eventos"]
	var morreu: Array[bool] = [false]
	cam.configurar_combate(func() -> bool: return false, func() -> bool: return morreu[0])
	cam.trocar(0, &"bencao", 0, true)

	for ini: InimigoRef in cam.inimigos_vivos():
		ini.vida = 0.0
	morreu[0] = true
	cam.passo(null)
	assert_int(cam.fase()).is_equal(Camaras.Fase.COMBATE)
	assert_bool(eventos.ha(&"camara_limpa")).is_false()


func test_ac_co_34_maldicao_e_acuada_vivas_nao_impedem_camara_limpa() -> void:
	var ctx := _criar_camara_combate(1)
	var cam: Camaras = ctx["camaras"]
	var eventos: EventosDoPasso = ctx["eventos"]
	cam.configurar_pactos(
		func(_idx: int) -> StringName: return &"espreitador_da_fenda",
		func(_idx: int, _esp: StringName, _pedras: Array[ObstaculoCircular]) -> Vector2: return Vector2(960.0, 540.0),
		func() -> bool: return true,
		func(_pos: Vector2) -> void: pass,
		func() -> float: return 24.0
	)
	cam.trocar(1, &"fragmentos", 0, true)
	for ini: InimigoRef in cam.inimigos_vivos():
		ini.vida = 0.0
	cam.passo(null)
	assert_int(cam.fase()).is_equal(Camaras.Fase.LIMPA)
	assert_int(eventos.do_tipo(&"camara_limpa").size()).is_equal(1)
