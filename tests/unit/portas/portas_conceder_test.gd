extends GdUnitTestSuite
## Story portas-e-recompensas/004: Conceder a recompensa (Fragmentos, cura, bênção).
## Cobre AC-PR-01, AC-PR-03, AC-PR-04, AC-PR-05 e AC-PR-34.


func test_ac_pr_04_e_34_fragmentos_por_profundidade_e_maximo_10_no_limiar() -> void:
	var rt := FabricasDeCatalogo.reward_table()
	assert_int(FormulasDePortas.fragmentos_por_porta(rt, 0)).is_equal(2)
	assert_int(FormulasDePortas.fragmentos_por_porta(rt, 1)).is_equal(2)
	assert_int(FormulasDePortas.fragmentos_por_porta(rt, 2)).is_equal(2)
	assert_int(FormulasDePortas.fragmentos_por_porta(rt, 3)).is_equal(3)
	assert_int(FormulasDePortas.fragmentos_por_porta(rt, 4)).is_equal(3)
	assert_int(FormulasDePortas.fragmentos_por_porta(rt, 6)).is_equal(4)
	assert_int(FormulasDePortas.max_fragmentos_portas_limiar(rt)).is_equal(10)


func test_ac_pr_05_cura_nominal_e_efetiva_lamina_e_ressonancia() -> void:
	var rt := FabricasDeCatalogo.reward_table()
	var eventos := EventosDoPasso.new()
	var portas := Portas.new(rt, null, null, null, eventos)
	var mod_tun := FabricaDaRun._modifiers_tuning_padrao()

	# Lâmina (Vida_max = 100): Vida 50/100 -> 80; Vida 85/100 -> 100 (evento nominal 30)
	var port_lam := Portador.new(1, 0, Atributos.Especie.JOGADOR, {Atributos.VIDA_MAX: 100.0}, mod_tun)
	var vida: Array[int] = [50]
	portas.configurar_jogador(port_lam, func() -> int: return vida[0], func(nv: int) -> void: vida[0] = nv)
	portas.conceder(&"cura", 1)
	assert_int(vida[0]).is_equal(80)

	vida[0] = 85
	portas.conceder(&"cura", 1)
	assert_int(vida[0]).is_equal(100)
	var evs := eventos.do_tipo(&"recompensa")
	var ultimo_ev := evs[evs.size() - 1] as EventosDePortas.EvRecompensa
	assert_int(ultimo_ev.quantidade).is_equal(30)

	# Ressonância (Vida_max = 80, Vida = 40): 64 (cura 24)
	var port_res := Portador.new(2, 0, Atributos.Especie.JOGADOR, {Atributos.VIDA_MAX: 80.0}, mod_tun)
	vida[0] = 40
	portas.configurar_jogador(port_res, func() -> int: return vida[0], func(nv: int) -> void: vida[0] = nv)
	portas.conceder(&"cura", 1)
	assert_int(vida[0]).is_equal(64)


func test_ac_pr_01_e_03_primeira_recompensa_bencao_e_conversao_em_fragmentos_quando_pool_vazio() -> void:
	var rt := FabricasDeCatalogo.reward_table()
	var eventos := EventosDoPasso.new()
	var conta := ContaFragmentos.new(FabricasDeCatalogo.economy_rates(), eventos)
	# BencaosNula tem restantes() == 0 -> recompensa de bênção vira Fragmentos!
	var portas := Portas.new(rt, null, conta, BencaosNula.new(), eventos)

	# AC-PR-01: 1ª câmara começa com `bencao`
	assert_str(String(portas.recompensa_pendente())).is_equal("bencao")

	# AC-PR-03: sem bênçãos restantes em p=1, vira 2 Fragmentos
	portas.conceder(&"bencao", 1)
	assert_int(conta.saldo()).is_equal(2)
	var evs := eventos.do_tipo(&"recompensa")
	assert_int(evs.size()).is_equal(1)
	assert_str(String((evs[0] as EventosDePortas.EvRecompensa).tipo_recompensa)).is_equal("fragmentos")
	assert_int((evs[0] as EventosDePortas.EvRecompensa).quantidade).is_equal(2)
