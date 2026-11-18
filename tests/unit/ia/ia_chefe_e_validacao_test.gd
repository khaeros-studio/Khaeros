extends GdUnitTestSuite
## Story ia-009 e 010: Chefe ativo na máquina de fases, lacaios e validação IV1–IV9 / IA1–IA14 (AC-IA-23..25, AC-IA-29, AC-IA-45, AC-IA-46, AC-IA-48, AC-IA-49).


func test_ac_ia_45_46_48_49_chefe_ativo_sem_rng_lacaios_e_respiro_na_transicao() -> void:
	var ctx := FixtureIA.ContextoTeste.new()
	ctx.ia.definir_jogador(0, Vector2(960.0, 450.0), 27.0)
	ctx.maldicao.id_campo = 10
	ctx.maldicao.pos = Vector2(960.0, 450.0)
	ctx.maldicao.raio = 24.0

	var chefe_def := FixtureTelegrafos.soberano_do_limiar()
	var id_ch := ctx.ia.criar_inimigo(chefe_def, Vector2(960.0, 285.0), OpcoesDeNascimento.de_chefe(), null)
	var ec := ctx.ia.estado_de(id_ch)

	# AC-IA-45: Vida 700 sem depth_hp_bonus; 50 passos de surgimento + 30 de aproximação sem consumir fluxo_ia
	assert_float(ec.vida_max).is_equal_approx(700.0, 1e-5)
	for p in 50:
		ctx.ia.passo(id_ch)
	assert_int(int(ec.fase)).is_equal(int(EstadoDeInimigoIA.Fase.APROXIMACAO))
	assert_int(ec.timer).is_equal(30)
	assert_int(ctx.fluxo_ia.chamadas_inteiro).is_equal(0)

	# AC-IA-48: Padrão 2 travado no jogador fere só o jogador pelo anel e dispara 12 projéteis com alvo = JOGADOR
	ec.estado_chefe.padrao = 2
	ec.timer = 1
	ctx.ia.passo(id_ch) # inicia preparo P2 (36 passos)
	for p in 36:
		ctx.ia.executar_item_7()
	assert_int(ctx.combate.danos_jogador.size()).is_equal(1)
	assert_float(float(ctx.combate.danos_jogador[0]["dano"])).is_equal_approx(15.0, 1e-5)
	assert_bool(ctx.combate.danos_maldicao.is_empty()).is_true()
	assert_int(ctx.combate.projeteis_disparados.size()).is_equal(12)
	for proj: Dictionary in ctx.combate.projeteis_disparados:
		assert_int(int(proj["alvo_faccao"])).is_equal(int(TelegrafoTipos.FaccaoAlvo.JOGADOR))

	# AC-IA-49: Chefe atraído com 50 entra em TransicaoFase -> zera atração e abre respiro de 30 passos
	ec.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	ec.restante_respiro = 0
	assert_bool(ctx.ia.atrair(id_ch, 50, 30)).is_true()
	ec.vida = 340.0
	ctx.ia.notificar_dano_no_chefe(id_ch)
	assert_int(int(ec.fase)).is_equal(int(EstadoDeInimigoIA.Fase.TRANSICAO_FASE))
	assert_int(ec.restante_atracao).is_equal(0)
	assert_int(ec.restante_respiro).is_equal(30)
	assert_bool(ctx.ia.atrair(id_ch, 90, 30)).is_false()
	for p in 30:
		ctx.ia.passo(id_ch)
	assert_bool(ctx.ia.atrair(id_ch, 90, 30)).is_true()

	# AC-IA-46: lacaio invocado pelo chefe aceita imobilizar e atrair
	var id_lac := ctx.ia.criar_inimigo(FixtureTelegrafos.eco_perdido(), Vector2(825.0, 285.0), OpcoesDeNascimento.lacaio_do_chefe())
	ctx.ia.estado_de(id_lac).fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	assert_bool(ctx.ia.imobilizar(id_lac, 90)).is_true()
	assert_bool(ctx.ia.atrair(id_lac, 90, 30)).is_true()


func test_ac_ia_23_24_25_29_validacao_iv_e_ia_fabrica_e_erros() -> void:
	# AC-IA-23: Lâmina (100 HP) vs dano 16 -> 7 golpes, t_min = 240 passos; Ressonância (80 HP) -> 5 golpes, 160 passos
	assert_int(ValidadorIA.golpes_para_morrer(100, 16)).is_equal(7)
	assert_int(ValidadorIA.t_min_morrer_passos(100, 16, 40)).is_equal(240)
	assert_int(ValidadorIA.golpes_para_morrer(80, 16)).is_equal(5)
	assert_int(ValidadorIA.t_min_morrer_passos(80, 16, 40)).is_equal(160)

	# AC-IA-25: catálogo de fábrica sem avisos IV5..IV9
	var itens_ok: Array[ItemDoCatalogo] = [
		ItemDoCatalogo.new(&"enemy", "res://eco.tres", 0, FixtureTelegrafos.eco_perdido()),
		ItemDoCatalogo.new(&"enemy", "res://anom.tres", 1, FixtureTelegrafos.anomalia_menor()),
		ItemDoCatalogo.new(&"enemy", "res://fenda.tres", 2, FixtureTelegrafos.fenda_errante()),
		ItemDoCatalogo.new(&"enemy", "res://sob.tres", 3, FixtureTelegrafos.soberano_do_limiar()),
		ItemDoCatalogo.new(&"weapon", "res://lamina.tres", 4, FabricasDeCatalogo.arma(&"lamina", 100, &"avanco")),
		ItemDoCatalogo.new(&"weapon", "res://ress.tres", 5, FabricasDeCatalogo.arma(&"ressonancia", 80, &"circulo")),
	]
	assert_array(ValidadorIA.validar_completo(itens_ok)).is_empty()

	# AC-IA-24: erros IV1..IV4
	var t_iv1 := IATuning.de_fabrica()
	t_iv1.surgimento_s = 0.0
	var t_iv2 := IATuning.de_fabrica()
	t_iv2.ranged_perto_px = 600.0
	var t_iv3 := IATuning.de_fabrica()
	t_iv3.fator_contorno = 1.5
	var in_iv4 := FixtureTelegrafos.eco_perdido()
	in_iv4.comportamento = &"invalido"

	assert_bool(ValidadorIA.validar_completo([], t_iv1).map(func(d: Diagnostico) -> StringName: return d.regra).has(&"IV1")).is_true()
	assert_bool(ValidadorIA.validar_completo([], t_iv2).map(func(d: Diagnostico) -> StringName: return d.regra).has(&"IV2")).is_true()
	assert_bool(ValidadorIA.validar_completo([], t_iv3).map(func(d: Diagnostico) -> StringName: return d.regra).has(&"IV3")).is_true()
	assert_bool(ValidadorIA.validar_completo([ItemDoCatalogo.new(&"enemy", "res://i.tres", 0, in_iv4)]).map(func(d: Diagnostico) -> StringName: return d.regra).has(&"IV4")).is_true()

	# AC-IA-29: avisos IV5..IV9 com dados defeituosos
	var in_rapido := FixtureTelegrafos.eco_perdido()
	in_rapido.velocidade = 280.0
	var arma_fragil := FabricasDeCatalogo.arma(&"lamina", 40, &"avanco")
	var t_def := IATuning.de_fabrica()
	t_def.avanco_passos = 20
	t_def.margem_visivel_px = 250.0
	t_def.execucao_melee_passos = 99
	var diags_av := ValidadorIA.validar_completo([
		ItemDoCatalogo.new(&"enemy", "res://r.tres", 0, in_rapido),
		ItemDoCatalogo.new(&"weapon", "res://af.tres", 1, arma_fragil),
	], t_def)
	var cods := diags_av.map(func(d: Diagnostico) -> StringName: return d.regra)
	for c_esp: StringName in [&"IV5", &"IV6", &"IV7", &"IV8", &"IV9"]:
		assert_bool(cods.has(c_esp)).is_true()
