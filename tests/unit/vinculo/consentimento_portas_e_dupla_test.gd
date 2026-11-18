extends GdUnitTestSuite
## Story vinculo-e-pactos/006: Consentimento no estado Bênção, Portas 2b e dupla que cresce.
## Cobre AC-VP-12, AC-VP-13, AC-VP-14 e AC-VP-15.


func test_ac_vp_12_13_15_consentimento_oferecer_vinculo_grava_libera_portas_e_cresce_dupla() -> void:
	var eventos := EventosDoPasso.new()
	var p := PerfilVinculo.new()
	var v := Vinculo.new(p, FabricasDeCatalogo.vinculo_tuning(), eventos)
	v.pedir_dupla(&"pactos") # concede Vulto Mudo -> dupla tem só 1

	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte.iniciar_run(0x33445566, true)
	v.planejar_encontro(&"pactos", FluxosDeVinculo.new(fonte).pactos(0))
	v.ao_montar_camara(1, [])
	v.acuada().vida = 80 # AC-VP-15: acuada com Vida = 80

	var acrescentado_id: Array[StringName] = [&""]
	var acrescentado_vida: Array[int] = [0]
	v.configurar_maldicoes(null, func(_pid: int, def: CurseDef, vida_ini: int) -> void:
		acrescentado_id[0] = def.id
		acrescentado_vida[0] = vida_ini
	)

	var portas := Portas.new(FabricasDeCatalogo.reward_table(), FluxosDePortas.new(fonte), null, BencaosNula.new(), eventos)
	portas.configurar_vinculo(v)
	v.configurar_portas(portas)

	# Limpa a câmara 1 -> acuada entra em AGUARDANDO e Portas entram em AGUARDANDO_PACTO
	v.ao_camara_limpa(1, &"combate")
	assert_bool(v.encontro_aguardando()).is_true()
	portas.iniciar_camara(&"fragmentos")
	portas.ao_camara_limpa(1, &"combate", 1)
	assert_int(portas.estado()).is_equal(Portas.Estado.AGUARDANDO_PACTO)

	# Interage e escolhe "Oferecer o vínculo"
	var opcoes := v.interagir_com_acuada()
	assert_array(opcoes).is_equal([&"oferecer", &"deixar_ir"])
	assert_bool(v.resolver_consentimento(&"oferecer")).is_true()

	# AC-VP-13: Espreitador pactuado nível 1, encontros_bem_sucedidos = 1, portas abertas!
	var est := p.estado_de(&"espreitador_da_fenda")
	assert_bool(est.pactuada).is_true()
	assert_int(est.nivel).is_equal(1)
	assert_int(est.encontros_bem_sucedidos).is_equal(1)
	assert_int(portas.estado()).is_equal(Portas.Estado.PORTAS_ABERTAS)

	# AC-VP-15: Espreitador entrou na reserva com Vida = min(80, 95) = 80
	assert_array(v.dupla_da_run()).is_equal([&"vulto_mudo", &"espreitador_da_fenda"])
	assert_str(String(acrescentado_id[0])).is_equal("espreitador_da_fenda")
	assert_int(acrescentado_vida[0]).is_equal(80)


func test_ac_vp_14_especie_rara_baluarte_exige_2_encontros_bem_sucedidos() -> void:
	var eventos := EventosDoPasso.new()
	var p := PerfilVinculo.new()
	p.primeiro_pacto_concedido = true
	p.primeiro_encontro_visto = true
	p.registrar_pacto_novo(&"vulto_mudo")
	p.registrar_pacto_novo(&"espreitador_da_fenda")
	p.encontro_pendente = ["baluarte_de_cinza"]

	var v := Vinculo.new(p, FabricasDeCatalogo.vinculo_tuning(), eventos)
	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte.iniciar_run(0x77778888, true)
	v.planejar_encontro(&"pactos", FluxosDeVinculo.new(fonte).pactos(0))
	var idx_enc: int = v.encontro().indice_camara
	v.ao_montar_camara(idx_enc, [])
	v.ao_camara_limpa(idx_enc, &"combate")

	# 1º encontro bem-sucedido do Baluarte (raro): tela mostra apenas ["ela_voltara"]
	var opcoes_1 := v.interagir_com_acuada()
	assert_array(opcoes_1).is_equal([&"ela_voltara"])
	assert_bool(v.resolver_consentimento(&"ela_voltara")).is_true()
	assert_bool(p.estado_de(&"baluarte_de_cinza").pactuada).is_false()
	assert_int(p.estado_de(&"baluarte_de_cinza").encontros_bem_sucedidos).is_equal(1)
	assert_array(p.encontro_pendente).is_equal(["baluarte_de_cinza"])

	# 2º encontro na run seguinte (garantido por G2): agora oferece o vínculo!
	v.planejar_encontro(&"pactos", FluxosDeVinculo.new(fonte).pactos(0))
	var idx_enc_2: int = v.encontro().indice_camara
	assert_str(String(v.encontro().especie_id)).is_equal("baluarte_de_cinza")
	v.ao_montar_camara(idx_enc_2, [])
	v.ao_camara_limpa(idx_enc_2, &"combate")
	var opcoes_2 := v.interagir_com_acuada()
	assert_array(opcoes_2).is_equal([&"oferecer", &"deixar_ir"])
	assert_bool(v.resolver_consentimento(&"oferecer")).is_true()
	assert_bool(p.estado_de(&"baluarte_de_cinza").pactuada).is_true()
	assert_bool(p.encontro_pendente.is_empty()).is_true()
