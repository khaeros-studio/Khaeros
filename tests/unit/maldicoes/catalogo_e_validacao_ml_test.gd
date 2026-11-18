extends GdUnitTestSuite


func test_ac_ml_04_catalogo_4_especies_atributos_exatos() -> void:
	var catalogo: Dictionary[StringName, CurseDef] = CatalogoMaldicoes.especies_mvp()
	assert_int(catalogo.size()).is_equal(4)

	var vulto: CurseDef = catalogo[&"vulto_mudo"]
	assert_float(vulto.vida_max).is_equal_approx(110.0, 0.001)
	assert_float(vulto.dano_basico).is_equal_approx(6.0, 0.001)
	assert_float(vulto.alcance_basico_px).is_equal_approx(105.0, 0.001)
	assert_float(vulto.velocidade).is_equal_approx(405.0, 0.001)
	assert_str(String(vulto.raridade)).is_equal("comum")

	var espreitador: CurseDef = catalogo[&"espreitador_da_fenda"]
	assert_float(espreitador.vida_max).is_equal_approx(100.0, 0.001)
	assert_float(espreitador.dano_basico).is_equal_approx(5.0, 0.001)
	assert_float(espreitador.alcance_basico_px).is_equal_approx(120.0, 0.001)
	assert_float(espreitador.velocidade).is_equal_approx(450.0, 0.001)
	assert_str(String(espreitador.raridade)).is_equal("refinado")
	assert_bool(espreitador.passivas.has(&"faro_do_vinculo")).is_true()

	var baluarte: CurseDef = catalogo[&"baluarte_de_cinza"]
	assert_float(baluarte.vida_max).is_equal_approx(140.0, 0.001)
	assert_float(baluarte.dano_basico).is_equal_approx(9.0, 0.001)
	assert_float(baluarte.alcance_basico_px).is_equal_approx(120.0, 0.001)
	assert_float(baluarte.velocidade).is_equal_approx(330.0, 0.001)
	assert_str(String(baluarte.raridade)).is_equal("raro")
	assert_bool(baluarte.passivas.has(&"carapaca_ancorada")).is_true()
	assert_str(String(baluarte.efeito_chamado)).is_equal("eco_de_muralha")

	var soberano: CurseDef = catalogo[&"soberano_do_limiar"]
	assert_float(soberano.vida_max).is_equal_approx(130.0, 0.001)
	assert_float(soberano.dano_basico).is_equal_approx(7.0, 0.001)
	assert_float(soberano.alcance_basico_px).is_equal_approx(135.0, 0.001)
	assert_float(soberano.velocidade).is_equal_approx(420.0, 0.001)
	assert_str(String(soberano.raridade)).is_equal("primordial")
	assert_bool(soberano.passivas.has(&"presenca_do_limiar")).is_true()
	assert_bool(soberano.passivas.has(&"vinculo_inquebravel")).is_true()
	assert_str(String(soberano.habilidade_unica)).is_equal("pulso_de_soberania")


func test_ac_ml_23_ml1_ml2_ml3_ml4_rejeitam_dados_invalidos() -> void:
	var mt_ruim := CatalogoMaldicoes.tuning_de_fabrica()
	mt_ruim.distancia_seguir_px = 500.0
	mt_ruim.alcance_fio_px = 480.0
	mt_ruim.duracao_salto_s = 0.0

	var c_ruim := CatalogoMaldicoes.vulto_mudo()
	c_ruim.vida_max = 10.0
	c_ruim.efeito_saida = &""
	c_ruim.chefe_origem_id = &"soberano_do_limiar"

	var itens: Array[ItemDoCatalogo] = [
		ItemDoCatalogo.new(&"tuning", "res://mt.tres", 0, mt_ruim),
		ItemDoCatalogo.new(&"curse", "res://c.tres", 1, c_ruim),
	]
	var diags: Array[Diagnostico] = ValidadorMaldicoes.validar_completo(itens)
	var cods := diags.map(func(d: Diagnostico) -> StringName: return d.regra)
	assert_bool(cods.has(&"ML1")).is_true()
	assert_bool(cods.has(&"ML2")).is_true()
	assert_bool(cods.has(&"ML3")).is_true()
	assert_bool(cods.has(&"ML4")).is_true()


func test_ac_ml_26_e_36_teto_de_atracao_e_abalo_do_eco_de_muralha() -> void:
	var mt := CatalogoMaldicoes.tuning_de_fabrica()
	var itens: Array[ItemDoCatalogo] = [
		ItemDoCatalogo.new(&"tuning", "res://mt.tres", 0, mt),
		ItemDoCatalogo.new(&"weapon", "res://pactos.tres", 1, FabricasDeCatalogo.arma(&"pactos", 80, &"projetil")),
	]
	# AC-ML-26: duracao_atracao_s (1,60 s = 96) + respiro (0,50 s = 30) = 126 > recarga_chamado (120) -> ML1
	mt.duracao_atracao_s = 1.60
	var diags_atr := ValidadorMaldicoes.validar_completo(itens, null, 0.50, 1.50, 1.50)
	var cods_atr := diags_atr.map(func(d: Diagnostico) -> StringName: return d.regra)
	assert_bool(cods_atr.has(&"ML1")).is_true()
	assert_bool(cods_atr.has(&"ML6")).is_true()

	# AC-ML-36: duracao_abalo_s do Eco de Muralha (2,00 s = 120) >= recarga_chamado (120) -> ML1
	mt.duracao_atracao_s = 1.50
	var diags_abalo := ValidadorMaldicoes.validar_completo(itens, null, 0.50, 1.50, 2.00)
	var cods_abalo := diags_abalo.map(func(d: Diagnostico) -> StringName: return d.regra)
	assert_bool(cods_abalo.has(&"ML1")).is_true()


func test_ac_ml_27_f6_paridade_pactos_60_40_e_sem_avisos_no_catalogo_padrao() -> void:
	var itens: Array[ItemDoCatalogo] = [
		ItemDoCatalogo.new(&"tuning", "res://mt.tres", 0, CatalogoMaldicoes.tuning_de_fabrica()),
		ItemDoCatalogo.new(&"tuning", "res://vt.tres", 1, FabricasDeCatalogo.vinculo_tuning()),
		ItemDoCatalogo.new(&"enemy", "res://sob.tres", 2, FabricasDeCatalogo.chefe_soberano()),
		ItemDoCatalogo.new(&"curse", "res://c1.tres", 3, CatalogoMaldicoes.vulto_mudo()),
		ItemDoCatalogo.new(&"curse", "res://c2.tres", 4, CatalogoMaldicoes.espreitador_da_fenda()),
		ItemDoCatalogo.new(&"curse", "res://c3.tres", 5, CatalogoMaldicoes.baluarte_de_cinza()),
		ItemDoCatalogo.new(&"curse", "res://c4.tres", 6, CatalogoMaldicoes.soberano_do_limiar()),
		ItemDoCatalogo.new(&"weapon", "res://w1.tres", 7, FabricasDeCatalogo.arma(&"lamina", 100, &"avanco")),
		ItemDoCatalogo.new(&"weapon", "res://w2.tres", 8, FabricasDeCatalogo.arma(&"ressonancia", 80, &"circulo")),
		ItemDoCatalogo.new(&"weapon", "res://w3.tres", 9, FabricasDeCatalogo.arma(&"pactos", 80, &"projetil")),
	]
	var diags := ValidadorMaldicoes.validar_completo(itens)
	assert_int(diags.size()).is_equal(0)

	var f6 := ValidadorMaldicoes.calcular_paridade_f6(itens)
	assert_float(float(f6["f_besta_min"])).is_greater_equal(0.50)
	assert_float(float(f6["f_besta_max"])).is_less_equal(0.70)
	assert_float(float(f6["paridade_max"])).is_less_equal(0.05)
