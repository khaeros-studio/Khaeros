extends GdUnitTestSuite


func test_ac_ml_07_f3_ciclo_de_ataque_basico_e_bonus_vinculo_nivel_4() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(
		&"vulto_mudo",
		&"espreitador_da_fenda",
		null,
		{&"vulto_mudo": 4}
	)
	var id_m: int = amb.modulo.maldicao_em_campo(0)
	var m: MaldicaoRef = amb.modulo.ref_de(id_m)
	m.pos = Vector2(400.0, 400.0)

	# Propaga +20% de dano_todo pelo EspelhoDaDupla
	var f_dano := FonteDeModificador.new(&"bencao:forca", [
		Modificador.new(Atributos.DANO_TODO, Modificador.Operacao.PERCENTUAL, 0.20),
	])
	amb.espelho_dupla.fonte_aplicada(0, f_dano)

	var id_in := FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(450.0, 400.0), 300.0)
	assert_bool(id_in != -1).is_true()

	# Vulto Mudo: preparo = 8 passos (entra em PREPARO com timer 7 e dispara após 8 passos)
	for _i in range(12):
		amb.avancar_passo(false)

	assert_int(amb.combate_aliado.golpes_registrados.size()).is_equal(1)
	var g: Dictionary = amb.combate_aliado.golpes_registrados[0]
	# dano_basico = 9.0 * (1 + 0.05) = 9.45; m_maldicao = 1.20 -> 9.45 * 1.20 = 11.34 -> round = 11
	assert_float(float(g["dano_golpe"])).is_equal_approx(9.45, 0.001)
	assert_float(float(g["m_maldicao"])).is_equal_approx(1.20, 0.001)
	assert_int(int(g["dano_int"])).is_equal(11)


func test_ac_ml_08_golpe_maldicao_via_r20_nao_aplica_status_da_lamina_nem_acumula_selo() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"espreitador_da_fenda")
	var id_m: int = amb.modulo.maldicao_em_campo(0)
	var m: MaldicaoRef = amb.modulo.ref_de(id_m)
	m.pos = Vector2(400.0, 400.0)

	var id_in := FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(450.0, 400.0), 300.0)
	for _i in range(12):
		amb.avancar_passo(false)

	assert_int(amb.combate_aliado.golpes_registrados.size()).is_equal(1)
	var g: Dictionary = amb.combate_aliado.golpes_registrados[0]
	assert_array(g["status"]).is_empty()
	assert_str(String(g["ataque_id"])).is_equal("vulto_mudo_basico")
	assert_float(amb.ia.estado_de(id_in).vida).is_equal_approx(291.0, 0.01)


func test_ac_ml_09_abate_por_maldicao_credita_jogador_e_dispara_cura_ao_abater() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"espreitador_da_fenda")
	var id_m: int = amb.modulo.maldicao_em_campo(0)
	amb.modulo.ref_de(id_m).pos = Vector2(400.0, 400.0)

	amb.combate_aliado.vida_jogador = 60
	amb.combate_aliado.vida_max_jogador = 100
	amb.combate_aliado.cura_ao_abater_configurada = 8

	FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(450.0, 400.0), 5.0)
	for _i in range(12):
		amb.avancar_passo(false)

	assert_int(amb.combate_aliado.abates_creditados).is_equal(1)
	assert_int(amb.combate_aliado.vida_jogador).is_equal(68)


func test_ac_ml_21_baluarte_de_cinza_golpe_pesado_interrompe_preparo_de_inimigo_comum() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"baluarte_de_cinza", &"vulto_mudo")
	var id_m: int = amb.modulo.maldicao_em_campo(0)
	amb.modulo.ref_de(id_m).pos = Vector2(400.0, 400.0)

	var id_in := FixtureMaldicoes.nascer_inimigo_padrao(amb, Vector2(460.0, 400.0), 300.0)
	var est_in: EstadoDeInimigoIA = amb.ia.estado_de(id_in)
	est_in.fase = EstadoDeInimigoIA.Fase.PREPARO
	est_in.timer = 40

	# Baluarte: preparo_s = 18/60 = 18 passos
	for _i in range(18):
		amb.avancar_passo(false)

	assert_int(amb.combate_aliado.golpes_registrados.size()).is_equal(1)
	assert_bool(bool(amb.combate_aliado.golpes_registrados[0]["pesado"])).is_true()
	assert_int(int(est_in.fase)).is_equal(int(EstadoDeInimigoIA.Fase.RECUPERACAO))
