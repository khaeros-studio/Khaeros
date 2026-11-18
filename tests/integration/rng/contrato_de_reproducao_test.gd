## Story RNG-005: contrato de reprodução R7 (AC-23, AC-27, AC-28, AC-38) com
## donos e sinks falsos.
extends GdUnitTestSuite

const SEED_REF: int = 0x3F9A07C2
const OUTRA_SEED: int = 0x0000BEEF
const PROFUNDIDADES: int = 5
const JOGADOR: Vector2 = Vector2(100.0, 100.0)
const ESCOLHAS: Array[int] = [0, 1, 2, 0, 1, 2]
const SEM_IA: Array[int] = [0, 0, 0, 0, 0, 0]
const IA_37: Array[int] = [37, 37, 37, 37, 37, 37]
const TROCA_NA_2: Array[int] = [2]
const NENHUMA: Array[int] = []
const ESTRUTURA: Array[int] = [1, 2, 3, 4, 5, 6, 8]
const ESTRUTURA_SEM_BENCAOS: Array[int] = [1, 2, 3, 4, 8]


func _run(fonte: FonteDeFluxos, seed_da_run: int, consumo_ia: Array[int], trocas: Array[int],
		sem_ondas: Array[int], n: int = PROFUNDIDADES) -> RunSimulada:
	fonte.iniciar_run(seed_da_run, false)
	var run := RunSimulada.new(fonte)
	run.jogar(n, consumo_ia, trocas, sem_ondas, ESCOLHAS, JOGADOR)
	return run


func _nova_fonte() -> FonteDeFluxos:
	return FonteDeFluxos.new(RelatorGravadorRng.new())


func test_r7_ia_diferente_mantem_estrutura_e_seed_diferente_muda() -> void:
	var a: RunSimulada = _run(_nova_fonte(), SEED_REF, SEM_IA, TROCA_NA_2, NENHUMA)
	var b: RunSimulada = _run(_nova_fonte(), SEED_REF, IA_37, TROCA_NA_2, NENHUMA)
	for f: int in ESTRUTURA:
		assert_array(b.linhas(f)).override_failure_message("finalidade %d" % f).is_equal(a.linhas(f))
		assert_int(a.linhas(f).size()).is_equal(PROFUNDIDADES)
	var outra: RunSimulada = _run(_nova_fonte(), OUTRA_SEED, SEM_IA, TROCA_NA_2, NENHUMA)
	for f: int in ESTRUTURA:
		assert_array(outra.linhas(f)).is_not_equal(a.linhas(f))


func test_r7_variante_sem_troca_mantem_1_a_4_e_8() -> void:
	var a: RunSimulada = _run(_nova_fonte(), SEED_REF, SEM_IA, TROCA_NA_2, NENHUMA)
	var c: RunSimulada = _run(_nova_fonte(), SEED_REF, SEM_IA, NENHUMA, NENHUMA)
	for f: int in ESTRUTURA_SEM_BENCAOS:
		assert_array(c.linhas(f)).override_failure_message("finalidade %d" % f).is_equal(a.linhas(f))


func test_santuario_sem_ondas_nao_altera_ondas_seguintes() -> void:
	var normal: RunSimulada = _run(_nova_fonte(), SEED_REF, SEM_IA, NENHUMA, NENHUMA)
	var com_santuario: RunSimulada = _run(_nova_fonte(), SEED_REF, SEM_IA, NENHUMA, [3] as Array[int])
	# ondas: normal tem p0..p4; com santuário falta p3 → índice 3 é a p4.
	assert_str(str(com_santuario.linhas(FonteDeFluxos.ONDAS)[3])).is_equal(str(normal.linhas(FonteDeFluxos.ONDAS)[4]))
	assert_str(str(com_santuario.linhas(FonteDeFluxos.ONDAS)[3])).starts_with("p4:")


func test_nova_run_na_mesma_sessao_mesma_seed_reproduz() -> void:
	var fonte: FonteDeFluxos = _nova_fonte()
	var primeira: RunSimulada = _run(fonte, SEED_REF, SEM_IA, TROCA_NA_2, NENHUMA)
	fonte.encerrar_run()
	fonte.descartar_run()
	var segunda: RunSimulada = _run(fonte, SEED_REF, IA_37, TROCA_NA_2, NENHUMA)
	for f: int in ESTRUTURA:
		assert_array(segunda.linhas(f)).is_equal(primeira.linhas(f))


func test_pactos_com_e_sem_encontro_igual_a_lamina_ate_indice_5() -> void:
	var pesos: Array[float] = [1.0, 1.0]
	var logs: Array[RunSimulada] = []
	for caso: int in 3:
		var fonte: FonteDeFluxos = _nova_fonte()
		var pactos: bool = caso < 2
		fonte.iniciar_run(SEED_REF, pactos)
		if pactos:
			var vinculo := DonoVinculoFalso.new(FluxosDeVinculo.new(fonte))
			var encontro: int = vinculo.decidir(0, 0.0, caso == 0, 1, 6, pesos)
			assert_int(encontro).is_equal(1 if caso == 0 else -1)
		var run := RunSimulada.new(fonte)
		run.jogar(6, SEM_IA, NENHUMA, NENHUMA, ESCOLHAS, JOGADOR)
		logs.append(run)
	for f: int in ESTRUTURA:
		assert_array(logs[1].linhas(f)).is_equal(logs[0].linhas(f))
		assert_array(logs[2].linhas(f)).is_equal(logs[0].linhas(f))


func test_sinks_recebem_seis_elementos_no_inicio_fim_e_relatorio() -> void:
	var sink_telemetria: Array[Dictionary] = []
	var sink_relatorio: Array[Dictionary] = []
	var fonte: FonteDeFluxos = _nova_fonte()
	var run: RunSimulada = _run(fonte, SEED_REF, SEM_IA, TROCA_NA_2, NENHUMA)
	var estado := EstadoInicialDaRun.new(fonte.seed(), "0.1.0", "1b4e" + "0".repeat(60), "1B4E",
		&"lamina", &"ressonancia", [&"vida", &"dano"] as Array[StringName], [2, 1] as Array[int])
	sink_telemetria.append(estado.para_inicio_de_run())
	sink_telemetria.append(EstadoInicialDaRun.para_fim_de_run(run.caminho))
	sink_relatorio.append(estado.para_relatorio_de_erro(run.caminho))
	var inicio: Dictionary = sink_telemetria[0]
	assert_int(inicio["seed"]).is_equal(SEED_REF)
	assert_str(inicio["versao"]).is_equal("0.1.0")
	assert_int(str(inicio["impressao"]).length()).is_equal(64)
	var estado_inicial: Dictionary = inicio["estado_inicial"]
	assert_str(estado_inicial["arma"]).is_equal("lamina")
	assert_str(estado_inicial["doutrina"]).is_equal("ressonancia")
	assert_array(estado_inicial["melhorias"]).is_equal([{"id": "vida", "nivel": 2}, {"id": "dano", "nivel": 1}])
	var caminho: Dictionary = sink_telemetria[1]["caminho"]
	assert_int((caminho["escolhas"] as Array).size()).is_equal(PROFUNDIDADES * 2)
	assert_array(caminho["trocas"]).is_equal([{"profundidade": 2}])
	var relatorio: Dictionary = sink_relatorio[0]
	for chave: String in ["seed", "versao", "impressao", "estado_inicial", "caminho"]:
		assert_bool(relatorio.has(chave)).override_failure_message(chave).is_true()
