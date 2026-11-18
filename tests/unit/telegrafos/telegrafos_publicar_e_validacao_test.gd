extends GdUnitTestSuite
## Story telegrafos-008 e 009: publicar() de vistas imutáveis e validação TV1–TV6 / TL1–TL12 (AC-TG-13, AC-TG-19, AC-TG-20, AC-TG-39).


func test_ac_tg_13_publicar_entrega_vistas_sem_alocar_e_com_contorno_por_faccao() -> void:
	var c := FixtureTelegrafos.ConsultaDublê.new()
	c.definir_dono(1, Vector2.ZERO)
	c.definir_dono(2, Vector2(0.0, 100.0))
	c.definir_dono(3, Vector2(0.0, 200.0))
	c.definir_jogador(0, Vector2(100.0, 0.0))
	c.definir_maldicao(10, Vector2(100.0, 100.0), 24.0, true)
	var tel := Telegrafos.new()
	tel.configurar(TelegraphTuning.de_fabrica(), c, FixtureTelegrafos.camara_livre())
	tel.iniciar_telegrafo(1, FixtureTelegrafos.eco_perdido(), 0, TelegrafoTipos.FaccaoAlvo.JOGADOR)
	tel.iniciar_telegrafo(2, FixtureTelegrafos.anomalia_menor(), 10, TelegrafoTipos.FaccaoAlvo.ALIADO)
	tel.iniciar_telegrafo(3, FixtureTelegrafos.fenda_errante(), 0, TelegrafoTipos.FaccaoAlvo.JOGADOR)

	var vistas := FixtureTelegrafos.vistas_pre_alocadas(24)
	var ref_0 := vistas[0]
	var n := tel.publicar(vistas)
	assert_int(n).is_equal(3)
	assert_object(vistas[0]).is_same(ref_0)
	assert_int(int(vistas[0].contorno_alvo)).is_equal(int(TelegrafoTipos.ContornoAlvo.PERIGO_JOGADOR))
	assert_int(int(vistas[1].contorno_alvo)).is_equal(int(TelegrafoTipos.ContornoAlvo.SECUNDARIO_ALIADO))
	assert_float(vistas[0].raio).is_equal_approx(90.0, 0.01)
	assert_float(vistas[2].comprimento).is_equal_approx(310.6, 0.1)


func test_ac_tg_19_20_39_validacao_tv_e_tl_fabrica_e_erros() -> void:
	var itens: Array[ItemDoCatalogo] = [
		ItemDoCatalogo.new(&"enemy", "res://eco.tres", 0, FixtureTelegrafos.eco_perdido()),
		ItemDoCatalogo.new(&"enemy", "res://eco_veio.tres", 1, FixtureTelegrafos.eco_do_veio()),
		ItemDoCatalogo.new(&"enemy", "res://anom.tres", 2, FixtureTelegrafos.anomalia_menor()),
		ItemDoCatalogo.new(&"enemy", "res://fenda.tres", 3, FixtureTelegrafos.fenda_errante()),
		ItemDoCatalogo.new(&"enemy", "res://soberano.tres", 4, FixtureTelegrafos.soberano_do_limiar()),
	]
	var diags_ok := ValidadorTelegrafos.validar_completo(itens, TelegraphTuning.de_fabrica(), 9)
	assert_array(diags_ok).is_empty()

	# Eco com preparo_s = 0.3 (18 passos) -> gera TV3 e TV4
	var eco_curto := FixtureTelegrafos.eco_perdido()
	eco_curto.preparo_s = 0.30
	var diags_curto := ValidadorTelegrafos.validar_completo(
		[ItemDoCatalogo.new(&"enemy", "res://eco_curto.tres", 0, eco_curto)],
		TelegraphTuning.de_fabrica(), 9)
	var codigos_curto := diags_curto.map(func(d: Diagnostico) -> StringName: return d.regra)
	assert_bool(codigos_curto.has(&"TV3")).is_true()
	assert_bool(codigos_curto.has(&"TV4")).is_true()

	# teto_telegrafos = 8 (< 9) -> gera TV5
	var t_reduzido := TelegraphTuning.de_fabrica()
	t_reduzido.teto_telegrafos = 8
	var diags_teto := ValidadorTelegrafos.validar_completo(itens, t_reduzido, 9)
	var codigos_teto := diags_teto.map(func(d: Diagnostico) -> StringName: return d.regra)
	assert_bool(codigos_teto.has(&"TV5")).is_true()

	# preparo_s = 0 e comportamento inválido -> TV1 e TV2
	var in_zero := FixtureTelegrafos.eco_perdido()
	in_zero.preparo_s = 0.0
	var in_sem_forma := FixtureTelegrafos.eco_perdido()
	in_sem_forma.comportamento = &"desconhecido"
	var diags_erro := ValidadorTelegrafos.validar_completo([
		ItemDoCatalogo.new(&"enemy", "res://z.tres", 0, in_zero),
		ItemDoCatalogo.new(&"enemy", "res://sf.tres", 1, in_sem_forma),
	], TelegraphTuning.de_fabrica(), 9)
	var codigos_erro := diags_erro.map(func(d: Diagnostico) -> StringName: return d.regra)
	assert_bool(codigos_erro.has(&"TV1")).is_true()
	assert_bool(codigos_erro.has(&"TV2")).is_true()
