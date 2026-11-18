extends GdUnitTestSuite


func test_ac_ml_14_regenera_4_porcento_por_segundo_na_reserva_pronta_com_acumulador_fracionario() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"espreitador_da_fenda", &"vulto_mudo")
	# Vulto Mudo na reserva tem 110 PV max; 5% de 110 = 5,5 PV/s -> 5 PV em 60 passos e +6 PV nos 60 seguintes (total +11 em 2 s)
	var m_res: MaldicaoRef = amb.modulo.ref_de(2)
	m_res.vida = 80

	for _i in range(60):
		amb.avancar_passo(false)
	assert_int(m_res.vida).is_equal(85)

	for _i in range(60):
		amb.avancar_passo(false)
	assert_int(m_res.vida).is_equal(91)


func test_recuperacao_exaustao_suporta_10s_600_passos_e_12s_720_passos_via_tuning() -> void:
	var tuning_12s := CatalogoMaldicoes.tuning_de_fabrica()
	tuning_12s.recuperacao_exausta_s = 12.0
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"espreitador_da_fenda", tuning_12s)

	var id_vulto: int = amb.modulo.maldicao_em_campo(0)
	amb.modulo.ferir_maldicao(id_vulto, 250.0, 1.0)
	assert_int(amb.modulo.estado_pacto(0).reserva.restante_exausta).is_equal(720)

	for _i in range(719):
		amb.avancar_passo(false)
	assert_str(String(amb.modulo.estado_pacto(0).reserva.estado)).is_equal("Exausta")

	amb.avancar_passo(false)
	assert_str(String(amb.modulo.estado_pacto(0).reserva.estado)).is_equal("Pronta")
	assert_int(amb.modulo.estado_pacto(0).reserva.vida).is_equal(55)


func test_ac_ml_20_espelho_da_dupla_propaga_dano_e_velocidade_sem_propagar_gatilhos() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"espreitador_da_fenda")
	var m_ativa: MaldicaoRef = amb.modulo.ref_de(1)
	var m_reserva: MaldicaoRef = amb.modulo.ref_de(2)

	var fonte_bencao := FonteDeModificador.new(&"elo:dupla_forte", [
		Modificador.new(Atributos.DANO_TODO, Modificador.Operacao.PERCENTUAL, 0.25),
		Modificador.new(Atributos.VELOCIDADE, Modificador.Operacao.PERCENTUAL, 0.10),
	])
	amb.espelho_dupla.fonte_aplicada(0, fonte_bencao)

	assert_float(m_ativa.multiplicador_dano()).is_equal_approx(1.25, 0.001)
	assert_float(m_reserva.multiplicador_dano()).is_equal_approx(1.25, 0.001)
	assert_float(m_ativa.velocidade_pxs()).is_equal_approx(405.0 * 1.10, 0.01)


func test_ac_ml_33_acrescentar_a_dupla_no_meio_da_run_com_vida_proporcional_da_acuada() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(&"vulto_mudo", &"")
	assert_object(amb.modulo.estado_pacto(0).reserva).is_null()

	# Acuada salva com 75% de vida (45 / 60): Baluarte de Cinza (140 PV max) entra na reserva Pronta
	var nova: MaldicaoRef = amb.modulo.acrescentar_a_dupla(
		0,
		CatalogoMaldicoes.baluarte_de_cinza(),
		45.0,
		2
	)
	assert_object(nova).is_not_null()
	assert_str(String(amb.modulo.estado_pacto(0).reserva.especie_id)).is_equal("baluarte_de_cinza")
	assert_str(String(amb.modulo.estado_pacto(0).reserva.estado)).is_equal("Pronta")
	assert_bool(amb.modulo.estado_pacto(0).troca_disponivel).is_true()


func test_ac_ml_34_niveis_de_vinculo_2_3_4_aplicam_vida_recuperacao_e_dano_basico() -> void:
	var amb := FixtureMaldicoes.criar_ambiente(
		&"vulto_mudo",
		&"espreitador_da_fenda",
		null,
		{&"vulto_mudo": 4}
	)
	var m: MaldicaoRef = amb.modulo.ref_de(1)
	# Nível >= 2: +5% vida_max -> round(110 * 1.05) = 116
	assert_int(m.vida_max()).is_equal(116)
	# Nível >= 3: mult_recuperacao_vinculo = 0.90 (540 passos de exaustão)
	assert_float(m.mult_recuperacao_vinculo).is_equal_approx(0.90, 0.001)
	# Nível >= 4: bonus_dano_basico_vinculo = +0.05
	assert_float(m.bonus_dano_basico_vinculo).is_equal_approx(0.05, 0.001)
