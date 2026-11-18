extends GdUnitTestSuite
## Story portas-e-recompensas/007 e 008: Escolha da porta, VistaDePorta, EvPortaEscolhida e F3-P.
## Cobre AC-PR-12, AC-PR-15, AC-PR-16, AC-PR-20, AC-PR-35 e AC-PR-36.


func test_ac_pr_12_15_16_36_vistas_quantidades_e_escolha_da_porta() -> void:
	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte.iniciar_run(0x778899AA, true)
	var eventos := EventosDoPasso.new()
	var conta := ContaFragmentos.new(FabricasDeCatalogo.economy_rates(), eventos)
	var run := Run.new(null, null, fonte, null, conta, eventos)
	run.iniciar_escolha_de_arma()
	run.confirmar_arma(&"lamina")

	var cam := Camaras.new(FabricasDeCatalogo.wave_rules(), FabricasDeCatalogo.room_tuning(), Run._regiao_limiar_padrao())
	var portas := Portas.new(FabricasDeCatalogo.reward_table(), FluxosDePortas.new(fonte), conta, BencaosNula.new(), eventos, FabricasDeCatalogo.room_tuning())
	portas.configurar_run(run)
	portas.configurar_camaras(cam)

	# Depois do santuário (índice 3, próxima é índice 4 com p=3): Fragmentos mostra +3
	portas.ao_camara_limpa(2, &"santuario", 3)
	var vistas := portas.vistas_de_porta()
	assert_bool(vistas.size() >= 2).is_true()
	for v: VistaDePorta in vistas:
		if v.tipo == &"fragmentos":
			assert_int(v.quantidade).is_equal(3)
			assert_str(v.rotulo_quantidade).is_equal("+3")
		elif v.tipo == &"cura":
			assert_int(v.quantidade).is_equal(30)
			assert_str(v.rotulo_quantidade).is_equal("+30%")
		elif v.tipo == &"bencao":
			assert_int(v.quantidade).is_equal(3)

	# Escolhe a porta 0 -> guarda recompensa pendente e emite EvPortaEscolhida
	var tipo_0: StringName = vistas[0].tipo
	assert_bool(portas.ao_porta_escolhida(0)).is_true()
	assert_str(String(portas.recompensa_pendente())).is_equal(String(tipo_0))
	assert_int(eventos.do_tipo(&"porta_escolhida_recompensa").size()).is_equal(1)

	# AC-PR-36: porta `chefe` depois do índice 5 não carrega recompensa e mostra 0 quantidade
	portas.iniciar_camara(&"fragmentos")
	portas.ao_camara_limpa(4, &"combate", 5)
	var vistas_chefe := portas.vistas_de_porta()
	assert_int(vistas_chefe.size()).is_equal(1)
	assert_str(String(vistas_chefe[0].tipo)).is_equal("chefe")
	assert_int(vistas_chefe[0].quantidade).is_equal(0)
	assert_str(vistas_chefe[0].rotulo_quantidade).is_equal("")
	assert_bool(vistas_chefe[0].carrega_recompensa).is_false()
	assert_bool(portas.ao_porta_escolhida(0)).is_true()
	assert_str(String(portas.recompensa_pendente())).is_equal("")


func test_ac_pr_35_esperanca_de_bencaos_por_run_no_limiar_com_chefe() -> void:
	var rt := FabricasDeCatalogo.reward_table()
	# k = 4 escolhas livres no Limiar com chefe -> E = 1 + 4 * 0,895 = 4,58
	assert_float(FormulasDePortas.esperanca_bencaos_run(rt, 4)).is_equal_approx(4.58, 1e-4)
	# k = 3 no Limiar sem chefe -> E = 1 + 3 * 0,895 = 3,685
	assert_float(FormulasDePortas.esperanca_bencaos_run(rt, 3)).is_equal_approx(3.685, 1e-4)
