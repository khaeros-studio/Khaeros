class_name StatusTickEMorteTest
extends GdUnitTestSuite
## Testes das Stories 002 e 003 (`efeitos-de-status`): tick periódico silencioso no item 7,
## ordem Sangramento -> Queimadura, expiração em 240/180 passos, morte por status no meio do tick,
## limpeza ao morrer/trocar de câmara e congelamento em hitstop/pausa (`AC-ST-06, 08, 12..16, 24, 25`).


func test_ac_st_06_08_expiracao_zera_acumulos_em_240_e_180_passos() -> void:
	var estado_vida := [500.0]
	var m := ModuloDeStatus.new()
	m.registrar_combatente(201, &"inimigo")
	m.configurar_callbacks(func(_id: int, dp: float) -> bool:
		estado_vida[0] -= dp
		return float(estado_vida[0]) <= 0.0
	)

	m.aplicar_status(201, &"sangramento", 5.0)
	for _i in range(240):
		m.tick(201)
	assert_int(m.estado(201)[&"sangramento"][&"restante"]).is_equal(0)
	assert_int(m.estado(201)[&"sangramento"][&"acumulos"]).is_equal(0)
	# 5 acúmulos * 2,4/s * 4s = 48,0 de dano total exato
	assert_float(500.0 - float(estado_vida[0])).is_equal_approx(48.0, 0.001)

	# Novo acúmulo depois de expirar começa em 1 (não em 6)
	m.aplicar_status(201, &"sangramento", 1.0)
	assert_int(m.estado(201)[&"sangramento"][&"acumulos"]).is_equal(1)


func test_ac_st_12_13_14_dano_silencioso_sem_reducao_dano_e_sem_gatilhos() -> void:
	var estado_vida := [100.0]
	var gatilhos_disparados: int = 0
	var fluxo_ganho: float = 0.0
	var hitstop_passos: int = 0

	var mod_tuning := ModifiersTuning.new()
	mod_tuning.teto_multiplicador_dano = 4.0
	mod_tuning.teto_reducao_dano = 0.6
	var portador := Portador.new(202, -1, Atributos.Especie.INIMIGO,
			{Atributos.VIDA_MAX: 100.0, Atributos.REDUCAO_DANO: 0.50}, mod_tuning)

	var m := ModuloDeStatus.new()
	m.registrar_combatente(202, &"inimigo", portador)
	m.configurar_callbacks(func(_id: int, dp: float) -> bool:
		# Dano silencioso: não consulta reducao_dano, não gera hitstop/fluxo/gatilhos
		estado_vida[0] -= dp
		return float(estado_vida[0]) <= 0.0
	)

	# 10 acúmulos de sangramento por 60 passos (1 s) = 24,0 de dano exato mesmo com reducao_dano = 0.50
	m.aplicar_status(202, &"sangramento", 10.0)
	for _i in range(60):
		m.tick(202)

	assert_float(100.0 - float(estado_vida[0])).is_equal_approx(24.0, 0.001)
	assert_int(gatilhos_disparados).is_equal(0)
	assert_float(fluxo_ganho).is_equal(0.0)
	assert_int(hitstop_passos).is_equal(0)


func test_ac_st_15_16_25_morte_no_sangramento_interrompe_queimadura_e_limpa_sem_numero() -> void:
	var estado := {"vida": 0.20, "chamadas": 0}
	var m := ModuloDeStatus.new()
	m.registrar_combatente(203, &"inimigo")
	m.configurar_callbacks(func(_id: int, dp: float) -> bool:
		estado["chamadas"] = int(estado["chamadas"]) + 1
		estado["vida"] = float(estado["vida"]) - dp
		return float(estado["vida"]) <= 0.0
	)

	# 10 acúmulos de sangramento = 0,40 de dano por passo (> 0,20 vida restante)
	m.aplicar_status(203, &"sangramento", 10.0)
	m.aplicar_status(203, &"queimadura", 6.0)
	m.aplicar_status(203, &"abalo", 1.0)

	m.tick(203)

	# Morreu no sub-passo de sangramento: queimadura não rodou (apenas 1 chamada de dano),
	# estado foi limpo e nenhum EvNumeroDeStatus foi emitido.
	assert_int(int(estado["chamadas"])).is_equal(1)
	assert_int(m.estado(203)[&"sangramento"][&"restante"]).is_equal(0)
	assert_int(m.estado(203)[&"queimadura"][&"restante"]).is_equal(0)
	assert_bool(m.estado(203)[&"abalo"][&"ativo"]).is_false()
	assert_int(m.drenar_eventos().size()).is_equal(0)


func test_ac_st_24_passo_congelado_nao_avanca_duracao_nem_aplica_dano() -> void:
	var estado_vida := [100.0]
	var m := ModuloDeStatus.new()
	m.registrar_combatente(204, &"inimigo")
	m.configurar_callbacks(func(_id: int, dp: float) -> bool:
		estado_vida[0] -= dp
		return float(estado_vida[0]) <= 0.0
	)

	m.aplicar_status(204, &"sangramento", 4.0)
	for _i in range(10):
		m.passo_congelado()

	assert_float(float(estado_vida[0])).is_equal(100.0)
	assert_int(m.estado(204)[&"sangramento"][&"restante"]).is_equal(240)
