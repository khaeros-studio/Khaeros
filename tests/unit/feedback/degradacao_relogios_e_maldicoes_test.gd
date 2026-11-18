class_name DegradacaoRelogiosEMaldicoesTest
extends GdUnitTestSuite
## Testes unitários de `DegradacaoDeVfx`, `RespostasVivas` e respostas das Maldições (story-005 a story-008).


func test_histerese_de_degradacao_e_corte_no_teto_preservando_p0_e_p1() -> void:
	var deg: DegradacaoDeVfx = DegradacaoDeVfx.new(FeedbackTuning.new())
	deg.iniciar_passo(0.50)
	assert_that(deg.nivel_atual()).is_equal(0)

	deg.iniciar_passo(0.91)
	assert_that(deg.nivel_atual()).is_equal(1)
	assert_that(deg.aceita_vfx(4, false)).is_false()
	assert_that(deg.aceita_vfx(3, false)).is_true()

	# Continua no nível 1 em 0.80 por histerese (sair_nivel_1 = 0.75)
	deg.iniciar_passo(0.80)
	assert_that(deg.nivel_atual()).is_equal(1)

	deg.iniciar_passo(0.96)
	assert_that(deg.nivel_atual()).is_equal(2)
	assert_that(deg.aceita_vfx(3, false)).is_false()
	assert_that(deg.aceita_vfx(1, false)).is_true()

	# Em uso >= 1.0, corta P4 -> P3 -> P2 e nunca corta P0/P1
	deg.iniciar_passo(1.02)
	var ativos: Array[PedidosDeFeedback.PedidoVfx] = [
		PedidosDeFeedback.PedidoVfx.new(&"recusou_morte", 1, Vector2.ZERO, Color.WHITE, 0),
		PedidosDeFeedback.PedidoVfx.new(&"golpe_pesado", 2, Vector2.ZERO, Color.WHITE, 1),
		PedidosDeFeedback.PedidoVfx.new(&"golpe_leve", 3, Vector2.ZERO, Color.WHITE, 2),
		PedidosDeFeedback.PedidoVfx.new(&"tick_status", 4, Vector2.ZERO, Color.WHITE, 3),
	]
	var cortados: int = deg.cortar_ativos_no_teto(ativos, 3)
	assert_that(cortados).is_equal(2)
	assert_that(ativos.size()).is_equal(2)
	assert_that(ativos[0].prioridade).is_equal(0)
	assert_that(ativos[1].prioridade).is_equal(1)


func test_relogios_hitstop_bencao_transicao_flash_maldicao_e_marca_virote() -> void:
	var arbitro: ArbitroDeFeedback = ArbitroDeFeedback.new()
	var vivas: RespostasVivas = arbitro.respostas_vivas()
	var pool_num: PoolDeNumeros = arbitro.pool_numeros()

	# Marca do Virote é única e muda de alvo
	arbitro.processar_descritores([
		{"id": &"virote_marcou", "alvo_id": 100},
		{"id": &"virote_marcou", "alvo_id": 200},
		{"id": &"golpe_leve", "alvo_id": 200, "dano": 18},
	])
	assert_that(vivas.alvo_marca_virote_id()).is_equal(200)
	assert_that(pool_num.quantidade_ativa()).is_equal(1)

	# Limite de flash de maldicao_atingida: 1 a cada 20 passos vivos
	assert_that(vivas.pode_emitir_flash_maldicao(7)).is_true()
	assert_that(vivas.pode_emitir_flash_maldicao(7)).is_false()
	for i: int in range(20):
		vivas.avancar_relogios(1.0 / 60.0, 1.0 / 60.0, false, EstadoDeJogo.Valor.JOGO, null)
	assert_that(vivas.pode_emitir_flash_maldicao(7)).is_true()

	# Na BENCAO, números somem e não voltam
	vivas.avancar_relogios(0.0, 1.0 / 60.0, false, EstadoDeJogo.Valor.BENCAO, pool_num)
	assert_that(pool_num.quantidade_ativa()).is_equal(0)

	# Na TRANSICAO, marca do Virote e VFX ativos são descartados
	vivas.avancar_relogios(0.0, 1.0 / 60.0, false, EstadoDeJogo.Valor.TRANSICAO, pool_num)
	assert_that(vivas.alvo_marca_virote_id()).is_equal(-1)
	assert_that(vivas.vfx_ativos().is_empty()).is_true()
	assert_that(PoolDeVfx.calcular_limite_sinais_status_por_inimigo(12)).is_equal(1)
	assert_that(PoolDeVfx.calcular_limite_sinais_status_por_inimigo(5)).is_equal(3)
