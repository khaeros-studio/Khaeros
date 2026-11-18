extends GdUnitTestSuite
## Story armas-das-doutrinas-002: Validação das armas (AV1–AV9, V2, nomes canônicos R8)
## (AC-AR-23 a AC-AR-34, AC-AR-49, AC-AR-50).


func test_ac_ar_23_av1_guarda() -> void:
	for par: Array in [
		[0.0, 0, ""],
		[8.0 / 60.0, 0, ""],
		[9.0 / 60.0, 1, "razão"],
		[15.0 / 60.0, 1, "razão"],
		[16.0 / 60.0, 1, "permanente"],
		[20.0 / 60.0, 1, "permanente"],
	]:
		var w: WeaponDef = FabricaDeArmas.lamina()
		w.ataque.guarda_s = float(par[0])
		var rel := ValidadorArmas.validar_catalogo([w])
		var av1 := rel.avisos_do_codigo(&"AV1")
		assert_int(av1.size()).is_equal(int(par[1]))
		if int(par[1]) > 0:
			assert_bool(av1[0].mensagem.contains(String(par[2]))).is_true()
		assert_int(rel.avisos_do_codigo(&"AV7").size()).is_equal(0)


func test_ac_ar_24_av2_paridade_entre_armas() -> void:
	var lam: WeaponDef = FabricaDeArmas.lamina()
	var res: WeaponDef = FabricaDeArmas.ressonancia()
	# s = 1,149 -> sem AV2; s = 1,151 -> 1 AV2; s = 0,85 -> 1 AV2
	for par: Array in [[1.149, 0], [1.151, 1], [0.85, 1]]:
		var s: float = float(par[0])
		var clone: WeaponDef = lam.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as WeaponDef
		clone.id = &"lamina_teste"
		clone.ataque.dano *= s
		clone.especial.dano *= s
		var rel := ValidadorArmas.validar_catalogo([lam, clone])
		assert_int(rel.avisos_do_codigo(&"AV2").size()).is_equal(int(par[1]))

	# Com 3 armas (lamina, ressonancia, lamina x 1,151): só lamina x lamina_teste avisa
	var clone_151: WeaponDef = lam.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as WeaponDef
	clone_151.id = &"lamina_teste"
	clone_151.ataque.dano *= 1.151
	clone_151.especial.dano *= 1.151
	var rel3 := ValidadorArmas.validar_catalogo([lam, res, clone_151])
	assert_array(rel3.av2_pares).is_equal(["lamina×lamina_teste"])


func test_ac_ar_25_e_49_av3_pontos_frageis_conjunto_exato() -> void:
	var duas_armas: Array[WeaponDef] = [FabricaDeArmas.lamina(), FabricaDeArmas.ressonancia()]
	var tres_armas: Array[WeaponDef] = FabricaDeArmas.armas_mvp()

	# p_max região = 7: 29 linhas nas 2 armas; + 10 com a Besta = 39 no total
	var rel_2_p7 := ValidadorArmas.validar_catalogo(duas_armas, FabricaDeArmas.tuning(4), null, {}, 7)
	var rel_3_p7 := ValidadorArmas.validar_catalogo(tres_armas, FabricaDeArmas.tuning(4), null, {}, 7)
	assert_int(rel_2_p7.av3_tuplas.size()).is_equal(29)
	assert_int(rel_3_p7.av3_tuplas.size()).is_equal(39)
	# Com alias p_max = 4 e região = 7, WV8 sai como aviso
	assert_int(rel_3_p7.avisos_do_codigo(&"WV8").size()).is_equal(1)

	# p_max fábrica = 4: 20 nas duas armas; 20 + 8 = 28 com a Besta; sem WV8
	var rel_2_p4 := ValidadorArmas.validar_catalogo(duas_armas, FabricaDeArmas.tuning(4), null, {}, 4)
	var rel_3_p4 := ValidadorArmas.validar_catalogo(tres_armas, FabricaDeArmas.tuning(4), null, {}, 4)
	assert_int(rel_2_p4.av3_tuplas.size()).is_equal(20)
	assert_int(rel_3_p4.av3_tuplas.size()).is_equal(28)
	assert_int(rel_3_p4.avisos_do_codigo(&"WV8").size()).is_equal(0)

	# margem_fragil = 0 em p_max = 7: 9 nas duas armas; 9 + 3 = 12 com a Besta
	var t_zero := FabricaDeArmas.tuning(7)
	t_zero.margem_fragil = 0
	assert_int(ValidadorArmas.validar_catalogo(duas_armas, t_zero, null, {}, 7).av3_tuplas.size()).is_equal(9)
	assert_int(ValidadorArmas.validar_catalogo(tres_armas, t_zero, null, {}, 7).av3_tuplas.size()).is_equal(12)


func test_ac_ar_26_e_27_e_28_av4_av5_av6() -> void:
	# AC-AR-26: catálogo de fábrica não dispara AV4 em p_max 3, 4 ou 7
	for p_max: int in [3, 4, 7]:
		var rel_fab := ValidadorArmas.validar_catalogo(FabricaDeArmas.armas_mvp(), FabricaDeArmas.tuning(p_max), null, {}, p_max)
		assert_array(rel_fab.av4_inimigos).is_empty()

	# Ataque sem combo pesado (dano 14, empurrao 900, R = 30): p_max 3 -> Eco, Fenda; p_max 4 e 7 -> Eco, Anomalia, Fenda
	var w_trava: WeaponDef = FabricaDeArmas.lamina()
	w_trava.ataque.multiplicadores_combo = PackedFloat64Array()
	w_trava.ataque.dano = 14.0
	w_trava.ataque.empurrao = 900.0
	w_trava.ataque.recarga_s = 30.0 / 60.0
	assert_array(ValidadorArmas.validar_catalogo([w_trava], null, null, {}, 3).av4_inimigos).is_equal([&"eco_perdido", &"fenda_errante"] as Array[StringName])
	assert_array(ValidadorArmas.validar_catalogo([w_trava], null, null, {}, 4).av4_inimigos).is_equal([&"eco_perdido", &"anomalia_menor", &"fenda_errante"] as Array[StringName])
	assert_array(ValidadorArmas.validar_catalogo([w_trava], null, null, {}, 7).av4_inimigos).is_equal([&"eco_perdido", &"anomalia_menor", &"fenda_errante"] as Array[StringName])

	# AC-AR-27: AV5 no Pulso (R = 14, teto 610,56)
	for par: Array in [[540.0, 0], [610.0, 0], [611.0, 1], [899.0, 1], [900.0, 0]]:
		var res: WeaponDef = FabricaDeArmas.ressonancia()
		res.ataque.empurrao = float(par[0])
		assert_int(ValidadorArmas.validar_catalogo([res]).avisos_do_codigo(&"AV5").size()).is_equal(int(par[1]))

	# AC-AR-28: AV6 repassa CV5 e CV13 sem duplicar como AV
	var w_cv5: WeaponDef = FabricaDeArmas.lamina()
	w_cv5.ataque.recarga_s = 34.0 / 60.0
	assert_int(ValidadorArmas.validar_catalogo([w_cv5]).avisos_do_codigo(&"CV5").size()).is_equal(1)

	var w_cv13: WeaponDef = FabricaDeArmas.ressonancia()
	w_cv13.ataque.params[&"vida_s"] = 1.0 / 60.0
	assert_int(ValidadorArmas.validar_catalogo([w_cv13]).erros_do_codigo(&"CV13").size()).is_equal(1)


func test_ac_ar_29_e_30_e_31_av7_v2_av8() -> void:
	# AC-AR-29: AV7 faixas de design (vida_max 70 e 140 passam; 69 e 141 avisam)
	for par: Array in [[70, 0], [140, 0], [69, 1], [141, 1]]:
		var w: WeaponDef = FabricaDeArmas.lamina()
		w.vida_max = int(par[0])
		assert_int(ValidadorArmas.validar_catalogo([w]).avisos_do_codigo(&"AV7").size()).is_equal(int(par[1]))

	# AC-AR-30: V2 erros de carga (vida_max 19 e 301 dão erro V2; velocidade 199,99 e 600,01 dão V2)
	for v_err: int in [19, 301]:
		var w: WeaponDef = FabricaDeArmas.lamina()
		w.vida_max = v_err
		assert_int(ValidadorArmas.validar_catalogo([w]).erros_do_codigo(&"V2").size()).is_equal(1)

	# AC-AR-31: AV8 fração do Especial na Lâmina (13,6 e 51,9 avisam; 13,8 e 51,6 passam)
	for par: Array in [[13.6, 1], [13.8, 0], [51.6, 0], [51.9, 1]]:
		var w: WeaponDef = FabricaDeArmas.lamina()
		w.especial.dano = float(par[0])
		assert_int(ValidadorArmas.validar_catalogo([w]).avisos_do_codigo(&"AV8").size()).is_equal(int(par[1]))


func test_ac_ar_32_e_33_e_34_e_50_catalogo_fabrica_av9_e_nomes_canonicos() -> void:
	# AC-AR-32 e AC-AR-50: catálogo de fábrica com as 3 armas tem 0 erros e 0 avisos AV
	var rel := ValidadorArmas.validar_catalogo(FabricaDeArmas.armas_mvp(), FabricaDeArmas.tuning(4), null, {}, 4)
	assert_array(rel.erros).is_empty()
	assert_array(rel.avisos).is_empty()

	# AV9: chamado no Especial da Lâmina, no Ataque de Pactos ou com combo dá erro AV9
	var w1: WeaponDef = FabricaDeArmas.lamina()
	w1.especial.forma = AtaqueConvertido.FORMA_CHAMADO
	assert_int(ValidadorArmas.validar_catalogo([w1]).erros_do_codigo(&"AV9").size()).is_equal(1)

	var w2: WeaponDef = FabricaDeArmas.pactos()
	w2.ataque.forma = AtaqueConvertido.FORMA_CHAMADO
	assert_int(ValidadorArmas.validar_catalogo([w2]).erros_do_codigo(&"AV9").size()).is_equal(1)

	var w3: WeaponDef = FabricaDeArmas.pactos()
	w3.especial.multiplicadores_combo = PackedFloat64Array([1.0, 1.8])
	assert_int(ValidadorArmas.validar_catalogo([w3]).erros_do_codigo(&"AV9").size()).is_equal(1)

	# AC-AR-33: nomes canônicos (sem acento dá V5; NFD normaliza para NFC e passa)
	assert_object(ValidadorArmas.validar_nome_canonico(&"WEAPON_LAMINA_NAME", "Lâmina do Juramento")).is_null()
	assert_object(ValidadorArmas.validar_nome_canonico(&"WEAPON_LAMINA_NAME", "Lamina do Juramento")).is_not_null()
	assert_object(ValidadorArmas.validar_nome_canonico(&"WEAPON_LAMINA_NAME", "La\u0302mina do Juramento")).is_null()

	# AC-AR-34: nenhuma outra chave pode resolver para "Corte" solto
	var tab_ok: Dictionary = FabricaDeArmas.NOMES_CANONICOS.duplicate()
	assert_array(ValidadorArmas.validar_corte_vs_corte_da_esquiva(tab_ok)).is_empty()
	tab_ok[&"TRAD_BLADE_CORTE_FANTASMA_NAME"] = "Corte"
	assert_bool(ValidadorArmas.validar_corte_vs_corte_da_esquiva(tab_ok).size() > 0).is_true()
