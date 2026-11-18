extends GdUnitTestSuite
## Story vinculo-e-pactos/003: Primeiro pacto (V3), escolha da dupla (V16/V16b) e seed.
## Cobre AC-VP-01 e V16/V16b.


func test_ac_vp_01_primeiro_pacto_vulto_mudo_sem_tela_de_dupla() -> void:
	var eventos := EventosDoPasso.new()
	var p := PerfilVinculo.new()
	var v := Vinculo.new(p, FabricasDeCatalogo.vinculo_tuning(), eventos)

	var abriu_tela: bool = v.pedir_dupla(&"pactos")
	assert_bool(abriu_tela).is_false()
	assert_bool(p.primeiro_pacto_concedido).is_true()

	var est := p.estado_de(&"vulto_mudo")
	assert_bool(est.pactuada).is_true()
	assert_int(est.nivel).is_equal(1)
	assert_int(est.vinculo_pontos).is_equal(0)

	var ev_reg := eventos.do_tipo(&"pacto_registrado")
	assert_int(ev_reg.size()).is_equal(1)
	assert_str(String((ev_reg[0] as EventosVinculo.EvPactoRegistrado).especie_id)).is_equal("vulto_mudo")

	var ev_dup := eventos.do_tipo(&"dupla_confirmada")
	assert_int(ev_dup.size()).is_equal(1)
	assert_str(String((ev_dup[0] as EventosVinculo.EvDuplaConfirmada).campo)).is_equal("vulto_mudo")
	assert_str(String((ev_dup[0] as EventosVinculo.EvDuplaConfirmada).reserva)).is_equal("")


func test_v16_escolha_da_dupla_com_2_ou_mais_pactuadas() -> void:
	var eventos := EventosDoPasso.new()
	var p := PerfilVinculo.new()
	p.primeiro_pacto_concedido = true
	p.registrar_pacto_novo(&"vulto_mudo")
	p.registrar_pacto_novo(&"espreitador_da_fenda")
	var v := Vinculo.new(p, FabricasDeCatalogo.vinculo_tuning(), eventos)

	# Com 2 pactuadas, pedir_dupla abre a tela e aguarda confirmar_dupla
	assert_bool(v.pedir_dupla(&"pactos")).is_true()
	assert_bool(v.tela_dupla_aberta()).is_true()

	# Recusa espécie repetida
	assert_bool(v.confirmar_dupla(&"vulto_mudo", &"vulto_mudo")).is_false()

	# Aceita dupla válida e atualiza ultima_dupla
	assert_bool(v.confirmar_dupla(&"espreitador_da_fenda", &"vulto_mudo")).is_true()
	assert_bool(v.tela_dupla_aberta()).is_false()
	assert_array(p.ultima_dupla).is_equal(["espreitador_da_fenda", "vulto_mudo"])
