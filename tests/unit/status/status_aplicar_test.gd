class_name StatusAplicarTest
extends GdUnitTestSuite
## Testes da Story 001 (`efeitos-de-status`): modelo e aplicação (`aplicar_status`),
## tetos de acúmulos, renovação de duração, teto ilimitado (`max_acumulos_sangramento = 0`),
## recusa de status desconhecido e recusa no jogador/Maldição (`AC-ST-01..05, 07, 26-R10`).


func test_ac_st_01_02_03_sangramento_acumula_renova_e_respeita_teto_10() -> void:
	var m := ModuloDeStatus.new()
	m.registrar_combatente(101, &"inimigo")

	# AC-ST-01: 1 acúmulo -> 240 passos
	assert_bool(m.aplicar_status(101, &"sangramento", 1.0)).is_true()
	var est1 := m.estado(101)
	assert_float(float(est1[&"sangramento"][&"acumulos"])).is_equal_approx(1.0, 0.0001)
	assert_int(est1[&"sangramento"][&"restante"]).is_equal(240)

	# Avança 60 passos -> restante 180
	for _i in range(60):
		m.tick(101)
	assert_int(m.estado(101)[&"sangramento"][&"restante"]).is_equal(180)

	# AC-ST-02: novo acúmulo -> acumulos 2, restante renovado para 240
	assert_bool(m.aplicar_status(101, &"sangramento", 1.0)).is_true()
	var est2 := m.estado(101)
	assert_float(float(est2[&"sangramento"][&"acumulos"])).is_equal_approx(2.0, 0.0001)
	assert_int(est2[&"sangramento"][&"restante"]).is_equal(240)

	# AC-ST-03: 15 acúmulos no teto 10 -> crava em 10 e renova duração para 240
	for _i in range(30):
		m.tick(101)
	assert_bool(m.aplicar_status(101, &"sangramento", 15.0)).is_true()
	var est3 := m.estado(101)
	assert_float(float(est3[&"sangramento"][&"acumulos"])).is_equal_approx(10.0, 0.0001)
	assert_int(est3[&"sangramento"][&"restante"]).is_equal(240)

	# AC-ST-05: acúmulo fracionário n = 0,5 -> Vida 1000,0 vira 995,2 após 240 passos
	var estado_vida := [1000.0]
	var mf := ModuloDeStatus.new()
	mf.registrar_combatente(109, &"inimigo")
	mf.configurar_callbacks(func(_id: int, dp: float) -> bool:
		estado_vida[0] -= dp
		return float(estado_vida[0]) <= 0.0
	)
	mf.aplicar_status(109, &"sangramento", 0.5)
	for _i in range(240):
		mf.tick(109)
	assert_float(float(estado_vida[0])).is_equal_approx(995.2, 0.0001)


func test_ac_st_04_sangramento_sem_teto_quando_max_acumulos_zero() -> void:
	var t := ValidadorStatus.fabrica()
	t.max_acumulos_sangramento = 0
	var m := ModuloDeStatus.new(t)
	m.registrar_combatente(102, &"inimigo")

	for _i in range(15):
		m.aplicar_status(102, &"sangramento", 1.0)
	assert_int(m.estado(102)[&"sangramento"][&"acumulos"]).is_equal(15)


func test_ac_st_05_queimadura_respeita_teto_6_e_renova_para_180() -> void:
	var m := ModuloDeStatus.new()
	m.registrar_combatente(103, &"inimigo")

	m.aplicar_status(103, &"queimadura", 2.0)
	for _i in range(40):
		m.tick(103)
	assert_int(m.estado(103)[&"queimadura"][&"restante"]).is_equal(140)

	m.aplicar_status(103, &"queimadura", 6.0)
	var est := m.estado(103)
	assert_int(est[&"queimadura"][&"acumulos"]).is_equal(6)
	assert_int(est[&"queimadura"][&"restante"]).is_equal(180)


func test_ac_st_07_coexistencia_independente_dos_tres_status() -> void:
	var m := ModuloDeStatus.new()
	m.registrar_combatente(104, &"inimigo")

	m.aplicar_status(104, &"sangramento", 3.0)
	m.aplicar_status(104, &"queimadura", 2.0)
	m.aplicar_status(104, &"abalo", 1.0)

	# Após 180 passos, queimadura expira, mas sangramento (restante 60) e abalo (restante 60) seguem ativos
	for _i in range(180):
		m.tick(104)
	var est := m.estado(104)
	assert_int(est[&"queimadura"][&"acumulos"]).is_equal(0)
	assert_int(est[&"queimadura"][&"restante"]).is_equal(0)
	assert_int(est[&"sangramento"][&"acumulos"]).is_equal(3)
	assert_int(est[&"sangramento"][&"restante"]).is_equal(60)
	assert_bool(est[&"abalo"][&"ativo"]).is_true()
	assert_int(est[&"abalo"][&"restante"]).is_equal(60)


func test_ac_st_26_r10_recusa_status_desconhecido_e_recusa_jogador_ou_maldicao() -> void:
	var relator := RelatorAcumulador.new()
	var m := ModuloDeStatus.new(null, relator)
	m.registrar_combatente(1, &"jogador")
	m.registrar_combatente(2, &"maldicao")
	m.registrar_combatente(105, &"inimigo")

	# Status desconhecido -> aviso no relator, sem alterar estado
	assert_bool(m.aplicar_status(105, &"veneno", 2.0)).is_false()
	assert_int(relator.entradas.size()).is_equal(1)

	# Jogador e Maldição aliada nunca recebem status (R10)
	assert_bool(m.aplicar_status(1, &"sangramento", 3.0)).is_false()
	assert_bool(m.aplicar_status(2, &"queimadura", 2.0)).is_false()
	assert_int(m.estado(1)[&"sangramento"][&"acumulos"]).is_equal(0)
	assert_int(m.estado(2)[&"queimadura"][&"acumulos"]).is_equal(0)

	# Inimigo não-alvejável (surgindo/morto) ou n <= 0 é ignorado
	m.definir_alvejavel(105, false)
	assert_bool(m.aplicar_status(105, &"sangramento", 1.0)).is_false()
	m.definir_alvejavel(105, true)
	assert_bool(m.aplicar_status(105, &"sangramento", 0.0)).is_false()
