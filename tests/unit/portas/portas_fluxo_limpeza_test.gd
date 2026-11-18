extends GdUnitTestSuite
## Story portas-e-recompensas/005: Fluxo da limpeza (R2): ordem, morte, santuário e fim da run.
## Cobre AC-PR-02, AC-PR-06, AC-PR-23, AC-PR-25, AC-PR-30 e AC-PR-31.


class _BencaosDuble:
	extends Bencaos
	var pool: int = 8
	var pedidos: Array[Vector2i] = []

	func _init() -> void:
		super(null, null, null, null, null, {}, null)

	func restantes() -> int:
		return pool

	func pedir_oferta(_regiao: StringName, indice: int) -> StringName:
		pedidos.append(Vector2i(0, indice))
		return ABERTA if pool > 0 else SEM_BENCAO


func _setup_portas(seed_val: int = 0x11112222) -> Dictionary:
	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte.iniciar_run(seed_val, true)
	var eventos := EventosDoPasso.new()
	var conta := ContaFragmentos.new(FabricasDeCatalogo.economy_rates(), eventos)
	var benc := _BencaosDuble.new()
	var run := Run.new(null, null, fonte, null, conta, eventos)
	run.iniciar_escolha_de_arma()
	run.confirmar_arma(&"lamina")
	var portas := Portas.new(FabricasDeCatalogo.reward_table(), FluxosDePortas.new(fonte), conta, benc, eventos)
	portas.configurar_run(run)
	return {"portas": portas, "run": run, "conta": conta, "bencaos": benc, "eventos": eventos}


func test_ac_pr_02_e_25_bencao_espera_tela_fechada_antes_de_abrir_portas() -> void:
	var ctx := _setup_portas()
	var portas: Portas = ctx["portas"]
	var benc: _BencaosDuble = ctx["bencaos"]

	portas.iniciar_camara(&"bencao")
	portas.ao_camara_limpa(0, &"combate", 0)

	assert_int(benc.pedidos.size()).is_equal(1)
	assert_int(portas.estado()).is_equal(Portas.Estado.AGUARDANDO_BENCAO)
	assert_bool(portas.portas_atuais().is_empty()).is_true()

	# Escolha antes de tela_fechada é recusada!
	assert_bool(portas.ao_bencao_escolhida(&"b1")).is_false()
	assert_int(portas.estado()).is_equal(Portas.Estado.AGUARDANDO_BENCAO)

	# Depois de tela_fechada, aceita e abre as portas!
	portas.ao_tela_bencao_fechada()
	assert_bool(portas.ao_bencao_escolhida(&"b1")).is_true()
	assert_int(portas.estado()).is_equal(Portas.Estado.PORTAS_ABERTAS)
	assert_bool(portas.portas_atuais().size() >= 2).is_true()


func test_ac_pr_23_morte_no_mesmo_passo_vence_a_limpeza() -> void:
	var ctx := _setup_portas()
	var portas: Portas = ctx["portas"]
	var run: Run = ctx["run"]
	var conta: ContaFragmentos = ctx["conta"]

	portas.iniciar_camara(&"fragmentos")
	run.ao_jogador_morreu() # Run sai de ATIVA
	portas.ao_camara_limpa(1, &"combate", 1)

	assert_int(conta.saldo()).is_equal(0)
	assert_bool(portas.portas_atuais().is_empty()).is_true()


func test_ac_pr_06_30_31_santuario_indice_5_comum_e_chefe_indice_6() -> void:
	var ctx := _setup_portas()
	var portas: Portas = ctx["portas"]
	var conta: ContaFragmentos = ctx["conta"]
	var eventos: EventosDoPasso = ctx["eventos"]

	# AC-PR-06: Santuário (índice 3) -> nenhuma recompensa, abre 2 ou 3 portas livres
	portas.ao_camara_limpa(2, &"santuario", 3)
	assert_int(conta.saldo()).is_equal(0)
	assert_int(portas.estado()).is_equal(Portas.Estado.PORTAS_ABERTAS)
	assert_bool(portas.portas_atuais().size() >= 2).is_true()

	# AC-PR-31: Índice 5 comum com recompensa `fragmentos` (p=4) -> dá +3 Fragmentos e abre 1 porta `chefe`
	portas.iniciar_camara(&"fragmentos")
	portas.ao_camara_limpa(4, &"combate", 5)
	assert_int(conta.saldo()).is_equal(3)
	assert_array(portas.portas_atuais()).is_equal([&"chefe"])

	# AC-PR-30: Chefe (índice 6, p=4) -> nenhuma recompensa de porta, nenhuma porta, FIM_DA_REGIAO
	var qtd_ev_rec_antes: int = eventos.do_tipo(&"recompensa").size()
	portas.iniciar_camara(&"")
	portas.ao_camara_limpa(4, &"chefe", 6)
	assert_int(eventos.do_tipo(&"recompensa").size()).is_equal(qtd_ev_rec_antes)
	assert_bool(portas.portas_atuais().is_empty()).is_true()
	assert_int(portas.estado()).is_equal(Portas.Estado.FIM_DA_REGIAO)
