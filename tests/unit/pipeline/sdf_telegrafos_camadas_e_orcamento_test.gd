extends GdUnitTestSuite
## Stories pipeline-visual 006 a 010: SDF F4, tracejado F7, malha de borda, pool de 24 telégrafos,
## contorno secundário R5a, validador de família/facção AC-PV-05/88, oclusão F9, traço do jogador R6,
## fio de vínculo e marca do Virote R5b, e orçamento de draw calls F10.


func test_escala_traco_f3_e_sdf_formas_zonas_crescimento_ac_pv_18_20_21_22_23_60_82() -> void:
	# AC-PV-18: s_tela por resolução
	assert_float(VisualMathSdf.s_tela(1280, 720)).is_equal_approx(0.6667, 1e-3)
	assert_float(VisualMathSdf.s_tela(1280, 800)).is_equal_approx(0.6667, 1e-3)
	assert_float(VisualMathSdf.s_tela(1920, 1080)).is_equal_approx(1.0, 1e-4)
	assert_float(VisualMathSdf.s_tela(2560, 1440)).is_equal_approx(1.3333, 1e-3)
	assert_float(VisualMathSdf.s_tela(3840, 2160)).is_equal_approx(2.0, 1e-4)

	# AC-PV-20: SDF de C120, A60, R400 e S200
	var c120 := Vector4(120.0, 0, 0, 0)
	assert_float(VisualMathSdf.sdf(VisualMathSdf.Forma.CIRCULO, Vector2(0, 0), c120)).is_equal_approx(-120.0, 1e-3)
	assert_float(VisualMathSdf.sdf(VisualMathSdf.Forma.CIRCULO, Vector2(118, 0), c120)).is_equal_approx(-2.0, 1e-3)
	assert_float(VisualMathSdf.sdf(VisualMathSdf.Forma.CIRCULO, Vector2(120, 0), c120)).is_equal_approx(0.0, 1e-3)

	var a60 := Vector4(120.0, 60.0, 120.0, 0.0)
	assert_float(VisualMathSdf.sdf(VisualMathSdf.Forma.ANEL, Vector2(90, 0), a60)).is_equal_approx(-30.0, 1e-3)
	assert_float(VisualMathSdf.sdf(VisualMathSdf.Forma.ANEL, Vector2(60, 0), a60)).is_equal_approx(0.0, 1e-3)

	var r400 := Vector4(400.0, 80.0, 0.0, 0.0)
	assert_float(VisualMathSdf.sdf(VisualMathSdf.Forma.RETANGULO, Vector2(200, 0), r400)).is_equal_approx(-40.0, 1e-3)
	assert_float(VisualMathSdf.sdf(VisualMathSdf.Forma.RETANGULO, Vector2(0, 0), r400)).is_equal_approx(0.0, 1e-3)

	var s200 := Vector4(200.0, 0.0, 0.0, deg_to_rad(45.0))
	assert_float(VisualMathSdf.sdf(VisualMathSdf.Forma.SETOR, Vector2(100, 0), s200)).is_equal_approx(-70.711, 1e-2)
	assert_float(VisualMathSdf.raio_interno_maximo(VisualMathSdf.Forma.SETOR, s200)).is_equal_approx(82.843, 1e-2)

	# AC-PV-60 e AC-PV-82: sem fresta e sem linha de meia cobertura em p >= 1
	var aa_1440 := 0.75
	var p_110 := VisualMathSdf.avaliar_ponto_telegrafo(
		VisualMathSdf.Forma.CIRCULO, VisualMathSdf.ModoCrescimento.CENTRO_A_BORDA,
		Vector2(110, 0), c120, 1.0, aa_1440
	)
	assert_float(float(p_110["alpha_a"])).is_equal_approx(0.5, 1e-3)
	assert_float(float(p_110["alpha_n"])).is_equal_approx(0.5, 1e-3)
	assert_float(float(p_110["alpha_f"])).is_equal_approx(1.0, 1e-3)

	var p_anel_meio := VisualMathSdf.avaliar_ponto_telegrafo(
		VisualMathSdf.Forma.ANEL, VisualMathSdf.ModoCrescimento.BORDA_AO_CENTRO,
		Vector2(90, 0), a60, 1.0, aa_1440
	)
	assert_float(float(p_anel_meio["alpha_n"])).is_equal_approx(1.0, 1e-3)


func test_malha_de_borda_area_e_tracejado_f7_ac_pv_28_61_62() -> void:
	# AC-PV-61: área da malha de borda do C120 dentro de ±2% de 5931.3 unidades² (-90% do quad cheio)
	var geom := MalhaDeBorda.gerar_geometria_borda(VisualMathSdf.Forma.CIRCULO, Vector4(120.0, 0, 0, 0), 4.0, 2.0, 0.0, 96)
	var area := MalhaDeBorda.area_malha(geom["vertices"], geom["indices"])
	var esperado := PI * (122.0 * 122.0 - 114.0 * 114.0)
	assert_float(absf(area - esperado) / esperado).is_less_equal(0.02)

	# AC-PV-28 e AC-PV-62: tracejado periódico no anel r = 150, sem costura em θ = ±π
	var p_info := VisualMathSdf.parametros_tracejado(TAU * 150.0, 8.0, 6.0)
	assert_int(int(p_info["n"])).is_equal(67)
	assert_float(float(p_info["P_aj"])).is_equal_approx(14.067, 1e-2)

	var perim := TAU * 150.0
	var s0 := VisualMathSdf.avaliar_tracejado(0.0, perim, 0.75, 1.0)
	var s_fim := VisualMathSdf.avaliar_tracejado(perim - 1e-6, perim, 0.75, 1.0)
	assert_float(float(s0["on"])).is_equal_approx(0.5, 1e-3)
	assert_float(absf(float(s0["on"]) - float(s_fim["on"]))).is_less_equal(1e-3)


func test_pool_de_telegrafos_24_slots_estados_e_contorno_secundario_ac_pv_24_25_49_84_85() -> void:
	var camadas := auto_free(CamadasDoMundo.new())
	var tuning := FabricasDeCatalogo.visual_tuning()
	var ev := EstadoVisual.new()
	ev.configurar(tuning, func() -> int: return 100_000)
	var pool := PoolDeTelegrafos.new(tuning, ev)
	pool.pre_instanciar(camadas)

	# AC-PV-25: 24 slots pré-instanciados e nó de anéis de área anterior aos preenchimentos
	var raiz_pre := camadas.raiz(CamadasDoMundo.Camada.TELEGRAFO_PREENCHIMENTO)
	assert_int(raiz_pre.get_child(0).get_index()).is_equal(pool.no_aneis_area().get_index())
	assert_int(pool.no_preenchimento(0).z_index).is_equal(0) # herda z = -5 da camada

	# AC-PV-84 e AC-PV-85: contorno secundário aparece em CRESCENDO e some em DISPARO
	var v := VistaDeTelegrafo.new()
	v.slot = 0
	v.forma = TelegrafoTipos.Forma.CIRCULO
	v.raio = 225.0
	v.contorno_secundario_raio = 420.0
	v.alvo_faccao = TelegrafoTipos.FaccaoAlvo.ALIADO
	v.estado = TelegrafoTipos.Estado.CRESCENDO
	v.p = 0.5
	pool.aplicar_vistas([v])
	assert_bool(pool.estado_slot(0).contorno_secundario_visivel).is_true()
	assert_bool(pool.no_preenchimento(0).visible).is_true()
	assert_bool(pool.no_contorno(0).visible).is_true()

	v.estado = TelegrafoTipos.Estado.DISPARO
	v.passos_no_estado = 0
	pool.aplicar_vistas([v])
	assert_bool(pool.estado_slot(0).contorno_secundario_visivel).is_false()

	v.passos_no_estado = 2
	pool.aplicar_vistas([v])
	assert_bool(pool.no_preenchimento(0).visible).is_false()

	# AC-PV-49: acima do teto (30 vistas) registra aviso sem travar
	var trinta: Array[VistaDeTelegrafo] = []
	for i in 30:
		var vi := VistaDeTelegrafo.new()
		vi.slot = i % 24
		vi.estado = TelegrafoTipos.Estado.CRESCENDO
		vi.raio = 100.0
		trinta.append(vi)
	pool.aplicar_vistas(trinta)
	assert_int(pool.avisos_acima_teto()).is_equal(1)


func test_validador_de_familia_oclusao_f9_traco_e_orcamento_ac_pv_05_33_80_83_86_87_88() -> void:
	# AC-PV-33: Oclusão F9 com histerese
	var ev := EstadoVisual.new()
	ev.configurar(FabricasDeCatalogo.visual_tuning())
	ev.registrar_oclusor(1, Rect2(800, 300, 160, 220), 520.0)
	for p in 6:
		ev.atualizar_oclusao_passo(Vector2(870, 500), Vector2(870, 455), 500.0)
	assert_float(ev.alfa_oclusor(1)).is_equal_approx(0.40, 1e-5)
	# Histerese: x = 964 ainda dentro de R_oc expandido por 8 px (até 968 exclusivo)
	ev.atualizar_oclusao_passo(Vector2(964, 500), Vector2(964, 455), 500.0)
	assert_bool(ev.oclusor_cobre(1)).is_true()
	ev.atualizar_oclusao_passo(Vector2(968, 500), Vector2(968, 455), 500.0)
	assert_bool(ev.oclusor_cobre(1)).is_false()

	# AC-PV-80: inversão substitui o tracejado de invulnerabilidade
	var corpo := TracoEVfxMaldicoes.EstadoCorpoJogador.new()
	corpo.aplicar_dano_recebido(6, 4, 40)
	for h in 6:
		assert_bool(corpo.inversao_ativa()).is_true()
		assert_bool(corpo.contorno_tracejado_ativo()).is_false()
		corpo.avancar_passo(true)
	for v_step in 4:
		assert_bool(corpo.inversao_ativa()).is_true()
		assert_bool(corpo.contorno_tracejado_ativo()).is_false()
		corpo.avancar_passo(false)
	assert_bool(corpo.inversao_ativa()).is_false()
	assert_bool(corpo.contorno_tracejado_ativo()).is_true()

	# AC-PV-83, 86, 87, 88: imagens residuais, fio de vínculo, marca do Virote e validador
	var camadas := auto_free(CamadasDoMundo.new())
	var vfx_m := TracoEVfxMaldicoes.new(FabricasDeCatalogo.visual_tuning())
	vfx_m.montar_vfx_maldicoes_em_z_menos_5(camadas)
	vfx_m.atualizar_fio_de_vinculo(true, Vector2.ZERO, Vector2(300, 0), 0.0)
	assert_str(String(vfx_m.estado_do_fio())).is_equal("normal")
	vfx_m.atualizar_fio_de_vinculo(true, Vector2.ZERO, Vector2(420, 0), 0.0)
	assert_str(String(vfx_m.estado_do_fio())).is_equal("tenso")
	vfx_m.atualizar_fio_de_vinculo(true, Vector2.ZERO, Vector2(500, 0), 0.25)
	assert_str(String(vfx_m.estado_do_fio())).is_equal("estourado")

	vfx_m.atualizar_marca_virote(10, Vector2(100, 200))
	assert_int(vfx_m.alvo_marca_virote()).is_equal(10)
	assert_bool(vfx_m.no_marca_virote().visible).is_true()
	vfx_m.atualizar_marca_virote(-1)
	assert_bool(vfx_m.no_marca_virote().visible).is_false()

	assert_bool(ValidadorDeFamilia.validar_dono_telegrafo(&"maldicao")).is_false()
	assert_bool(ValidadorDeFamilia.validar_dono_telegrafo(&"inimigo")).is_true()

	# Orçamento F10 / proxy de draw calls <= 350 operacional
	var proxy := ProxyDeOrcamento.new()
	proxy.definir_grupo(&"ambiente", 32)
	proxy.definir_grupo(&"sombras_e_telegrafos", 54)
	proxy.definir_grupo(&"entidades", 120)
	proxy.definir_grupo(&"vfx", 48)
	proxy.definir_grupo(&"passes", 2)
	proxy.definir_grupo(&"ui", 36)
	assert_int(proxy.total_draw_calls_proxy()).is_equal(292)
	assert_bool(proxy.dentro_do_orcamento_operacional()).is_true()
	assert_float(ProxyDeOrcamento.overdraw_telegrafos_c120(24, true)).is_less_equal(0.80)
