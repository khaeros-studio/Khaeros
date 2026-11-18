extends GdUnitTestSuite
## Story run-e-regioes/008: ResumoDaRun imutável (12 campos) e duração em passos.
## Cobre AC-RN-18, AC-RN-23 e AC-RN-37.


func test_ac_rn_18_23_37_resumo_12_campos_imutavel_e_exemplos_f2_f3() -> void:
	var bencaos: Array[StringName] = [&"b1", &"b2"]
	var dupla: Array[StringName] = [&"vulto_mudo", &"espreitador_da_fenda"]
	# Exemplo F2: coletou 7 e venceu (+15) -> 22; 3600 passos -> 60,0 s
	var r_vit := ResumoDaRun.new(
		&"vitoria", "3F9A-07C2", &"pactos", 7,
		bencaos, 7, 15, 24, 3600, &"pactuado", dupla
	)
	assert_str(String(r_vit.motivo())).is_equal("vitoria")
	assert_str(r_vit.seed_texto()).is_equal("3F9A-07C2")
	assert_str(String(r_vit.arma())).is_equal("pactos")
	assert_int(r_vit.camaras_limpas()).is_equal(7)
	assert_array(r_vit.bencaos_tomadas()).is_equal([&"b1", &"b2"])
	assert_int(r_vit.fragmentos_coletados()).is_equal(7)
	assert_int(r_vit.bonus_vitoria()).is_equal(15)
	assert_int(r_vit.total()).is_equal(22)
	assert_int(r_vit.abates()).is_equal(24)
	assert_float(r_vit.duracao_s()).is_equal_approx(60.0, 1e-6)
	assert_str(String(r_vit.desfecho_chefe())).is_equal("pactuado")
	assert_array(r_vit.dupla()).is_equal([&"vulto_mudo", &"espreitador_da_fenda"])

	# Imutabilidade: mutar os arrays originais não altera o resumo, e os arrays devolvidos são read-only
	bencaos.append(&"b3")
	dupla.append(&"baluarte_de_cinza")
	assert_int(r_vit.bencaos_tomadas().size()).is_equal(2)
	assert_int(r_vit.dupla().size()).is_equal(2)
	assert_bool(r_vit.bencaos_tomadas().is_read_only()).is_true()
	assert_bool(r_vit.dupla().is_read_only()).is_true()

	# Exemplos F2: coletou 7 e morreu -> total 7; coletou 4 e abandonou -> total 4 (após limpar 0..3 -> 4 câmaras limpas)
	var r_morte := ResumoDaRun.new(&"morte", "3F9A-07C2", &"lamina", 4, [], 7, 15, 10, 1200)
	assert_int(r_morte.bonus_vitoria()).is_equal(0)
	assert_int(r_morte.total()).is_equal(7)
	assert_int(r_morte.camaras_limpas()).is_equal(4)

	var r_aband := ResumoDaRun.new(&"abandono", "3F9A-07C2", &"lamina", 2, [], 4, 15, 5, 600)
	assert_int(r_aband.total()).is_equal(4)
	assert_int(r_aband.para_dicionario().size()).is_equal(12)
