extends GdUnitTestSuite
## Story conteudo-006: contrato ValidadorDoDono, SegundaPassada e regras dos donos (AC-52 a AC-57).


class _LeitorEmMemoria:
	extends CarregadorDeCatalogo.Leitor
	var recursos: Dictionary[String, Resource] = {}

	func existe(caminho: String) -> bool:
		return recursos.has(caminho)

	func carregar(caminho: String) -> Resource:
		return recursos.get(caminho, null)


class _ArteFalsa:
	extends VerificadorDeArte

	func existe(_caminho: String) -> bool:
		return false


class _DonoDeSegunda:
	extends ValidadorDoDono

	func prefixo() -> StringName:
		return &"XX"

	func validar(_itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
		return []

	func precisa_da_segunda_passada() -> bool:
		return true

	func validar_segunda_passada(_itens: Array[ItemDoCatalogo], _catalogo: Catalogo) -> Array[Diagnostico]:
		return [Diagnostico.novo(&"XX7", "", null, "regra cruzada", Diagnostico.Nivel.AVISO)]


func _diags(regra: ValidadorDeRegra, itens: Array[ItemDoCatalogo], codigo: StringName) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	for d in regra.validar(itens):
		if d.regra == codigo:
			out.append(d)
	return out


func _diags_lista(lista: Array[Diagnostico], codigo: StringName) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	for d in lista:
		if d.regra == codigo:
			out.append(d)
	return out


func _def(itens: Array[ItemDoCatalogo], id: StringName, tipo: StringName) -> DefinicaoBase:
	for i in itens:
		if i.definicao.id == id and i.tipo == tipo:
			return i.definicao
	return null


func _catalogo_de(itens: Array[ItemDoCatalogo]) -> Catalogo:
	var cat := Catalogo.new(RelatorAcumulador.new())
	for i in itens:
		cat.adicionar(i.tipo, i.definicao)
	return cat


func _carregar_com_donos(itens: Array[ItemDoCatalogo]) -> CarregadorDeCatalogo:
	var leitor := _LeitorEmMemoria.new()
	var m := ManifestoDoCatalogo.new()
	for item in itens:
		m.acrescentar(item.tipo, item.arquivo)
		leitor.recursos[item.arquivo] = item.definicao
	leitor.recursos["res://t/manifesto.tres"] = m
	var v := ValidadorDeCatalogo.new(FabricasDeCatalogo.registros(), FabricasDeCatalogo.textos_para(itens), _ArteFalsa.new())
	var donos := FabricasDeCatalogo.validadores_dos_donos()
	for dono in donos:
		v.acrescentar(dono)
	var sp := SegundaPassada.new(donos)
	var c := CarregadorDeCatalogo.new(v, RelatorAcumulador.new(), leitor, sp)
	c.carregar("res://t/manifesto.tres")
	return c


# --- AC-52: Tunings de fábrica e faixas dos donos ----------------------------

func test_ac52_tunings_de_fabrica_carregam_com_zero_erros_e_zero_avisos() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	var c := _carregar_com_donos(itens)
	var textos: Array = []
	for d in c.diagnosticos():
		textos.append(d.texto())
	assert_array(textos).is_empty()
	assert_int(c.estado()).is_equal(CarregadorDeCatalogo.Estado.PRONTO)
	assert_object(c.catalogo()).is_not_null()


func test_ac52_valores_fora_de_faixa_geram_codigo_do_dono() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"hud_tuning", &"tuning") as HudTuning).margem_segura_px = 70
	var hu14 := _diags(RegrasHu.new(), itens, &"HU14")
	assert_int(hu14.size()).is_equal(1)
	assert_str(hu14[0].mensagem).is_equal("HudTuning: margem_segura_px 70 fora da faixa 24–64")

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"tela_bencao_tuning", &"tuning") as TelaBencaoTuning).trava_confirmar_ms = 400
	var tb1 := _diags(RegrasTb.new(), itens, &"TB1")
	assert_int(tb1.size()).is_equal(1)
	assert_str(tb1[0].mensagem).is_equal("TelaBencaoTuning: trava_confirmar_ms 400 fora da faixa 500–2000")

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"armas_tuning", &"tuning") as ArmasTuning).p_max = 6
	var wv8 := _diags(RegrasWv.new(), itens, &"WV8")
	assert_int(wv8.size()).is_equal(1)
	assert_bool(wv8[0].eh_aviso()).is_true()

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"bencaos_tuning", &"tuning") as BencaosTuning).tamanho_oferta = 5
	assert_int(_diags(RegrasBn.new(), itens, &"BN1").size()).is_equal(1)

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"telemetria_tuning", &"tuning") as TelemetriaTuning).max_sessoes = 99
	assert_int(_diags(RegrasTl.new(), itens, &"TL1").size()).is_equal(1)

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"feedback_tuning", &"tuning") as FeedbackTuning).limiar_retorno = 0.95
	assert_int(_diags(RegrasFb.new(), itens, &"FB3").size()).is_equal(1)

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"economy_rates", &"economy_rates") as EconomyRates).fragmentos_provacao = 0
	assert_int(_diags(RegrasEc.new(), itens, &"EC1").size()).is_equal(1)

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"reward_table", &"reward_table") as RewardTable).primeira_recompensa = &"cura"
	assert_int(_diags(RegrasPv.new(), itens, &"PV2").size()).is_equal(1)

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"visual_tuning", &"tuning") as VisualTuning).teto_drawcalls_passes = 9
	assert_int(_diags(RegrasVv.new(), itens, &"VV15").size()).is_equal(1)

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"armas_tuning", &"tuning") as ArmasTuning).meta_paridade = 0.50
	assert_int(_diags(RegrasAv.new(), itens, &"AV7").size()).is_equal(1)


# --- AC-53: Catálogo MVP de Pactos (ML, VP, CH sem erros nem avisos) ---------

func test_ac53_catalogo_pactos_passa_ml_vp_ch_nas_duas_passadas() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	var cat := _catalogo_de(itens)
	var ml := RegrasMl.new()
	var vp := RegrasVp.new()
	var ch := RegrasCh.new()
	assert_array(ml.validar(itens)).is_empty()
	assert_array(vp.validar(itens)).is_empty()
	assert_array(ch.validar(itens)).is_empty()
	var sp := SegundaPassada.new([ml, vp, ch] as Array[ValidadorDoDono])
	assert_array(sp.validar(itens, cat)).is_empty()
	var reg := cat.obter(&"region", &"limiar", "teste") as RegionDef
	assert_str(String(reg.chefe)).is_equal("soberano_do_limiar")
	assert_bool(cat.existe(&"enemy", &"anomalia_maior")).is_true()


# --- AC-54: Violações ML, VP e CH bloqueiam a run ----------------------------

func test_ac54_violacoes_ml_vp_ch_emitem_codigo_e_bloqueiam_a_run() -> void:
	# 1. distancia_seguir_px = 500 -> ML1
	var itens := FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"maldicoes_tuning", &"tuning") as MaldicoesTuning).distancia_seguir_px = 500.0
	var c := _carregar_com_donos(itens)
	assert_int(_diags_lista(c.diagnosticos(), &"ML1").size()).is_equal(1)
	assert_int(c.estado()).is_equal(CarregadorDeCatalogo.Estado.FALHOU)
	assert_object(c.catalogo()).is_null()

	# 2. preparo_s = 0 -> ML2
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"vulto_mudo", &"curse") as CurseDef).preparo_s = 0.0
	c = _carregar_com_donos(itens)
	assert_int(_diags_lista(c.diagnosticos(), &"ML2").size()).is_equal(1)
	assert_int(c.estado()).is_equal(CarregadorDeCatalogo.Estado.FALHOU)

	# 3. primordial sem chefe_origem_id -> ML4
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"soberano_do_limiar", &"curse") as CurseDef).chefe_origem_id = &""
	c = _carregar_com_donos(itens)
	assert_int(_diags_lista(c.diagnosticos(), &"ML4").size()).is_equal(1)
	assert_int(c.estado()).is_equal(CarregadorDeCatalogo.Estado.FALHOU)

	# 4. limiares_nivel = [20, 20, 90, 140] -> VP1
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"vinculo_tuning", &"tuning") as VinculoTuning).limiares_nivel = PackedInt64Array([20, 20, 90, 140])
	c = _carregar_com_donos(itens)
	assert_int(_diags_lista(c.diagnosticos(), &"VP1").size()).is_equal(1)
	assert_int(c.estado()).is_equal(CarregadorDeCatalogo.Estado.FALHOU)

	# 5. indices_encontro = [0, 1] -> VP3
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"vinculo_tuning", &"tuning") as VinculoTuning).indices_encontro = PackedInt64Array([0, 1])
	c = _carregar_com_donos(itens)
	assert_int(_diags_lista(c.diagnosticos(), &"VP3").size()).is_equal(1)
	assert_int(c.estado()).is_equal(CarregadorDeCatalogo.Estado.FALHOU)

	# 6. chefe com 3 padrões -> CH1
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"soberano_do_limiar", &"enemy") as EnemyDef).padroes.resize(3)
	c = _carregar_com_donos(itens)
	assert_int(_diags_lista(c.diagnosticos(), &"CH1").size()).is_equal(1)
	assert_int(c.estado()).is_equal(CarregadorDeCatalogo.Estado.FALHOU)

	# 7. lacaios_por_convergencia = 4 com max_lacaios_vivos = 3 -> CH3
	itens = FabricasDeCatalogo.itens_mvp()
	var ct := _def(itens, &"chefes_tuning", &"tuning") as ChefesTuning
	ct.lacaios_por_convergencia = 4
	ct.max_lacaios_vivos = 3
	c = _carregar_com_donos(itens)
	assert_int(_diags_lista(c.diagnosticos(), &"CH3").size()).is_equal(1)
	assert_int(c.estado()).is_equal(CarregadorDeCatalogo.Estado.FALHOU)


# --- AC-55: HU15–HU17 --------------------------------------------------------

func test_ac55_hu15_a_hu17_validam_faixas_de_pacto_no_hud() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"hud_tuning", &"tuning") as HudTuning).pacto_tremor_px = 9
	var d15 := _diags(RegrasHu.new(), itens, &"HU15")
	assert_int(d15.size()).is_equal(1)
	assert_str(d15[0].mensagem).is_equal("HudTuning: pacto_tremor_px 9 fora da faixa 1–8")

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"hud_tuning", &"tuning") as HudTuning).pacto_tremor_s = 0.04
	var d16 := _diags(RegrasHu.new(), itens, &"HU16")
	assert_int(d16.size()).is_equal(1)
	assert_str(d16[0].mensagem).is_equal("HudTuning: pacto_tremor_s 0.04 fora da faixa 0.05–0.40")

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"hud_tuning", &"tuning") as HudTuning).pacto_intervalo_px = 30
	var d17 := _diags(RegrasHu.new(), itens, &"HU17")
	assert_int(d17.size()).is_equal(1)
	assert_str(d17[0].mensagem).is_equal("HudTuning: pacto_intervalo_px 30 fora da faixa 4–24")


# --- AC-56: AV9 --------------------------------------------------------------

func test_ac56_av9_chamado_fora_do_lugar_da_um_erro_cada_e_fabrica_passa() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	assert_array(RegrasAv.new().validar(itens)).is_empty()
	assert_array(V4Referencias.new(FabricasDeCatalogo.registros()).validar(itens)).is_empty()

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"lamina", &"weapon") as WeaponDef).especial.forma = &"chamado"
	assert_int(_diags(RegrasAv.new(), itens, &"AV9").size()).is_equal(1)

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"pactos", &"weapon") as WeaponDef).ataque.forma = &"chamado"
	assert_int(_diags(RegrasAv.new(), itens, &"AV9").size()).is_equal(1)

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"pactos", &"weapon") as WeaponDef).especial.status = &"abalo"
	var d := _diags(RegrasAv.new(), itens, &"AV9")
	assert_int(d.size()).is_equal(1)
	assert_bool(d[0].eh_erro()).is_true()


# --- AC-57: RN1–RN3 ----------------------------------------------------------

func test_ac57_rn_arma_padrao_e_camaras_jogaveis_geram_codigos() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	var rt := _def(itens, &"run_tuning", &"tuning") as RunTuning
	assert_str(String(rt.arma_padrao)).is_equal("pactos")
	assert_array(RegrasRn.new().validar(itens)).is_empty()

	rt.arma_padrao = &"veu"
	assert_int(_diags(RegrasRn.new(), itens, &"RN1").size()).is_equal(1)

	rt.arma_padrao = &"pactos"
	rt.camaras_jogaveis = {&"limiar": 8}
	assert_int(_diags(RegrasRn.new(), itens, &"RN3").size()).is_equal(1)

	rt.camaras_jogaveis = {&"limiar": 4}
	assert_int(_diags(RegrasRn.new(), itens, &"RN2").size()).is_equal(1)

	rt.camaras_jogaveis = {&"limiar": 7}
	assert_array(RegrasRn.new().validar(itens)).is_empty()


# --- Segunda passada (ML7, ML8, VP5–VP7, CH5–CH6) ---------------------------

func test_ml7_e_ml8_rodam_apenas_na_segunda_passada() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"pactos", &"weapon") as WeaponDef).ataque.dano = 50.0
	var ml := RegrasMl.new()
	# Primeira passada não emite ML7 nem ML8
	assert_array(ml.validar(itens)).is_empty()
	# Segunda passada cruza CurseDef com WeaponDef pactos e emite ML7 e ML8
	var sp := SegundaPassada.new([ml] as Array[ValidadorDoDono])
	var diags := sp.validar(itens, _catalogo_de(itens))
	assert_bool(_diags_lista(diags, &"ML7").size() > 0).is_true()
	assert_bool(_diags_lista(diags, &"ML8").size() > 0).is_true()


func test_segunda_passada_so_roda_donos_que_pedem() -> void:
	var dono := _DonoDeSegunda.new()
	var sp := SegundaPassada.new([dono, RegrasRn.new()] as Array[ValidadorDoDono])
	var diags := sp.validar(FabricasDeCatalogo.itens_mvp(), Catalogo.new(RelatorAcumulador.new()))
	assert_int(diags.size()).is_equal(1)
	assert_str(String(diags[0].regra)).is_equal("XX7")
	assert_array(dono.validar(FabricasDeCatalogo.itens_mvp())).is_empty()


func test_dono_registrado_no_composto_roda_na_primeira_passada() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"run_tuning", &"tuning") as RunTuning).arma_padrao = &"veu"
	var v := ValidadorDeCatalogo.new(FabricasDeCatalogo.registros(), FabricasDeCatalogo.textos_para(itens), _ArteFalsa.new())
	v.acrescentar(RegrasRn.new())
	var codigos := v.validar(itens).map(func(d: Diagnostico) -> StringName: return d.regra)
	assert_bool(codigos.has(&"RN1")).is_true()


func test_carregador_reconhece_input_tuning_e_modifiers_tuning_como_tuning() -> void:
	for d: DefinicaoBase in [InputTuning.new(), ModifiersTuning.new()]:
		assert_object(V1Estrutura.verificar_tipo(&"tuning", "res://t.tres", 0, d)).is_null()
		assert_object(V1Estrutura.verificar_tipo(&"weapon", "res://t.tres", 0, d)).is_not_null()
