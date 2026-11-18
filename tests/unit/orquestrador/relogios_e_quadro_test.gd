## Testes dos relógios t_vivo/t_apres, quadro() e troca de câmara em seis ações
## (ADR-0001; story orquestrador-do-passo/005). Pipeline e ações são dublês.
extends GdUnitTestSuite

const Dubles := preload("res://tests/unit/orquestrador/dubles_do_orquestrador.gd")
const E := EstadoDeJogo.Valor
const DT_MAX_FIXTURE: float = 0.1
const DELTA_QUADRO: float = 0.02
const DELTA_LONGO: float = 1.0
const WIPE_ANTES_DA_METADE: float = 0.49
const WIPE_METADE: float = 0.5
const WIPE_DEPOIS: float = 0.7
const WIPE_FIM: float = 1.0


func _montar() -> Dubles.Montagem:
	return Dubles.Montagem.new(DT_MAX_FIXTURE)


## Leva à Transição a partir de JOGO, com passos vivos e t_apres acumulados.
func _em_transicao_com_relogios(m: Dubles.Montagem) -> void:
	m.levar_a(E.JOGO)
	m.passos(30)
	m.orq.quadro(DELTA_QUADRO)
	m.modulo(OrdemDoPasso.CAMARAS).acao = func() -> void:
		m.orq.pedir_estado(E.TRANSICAO)
	m.orq.passo_fisico()
	m.modulo(OrdemDoPasso.CAMARAS).acao = Callable()


func test_troca_seis_acoes_em_ordem_uma_vez_no_primeiro_quadro_com_metade() -> void:
	var m := _montar()
	_em_transicao_com_relogios(m)

	m.pipeline.progresso = WIPE_ANTES_DA_METADE
	m.orq.quadro(DELTA_QUADRO)
	assert_array(m.diario_acoes).is_empty()

	m.pipeline.progresso = WIPE_METADE
	m.orq.quadro(DELTA_QUADRO)
	assert_array(m.diario_acoes).is_equal(m.nomes_acoes)

	m.pipeline.progresso = WIPE_DEPOIS
	m.orq.quadro(DELTA_QUADRO)
	m.orq.quadro(DELTA_QUADRO)
	assert_array(m.diario_acoes).is_equal(m.nomes_acoes)


func test_t_apres_avanca_com_teto_em_jogo_transicao_e_morte() -> void:
	for estado: EstadoDeJogo.Valor in [E.JOGO, E.TRANSICAO, E.MORTE]:
		var m := _montar()
		m.levar_a(estado)

		m.orq.quadro(DELTA_LONGO)

		assert_float(m.orq.t_apres()).override_failure_message(EstadoDeJogo.nome(estado)).is_equal(DT_MAX_FIXTURE)
		m.orq.quadro(DELTA_QUADRO)
		assert_float(m.orq.t_apres()).is_equal_approx(DT_MAX_FIXTURE + DELTA_QUADRO, 1e-9)


func test_t_apres_parado_em_pausa_e_bencao() -> void:
	for estado: EstadoDeJogo.Valor in [E.PAUSA, E.BENCAO]:
		var m := _montar()
		m.levar_a(estado)

		m.orq.quadro(DELTA_QUADRO)

		assert_float(m.orq.t_apres()).override_failure_message(EstadoDeJogo.nome(estado)).is_equal(0.0)


func test_relogios_zeram_na_troca_e_nao_no_pedido_passos_em_jogo_permanece() -> void:
	var m := _montar()
	_em_transicao_com_relogios(m)
	var passos := m.orq.passos_em_jogo()

	# no pedido de TRANSICAO nada zera
	assert_int(m.orq.n_vivos()).is_equal(31)
	assert_float(m.orq.t_apres()).is_greater(0.0)

	m.pipeline.progresso = WIPE_METADE
	m.orq.quadro(DELTA_QUADRO)

	assert_int(m.orq.n_vivos()).is_equal(0)
	assert_float(m.orq.t_vivo()).is_equal(0.0)
	assert_float(m.orq.t_apres()).is_equal(0.0)
	assert_int(m.orq.passos_em_jogo()).is_equal(passos)


func test_quadro_com_zero_ou_tres_passos_nao_altera_passos_executados() -> void:
	var m := _montar()
	m.levar_a(E.JOGO)

	m.orq.quadro(DELTA_QUADRO)
	m.orq.quadro(DELTA_QUADRO)
	assert_int(m.orq.passos_em_jogo()).is_equal(0)
	assert_int(m.fonte.chamadas).is_equal(0)

	m.passos(3)
	m.orq.quadro(DELTA_QUADRO)
	assert_int(m.orq.passos_em_jogo()).is_equal(3)
	assert_int(m.orq.n_vivos()).is_equal(3)
	assert_int(m.fonte.chamadas).is_equal(3)


func test_quadro_entrega_relogios_ao_pipeline_todo_quadro() -> void:
	var m := _montar()
	m.levar_a(E.JOGO)
	m.passos(6)

	m.orq.quadro(DELTA_QUADRO)
	m.orq.quadro(DELTA_QUADRO)

	assert_int(m.pipeline.recebidos.size()).is_equal(2)
	assert_float(m.pipeline.recebidos[1].x).is_equal_approx(6 / 60.0, 1e-6)
	assert_float(m.pipeline.recebidos[1].y).is_equal_approx(2 * DELTA_QUADRO, 1e-6)


func test_fim_do_wipe_pede_jogo_depois_da_troca() -> void:
	var m := _montar()
	_em_transicao_com_relogios(m)
	m.pipeline.progresso = WIPE_METADE
	m.orq.quadro(DELTA_QUADRO)
	assert_int(m.orq.estado()).is_equal(E.TRANSICAO)

	m.pipeline.progresso = WIPE_FIM
	m.orq.quadro(DELTA_QUADRO)

	assert_int(m.orq.estado()).is_equal(E.JOGO)


func test_configurar_quadro_sem_seis_acoes_devolve_false() -> void:
	var m := _montar()
	var orq := OrquestradorDoPasso.new(EventosDoPasso.new())
	var cinco: Array[AcaoDeTroca] = m.acoes.slice(0, 5)

	assert_bool(orq.configurar_quadro(m.pipeline, cinco, DT_MAX_FIXTURE)).is_false()
	assert_bool(orq.configurar_quadro(m.pipeline, m.acoes, DT_MAX_FIXTURE)).is_true()
