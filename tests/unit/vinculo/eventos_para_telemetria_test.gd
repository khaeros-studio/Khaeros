extends GdUnitTestSuite
## Story vinculo-e-pactos/009 e 010: Eventos do Vínculo para a Telemetria e estado inicial ampliado.
## Cobre AC-TL-34, AC-TL-36, AC-TL-37, AC-TL-38 e AC-TL-39 (do lado emissor do Vínculo).


func test_eventos_telemetria_estado_inicial_encontro_pacto_e_vinculo_fim_run() -> void:
	var eventos := EventosDoPasso.new()
	var p := PerfilVinculo.new()
	var v := Vinculo.new(p, FabricasDeCatalogo.vinculo_tuning(), eventos)

	# 1. Primeiro pacto emite `pacto(primeiro)`
	v.pedir_dupla(&"pactos")
	var ev_pactos_1 := eventos.do_tipo(&"pacto")
	assert_int(ev_pactos_1.size()).is_equal(1)
	assert_str(String((ev_pactos_1[0] as EventosVinculo.EvPactoFormado).origem)).is_equal("primeiro")

	# 2. Estado inicial ampliado para Telemetria / RNG (AC-TL-34)
	var pv_rng := p.para_estado_inicial_rng()
	var dict_rng := pv_rng.para_dicionario()
	assert_bool(dict_rng.has("especies_pactuadas")).is_true()
	assert_bool(dict_rng.has("encontro_pendente")).is_true()
	assert_bool(dict_rng.has("primeiro_encontro_visto")).is_true()
	assert_bool(dict_rng.has("runs_pactos_sem_encontro")).is_true()

	# 3. Encontro de pacto emite `encontro_pacto` e `pacto(encontro)` (AC-TL-36, AC-TL-37)
	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte.iniciar_run(0x12345678, true)
	v.planejar_encontro(&"pactos", FluxosDeVinculo.new(fonte).pactos(0))
	v.ao_montar_camara(1, [])
	v.ao_camara_limpa(1, &"combate")
	v.interagir_com_acuada()
	v.resolver_consentimento(&"oferecer")

	var ev_enc := eventos.do_tipo(&"encontro_pacto")
	assert_int(ev_enc.size()).is_equal(1)
	var e0 := ev_enc[0] as EventosVinculo.EvEncontroPacto
	assert_int(e0.indice_camara).is_equal(1)
	assert_str(String(e0.especie)).is_equal("espreitador_da_fenda")
	assert_str(String(e0.resultado)).is_equal("pactuada")
	assert_int(e0.vida_restante).is_equal(114)

	# 4. Fim de run emite `vinculo_fim_run` por espécie da dupla (AC-TL-38)
	v.registrar_acerto_maldicao(&"vulto_mudo")
	v.ao_camara_limpa(2, &"combate")
	v.consolidar_run(&"vitoria", true)
	var ev_fim := eventos.do_tipo(&"vinculo_fim_run")
	assert_int(ev_fim.size()).is_equal(2)
