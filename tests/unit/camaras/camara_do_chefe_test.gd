extends GdUnitTestSuite
## Story camaras-e-ondas/009: Câmara do chefe — sem sorteio, Subjugado, limpar_camara_chefe e teto de lacaios.
## Cobre AC-CO-29, AC-CO-30, AC-CO-31, AC-CO-32, AC-CO-33 e TR-camaras-014.


func _criar_camara_chefe() -> Dictionary:
	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte.iniciar_run(0x99887766, true)
	var eventos := EventosDoPasso.new()
	var wr := FabricasDeCatalogo.wave_rules()
	var rt := FabricasDeCatalogo.room_tuning()
	var reg := Run._regiao_limiar_padrao()
	var eco := FabricasDeCatalogo.inimigo(&"eco_perdido")
	var chefe := FabricasDeCatalogo.chefe_soberano()
	var cam := Camaras.new(wr, rt, reg, FluxosDeCamaras.new(fonte), eventos, [eco], chefe, null, FluxosDeIa.new(fonte))
	return {"camaras": cam, "fonte": fonte, "eventos": eventos, "eco": eco}


func test_ac_co_29_chefe_monta_com_layout_fixo_e_zero_fluxos_consumidos() -> void:
	var ctx := _criar_camara_chefe()
	var cam: Camaras = ctx["camaras"]
	var fonte: FonteDeFluxos = ctx["fonte"]
	var chamou_sortear_elite: Array[bool] = [false]
	cam.configurar_ia(func(_p: int, _ja: bool) -> bool:
		chamou_sortear_elite[0] = true
		return false
	)
	cam.trocar(6, &"", 0, true)

	assert_int(fonte.fluxos_abertos()).is_equal(0)
	assert_bool(chamou_sortear_elite[0]).is_false()
	assert_int(cam.profundidade_atual()).is_equal(4)
	assert_int(cam.obstaculos().size()).is_equal(4)
	assert_that(cam.obstaculos()[0].centro).is_equal(Vector2(390.0, 300.0))
	assert_that(cam.obstaculos()[3].centro).is_equal(Vector2(1530.0, 750.0))
	assert_int(cam.inimigos_vivos().size()).is_equal(1)
	var c_ref: InimigoRef = cam.inimigos_vivos()[0]
	assert_bool(c_ref.chefe).is_true()
	assert_that(c_ref.posicao).is_equal(Vector2(960.0, 285.0))
	assert_str(String(c_ref.fase)).is_equal("SURGINDO")


func test_ac_co_30_chefe_fora_de_pactos_limpa_apos_hitstop() -> void:
	var ctx := _criar_camara_chefe()
	var cam: Camaras = ctx["camaras"]
	var eventos: EventosDoPasso = ctx["eventos"]
	var hitstop: Array[bool] = [true]
	cam.configurar_combate(func() -> bool: return hitstop[0], func() -> bool: return false)
	cam.trocar(6, &"", 0, true)

	# Chefe morre no passo 640 (com 36 passos de hitstop)
	cam.inimigos_vivos()[0].vida = 0.0
	cam.passo(null)
	assert_int(cam.fase()).is_equal(Camaras.Fase.COMBATE)
	assert_bool(eventos.ha(&"camara_limpa")).is_false()

	# Passo 677: hitstop 0 -> limpa e emite camara_limpa(4, chefe) uma vez
	hitstop[0] = false
	cam.passo(null)
	assert_int(cam.fase()).is_equal(Camaras.Fase.LIMPA)
	var evs := eventos.do_tipo(&"camara_limpa")
	assert_int(evs.size()).is_equal(1)
	var ev := evs[0] as EventosDeCamaras.EvCamaraLimpa
	assert_int(ev.profundidade).is_equal(4)
	assert_str(String(ev.tipo_camara)).is_equal("chefe")


func test_ac_co_31_32_33_subjugado_limpar_camara_chefe_e_teto_de_lacaios() -> void:
	var ctx := _criar_camara_chefe()
	var cam: Camaras = ctx["camaras"]
	var eventos: EventosDoPasso = ctx["eventos"]
	var eco: EnemyDef = ctx["eco"]
	cam.trocar(6, &"", 0, true)

	# AC-CO-33: limpar_camara_chefe() na fase Combate -> ignorado e registra erro de integração
	assert_bool(cam.limpar_camara_chefe()).is_false()
	assert_int(cam.erros_integracao().size()).is_equal(1)
	assert_int(cam.fase()).is_equal(Camaras.Fase.COMBATE)

	# TR-camaras-014: teto de 9 inimigos para chefe + lacaios
	for i in 12:
		cam.adicionar_lacaio_do_chefe(eco, Vector2(400.0 + float(i) * 30.0, 400.0))
	assert_int(cam.inimigos_vivos().size()).is_equal(9)

	# AC-CO-31: chefe_subjugado -> fase SUBJUGADO, "em combate" falso, R9 suspensa
	for ini: InimigoRef in cam.inimigos_vivos():
		ini.vida = 0.0
	cam.chefe_subjugado(&"soberano_do_limiar")
	assert_int(cam.fase()).is_equal(Camaras.Fase.SUBJUGADO)
	assert_bool(cam.em_combate()).is_false()
	cam.passo(null)
	assert_bool(eventos.ha(&"camara_limpa")).is_false()

	# AC-CO-32: limpar_camara_chefe() após resolver_subjugado -> fase Limpa e camara_limpa(4, chefe) 1 vez; 2º pedido ignorado
	assert_bool(cam.limpar_camara_chefe()).is_true()
	assert_bool(cam.limpar_camara_chefe()).is_false()
	assert_int(cam.fase()).is_equal(Camaras.Fase.LIMPA)
	assert_int(eventos.do_tipo(&"camara_limpa").size()).is_equal(1)
