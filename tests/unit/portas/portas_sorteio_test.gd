extends GdUnitTestSuite
## Story portas-e-recompensas/002: Sorteio das portas livres (quantas e quais tipos, F2).
## Cobre AC-PR-07, AC-PR-09, AC-PR-11, AC-PR-13 e AC-PR-14.


func test_ac_pr_07_e_09_quantas_portas_e_tipos_distintos() -> void:
	var rt := FabricasDeCatalogo.reward_table()
	# u0 = 0,2999 < 0,3 -> 3 portas distintas
	var p3 := SorteioDePortas.sortear_com_reais(rt, 0.2999, 0.1, 0.1, 0.0)
	assert_int(p3.size()).is_equal(3)
	assert_array(p3).contains_exactly_in_any_order([&"bencao", &"fragmentos", &"cura"])

	# u0 = 0,3 -> 2 portas distintas
	var p2 := SorteioDePortas.sortear_com_reais(rt, 0.3000, 0.1, 0.1, 0.0)
	assert_int(p2.size()).is_equal(2)
	assert_bool(p2[0] != p2[1]).is_true()


func test_ac_pr_11_fronteiras_de_sorteio_ponderado() -> void:
	var rt := FabricasDeCatalogo.reward_table()
	# 1º tipo (pesos 3/2/1, soma 6): u1 = 0,4999 -> bênção; 0,5 -> Fragmentos; 0,8333 -> Fragmentos; 0,8334 -> cura
	assert_str(String(SorteioDePortas.sortear_com_reais(rt, 0.5, 0.4999, 0.1)[0])).is_equal("bencao")
	assert_str(String(SorteioDePortas.sortear_com_reais(rt, 0.5, 0.5000, 0.1)[0])).is_equal("fragmentos")
	assert_str(String(SorteioDePortas.sortear_com_reais(rt, 0.5, 0.8333, 0.1)[0])).is_equal("fragmentos")
	assert_str(String(SorteioDePortas.sortear_com_reais(rt, 0.5, 0.8334, 0.1)[0])).is_equal("cura")

	# 2º tipo com bênção primeiro (restam Fragmentos 2 e cura 1, soma 3; fronteira 2/3 = 0,66666...):
	assert_str(String(SorteioDePortas.sortear_com_reais(rt, 0.5, 0.1, 0.6666)[1])).is_equal("fragmentos")
	assert_str(String(SorteioDePortas.sortear_com_reais(rt, 0.5, 0.1, 0.6667)[1])).is_equal("cura")


func test_ac_pr_13_peso_zero_nunca_sai_e_limita_n() -> void:
	var rt := FabricasDeCatalogo.reward_table()
	rt.pesos_portas[&"cura"] = 0.0
	var p := SorteioDePortas.sortear_com_reais(rt, 0.1, 0.2, 0.2) # u0=0.1 pediria 3, mas só há 2 tipos > 0
	assert_int(p.size()).is_equal(2)
	assert_array(p).contains_exactly_in_any_order([&"bencao", &"fragmentos"])


func test_ac_pr_14_distribuicao_e_probabilidade_bencao() -> void:
	var rt := FabricasDeCatalogo.reward_table()
	assert_float(ValidacaoRewardTable.prob_bencao_na_escolha(rt)).is_equal_approx(0.895, 1e-4)

	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte.iniciar_run(0x13572468, false)
	var fp := FluxosDePortas.new(fonte).portas(0, 0)
	var n_amostras: int = 10000
	var com_bencao: int = 0
	for _i in n_amostras:
		var s := SorteioDePortas.sortear(rt, fp)
		if s.has(&"bencao"):
			com_bencao += 1
	var taxa: float = float(com_bencao) / float(n_amostras)
	assert_float(taxa).is_equal_approx(0.895, 0.02)
