extends GdUnitTestSuite
## Story portas-e-recompensas/006: Estado Aguardando pacto (passo 2b).
## Cobre AC-PR-26, AC-PR-27, AC-PR-28 e AC-PR-29.


class _BencaosSempreAberta:
	extends Bencaos
	func _init() -> void:
		super(null, null, null, null, null, {}, null)
	func restantes() -> int:
		return 8
	func pedir_oferta(_r: StringName, _i: int) -> StringName:
		return ABERTA


func _criar_portas_com_encontro(aguardando_inicial: bool) -> Dictionary:
	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte.iniciar_run(0x22334455, true)
	var eventos := EventosDoPasso.new()
	var conta := ContaFragmentos.new(FabricasDeCatalogo.economy_rates(), eventos)
	var run := Run.new(null, null, fonte, null, conta, eventos)
	run.iniciar_escolha_de_arma()
	run.confirmar_arma(&"lamina")
	var aguardando: Array[bool] = [aguardando_inicial]
	var portas := Portas.new(FabricasDeCatalogo.reward_table(), FluxosDePortas.new(fonte), conta, _BencaosSempreAberta.new(), eventos)
	portas.configurar_run(run)
	portas.configurar_vinculo(null, func() -> bool: return aguardando[0])
	return {"portas": portas, "run": run, "conta": conta, "eventos": eventos, "aguardando": aguardando}


func test_ac_pr_26_e_29_espera_pacto_com_fragmentos_e_ignora_duplicado_ou_morte() -> void:
	var ctx := _criar_portas_com_encontro(true)
	var portas: Portas = ctx["portas"]
	var conta: ContaFragmentos = ctx["conta"]

	portas.iniciar_camara(&"fragmentos")
	portas.ao_camara_limpa(1, &"combate", 1)

	# Concedeu +2 Fragmentos, mas entrou em AGUARDANDO_PACTO sem abrir portas
	assert_int(conta.saldo()).is_equal(2)
	assert_int(portas.estado()).is_equal(Portas.Estado.AGUARDANDO_PACTO)
	assert_bool(portas.portas_atuais().is_empty()).is_true()

	# Chega pacto_resolvido -> abre portas no mesmo passo; 2º pacto_resolvido é ignorado
	assert_bool(portas.ao_pacto_resolvido()).is_true()
	assert_int(portas.estado()).is_equal(Portas.Estado.PORTAS_ABERTAS)
	assert_bool(portas.portas_atuais().size() >= 2).is_true()
	assert_bool(portas.ao_pacto_resolvido()).is_false()


func test_ac_pr_27_ordem_recompensa_bencao_pacto_portas_e_pacto_lembrado() -> void:
	var ctx := _criar_portas_com_encontro(true)
	var portas: Portas = ctx["portas"]

	portas.iniciar_camara(&"bencao")
	portas.ao_camara_limpa(1, &"combate", 1)
	assert_int(portas.estado()).is_equal(Portas.Estado.AGUARDANDO_BENCAO)

	# Fecha a tela de bênção -> vai para AGUARDANDO_PACTO (portas seguem fechadas)
	portas.ao_tela_bencao_fechada()
	assert_bool(portas.ao_bencao_escolhida(&"b1")).is_true()
	assert_int(portas.estado()).is_equal(Portas.Estado.AGUARDANDO_PACTO)
	assert_bool(portas.portas_atuais().is_empty()).is_true()

	# Agora resolve o pacto -> portas abrem!
	assert_bool(portas.ao_pacto_resolvido()).is_true()
	assert_int(portas.estado()).is_equal(Portas.Estado.PORTAS_ABERTAS)

	# Caso pacto_resolvido lembrado antes do fim da bênção:
	portas.iniciar_camara(&"bencao")
	portas.ao_camara_limpa(2, &"combate", 2)
	assert_bool(portas.ao_pacto_resolvido()).is_true() # lembrado!
	portas.ao_tela_bencao_fechada()
	assert_bool(portas.ao_bencao_escolhida(&"b2")).is_true()
	assert_int(portas.estado()).is_equal(Portas.Estado.PORTAS_ABERTAS)


func test_ac_pr_28_sem_encontro_ou_acuada_fugiu_abre_portas_na_hora() -> void:
	var ctx := _criar_portas_com_encontro(false)
	var portas: Portas = ctx["portas"]

	portas.iniciar_camara(&"fragmentos")
	portas.ao_camara_limpa(1, &"combate", 1)
	assert_int(portas.estado()).is_equal(Portas.Estado.PORTAS_ABERTAS)
	assert_bool(portas.portas_atuais().size() >= 2).is_true()
