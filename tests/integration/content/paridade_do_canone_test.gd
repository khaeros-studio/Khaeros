extends GdUnitTestSuite
## Story conteudo-010 & assets-e-conteudo-001..005, 009 [I]:
## Carga real de `res://assets/data/content_catalog.tres`, paridade com o cânone (F1–F6),
## V1–V11 + validadores dos donos (1ª e 2ª passadas), varredura de órfãos e CSVs `keep`
## (AC-01, AC-04, AC-20, AC-34, AC-37, AC-39, AC-41, AC-45, AC-48, AC-53, AC-60).


func _registros_completos() -> RegistrosDeChaves:
	var r := FabricasDeCatalogo.registros()
	TabelaDeEfeitos.registrar_em(r)
	return r


func test_ac01_ac20_ac53_manifesto_real_carrega_pronto_com_zero_erros() -> void:
	var textos := TabelaDeTextosCsv.de_arquivo("res://assets/i18n/conteudo.csv")
	var registros := _registros_completos()
	var validador := ValidadorDeCatalogo.new(registros, textos, VerificadorDeArte.new())
	var donos := FabricasDeCatalogo.validadores_dos_donos()
	for d in donos:
		validador.acrescentar(d)
	validador.acrescentar(V5NomesCanonicos.new(textos))
	validador.acrescentar(V9IdsRegistrados.de_arquivo("res://assets/data/canon/ids_registrados.csv"))

	var sp := SegundaPassada.new(donos)
	var carregador := CarregadorDeCatalogo.new(validador, RelatorAcumulador.new(), null, sp, 60)
	var ok := carregador.carregar()
	var msgs: Array = carregador.diagnosticos().map(func(d: Diagnostico) -> String: return d.texto())
	assert_bool(ok).override_failure_message("\n".join(msgs)).is_true()
	assert_int(carregador.estado()).is_equal(CarregadorDeCatalogo.Estado.PRONTO)

	var cat := carregador.catalogo()
	assert_object(cat).is_not_null()
	assert_int(cat.listar(&"weapon").size()).is_equal(5)
	assert_bool(cat.existe(&"weapon", &"guardiao")).is_true()
	assert_bool(cat.existe(&"weapon", &"veu")).is_true()
	assert_int(cat.listar(&"enemy").size()).is_equal(5)
	assert_int(cat.listar(&"boon").size()).is_equal(18)
	assert_int(cat.listar(&"curse").size()).is_equal(4)
	assert_int(cat.listar(&"region").size()).is_equal(1)
	assert_int(cat.listar(&"som").size()).is_equal(10)
	assert_bool(cat.existe(&"enemy", &"anomalia_maior")).is_true()
	assert_bool(cat.existe(&"enemy", &"soberano_do_limiar")).is_true()


func test_ac04_e_ac45_zero_orfaos_em_assets_data_e_csvs_canon_com_importer_keep() -> void:
	var manifesto := ResourceLoader.load("res://assets/data/content_catalog.tres") as ManifestoDoCatalogo
	assert_object(manifesto).is_not_null()
	var em_disco := VarreduraDeOrfaos.listar_tres_em_disco("res://assets/data")
	var orfaos := VarreduraDeOrfaos.verificar_orfaos(manifesto, em_disco)
	assert_array(orfaos).is_empty()

	# Verifica que todo .tres listado no manifesto tem todos os campos obrigatórios gravados no texto
	for i in manifesto.tamanho():
		var cam := manifesto.caminhos[i]
		var def := ResourceLoader.load(cam) as DefinicaoBase
		var txt := FileAccess.get_file_as_string(cam)
		var diags_txt := VarreduraDeOrfaos.verificar_texto_tres(txt, def, cam, i)
		assert_array(diags_txt).override_failure_message(cam).is_empty()

	# AC-45: todo .csv em assets/data/canon/ tem .csv.import com importer="keep" e zero .translation
	var dir := DirAccess.open("res://assets/data/canon")
	assert_object(dir).is_not_null()
	var csvs_vistos := 0
	for f in dir.get_files():
		assert_bool(f.ends_with(".translation")).is_false()
		if f.ends_with(".csv"):
			csvs_vistos += 1
			var imp := "res://assets/data/canon/" + f + ".import"
			assert_bool(FileAccess.file_exists(imp)).override_failure_message("Falta " + imp).is_true()
			var imp_txt := FileAccess.get_file_as_string(imp)
			assert_str(imp_txt).contains("importer=\"keep\"")
	assert_int(csvs_vistos).is_greater_equal(8)


func test_ac34_ac37_ac39_ac41_paridade_das_bencaos_armas_e_inimigos_com_o_canone() -> void:
	var textos := TabelaDeTextosCsv.de_arquivo("res://assets/i18n/conteudo.csv")
	var registros := _registros_completos()
	var validador := ValidadorDeCatalogo.new(registros, textos, VerificadorDeArte.new())
	var carregador := CarregadorDeCatalogo.new(validador, RelatorAcumulador.new(), null, 60)
	assert_bool(carregador.carregar()).is_true()
	var cat := carregador.catalogo()

	# AC-37 & AC-41: 18 bênçãos na ordem exata de FixtureBn.IDS
	var boons := cat.listar(&"boon")
	var ids_boon: Array[StringName] = []
	for b: DefinicaoBase in boons:
		ids_boon.append(b.id)
	assert_array(ids_boon).is_equal(FixtureBn.IDS)

	var corte_fantasma := cat.obter(&"boon", &"trad_blade_corte_fantasma", "teste") as BoonDef
	assert_float(corte_fantasma.efeitos[0].valor).is_equal_approx(10.0, 1e-6)
	assert_float(corte_fantasma.efeitos[0].params[&"sangramento"]).is_equal_approx(1.0, 1e-6)

	var linha_contada := cat.obter(&"boon", &"trad_resonance_linha_contada", "teste") as BoonDef
	assert_float(linha_contada.efeitos[0].params[&"a_cada"]).is_equal_approx(4.0, 1e-6)
	var tpl_linha := textos.texto(String(linha_contada.chave_descricao))
	assert_str(V10Descricoes.preencher(tpl_linha, linha_contada.efeitos, 1.0)).is_equal("Cada 4º acerto causa +60% de dano.")
	assert_str(V10Descricoes.preencher(tpl_linha, linha_contada.efeitos, 2.0)).is_equal("Cada 4º acerto causa +120% de dano.")

	var fardo := cat.obter(&"boon", &"trad_pacts_fardo_repartido", "teste") as BoonDef
	assert_float(fardo.efeitos[0].valor).is_equal_approx(3.0, 1e-6)

	var preco_nome := cat.obter(&"boon", &"trad_resonance_preco_nome", "teste") as BoonDef
	assert_int(preco_nome.efeitos.size()).is_equal(2)
	assert_str(String(preco_nome.chave_preco)).is_equal("TRAD_RESONANCE_PRECO_NOME_PRICE")

	# AC-34 & AC-39: paridade de armas e inimigos importados pelo mapa_ids.csv
	var mapa := ImportadorDeCanone.carregar_mapa_ids()
	var r_lam := ImportadorDeCanone.converter_arma(mapa, {
		"id": "BLADE", "doctrine": "BLADE", "maxHp": 100, "moveSpeed": 4.3,
		"attack": {"shape": "arc", "damage": 14.0, "cooldownTicks": 16, "knockback": 5.0, "range": 95.0, "dot": 0.35, "combo": [1.0, 1.0, 1.8]},
		"special": {"shape": "lunge", "damage": 26.0, "cooldownTicks": 70, "knockback": 12.0, "distance": 220.0, "durationTicks": 10, "radius": 46.0},
	})
	assert_bool(r_lam["ok"]).is_true()
	var lam_imp: WeaponDef = r_lam["definicao"]
	var lam_cat := cat.obter(&"weapon", &"lamina", "teste") as WeaponDef
	assert_int(lam_cat.vida_max).is_equal(lam_imp.vida_max)
	assert_float(lam_cat.velocidade).is_equal_approx(lam_imp.velocidade, 1e-6)
	assert_float(lam_cat.ataque.dano).is_equal_approx(lam_imp.ataque.dano, 1e-6)
	assert_float(lam_cat.ataque.recarga_s).is_equal_approx(lam_imp.ataque.recarga_s, 1e-6)
	assert_float(lam_cat.ataque.params[&"alcance_px"]).is_equal_approx(lam_imp.ataque.params[&"alcance_px"], 1e-6)
	assert_float(lam_cat.ataque.params[&"meio_angulo_graus"]).is_equal_approx(lam_imp.ataque.params[&"meio_angulo_graus"], 1e-6)
	assert_str(String(lam_cat.ataque.forma)).is_equal("arco")
	assert_str(String(lam_cat.especial.forma)).is_equal("avanco")

	var limiar := cat.obter(&"region", &"limiar", "teste") as RegionDef
	assert_array(limiar.camaras).is_equal([&"combate", &"combate", &"combate", &"santuario", &"combate", &"combate", &"chefe"])
	assert_array(limiar.pool_inimigos).is_equal([&"eco_perdido", &"anomalia_menor", &"fenda_errante"])
	assert_str(String(limiar.chefe)).is_equal("soberano_do_limiar")
