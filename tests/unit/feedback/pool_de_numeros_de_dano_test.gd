class_name PoolDeNumerosDeDanoTest
extends GdUnitTestSuite
## Testes unitários do `PoolDeNumeros` (`F1`, `F2`, `F5`, `R6`, `R16`, story-004).


func test_soma_golpes_na_janela_de_300ms_incluindo_maldicao_e_parede_mas_dourado_nunca_soma() -> void:
	var pool: PoolDeNumeros = PoolDeNumeros.new(6, 0.30)

	var s1: PoolDeNumeros.SlotNumero = pool.registrar_dano(&"golpe_leve", 42, 15, Vector2(100, 100), false, false, false)
	assert_that(s1 != null).is_true()
	assert_that(s1.valor_acumulado).is_equal(15)

	pool.avancar_apres(0.10, false)
	# Golpe da Maldição no mesmo alvo dentro de 0.30s soma no mesmo número e nunca é dourado
	var s2: PoolDeNumeros.SlotNumero = pool.registrar_dano(&"maldicao_atacou", 42, 10, Vector2(102, 98), true, true, false)
	assert_that(s2).is_same(s1)
	assert_that(s1.valor_acumulado).is_equal(25)
	assert_that(s1.faixa).is_equal(PoolDeNumeros.FAIXA_GOLPE)

	# Dourado do jogador no mesmo alvo abre novo slot sem somar
	var s_dourado: PoolDeNumeros.SlotNumero = pool.registrar_dano(&"golpe_pesado", 42, 50, Vector2(105, 95), true, false, false)
	assert_that(s_dourado != s1).is_true()
	assert_that(s_dourado.faixa).is_equal(PoolDeNumeros.FAIXA_DOURADO)
	assert_that(pool.quantidade_ativa()).is_equal(2)


func test_jogador_atingido_e_maldicao_atingida_nunca_geram_numero_e_despejo_respeita_prioridade() -> void:
	var pool: PoolDeNumeros = PoolDeNumeros.new(4, 0.30)
	assert_that(pool.registrar_dano(&"jogador_atingido", 1, 30, Vector2.ZERO) == null).is_true()
	assert_that(pool.registrar_dano(&"maldicao_atingida", 2, 20, Vector2.ZERO) == null).is_true()

	# Preenche 4 slots: 1 dourado, 2 golpes, 1 status
	pool.registrar_dano(&"golpe_pesado", 10, 40, Vector2.ZERO, true, false, false)
	pool.registrar_dano(&"golpe_leve", 11, 12, Vector2.ZERO, false, false, false)
	pool.registrar_dano(&"tick_status", 12, 5, Vector2.ZERO, false, false, true)
	pool.registrar_dano(&"golpe_leve", 13, 14, Vector2.ZERO, false, false, false)
	assert_that(pool.quantidade_ativa()).is_equal(4)

	# 5º número (dourado no alvo 14) deve desalojar o slot de status (alvo 12)
	pool.registrar_dano(&"golpe_pesado", 14, 60, Vector2.ZERO, true, false, false)
	var tem_alvo_12: bool = false
	for s: PoolDeNumeros.SlotNumero in pool.slots():
		if s.ativo and s.alvo_id == 12:
			tem_alvo_12 = true
	assert_that(tem_alvo_12).is_false()
