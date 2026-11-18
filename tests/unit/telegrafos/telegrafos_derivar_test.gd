extends GdUnitTestSuite
## Story telegrafos-002: FormasDeTelegrafo.derivar() dos EnemyDef e raio do alvo (AC-TG-07, AC-TG-09, AC-TG-11, AC-TG-26, AC-TG-29).


func test_ac_tg_07_setor_do_eco_perdido() -> void:
	var f := FormasDeTelegrafo.derivar(FixtureTelegrafos.eco_perdido(), 27.0)
	assert_bool(f.valida).is_true()
	assert_int(int(f.forma)).is_equal(int(TelegrafoTipos.Forma.SETOR))
	assert_int(int(f.modo)).is_equal(int(TelegrafoTipos.Modo.CENTRO_A_BORDA))
	assert_float(f.raio).is_equal_approx(90.0, 0.01)
	assert_float(f.meio_angulo_graus).is_equal_approx(78.46, 0.01)


func test_ac_tg_09_largura_e_modo_da_faixa_da_anomalia() -> void:
	var f := FormasDeTelegrafo.derivar(FixtureTelegrafos.anomalia_menor(), 27.0)
	assert_bool(f.valida).is_true()
	assert_int(int(f.forma)).is_equal(int(TelegrafoTipos.Forma.RETANGULO))
	assert_int(int(f.modo)).is_equal(int(TelegrafoTipos.Modo.AO_LONGO_DO_EIXO))
	assert_float(f.largura).is_equal_approx(81.0, 0.01)
	assert_float(f.comprimento).is_equal_approx(1728.0, 0.01)


func test_ac_tg_11_26_avanco_fenda_estilhaco_e_variantes_do_veio() -> void:
	var f_fenda := FormasDeTelegrafo.derivar(FixtureTelegrafos.fenda_errante(), 27.0)
	assert_float(f_fenda.comprimento).is_equal_approx(310.6, 0.1)
	assert_float(f_fenda.largura).is_equal_approx(114.0, 0.1)
	assert_float(f_fenda.x_min).is_equal_approx(-57.0, 0.1)
	assert_float(f_fenda.folga_canto).is_equal_approx(23.6, 0.1)

	var f_est := FormasDeTelegrafo.derivar(FixtureTelegrafos.estilhaco_vivo(), 27.0)
	assert_float(f_est.comprimento).is_equal_approx(341.6, 0.1)
	assert_float(f_est.largura).is_equal_approx(117.0, 0.1)

	var f_eco_veio := FormasDeTelegrafo.derivar(FixtureTelegrafos.eco_do_veio(), 27.0)
	assert_float(f_eco_veio.raio).is_equal_approx(96.75, 0.01)

	var f_anom_veio := FormasDeTelegrafo.derivar(FixtureTelegrafos.anomalia_do_veio(), 27.0)
	assert_float(f_anom_veio.comprimento).is_equal_approx(1945.5, 0.01)


func test_ac_tg_29_dimensoes_pelo_raio_do_alvo_travado_f7() -> void:
	var eco := FixtureTelegrafos.eco_perdido()
	var anom := FixtureTelegrafos.anomalia_menor()
	var fenda := FixtureTelegrafos.fenda_errante()

	# Setor do Eco: Vulto (24) = 87, Baluarte (30) = 93, Jogador (27) = 90, Espreitador (22.5) = 85.5, Soberano (28.5) = 91.5
	assert_float(FormasDeTelegrafo.derivar(eco, 24.0).raio).is_equal_approx(87.0, 0.01)
	assert_float(FormasDeTelegrafo.derivar(eco, 30.0).raio).is_equal_approx(93.0, 0.01)
	assert_float(FormasDeTelegrafo.derivar(eco, 27.0).raio).is_equal_approx(90.0, 0.01)
	assert_float(FormasDeTelegrafo.derivar(eco, 22.5).raio).is_equal_approx(85.5, 0.01)
	assert_float(FormasDeTelegrafo.derivar(eco, 28.5).raio).is_equal_approx(91.5, 0.01)

	# Faixa da Anomalia no Baluarte (30): 87 x 1731; no Soberano (28.5): 84 x 1729.5
	var fa_bal := FormasDeTelegrafo.derivar(anom, 30.0)
	assert_float(fa_bal.largura).is_equal_approx(87.0, 0.01)
	assert_float(fa_bal.comprimento).is_equal_approx(1731.0, 0.01)
	var fa_sob := FormasDeTelegrafo.derivar(anom, 28.5)
	assert_float(fa_sob.largura).is_equal_approx(84.0, 0.01)
	assert_float(fa_sob.comprimento).is_equal_approx(1729.5, 0.01)

	# Avanço da Fenda no Baluarte (30): R_c 60, 316.6 x 120
	var ff_bal := FormasDeTelegrafo.derivar(fenda, 30.0)
	assert_float(ff_bal.r_c).is_equal_approx(60.0, 0.01)
	assert_float(ff_bal.comprimento).is_equal_approx(316.6, 0.1)
	assert_float(ff_bal.largura).is_equal_approx(120.0, 0.01)
