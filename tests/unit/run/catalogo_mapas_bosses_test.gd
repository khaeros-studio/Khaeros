extends GdUnitTestSuite
## Testes unitários para [CatalogoMapasBosses]: progressão dos 5 mapas e 5 chefes de Khaeros,
## mecanismos táticos, fraquezas obrigatórias, espólios canônicos, geometria segura,
## imutabilidade por cópia profunda e consolidação de assets em [method CatalogoMapasBosses.resumo_assets_totais].


func test_cinco_mapas_em_ordem_crescente_com_ids_e_chefes_unicos() -> void:
	var lista_mapas: Array[Dictionary] = CatalogoMapasBosses.mapas()
	assert_int(lista_mapas.size()).is_equal(5)

	var ids_esperados: Array[String] = [
		"colina_raizes_profundas",
		"costa_abissal",
		"escarpas_copa_quebrada",
		"fendas_cinzentas",
		"terras_baldias_subterraneas",
	]
	assert_array(CatalogoMapasBosses.ids_mapas()).is_equal(ids_esperados)

	var nomes_esperados: Array[String] = [
		"Colina das Raízes Profundas",
		"Costa Abissal (Cais da Água Negra)",
		"Escarpas da Copa Quebrada",
		"Fendas Cinzentas (Fosso-Prisão Antigo)",
		"Terras Baldias Subterrâneas (Abismo dos Selos)",
	]
	var ranks_esperados: Array[String] = ["C+", "A+", "A+", "S", "Cataclísmico"]
	var niveis_esperados: Array[int] = [21, 48, 53, 74, 90]
	var escalas_esperadas: Array[float] = [8.0, 32.0, 20.0, 25.0, 50.0]
	var zooms_esperados: Array[float] = [1.08, 0.92, 0.94, 0.90, 0.82]
	var formas_esperadas: Array[String] = ["circular", "costeira", "verticalizada", "retangular", "caverna"]

	var bosses_esperados: Array[String] = [
		"devorador_coroa_espinhos",
		"leviata_mare_morta",
		"vigia_coroa_partida",
		"tirano_quebra_grilhoes",
		"pesadelo_fendas_subterraneas",
	]
	var nomes_bosses_esperados: Array[String] = [
		"Devorador da Coroa de Espinhos",
		"Leviatã da Maré Morta",
		"Vigia da Coroa Partida",
		"Tirano Quebra-Grilhões",
		"Pesadelo das Fendas Subterrâneas",
	]
	var vidas_esperadas: Array[float] = [1250.0, 2400.0, 2850.0, 3900.0, 6200.0]
	var velocidades_esperadas: Array[float] = [0.0, 165.0, 122.0, 158.0, 175.0]
	var raios_esperados: Array[float] = [88.0, 108.0, 102.0, 112.0, 136.0]
	var danos_esperados: Array[float] = [19.0, 28.0, 32.0, 38.0, 46.0]
	var sprites_esperados: Array[float] = [1.45, 2.15, 2.05, 2.25, 2.85]

	var campos_obrigatorios: Array[String] = [
		"id",
		"nome",
		"subtitulo",
		"bioma",
		"rank",
		"nivel_recomendado",
		"escala_metros",
		"camera_zoom",
		"paleta",
		"arena",
		"boss",
		"zonas_seguras",
		"perigos_dinamicos",
		"obstaculos",
		"interativos",
		"props_storytelling",
		"mecanicas_ambientais",
		"assets_necessarios",
	]

	var ids_mapas_unicos: Dictionary = {}
	var ids_bosses_unicos: Dictionary = {}
	var nivel_anterior: int = 0

	for i: int in range(lista_mapas.size()):
		var mapa: Dictionary = lista_mapas[i]
		for campo: String in campos_obrigatorios:
			assert_bool(mapa.has(campo)).is_true()

		var id_mapa: String = String(mapa["id"])
		var nivel: int = int(mapa["nivel_recomendado"])
		assert_str(id_mapa).is_equal(ids_esperados[i])
		assert_str(String(mapa["nome"])).is_equal(nomes_esperados[i])
		assert_str(String(mapa["subtitulo"])).is_not_empty()
		assert_str(String(mapa["bioma"])).is_not_empty()
		assert_str(String(mapa["rank"])).is_equal(ranks_esperados[i])
		assert_int(nivel).is_equal(niveis_esperados[i])
		assert_int(nivel).is_greater(nivel_anterior)
		nivel_anterior = nivel

		assert_float(float(mapa["escala_metros"])).is_equal(escalas_esperadas[i])
		assert_float(float(mapa["camera_zoom"])).is_equal(zooms_esperados[i])

		var paleta: Dictionary = mapa["paleta"] as Dictionary
		assert_bool(paleta["bg"] is Color).is_true()
		assert_bool(paleta["floor"] is Color).is_true()
		assert_bool(paleta["accent"] is Color).is_true()
		assert_bool(paleta["border"] is Color).is_true()
		assert_str(String(paleta["motif"])).is_not_empty()

		var arena: Dictionary = mapa["arena"] as Dictionary
		assert_str(String(arena["forma"])).is_equal(formas_esperadas[i])

		var boss: Dictionary = mapa["boss"] as Dictionary
		var id_boss: String = String(boss["id"])
		assert_str(id_boss).is_equal(bosses_esperados[i])
		assert_str(String(boss["nome"])).is_equal(nomes_bosses_esperados[i])
		assert_str(String(boss["arquetipo"])).is_not_empty()
		assert_float(float(boss["vida"])).is_equal(vidas_esperadas[i])
		assert_float(float(boss["velocidade"])).is_equal(velocidades_esperadas[i])
		assert_float(float(boss["raio_px"])).is_equal(raios_esperados[i])
		assert_float(float(boss["dano"])).is_equal(danos_esperados[i])
		assert_float(float(boss["escala_sprite"])).is_equal(sprites_esperados[i])

		var habilidades: Array = boss["habilidades"] as Array
		assert_int(habilidades.size()).is_equal(4)

		assert_bool(ids_mapas_unicos.has(id_mapa)).is_false()
		assert_bool(ids_bosses_unicos.has(id_boss)).is_false()
		ids_mapas_unicos[id_mapa] = true
		ids_bosses_unicos[id_boss] = true

		var por_id: Dictionary = CatalogoMapasBosses.obter_mapa(id_mapa)
		assert_str(String(por_id["id"])).is_equal(id_mapa)
		var por_boss: Dictionary = CatalogoMapasBosses.obter_por_boss(id_boss)
		assert_str(String(por_boss["id"])).is_equal(id_mapa)

	assert_int(ids_mapas_unicos.size()).is_equal(5)
	assert_int(ids_bosses_unicos.size()).is_equal(5)
	assert_bool(CatalogoMapasBosses.obter_mapa("").is_empty()).is_true()
	assert_bool(CatalogoMapasBosses.obter_mapa("mapa_inexistente").is_empty()).is_true()
	assert_bool(CatalogoMapasBosses.obter_por_boss("").is_empty()).is_true()
	assert_bool(CatalogoMapasBosses.obter_por_boss("boss_inexistente").is_empty()).is_true()


func test_perigos_contramedidas_mecanicas_assets_e_espolios_canonicos() -> void:
	var lista_mapas: Array[Dictionary] = CatalogoMapasBosses.mapas()
	var espolios_esperados_por_boss: Dictionary = {
		"devorador_coroa_espinhos": [
			{"id": "nucleo_espinho", "nome": "Núcleo de Espinho"},
			{"id": "casca_espinhosa", "nome": "Casca Espinhosa"},
		],
		"leviata_mare_morta": [
			{"id": "nucleo_abissal", "nome": "Núcleo Abissal"},
			{"id": "escama_ruina", "nome": "Escama de Ruína"},
		],
		"vigia_coroa_partida": [
			{"id": "nucleo_coroa", "nome": "Núcleo da Coroa"},
			{"id": "placa_coroa_regenerada", "nome": "Placa de Coroa Regenerada"},
		],
		"tirano_quebra_grilhoes": [
			{"id": "nucleo_tirano", "nome": "Núcleo do Tirano"},
			{"id": "garra_fendedora", "nome": "Garra Fendedora"},
		],
		"pesadelo_fendas_subterraneas": [
			{"id": "nucleo_abismo", "nome": "Núcleo do Abismo"},
		],
	}

	for mapa: Dictionary in lista_mapas:
		var zonas_seguras: Array = mapa["zonas_seguras"] as Array
		var perigos_dinamicos: Array = mapa["perigos_dinamicos"] as Array
		var obstaculos: Array = mapa["obstaculos"] as Array
		var interativos: Array = mapa["interativos"] as Array
		var mecanicas: Array = mapa["mecanicas_ambientais"] as Array
		var assets: Dictionary = mapa["assets_necessarios"] as Dictionary
		var boss: Dictionary = mapa["boss"] as Dictionary
		var boss_id: String = String(boss["id"])

		assert_int(perigos_dinamicos.size()).is_greater_equal(1)
		assert_int(zonas_seguras.size() + obstaculos.size() + interativos.size()).is_greater_equal(1)
		assert_int(mecanicas.size()).is_greater_equal(1)

		for mec_var: Variant in mecanicas:
			var mec: Dictionary = mec_var as Dictionary
			assert_str(String(mec["id"])).is_not_empty()
			assert_str(String(mec["nome"])).is_not_empty()
			assert_int(int(mec["intervalo_passos"])).is_greater_equal(0)

		assert_str(String(assets["arena_bg"])).is_not_empty()
		for chave_lista: String in ["tiles", "props", "vfx", "indicadores_perigo", "boss_atlases"]:
			var arr_assets: Array = assets[chave_lista] as Array
			assert_int(arr_assets.size()).is_greater_equal(1)
			for item_var: Variant in arr_assets:
				assert_str(String(item_var)).is_not_empty()

		var espolios_reais: Array = boss["espolios"] as Array
		var espolios_ref: Array = espolios_esperados_por_boss[boss_id] as Array
		assert_int(espolios_reais.size()).is_equal(espolios_ref.size())
		for idx: int in range(espolios_ref.size()):
			var esperado: Dictionary = espolios_ref[idx] as Dictionary
			var obtido: Dictionary = espolios_reais[idx] as Dictionary
			assert_str(String(obtido["id"])).is_equal(String(esperado["id"]))
			assert_str(String(obtido["nome"])).is_equal(String(esperado["nome"]))

	# Verificações específicas de layout por mapa do plano canônico
	var m1: Dictionary = CatalogoMapasBosses.obter_mapa("colina_raizes_profundas")
	assert_int(_contar_por_tipo(m1["zonas_seguras"] as Array, "laje_pedra_antiga")).is_equal(5)
	assert_int(_contar_por_tipo(m1["perigos_dinamicos"] as Array, "solo_raizes_sensor")).is_equal(1)
	assert_int(_contar_por_tipo(m1["perigos_dinamicos"] as Array, "bolsao_esporos")).is_equal(4)

	var m2: Dictionary = CatalogoMapasBosses.obter_mapa("costa_abissal")
	assert_int(_contar_por_tipo(m2["obstaculos"] as Array, "quebra_mares_farol")).is_equal(3)

	var m3: Dictionary = CatalogoMapasBosses.obter_mapa("escarpas_copa_quebrada")
	var platos_e2: int = 0
	var pontes_e1: int = 0
	for z3_var: Variant in (m3["zonas_seguras"] as Array):
		var z3: Dictionary = z3_var as Dictionary
		var elev: int = int(z3.get("elevacao", 0))
		if elev == 2:
			platos_e2 += 1
		elif elev == 1:
			pontes_e1 += 1
	assert_int(platos_e2).is_equal(3)
	assert_int(pontes_e1).is_equal(2)
	var obs3: Array = m3["obstaculos"] as Array
	assert_int(obs3.size()).is_equal(4)
	for ob3_var: Variant in obs3:
		var ob3: Dictionary = ob3_var as Dictionary
		assert_bool(bool(ob3["destrutivel"])).is_true()
		assert_float(float(ob3["hp"])).is_equal(120.0)

	var m4: Dictionary = CatalogoMapasBosses.obter_mapa("fendas_cinzentas")
	assert_int(_contar_por_tipo(m4["perigos_dinamicos"] as Array, "correntes_partidas")).is_equal(3)
	var obs4: Array = m4["obstaculos"] as Array
	assert_int(obs4.size()).is_equal(4)
	for ob4_var: Variant in obs4:
		var ob4: Dictionary = ob4_var as Dictionary
		assert_str(String(ob4["tipo"])).is_equal("monolito_contencao")
		assert_str(String(ob4["efeito_impacto_boss"])).is_equal("interrompe_investida_e_atordoa")


func test_boss_cinco_fraquezas_obrigatorias_e_interativos_correspondentes() -> void:
	var mapa5: Dictionary = CatalogoMapasBosses.obter_por_boss("pesadelo_fendas_subterraneas")
	assert_str(String(mapa5["id"])).is_equal("terras_baldias_subterraneas")

	var boss5: Dictionary = mapa5["boss"] as Dictionary
	assert_str(String(boss5["nome"])).is_equal("Pesadelo das Fendas Subterrâneas")

	var fraquezas_raw: Array = boss5["fraquezas"] as Array
	var fraquezas: Array[String] = []
	for fr_var: Variant in fraquezas_raw:
		fraquezas.append(String(fr_var))

	var obrigatorias: Array[String] = [
		"Luz Sagrada",
		"Vibrações Harmônicas",
		"Selos Antigos",
	]
	for obg: String in obrigatorias:
		assert_bool(fraquezas.has(obg)).is_true()

	var zonas_seguras5: Array = mapa5["zonas_seguras"] as Array
	assert_int(_contar_por_tipo(zonas_seguras5, "fenda_luz_sagrada")).is_equal(3)
	assert_int(_contar_por_tipo(zonas_seguras5, "rocha_matriz_runica")).is_greater_equal(1)

	var interativos5: Array = mapa5["interativos"] as Array
	var selos_contagem: int = 0
	var cristais_contagem: int = 0
	for it_var: Variant in interativos5:
		var it: Dictionary = it_var as Dictionary
		var tipo_it: String = String(it["tipo"])
		var acao_it: String = String(it["acao"])
		if tipo_it == "selo_runico_antigo":
			assert_str(acao_it).is_equal("conter_na_superficie_e_cortar_regeneracao")
			selos_contagem += 1
		elif tipo_it == "cristal_harmonico":
			assert_str(acao_it).is_equal("emitir_vibracao_harmonica_desorientar")
			cristais_contagem += 1

	assert_int(selos_contagem).is_equal(4)
	assert_int(cristais_contagem).is_equal(3)


func test_geometria_segura_sem_sobreposicao_no_spawn_e_dentro_das_margens() -> void:
	var lista_mapas: Array[Dictionary] = CatalogoMapasBosses.mapas()
	var margem: float = 80.0

	for mapa: Dictionary in lista_mapas:
		var arena: Dictionary = mapa["arena"] as Dictionary
		var largura: float = float(arena["largura"])
		var altura: float = float(arena["altura"])
		var spawn_jogador: Vector2 = arena["spawn_jogador"] as Vector2
		var spawn_boss: Vector2 = arena["spawn_boss"] as Vector2
		var boss: Dictionary = mapa["boss"] as Dictionary
		var raio_boss: float = float(boss["raio_px"])

		_assert_dentro_da_arena(spawn_jogador, 0.0, largura, altura, margem)
		_assert_dentro_da_arena(spawn_boss, 0.0, largura, altura, margem)

		var listas_espaciais: Array[String] = [
			"zonas_seguras",
			"perigos_dinamicos",
			"obstaculos",
			"interativos",
			"props_storytelling",
		]
		for chave: String in listas_espaciais:
			var elementos: Array = mapa[chave] as Array
			for el_var: Variant in elementos:
				var el: Dictionary = el_var as Dictionary
				var pos: Vector2 = el["pos"] as Vector2
				var raio: float = float(el.get("raio", 0.0))
				_assert_dentro_da_arena(pos, raio, largura, altura, margem)

		var obstaculos: Array = mapa["obstaculos"] as Array
		for ob_var: Variant in obstaculos:
			var ob: Dictionary = ob_var as Dictionary
			var pos_ob: Vector2 = ob["pos"] as Vector2
			var raio_ob: float = float(ob["raio"])
			assert_float(pos_ob.distance_to(spawn_jogador)).is_greater_equal(raio_ob + 140.0)
			assert_float(pos_ob.distance_to(spawn_boss)).is_greater_equal(raio_ob + raio_boss)


func test_imutabilidade_por_copia_profunda_e_precisao_resumo_assets_totais() -> void:
	var copia_a: Dictionary = CatalogoMapasBosses.obter_mapa("terras_baldias_subterraneas")
	assert_str(String(copia_a["nome"])).is_equal("Terras Baldias Subterrâneas (Abismo dos Selos)")

	# Mutações profundas na cópia retornada não devem contaminar chamadas subsequentes
	copia_a["nome"] = "Mutado"
	(copia_a["arena"] as Dictionary)["largura"] = 99999.0
	(copia_a["arena"] as Dictionary)["spawn_jogador"] = Vector2.ZERO
	(copia_a["boss"] as Dictionary)["vida"] = 1.0
	((copia_a["boss"] as Dictionary)["fraquezas"] as Array).clear()
	((copia_a["boss"] as Dictionary)["espolios"] as Array).clear()
	(copia_a["zonas_seguras"] as Array).clear()
	(copia_a["interativos"] as Array).clear()
	((copia_a["assets_necessarios"] as Dictionary)["tiles"] as Array).append("res://asset_falso.png")

	var copia_b: Dictionary = CatalogoMapasBosses.obter_mapa("terras_baldias_subterraneas")
	assert_str(String(copia_b["nome"])).is_equal("Terras Baldias Subterrâneas (Abismo dos Selos)")
	assert_float(float((copia_b["arena"] as Dictionary)["largura"])).is_equal(3800.0)
	assert_vector((copia_b["arena"] as Dictionary)["spawn_jogador"] as Vector2).is_equal(Vector2(1900.0, 1780.0))
	assert_float(float((copia_b["boss"] as Dictionary)["vida"])).is_equal(6200.0)
	assert_int(((copia_b["boss"] as Dictionary)["fraquezas"] as Array).size()).is_equal(3)
	assert_int(((copia_b["boss"] as Dictionary)["espolios"] as Array).size()).is_equal(1)
	assert_int((copia_b["zonas_seguras"] as Array).size()).is_equal(6)
	assert_int((copia_b["interativos"] as Array).size()).is_equal(7)
	assert_bool(((copia_b["assets_necessarios"] as Dictionary)["tiles"] as Array).has("res://asset_falso.png")).is_false()

	# Verifica também isolamento em obter_por_boss() e mapas()
	var por_boss: Dictionary = CatalogoMapasBosses.obter_por_boss("devorador_coroa_espinhos")
	(por_boss["boss"] as Dictionary)["dano"] = 9999.0
	var lista_nova: Array[Dictionary] = CatalogoMapasBosses.mapas()
	assert_float(float((lista_nova[0]["boss"] as Dictionary)["dano"])).is_equal(19.0)

	# Verifica consolidação exata e unicidade de resumo_assets_totais()
	var resumo: Dictionary = CatalogoMapasBosses.resumo_assets_totais()
	var categorias: Array[String] = [
		"arena_bg",
		"tiles",
		"props",
		"vfx",
		"indicadores_perigo",
		"boss_atlases",
	]
	assert_int(resumo.size()).is_equal(categorias.size())

	var esperados_unicos: Dictionary = {}
	for cat: String in categorias:
		esperados_unicos[cat] = {}

	for mapa_item: Dictionary in lista_nova:
		var assets_mapa: Dictionary = mapa_item["assets_necessarios"] as Dictionary
		for cat: String in categorias:
			var conjunto: Dictionary = esperados_unicos[cat] as Dictionary
			var val: Variant = assets_mapa[cat]
			if val is String:
				conjunto[String(val)] = true
			elif val is Array:
				for elem_var: Variant in (val as Array):
					conjunto[String(elem_var)] = true

	for cat: String in categorias:
		assert_bool(resumo.has(cat)).is_true()
		var lista_resumo: Array = resumo[cat] as Array
		var conjunto_esp: Dictionary = esperados_unicos[cat] as Dictionary
		assert_int(lista_resumo.size()).is_equal(conjunto_esp.size())
		var vistos_resumo: Dictionary = {}
		for asset_var: Variant in lista_resumo:
			var asset_str: String = String(asset_var)
			assert_str(asset_str).is_not_empty()
			assert_bool(vistos_resumo.has(asset_str)).is_false()
			assert_bool(conjunto_esp.has(asset_str)).is_true()
			vistos_resumo[asset_str] = true

	assert_int((resumo["arena_bg"] as Array).size()).is_equal(5)
	assert_int((resumo["boss_atlases"] as Array).size()).is_equal(5)

	# Mutar o resumo retornado não contamina chamadas futuras
	(resumo["arena_bg"] as Array).clear()
	var resumo_2: Dictionary = CatalogoMapasBosses.resumo_assets_totais()
	assert_int((resumo_2["arena_bg"] as Array).size()).is_equal(5)


func _assert_dentro_da_arena(
	pos: Vector2,
	raio: float,
	largura: float,
	altura: float,
	margem: float
) -> void:
	assert_float(pos.x).is_greater_equal(margem)
	assert_float(pos.x).is_less_equal(largura - margem)
	assert_float(pos.y).is_greater_equal(margem)
	assert_float(pos.y).is_less_equal(altura - margem)
	if raio > 0.0:
		assert_float(pos.x - raio).is_greater_equal(margem)
		assert_float(pos.x + raio).is_less_equal(largura - margem)
		assert_float(pos.y - raio).is_greater_equal(margem)
		assert_float(pos.y + raio).is_less_equal(altura - margem)


func _contar_por_tipo(itens: Array, tipo_alvo: String) -> int:
	var total: int = 0
	for item_var: Variant in itens:
		var item: Dictionary = item_var as Dictionary
		if String(item.get("tipo", "")) == tipo_alvo:
			total += 1
	return total
