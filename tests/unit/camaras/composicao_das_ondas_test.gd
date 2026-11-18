extends GdUnitTestSuite
## Story camaras-e-ondas/004: Composição das ondas — orçamento, tamanho e elite.
## Cobre AC-CO-07, AC-CO-08, AC-CO-10 (parte elite) e AC-CO-11 (parte ondas).


class _FluxoOndasDuble:
	extends FluxoRng
	var escolhas: Array[int] = []
	var _idx: int = 0

	func _init(p_escolhas: Array[int] = []) -> void:
		super(1, RelatorDeErrosRng.new(), null)
		escolhas = p_escolhas

	func inteiro(n: int) -> int:
		if _idx < escolhas.size():
			var v: int = escolhas[_idx]
			_idx += 1
			return clampi(v, 0, n - 1)
		return 0


func test_ac_co_07_orcamento_e_numero_de_ondas_no_limiar_e_regiao_1() -> void:
	var wr := FabricasDeCatalogo.wave_rules()
	var esperados_orc: Array[float] = [3.0, 3.9, 4.8, 5.7, 6.6]
	var esperados_ondas: Array[int] = [1, 1, 2, 2, 2]
	for p: int in 5:
		assert_float(ComposicaoDeOndas.orcamento_onda(wr, p, 0)).is_equal_approx(esperados_orc[p], 1e-9)
		assert_int(ComposicaoDeOndas.numero_de_ondas(wr, p)).is_equal(esperados_ondas[p])
	# Região 1 (índice 1), p 0 -> 5,0
	assert_float(ComposicaoDeOndas.orcamento_onda(wr, 0, 1)).is_equal_approx(5.0, 1e-9)


func test_ac_co_08_composicao_por_custo_e_teto_de_9_inimigos() -> void:
	var wr := FabricasDeCatalogo.wave_rules()
	var eco := FabricasDeCatalogo.inimigo(&"eco_perdido")
	eco.custo_onda = 1
	var fenda := FabricasDeCatalogo.inimigo(&"fenda_viva")
	fenda.custo_onda = 2
	var pool: Array[EnemyDef] = [eco, fenda]

	# Sorteio [Fenda (idx 1), Eco (idx 0)] em p=0 (orçamento 3) -> 2 inimigos, custo 3
	var onda1 := ComposicaoDeOndas.compor_uma_onda(wr, pool, 3.0, _FluxoOndasDuble.new([1, 0]))
	assert_int(onda1.size()).is_equal(2)
	assert_str(String(onda1[0].inimigo_id)).is_equal("fenda_viva")
	assert_str(String(onda1[1].inimigo_id)).is_equal("eco_perdido")

	# Sorteio [Eco, Eco, Eco] em p=0 (orçamento 3) -> 3 inimigos
	var onda2 := ComposicaoDeOndas.compor_uma_onda(wr, pool, 3.0, _FluxoOndasDuble.new([0, 0, 0]))
	assert_int(onda2.size()).is_equal(3)

	# Orçamento 20 -> para em max_inimigos_onda = 9
	var onda_teto := ComposicaoDeOndas.compor_uma_onda(wr, [eco], 20.0, _FluxoOndasDuble.new())
	assert_int(onda_teto.size()).is_equal(9)


func test_ac_co_10_sorteio_de_elite_passa_ja_ha_elite_na_ordem() -> void:
	var wr := FabricasDeCatalogo.wave_rules()
	var eco := FabricasDeCatalogo.inimigo(&"eco_perdido")
	var onda := ComposicaoDeOndas.compor_uma_onda(wr, [eco], 3.0, _FluxoOndasDuble.new([0, 0, 0]))
	var historico_ja_ha: Array[bool] = []
	var respostas: Array[bool] = [false, true, false]
	var idx_call: Array[int] = [0]
	ComposicaoDeOndas.aplicar_sorteio_de_elites(onda, 3, func(_p: int, ja_ha: bool) -> bool:
		historico_ja_ha.append(ja_ha)
		var r: bool = respostas[idx_call[0]]
		idx_call[0] += 1
		return r
	)
	assert_array(historico_ja_ha).is_equal([false, false, true])
	assert_bool(onda[0].elite).is_false()
	assert_bool(onda[1].elite).is_true()
	assert_bool(onda[2].elite).is_false()
