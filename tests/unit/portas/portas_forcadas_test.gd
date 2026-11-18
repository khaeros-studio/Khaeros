extends GdUnitTestSuite
## Story portas-e-recompensas/003: Portas forçadas, chaves por índice e consumo fixo.
## Cobre AC-PR-08, AC-PR-10, AC-PR-32 e AC-PR-33.


func test_ac_pr_32_33_portas_do_limiar_livres_e_forcadas_com_consumo_fixo() -> void:
	var rt := FabricasDeCatalogo.reward_table()
	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte.iniciar_run(0x3F9A07C2, true)
	var fp := FluxosDePortas.new(fonte)
	var run: Run = Run.new()
	var portas: Portas = Portas.new(rt, fp)
	portas.configurar_run(run)

	# Escolhas livres: depois dos índices 0, 1, 3 e 4 (cada uma consome 4 reais da sua chave)
	for idx_livre: int in [0, 1, 3, 4]:
		var s := portas.portas_para_indice(idx_livre, 0)
		assert_bool(s.size() >= 2 and s.size() <= 3).is_true()
		assert_bool(s.has(&"ultima")).is_false()

	# Forçadas: depois do 2 -> [santuario] (0 reais); depois do 5 -> [chefe] (0 reais); depois do 6 -> []
	assert_array(portas.portas_para_indice(2, 0)).is_equal([&"santuario"])
	assert_array(portas.portas_para_indice(5, 0)).is_equal([&"chefe"])
	assert_array(portas.portas_para_indice(6, 0)).is_empty()

	# Apenas 4 fluxos de portas foram abertos (chaves 0, 1, 3, 4); chaves 2, 5 e 6 não foram abertas!
	assert_int(fonte.fluxos_abertos()).is_equal(4)


func test_ac_pr_08_porta_ultima_em_regiao_sem_chefe_de_6_camaras() -> void:
	var rt := FabricasDeCatalogo.reward_table()
	var run_tun := FabricasDeCatalogo.run_tuning()
	run_tun.camaras_jogaveis[&"limiar"] = 6 # modo legado sem chefe (índice 5 é a última jogável de combate)
	var run: Run = Run.new(run_tun)
	var portas: Portas = Portas.new(rt)
	portas.configurar_run(run)

	# Depois do índice 4 (próxima é 5, última jogável sem chefe): 1 porta forçada `ultima`
	assert_array(portas.portas_para_indice(4, 0)).is_equal([&"ultima"])
	assert_array(portas.portas_para_indice(5, 0)).is_empty()
