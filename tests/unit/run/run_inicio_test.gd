extends GdUnitTestSuite
## Story run-e-regioes/004: Início da run — arma, dupla, seed, estado inicial, câmara 0.
## Cobre AC-RN-02, AC-RN-03, AC-RN-04, AC-RN-05, AC-RN-27 e AC-RN-28.


class _EntropiaFixa:
	extends FonteDeEntropia
	var valor: int = 0x3F9A07C2
	func sortear_u32() -> int:
		return valor


func test_ac_rn_02_e_27_ordem_de_inicio_com_lamina_e_com_pactos() -> void:
	var ordem: Array[String] = []
	var p := PerfilVinculo.new()
	p.primeiro_pacto_concedido = true
	p.registrar_pacto_novo(&"vulto_mudo")
	p.registrar_pacto_novo(&"espreitador_da_fenda")
	var v := Vinculo.new(p)
	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	var criador := CriadorDeSeed.new(_EntropiaFixa.new(), true, PackedStringArray(), RelatorDeErrosRng.new())
	var run := Run.new(null, null, fonte, criador)
	run.configurar_vinculo(v)
	run.configurar_callbacks(func(_arma: StringName, _dupla: Array[StringName], _seed: int) -> void:
		ordem.append("estado_inicial")
	)

	var cam_duble := Camaras.new(FabricasDeCatalogo.wave_rules(), FabricasDeCatalogo.room_tuning(), Run._regiao_limiar_padrao())
	run.configurar_camaras(cam_duble)

	# Com Pactos e 2 pactuadas: confirmar_arma pede dupla -> confirmar_dupla cria seed, estado_inicial, câmara 0
	run.iniciar_escolha_de_arma()
	ordem.append("arma")
	assert_bool(run.confirmar_arma(&"pactos")).is_true()
	ordem.append("pedir_dupla")
	assert_int(run.fase()).is_equal(Run.Fase.ESCOLHA_DA_DUPLA)
	ordem.append("dupla_confirmada")
	assert_bool(run.confirmar_dupla(&"vulto_mudo", &"espreitador_da_fenda")).is_true()
	assert_array(ordem).is_equal(["arma", "pedir_dupla", "dupla_confirmada", "estado_inicial"])
	assert_int(cam_duble.indice_atual()).is_equal(0)


func test_ac_rn_03_04_05_28_preferencia_arma_seed_debug_e_vidas_iniciais() -> void:
	var prefs: PreferenciasDeArmaEmMemoria = PreferenciasDeArmaEmMemoria.new()
	var ent := _EntropiaFixa.new()
	var criador_sem_arg := CriadorDeSeed.new(ent, true, PackedStringArray(), RelatorDeErrosRng.new())
	var run := Run.new(null, null, null, criador_sem_arg, null, null, prefs)

	# AC-RN-28: 3 cartas disponíveis
	assert_array(run.cartas_disponiveis()).is_equal([&"lamina", &"ressonancia", &"pactos"])

	# AC-RN-03: primeira run sem escolha usa arma_padrao (lamina, Vida 100); depois lembra a última escolhida
	run.iniciar_escolha_de_arma()
	run.confirmar_arma()
	assert_str(String(run.arma())).is_equal("lamina")
	assert_int(run.vida_inicial_jogador()).is_equal(100)
	assert_int(run.seed_valor()).is_equal(0x3F9A07C2)

	# Escolhe Ressonância (Vida 80) -> fica lembrada em prefs
	run.ao_jogador_morreu()
	run.nova_run()
	run.confirmar_arma(&"ressonancia")
	assert_int(run.vida_inicial_jogador()).is_equal(80)
	assert_str(String(prefs.ultima_arma())).is_equal("ressonancia")

	# Na run seguinte, confirmar_arma() vazio usa a última lembrada (ressonancia)
	run.ao_jogador_morreu()
	run.nova_run()
	run.confirmar_arma()
	assert_str(String(run.arma())).is_equal("ressonancia")

	# AC-RN-04: --seed=1B2C3D4E em debug -> 0x1B2C3D4E; --seed=XYZ inválida -> cai no provedor (0x3F9A07C2)
	run.ao_jogador_morreu()
	run.nova_run()
	run.confirmar_arma(&"pactos", "1B2C3D4E")
	assert_int(run.vida_inicial_jogador()).is_equal(90)
	assert_int(run.seed_valor()).is_equal(0x1B2C3D4E)

	run.ao_jogador_morreu()
	run.nova_run()
	run.confirmar_arma(&"lamina", "XYZ")
	assert_int(run.seed_valor()).is_equal(0x3F9A07C2)
