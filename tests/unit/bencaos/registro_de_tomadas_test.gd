extends GdUnitTestSuite
## Story bencaos-tradicoes-002: RegistroDeBencaos (AC-BN-01, 15, 16).


func test_sem_tomadas_pool_18_e_tomada_nao_volta() -> void:
	var reg := RegistroDeBencaos.new(FixtureBn.boons())
	assert_int(reg.restantes()).is_equal(18)
	assert_bool(reg.registrar(FixtureBn.IDS[9], SorteioDeOferta.COMUM)).is_true()
	assert_int(reg.restantes()).is_equal(17)
	var ids := reg.livres().map(func(b: BoonDef) -> StringName: return b.id)
	assert_bool(ids.has(FixtureBn.IDS[9])).is_false()
	assert_bool(reg.registrar(FixtureBn.IDS[9], SorteioDeOferta.RARA)).is_false()


func test_livres_mantem_ordem_do_manifesto() -> void:
	var reg := RegistroDeBencaos.new(FixtureBn.boons())
	reg.registrar(FixtureBn.IDS[1], SorteioDeOferta.COMUM)
	var livres := reg.livres()
	assert_str(String(livres[0].id)).is_equal(String(FixtureBn.IDS[0]))
	assert_str(String(livres[1].id)).is_equal(String(FixtureBn.IDS[2]))


func test_duas_tomadas_restantes_16_e_tomadas_em_ordem() -> void:
	var reg := RegistroDeBencaos.new(FixtureBn.boons())
	reg.registrar(FixtureBn.IDS[6], SorteioDeOferta.EPICA)
	reg.registrar(FixtureBn.IDS[0], SorteioDeOferta.RARA)
	var t := reg.tomadas()
	assert_int(reg.restantes()).is_equal(16)
	assert_int(t.size()).is_equal(2)
	assert_str(String(t[0][&"id"])).is_equal(String(FixtureBn.IDS[6]))
	assert_int(t[0][&"raridade"]).is_equal(SorteioDeOferta.EPICA)
	assert_str(String(t[1][&"id"])).is_equal(String(FixtureBn.IDS[0]))
	assert_bool(t.is_read_only()).is_true()


func test_id_fora_do_pool_recusado() -> void:
	var reg := RegistroDeBencaos.new(FixtureBn.boons())
	assert_bool(reg.registrar(&"trad_inexistente", SorteioDeOferta.COMUM)).is_false()
	assert_int(reg.restantes()).is_equal(18)


func test_nova_run_recria_registro_vazio() -> void:
	var reg := RegistroDeBencaos.new(FixtureBn.boons())
	reg.registrar(FixtureBn.IDS[3], SorteioDeOferta.COMUM)
	reg = RegistroDeBencaos.new(FixtureBn.boons())
	assert_array(reg.tomadas()).is_empty()
	assert_int(reg.restantes()).is_equal(18)
