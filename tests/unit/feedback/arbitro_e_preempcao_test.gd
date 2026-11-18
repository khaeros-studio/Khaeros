class_name ArbitroEPreempcaoTest
extends GdUnitTestSuite
## Testes unitários do `ArbitroDeFeedback`, `SeletorDeImpulso` e preempção (story-002 e story-003).


func test_seletor_de_impulso_envia_no_maximo_um_pedido_por_passo_com_preempcao() -> void:
	var arbitro: ArbitroDeFeedback = ArbitroDeFeedback.new()
	var saida: PedidosDeFeedback.SaidaDoArbitro = arbitro.processar_descritores([
		{"id": &"golpe_leve", "alvo_id": 10, "dano": 12, "direcao": Vector2.RIGHT},
		{"id": &"jogador_atingido", "alvo_id": 1, "dano": 20, "direcao": Vector2.LEFT},
		{"id": &"recusou_morte", "alvo_id": 1, "direcao": Vector2.UP},
	], 0.2, 1, 0.5)

	assert_that(saida.pedido_impulso != null).is_true()
	assert_that(saida.pedido_impulso.preset).is_equal(&"chefe")
	assert_that(saida.pedido_impulso.escala).is_equal_approx(1.0, 0.001)


func test_opcoes_intensidade_tremor_e_reduzir_flashes_filtram_impulso_e_impact_frame() -> void:
	var arbitro: ArbitroDeFeedback = ArbitroDeFeedback.new()
	arbitro.configurar_acessibilidade(0.0, true, &"ligado", true)

	var saida: PedidosDeFeedback.SaidaDoArbitro = arbitro.processar_descritores([
		{"id": &"recusou_morte", "alvo_id": 1},
		{"id": &"telegrafo_disparou", "slot_telegrafo": 2, "area_norm": 0.15},
	])

	assert_that(saida.pedido_impulso == null).is_true()
	assert_that(saida.pedido_impacto == null).is_true()
	assert_that(saida.flashes_telegrafo.size()).is_equal(1)
	assert_that(saida.flashes_telegrafo[0].flash_permitido).is_false()
	# O gancho de áudio P0 continua sendo emitido mesmo com flashes/tremor desligados
	assert_that(saida.pedidos_som.size()).is_equal(2)
