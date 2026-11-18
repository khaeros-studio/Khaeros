extends GdUnitTestSuite
## Story vinculo-e-pactos/004: Sorteio do encontro (F1) no fluxo RNG `pactos` e consultas.
## Cobre AC-VP-03, AC-VP-04, AC-VP-05 e AC-VP-06.


func test_ac_vp_03_garantia_g1_primeiro_encontro_indice_1_espreitador_e_4_reais() -> void:
	var p := PerfilVinculo.new()
	p.primeiro_pacto_concedido = true
	p.registrar_pacto_novo(&"vulto_mudo")
	var vt := FabricasDeCatalogo.vinculo_tuning()

	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte.iniciar_run(0xABCDEF12, true)
	var fp := FluxosDeVinculo.new(fonte).pactos(0)

	var res := SorteioDoEncontro.sortear(p, vt, fp)
	assert_bool(res.ocorre).is_true()
	assert_int(res.indice_camara).is_equal(1)
	assert_str(String(res.especie_id)).is_equal("espreitador_da_fenda")
	assert_int(res.reais_consumidos.size()).is_equal(4)


func test_ac_vp_04_consumo_fixo_4_reais_com_e_sem_encontro_pendente() -> void:
	var vt := FabricasDeCatalogo.vinculo_tuning()
	var p1 := PerfilVinculo.new()
	p1.primeiro_encontro_visto = true
	p1.registrar_pacto_novo(&"vulto_mudo")

	var p2 := PerfilVinculo.new()
	p2.primeiro_encontro_visto = true
	p2.registrar_pacto_novo(&"vulto_mudo")
	p2.encontro_pendente = ["baluarte_de_cinza"]

	var f1 := FonteDeFluxos.new(RelatorDeErrosRng.new())
	f1.iniciar_run(0x12345678, true)
	var fp1 := FluxosDeVinculo.new(f1).pactos(0)
	var r1 := SorteioDoEncontro.sortear(p1, vt, fp1)

	var f2 := FonteDeFluxos.new(RelatorDeErrosRng.new())
	f2.iniciar_run(0x12345678, true)
	var fp2 := FluxosDeVinculo.new(f2).pactos(0)
	var r2 := SorteioDoEncontro.sortear(p2, vt, fp2)

	assert_array(r1.reais_consumidos).is_equal(r2.reais_consumidos)
	assert_int(fp1.estado()).is_equal(fp2.estado())
	assert_str(String(r2.especie_id)).is_equal("baluarte_de_cinza")


func test_ac_vp_05_exemplo_f1_com_reais_fixos_e_reafirmacao() -> void:
	var vt := FabricasDeCatalogo.vinculo_tuning()
	var p := PerfilVinculo.new()
	p.primeiro_encontro_visto = true
	p.registrar_pacto_novo(&"vulto_mudo")
	p.registrar_pacto_novo(&"espreitador_da_fenda")

	# u = (0,42; 0,81; 0,30; 0,55) -> ocorre, índice 2, espécie baluarte_de_cinza
	var r_np := SorteioDoEncontro.sortear_com_reais(p, vt, 0.42, 0.81, 0.30, 0.55)
	assert_bool(r_np.ocorre).is_true()
	assert_int(r_np.indice_camara).is_equal(2)
	assert_str(String(r_np.especie_id)).is_equal("baluarte_de_cinza")

	# Com u2 = 0,90 (>= 0,75): grupo P {vulto_mudo (3), espreitador_da_fenda (2)}, u3 = 0,55 < 0,6 -> vulto_mudo
	var r_p := SorteioDoEncontro.sortear_com_reais(p, vt, 0.42, 0.81, 0.90, 0.55)
	assert_str(String(r_p.especie_id)).is_equal("vulto_mudo")


func test_ac_vp_06_garantia_g3_pity_runs() -> void:
	var vt := FabricasDeCatalogo.vinculo_tuning()
	var p := PerfilVinculo.new()
	p.primeiro_encontro_visto = true
	p.runs_pactos_sem_encontro = 2
	p.registrar_pacto_novo(&"vulto_mudo")

	var r := SorteioDoEncontro.sortear_com_reais(p, vt, 0.99, 0.1, 0.1, 0.1)
	assert_bool(r.ocorre).is_true()
