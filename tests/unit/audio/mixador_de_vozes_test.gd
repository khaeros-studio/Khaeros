class_name MixadorDeVozesTest
extends GdUnitTestSuite
## Testes unitários do `MixadorDeVozes` (`F4` / `R9`, ADR-0016 §2, story-002).


func test_deduplicacao_no_mesmo_passo_preserva_maior_prioridade() -> void:
	var mix: MixadorDeVozes = MixadorDeVozes.new(4, 16)
	var pedidos: Array[PedidoDeSom] = [
		PedidoDeSom.new(&"sfx_acerto", 3),
		PedidoDeSom.new(&"sfx_acerto", 1),
		PedidoDeSom.new(&"sfx_esquiva", 2),
	]
	var saida: Array[ComandoDeVoz] = []
	var n: int = mix.resolver(pedidos, saida)
	assert_that(n).is_equal(2)
	assert_that(saida[0].gancho).is_equal(&"sfx_acerto")
	assert_that(saida[0].prioridade).is_equal(1)
	assert_that(saida[1].gancho).is_equal(&"sfx_esquiva")


func test_teto_por_gancho_rouba_a_voz_mais_antiga_do_mesmo_gancho() -> void:
	var mix: MixadorDeVozes = MixadorDeVozes.new(4, 16)
	var saida: Array[ComandoDeVoz] = []
	for i: int in range(4):
		var p: Array[PedidoDeSom] = [PedidoDeSom.new(&"sfx_virote", 2)]
		mix.resolver(p, saida)
		assert_that(saida[0].slot).is_equal(i)
		assert_that(saida[0].parar_antes).is_false()

	assert_that(mix.vozes_ativas_do_gancho(&"sfx_virote")).is_equal(4)

	# 5º pedido do mesmo gancho deve roubar o slot 0 (o mais antigo desse gancho)
	var quinto: Array[PedidoDeSom] = [PedidoDeSom.new(&"sfx_virote", 2)]
	mix.resolver(quinto, saida)
	assert_that(saida.size()).is_equal(1)
	assert_that(saida[0].slot).is_equal(0)
	assert_that(saida[0].parar_antes).is_true()
	assert_that(mix.vozes_ativas_do_gancho(&"sfx_virote")).is_equal(4)


func test_roubo_da_voz_mais_antiga_de_menor_prioridade_e_imunidade_p0() -> void:
	var mix: MixadorDeVozes = MixadorDeVozes.new(4, 4)
	var saida: Array[ComandoDeVoz] = []

	# Preenche 4 slots: slot 0 (P0), slot 1 (P2), slot 2 (P3 mais antigo), slot 3 (P3 mais novo)
	mix.resolver([PedidoDeSom.new(&"sfx_morte", 0)], saida)
	mix.resolver([PedidoDeSom.new(&"sfx_golpe", 2)], saida)
	mix.resolver([PedidoDeSom.new(&"sfx_passo_a", 3)], saida)
	mix.resolver([PedidoDeSom.new(&"sfx_passo_b", 3)], saida)

	# Novo P1 deve roubar slot 2 (P3 mais antigo)
	mix.resolver([PedidoDeSom.new(&"sfx_chefe", 1)], saida)
	assert_that(saida.size()).is_equal(1)
	assert_that(saida[0].slot).is_equal(2)
	assert_that(saida[0].parar_antes).is_true()

	# Se todos os 4 slots forem P0, um novo P0 não rouba P0 e incrementa vozes_p0_descartadas
	var mix_p0: MixadorDeVozes = MixadorDeVozes.new(4, 4)
	for i: int in range(4):
		mix_p0.resolver([PedidoDeSom.new(StringName("sfx_p0_%d" % i), 0)], saida)
	mix_p0.resolver([PedidoDeSom.new(&"sfx_p0_extra", 0)], saida)
	assert_that(saida.is_empty()).is_true()
	assert_that(mix_p0.vozes_p0_descartadas()).is_equal(1)
