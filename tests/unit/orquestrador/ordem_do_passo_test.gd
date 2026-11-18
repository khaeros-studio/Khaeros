## Testes da ordem fixa do passo vivo, hitstop e passo fora de JOGO
## (ADR-0001 e emenda Pactos; story orquestrador-do-passo/004). Módulos falsos registram a ordem.
extends GdUnitTestSuite

const Dubles := preload("res://tests/unit/orquestrador/dubles_do_orquestrador.gd")
const E := EstadoDeJogo.Valor
const DT_MAX_FIXTURE: float = 0.1


func _montar() -> Dubles.Montagem:
	return Dubles.Montagem.new(DT_MAX_FIXTURE)


func test_ordem_do_passo_lista_unica_igual_a_do_adr() -> void:
	# Lista do ADR-0001 (emenda 2026-11-16): 1, 3, 4, 5, 6, 6.1, 7, 8, 9, 10
	var adr: Array[StringName] = [&"input", &"combate_inicio", &"movimento", &"combate_golpe", &"selo",
			&"maldicoes", &"inimigos", &"projeteis", &"mortes", &"camaras"]

	assert_array(OrdemDoPasso.itens()).is_equal(adr)
	assert_array(OrdemDoPasso.modulos()).is_equal(adr.slice(1))


func test_passo_vivo_chama_itens_na_ordem_exata_uma_vez_cada() -> void:
	var m := _montar()
	m.levar_a(E.JOGO)

	m.orq.passo_fisico()

	assert_array(m.diario).is_equal(OrdemDoPasso.itens())
	for chave: StringName in OrdemDoPasso.itens():
		assert_int(m.diario.count(chave)).override_failure_message(String(chave)).is_equal(1)
	assert_int(m.hitstop.consultas).is_equal(1)


func test_passo_vivo_todos_os_modulos_recebem_a_mesma_amostra() -> void:
	var m := _montar()
	m.levar_a(E.JOGO)

	m.orq.passo_fisico()

	var primeira: AmostraDeEntrada = m.modulo(OrdemDoPasso.COMBATE_INICIO).amostras[0]
	for chave: StringName in OrdemDoPasso.modulos():
		assert_object(m.modulo(chave).amostras[0]).is_same(primeira)


func test_fora_de_jogo_so_passo_congelado_do_movimento() -> void:
	for estado: EstadoDeJogo.Valor in [E.MENU, E.PAUSA, E.BENCAO, E.TRANSICAO, E.MORTE]:
		var m := _montar()
		m.levar_a(estado)

		m.orq.passo_fisico()

		var esperado: Array[StringName] = [OrdemDoPasso.INPUT, &"movimento:congelado"]
		assert_array(m.diario).override_failure_message(EstadoDeJogo.nome(estado)).is_equal(esperado)
		assert_int(m.hitstop.consultas).is_equal(0)


func test_hitstop_ativo_combate_desconta_e_movimento_congela_sem_maldicoes_nem_camaras() -> void:
	var m := _montar()
	m.levar_a(E.JOGO)
	m.hitstop.pedir(1)

	m.orq.passo_fisico()

	var esperado: Array[StringName] = [OrdemDoPasso.INPUT, Dubles.HitstopFalso.DESCONTO, &"movimento:congelado"]
	assert_array(m.diario).is_equal(esperado)
	assert_bool(m.diario.has(OrdemDoPasso.MALDICOES)).is_false()
	assert_bool(m.diario.has(OrdemDoPasso.CAMARAS)).is_false()


func test_hitstop_pendente_nao_desconta_no_passo_do_pedido() -> void:
	# Arrange — o golpe (item 5) pede hitstop de 2 passos
	var m := _montar()
	m.levar_a(E.JOGO)
	m.modulo(OrdemDoPasso.COMBATE_GOLPE).acao = func() -> void:
		m.hitstop.pedir(2)

	# Act
	m.orq.passo_fisico()

	# Assert — passo inteiro roda (itens 7-10 inclusive), nada descontado
	assert_array(m.diario).is_equal(OrdemDoPasso.itens())
	assert_int(m.hitstop.restante).is_equal(0)
	assert_int(m.hitstop.pedido).is_equal(2)


func test_camara_limpa_avaliada_so_com_hitstop_inativo() -> void:
	var m := _montar()
	m.levar_a(E.JOGO)
	var hitstop_na_avaliacao: Array[bool] = []
	m.modulo(OrdemDoPasso.CAMARAS).acao = func() -> void:
		hitstop_na_avaliacao.append(m.hitstop.restante > 0)
	m.hitstop.pedir(3)

	m.passos(5)

	assert_array(hitstop_na_avaliacao).is_equal([false, false])


func test_passo_vivo_finaliza_vivo_e_hitstop_finaliza_nao_vivo_contando_em_jogo() -> void:
	var m := _montar()
	m.levar_a(E.JOGO)

	m.orq.passo_fisico()
	assert_int(m.orq.n_vivos()).is_equal(1)
	assert_int(m.orq.passos_em_jogo()).is_equal(1)

	m.hitstop.pedir(1)
	m.orq.passo_fisico()
	assert_int(m.orq.n_vivos()).is_equal(1)
	assert_int(m.orq.passos_em_jogo()).is_equal(2)
	assert_int(m.consumidor.entregas.size()).is_equal(2)


func test_configurar_passo_modulo_ausente_devolve_chave_e_nao_configura() -> void:
	var m := _montar()
	var modulos: Dictionary[StringName, Passo] = m.modulos.duplicate()
	modulos.erase(OrdemDoPasso.MALDICOES)
	var orq := OrquestradorDoPasso.new(EventosDoPasso.new())

	var ausentes := orq.configurar_passo(m.fonte, m.hitstop, modulos)

	assert_array(Array(ausentes)).is_equal([String(OrdemDoPasso.MALDICOES)])
