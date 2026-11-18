extends GdUnitTestSuite
## Story selo-e-fluxo-003: Plantar o Selo — custo, recarga, buffer e centro preso
## (AC-SF-07 a AC-SF-13, AC-SF-27).

const CAMARA := Rect2(0.0, 0.0, 1920.0, 1080.0)


func test_ac_sf_07_custo_recarga_e_evento_selo() -> void:
	var eventos := EventosDoPasso.new()
	var s := Selo.new(SealTuning.fabrica(), eventos)
	var buf := BufferDeComandos.new(10)
	buf.apertar(Acoes.SELO)
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, true)

	assert_int(s.quantidade_ativos()).is_equal(1)
	assert_float(s.fluxo()).is_equal_approx(60.0, 1e-6)
	assert_int(s.recarga()).is_equal(30)
	var evs: Array[EventoDoPasso] = eventos.do_tipo(EvSelo.TIPO)
	assert_int(evs.size()).is_equal(1)
	var ev := evs[0] as EvSelo
	assert_float(ev.centro.x).is_equal_approx(1140.0, 0.01)
	assert_float(ev.centro.y).is_equal_approx(540.0, 0.01)
	assert_float(ev.raio_px).is_equal_approx(142.5, 0.01)
	assert_int(ev.duracao_passos).is_equal(200)

	# Passos 1..28: recarga desce de 30 para 2
	for _p: int in range(1, 29):
		buf.avancar_passo()
		s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, false)
	# Passo 29: recarga vai de 2 a 1 -> novo toque no passo 29 não sai
	buf.avancar_passo()
	buf.apertar(Acoes.SELO)
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, true)
	assert_int(s.quantidade_ativos()).is_equal(1)
	# Passo 30: recarga chega a 0 -> sai do buffer!
	buf.avancar_passo()
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, false)
	assert_int(s.quantidade_ativos()).is_equal(2)


func test_ac_sf_08_e_09_fluxo_insuficiente_e_fronteira() -> void:
	# AC-SF-08: Fluxo 30, toque no passo 0 -> nenhum Selo e 1 selo_sem_fluxo; segurar não repete; toque novo repete
	var eventos := EventosDoPasso.new()
	var s := Selo.new(SealTuning.fabrica(), eventos)
	s.definir_fluxo_para_teste(30.0)
	var buf := BufferDeComandos.new(10)
	buf.apertar(Acoes.SELO)
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, true)
	assert_int(s.quantidade_ativos()).is_equal(0)
	assert_int(eventos.do_tipo(EvSeloSemFluxo.TIPO).size()).is_equal(1)

	# Segurar (toque_novo_selo = false) não emite outro
	buf.avancar_passo()
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, false)
	assert_int(eventos.do_tipo(EvSeloSemFluxo.TIPO).size()).is_equal(1)

	# Toque novo gera outro
	buf.avancar_passo()
	buf.apertar(Acoes.SELO)
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, true)
	assert_int(eventos.do_tipo(EvSeloSemFluxo.TIPO).size()).is_equal(2)

	# AC-SF-09: Fluxo 39,94 + 0,06 = 40,00 -> sai; com 39,90 -> não sai
	var s_ok := Selo.new()
	s_ok.definir_fluxo_para_teste(39.94)
	var b_ok := BufferDeComandos.new(10)
	b_ok.apertar(Acoes.SELO)
	s_ok.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, b_ok, true)
	assert_int(s_ok.quantidade_ativos()).is_equal(1)

	var s_no := Selo.new()
	s_no.definir_fluxo_para_teste(39.90)
	var b_no := BufferDeComandos.new(10)
	b_no.apertar(Acoes.SELO)
	s_no.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, b_no, true)
	assert_int(s_no.quantidade_ativos()).is_equal(0)


func test_ac_sf_10_e_11_esquiva_investida_e_buffer() -> void:
	# AC-SF-10: em esquiva não sai; sai no último passo da esquiva (em_esquiva já falso)
	var s := Selo.new()
	var buf := BufferDeComandos.new(10)
	buf.apertar(Acoes.SELO)
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, true, true)
	assert_int(s.quantidade_ativos()).is_equal(0)
	buf.avancar_passo()
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, false, false)
	assert_int(s.quantidade_ativos()).is_equal(1)

	# No passo do disparo da investida (investida_no_item_5 = false): sai! Nos passos 1..9 (true): não sai
	var s_inv := Selo.new()
	var b_inv := BufferDeComandos.new(10)
	b_inv.apertar(Acoes.SELO)
	s_inv.receber_investida_do_item_5(false)
	s_inv.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, b_inv, true, false)
	assert_int(s_inv.quantidade_ativos()).is_equal(1)

	s_inv.definir_recarga_para_teste(0)
	b_inv.apertar(Acoes.SELO)
	s_inv.receber_investida_do_item_5(true)
	s_inv.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, b_inv, true, false)
	assert_int(s_inv.quantidade_ativos()).is_equal(1)

	# AC-SF-11: Ataque, Especial e Selo no buffer -> Selo só consome `selo`
	var s_ord := Selo.new()
	var b_ord := BufferDeComandos.new(10)
	b_ord.apertar(Acoes.ATAQUE)
	b_ord.apertar(Acoes.ESPECIAL)
	b_ord.apertar(Acoes.SELO)
	s_ord.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, b_ord, true)
	assert_bool(b_ord.tem(Acoes.SELO)).is_false()
	assert_bool(b_ord.tem(Acoes.ATAQUE)).is_true()
	assert_bool(b_ord.tem(Acoes.ESPECIAL)).is_true()


func test_ac_sf_12_e_13_e_27_centro_preso_obstaculo_e_expiracao_do_buffer() -> void:
	var s := Selo.new()
	# AC-SF-12: 4 casos de centro preso em câmara 1920x1080 (margem 30)
	var c1: Vector2 = s.calcular_centro_preso(Vector2(100.0, 540.0), Vector2(-1.0, 0.0), CAMARA)
	var c2: Vector2 = s.calcular_centro_preso(Vector2(60.0, 60.0), Vector2(-0.70710678, -0.70710678), CAMARA)
	var c3: Vector2 = s.calcular_centro_preso(Vector2(960.0, 80.0), Vector2(0.6, -0.8), CAMARA)
	var c4: Vector2 = s.calcular_centro_preso(Vector2(27.0, 540.0), Vector2(-1.0, 0.0), CAMARA)
	assert_float(c1.x).is_equal_approx(30.0, 0.01)
	assert_float(c1.y).is_equal_approx(540.0, 0.01)
	assert_float(c2.x).is_equal_approx(30.0, 0.01)
	assert_float(c2.y).is_equal_approx(30.0, 0.01)
	assert_float(c3.x).is_equal_approx(1068.0, 0.01)
	assert_float(c3.y).is_equal_approx(30.0, 0.01)
	assert_float(c4.x).is_equal_approx(30.0, 0.01)
	assert_float(c4.y).is_equal_approx(540.0, 0.01)

	# AC-SF-13: obstáculo sobre (1140, 540) é ignorado e o Saco leva dano
	var saco: Dictionary = {&"id": 1, &"pos": Vector2(1140.0, 540.0), &"raio": 24.0, &"vida": 1000.0}
	var buf := BufferDeComandos.new(10)
	buf.apertar(Acoes.SELO)
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, true, false, [saco])
	assert_float(float(saco[&"vida"])).is_equal_approx(999.88, 1e-6)

	# AC-SF-27: Fluxo 39,00 sem acertos (leva 17 passos, buffer de 10 expira -> não sai);
	# com Fluxo 39,70 (chega a 40 no 5º passo, índice 4) -> sai!
	var s_exp := Selo.new()
	s_exp.definir_fluxo_para_teste(39.00)
	var b_exp := BufferDeComandos.new(10)
	b_exp.apertar(Acoes.SELO)
	for p: int in 20:
		if p > 0:
			b_exp.avancar_passo()
		s_exp.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, b_exp, p == 0)
	assert_int(s_exp.quantidade_ativos()).is_equal(0)

	var s_5 := Selo.new()
	s_5.definir_fluxo_para_teste(39.70)
	var b_5 := BufferDeComandos.new(10)
	b_5.apertar(Acoes.SELO)
	for p: int in 5:
		if p > 0:
			b_5.avancar_passo()
		s_5.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, b_5, p == 0)
	assert_int(s_5.quantidade_ativos()).is_equal(1)
