extends GdUnitTestSuite
## Testes unitários para [CatalogoCampanha]: 4 regiões, 4 chefes, 15 bênçãos e sorteio determinístico.


func test_quatro_regioes_em_ordem_com_paleta_ondas_e_chefes() -> void:
	var regioes: Array[Dictionary] = CatalogoCampanha.regioes()
	assert_int(regioes.size()).is_equal(4)

	var ids_esperados: Array[String] = [
		"limiar",
		"veio_instavel",
		"fosso_das_cinzas",
		"santuario_partido",
	]
	var chefes_esperados: Array[String] = [
		"soberano_do_limiar",
		"guardiao_do_rito",
		"colosso_de_cinza",
		"arconte_da_fenda",
	]
	var vidas_esperadas: Array[float] = [700.0, 950.0, 1150.0, 1400.0]
	var estilos_esperados: Array[String] = ["soberano", "leque", "colosso", "arconte"]
	var motifs_esperados: Array[String] = ["limiar", "veio", "cinzas", "santuario"]

	var chefes_unicos: Dictionary = {}
	for i: int in regioes.size():
		var reg: Dictionary = regioes[i]
		assert_str(String(reg["id"])).is_equal(ids_esperados[i])
		assert_str(String(reg["nome"])).is_not_empty()
		assert_str(String(reg["motif"])).is_equal(motifs_esperados[i])
		assert_bool(reg["bg"] is Color).is_true()
		assert_bool(reg["floor"] is Color).is_true()
		assert_bool(reg["accent"] is Color).is_true()
		assert_bool(reg["border"] is Color).is_true()

		var ondas: Array = reg["ondas"] as Array
		assert_int(ondas.size()).is_equal(3)
		for onda_var: Variant in ondas:
			var onda: Array = onda_var as Array
			assert_int(onda.size()).is_greater(0)

		var chefe: Dictionary = reg["chefe"] as Dictionary
		var chefe_id: String = String(chefe["id"])
		assert_str(chefe_id).is_equal(chefes_esperados[i])
		assert_str(String(chefe["nome"])).is_not_empty()
		assert_float(float(chefe["vida"])).is_equal(vidas_esperadas[i])
		assert_str(String(chefe["boss_style"])).is_equal(estilos_esperados[i])
		chefes_unicos[chefe_id] = true

	assert_int(chefes_unicos.size()).is_equal(4)


func test_pool_de_quinze_bencaos_validas() -> void:
	var pool: Array[Dictionary] = CatalogoCampanha.bencaos_pool()
	assert_int(pool.size()).is_equal(15)

	var raridades_validas: Array[String] = ["comum", "rara", "epica"]
	var ids_vistos: Dictionary = {}
	var efeitos_vistos: Dictionary = {}

	for item: Dictionary in pool:
		var item_id: String = String(item["id"])
		var nome: String = String(item["nome"])
		var texto: String = String(item["texto"])
		var raridade: String = String(item["raridade"])
		var efeito: String = String(item["efeito"])
		var valor: float = float(item["valor"])

		assert_str(item_id).is_not_empty()
		assert_bool(ids_vistos.has(item_id)).is_false()
		ids_vistos[item_id] = true

		assert_str(nome).is_not_empty()
		assert_str(texto).is_not_empty()
		assert_bool(raridades_validas.has(raridade)).is_true()
		assert_str(efeito).is_not_empty()
		assert_float(valor).is_greater(0.0)
		efeitos_vistos[efeito] = true

	var efeitos_obrigatorios: Array[String] = [
		"dano_pct",
		"velocidade_pct",
		"vida_max_cura",
		"esquiva_carga",
		"esquiva_recarga",
		"ataque_rapido",
		"alcance_pct",
		"vampirismo",
		"empurrao_pct",
		"especial_dano",
		"escudo_camara",
		"critico_chance",
	]
	for ef: String in efeitos_obrigatorios:
		assert_bool(efeitos_vistos.has(ef)).is_true()


func test_sortear_oferta_deterministica_e_tres_distintas() -> void:
	var vazias: Array[StringName] = []
	var oferta_a: Array[Dictionary] = CatalogoCampanha.sortear_oferta(0x4B484145, 0, vazias)
	var oferta_b: Array[Dictionary] = CatalogoCampanha.sortear_oferta(0x4B484145, 0, vazias)
	assert_int(oferta_a.size()).is_equal(3)
	assert_int(oferta_b.size()).is_equal(3)

	var ids_a: Array[String] = []
	var ids_b: Array[String] = []
	var unicos_a: Dictionary = {}
	for i: int in 3:
		var id_a: String = String(oferta_a[i]["id"])
		var id_b: String = String(oferta_b[i]["id"])
		ids_a.append(id_a)
		ids_b.append(id_b)
		unicos_a[id_a] = true

	assert_array(ids_a).is_equal(ids_b)
	assert_int(unicos_a.size()).is_equal(3)

	# Respeita ja_tomadas quando ha pelo menos 3 disponiveis
	var tomadas: Array[StringName] = [
		StringName(ids_a[0]),
		StringName(ids_a[1]),
		StringName(ids_a[2]),
	]
	var oferta_filtrada: Array[Dictionary] = CatalogoCampanha.sortear_oferta(0x4B484145, 1, tomadas)
	assert_int(oferta_filtrada.size()).is_equal(3)
	var unicos_f: Dictionary = {}
	for carta: Dictionary in oferta_filtrada:
		var cid: StringName = StringName(String(carta["id"]))
		assert_bool(tomadas.has(cid)).is_false()
		unicos_f[cid] = true
	assert_int(unicos_f.size()).is_equal(3)

	# Mesmo com quase todo o pool tomado, continua retornando 3 cartas distintas
	var pool: Array[Dictionary] = CatalogoCampanha.bencaos_pool()
	var quase_todas: Array[StringName] = []
	for i: int in range(pool.size() - 1):
		quase_todas.append(StringName(String(pool[i]["id"])))
	var oferta_fallback: Array[Dictionary] = CatalogoCampanha.sortear_oferta(0x12345678, 2, quase_todas)
	assert_int(oferta_fallback.size()).is_equal(3)
	var unicos_fb: Dictionary = {}
	for carta_fb: Dictionary in oferta_fallback:
		unicos_fb[String(carta_fb["id"])] = true
	assert_int(unicos_fb.size()).is_equal(3)
