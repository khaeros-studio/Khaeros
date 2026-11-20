extends GdUnitTestSuite
## Testes unitários para [ArvoreDosReinos] (9 Reinos jogáveis em escalada roguelike)
## e expansão de [SistemaQuests] (11 Contratos da Ordem, incluindo os 5 novos chefes).


func test_nove_reinos_em_ordem_canonica_e_helpers_de_busca() -> void:
	# Arrange
	var ids_esperados: Array[String] = [
		"limiar",
		"colina_raizes_profundas",
		"veio_instavel",
		"fosso_das_cinzas",
		"costa_abissal",
		"escarpas_copa_quebrada",
		"santuario_partido",
		"fendas_cinzentas",
		"terras_baldias_subterraneas",
	]
	var nomes_esperados: Array[String] = [
		"O Limiar da Beira",
		"Colina das Raízes Profundas",
		"Veio Instável",
		"Fosso das Cinzas",
		"Costa Abissal",
		"Escarpas da Copa Quebrada",
		"Santuário Partido",
		"Fendas Cinzentas",
		"Terras Baldias Subterrâneas",
	]
	var subtitulos_esperados: Array[String] = [
		"As Lajes do Primeiro Juramento",
		"Clareira do Sensor Vivo",
		"Fissuras da Ressonância",
		"A Fornalha Silenciosa",
		"Cais da Água Negra",
		"Platôs dos Seis Olhos",
		"Observatório Estrelado",
		"Fosso-Prisão Imperial",
		"Abismo dos Selos Antigos",
	]
	var ranks_esperados: Array[String] = ["D", "C+", "B", "A", "A+", "A+", "S-", "S", "Cataclísmico"]
	var niveis_esperados: Array[int] = [1, 21, 30, 38, 48, 53, 64, 74, 90]
	var tiers_esperados: Array[int] = [1, 1, 1, 2, 2, 2, 3, 3, 3]
	var hp_mults_esperados: Array[float] = [1.0, 1.35, 1.65, 2.00, 2.40, 2.80, 3.30, 3.90, 4.80]
	var dmg_mults_esperados: Array[float] = [1.0, 1.15, 1.25, 1.35, 1.48, 1.60, 1.75, 1.92, 2.15]
	var zooms_esperados: Array[float] = [1.12, 1.08, 1.12, 1.12, 0.92, 0.94, 1.12, 0.90, 0.82]
	var quests_esperadas: Array[String] = [
		"queda_soberano",
		"coroa_de_espinhos",
		"ecos_do_veio",
		"forja_silenciada",
		"mare_morta",
		"vigia_escarpa",
		"santuario_partido",
		"tirano_quebrado",
		"pesadelo_selado",
	]

	# Act
	var lista: Array[Dictionary] = ArvoreDosReinos.reinos()

	# Assert
	assert_int(ArvoreDosReinos.total_reinos()).is_equal(9)
	assert_int(lista.size()).is_equal(9)

	for i: int in range(lista.size()):
		var reino: Dictionary = lista[i]
		assert_int(int(reino["indice"])).is_equal(i)
		assert_str(String(reino["id"])).is_equal(ids_esperados[i])
		assert_str(String(reino["nome"])).is_equal(nomes_esperados[i])
		assert_str(String(reino["subtitulo"])).is_equal(subtitulos_esperados[i])
		assert_str(String(reino["rank"])).is_equal(ranks_esperados[i])
		assert_int(int(reino["nivel"])).is_equal(niveis_esperados[i])
		assert_int(int(reino["tier"])).is_equal(tiers_esperados[i])
		assert_float(float(reino["hp_mult"])).is_equal_approx(hp_mults_esperados[i], 0.0001)
		assert_float(float(reino["dmg_mult"])).is_equal_approx(dmg_mults_esperados[i], 0.0001)
		assert_float(float(reino["camera_zoom"])).is_equal_approx(zooms_esperados[i], 0.0001)
		assert_str(String(reino["quest_id"])).is_equal(quests_esperadas[i])

		var por_indice: Dictionary = ArvoreDosReinos.obter_reino(i)
		assert_str(String(por_indice["id"])).is_equal(ids_esperados[i])
		var por_id: Dictionary = ArvoreDosReinos.obter_por_id(ids_esperados[i])
		assert_int(int(por_id["indice"])).is_equal(i)

	assert_bool(ArvoreDosReinos.obter_reino(-1).is_empty()).is_true()
	assert_bool(ArvoreDosReinos.obter_reino(9).is_empty()).is_true()
	assert_bool(ArvoreDosReinos.obter_por_id("").is_empty()).is_true()
	assert_bool(ArvoreDosReinos.obter_por_id("reino_inexistente").is_empty()).is_true()


func test_escalada_monotonica_estrita_de_nivel_hp_e_dano() -> void:
	# Arrange
	var lista: Array[Dictionary] = ArvoreDosReinos.reinos()
	var nivel_anterior: int = 0
	var hp_mult_anterior: float = 0.0
	var dmg_mult_anterior: float = 0.0
	var tier_anterior: int = 1

	# Act & Assert
	for reino: Dictionary in lista:
		var nivel: int = int(reino["nivel"])
		var hp_mult: float = float(reino["hp_mult"])
		var dmg_mult: float = float(reino["dmg_mult"])
		var tier: int = int(reino["tier"])

		assert_int(nivel).is_greater(nivel_anterior)
		assert_float(hp_mult).is_greater(hp_mult_anterior)
		assert_float(dmg_mult).is_greater(dmg_mult_anterior)
		assert_int(tier).is_greater_equal(tier_anterior)
		assert_bool(tier >= 1 and tier <= 3).is_true()

		nivel_anterior = nivel
		hp_mult_anterior = hp_mult
		dmg_mult_anterior = dmg_mult
		tier_anterior = tier


func test_nove_chefes_unicos_espolios_paletas_pilares_e_ondas_validas() -> void:
	# Arrange
	var chefes_esperados: Array[String] = [
		"soberano_do_limiar",
		"devorador_coroa_espinhos",
		"guardiao_do_rito",
		"colosso_de_cinza",
		"leviata_mare_morta",
		"vigia_coroa_partida",
		"arconte_da_fenda",
		"tirano_quebra_grilhoes",
		"pesadelo_fendas_subterraneas",
	]
	var arquetipos_validos: Array[String] = [
		"eco_perdido",
		"anomalia_menor",
		"vulto_mudo",
		"espreitador_da_fenda",
		"baluarte_de_cinza",
		"fenda_errante",
	]
	var lista: Array[Dictionary] = ArvoreDosReinos.reinos()
	var chefes_unicos: Dictionary = {}

	# Act & Assert
	for i: int in range(lista.size()):
		var reino: Dictionary = lista[i]
		assert_bool(reino["bg"] is Color).is_true()
		assert_bool(reino["floor"] is Color).is_true()
		assert_bool(reino["accent"] is Color).is_true()
		assert_bool(reino["border"] is Color).is_true()
		assert_str(String(reino["fala_entrada"])).is_not_empty()

		var paleta: Dictionary = reino["paleta"] as Dictionary
		assert_bool(paleta["bg"] is Color).is_true()
		assert_bool(paleta["floor"] is Color).is_true()
		assert_bool(paleta["accent"] is Color).is_true()
		assert_bool(paleta["border"] is Color).is_true()

		var pilares: Array = reino["pilares"] as Array
		assert_int(pilares.size()).is_greater_equal(2)
		for pilar_var: Variant in pilares:
			var pilar: Dictionary = pilar_var as Dictionary
			assert_float(float(pilar["x"])).is_greater(0.0)
			assert_float(float(pilar["y"])).is_greater(0.0)
			assert_float(float(pilar["r"])).is_greater(0.0)

		var ondas: Array = reino["ondas"] as Array
		assert_int(ondas.size()).is_equal(3)
		for onda_var: Variant in ondas:
			var onda: Array = onda_var as Array
			assert_int(onda.size()).is_greater_equal(4)
			for spawn_var: Variant in onda:
				var spawn: Dictionary = spawn_var as Dictionary
				assert_bool(arquetipos_validos.has(String(spawn["id"]))).is_true()

		var chefe: Dictionary = reino["chefe"] as Dictionary
		var chefe_id: String = String(chefe["id"])
		assert_str(chefe_id).is_equal(chefes_esperados[i])
		assert_bool(chefes_unicos.has(chefe_id)).is_false()
		chefes_unicos[chefe_id] = true

		assert_str(String(chefe["nome"])).is_not_empty()
		assert_float(float(chefe["vida"])).is_greater(0.0)
		assert_float(float(chefe["velocidade"])).is_greater_equal(0.0)
		assert_float(float(chefe["raio"])).is_greater(0.0)
		assert_float(float(chefe["dano"])).is_greater(0.0)

		var espolios_chefe: Array = chefe["espolios"] as Array
		var espolios_reino: Array = reino["espolios"] as Array
		assert_int(espolios_chefe.size()).is_greater_equal(1)
		assert_int(espolios_reino.size()).is_equal(espolios_chefe.size())
		for j: int in range(espolios_chefe.size()):
			var esp_nome: String = String(espolios_chefe[j])
			assert_str(esp_nome).is_not_empty()
			assert_str(String(espolios_reino[j])).is_equal(esp_nome)

	assert_int(chefes_unicos.size()).is_equal(9)

	# Verifica paridade exata dos 5 reinos avançados com CatalogoMapasBosses
	var ids_avancados: Array[String] = CatalogoMapasBosses.ids_mapas()
	for mapa_id: String in ids_avancados:
		var mapa: Dictionary = CatalogoMapasBosses.obter_mapa(mapa_id)
		var reino_av: Dictionary = ArvoreDosReinos.obter_por_id(mapa_id)
		var boss_mapa: Dictionary = mapa["boss"] as Dictionary
		var chefe_av: Dictionary = reino_av["chefe"] as Dictionary
		assert_float(float(reino_av["camera_zoom"])).is_equal_approx(float(mapa["camera_zoom"]), 0.0001)
		assert_str(String(chefe_av["id"])).is_equal(String(boss_mapa["id"]))
		assert_float(float(chefe_av["vida"])).is_equal_approx(float(boss_mapa["vida"]), 0.0001)
		assert_float(float(chefe_av["velocidade"])).is_equal_approx(float(boss_mapa["velocidade"]), 0.0001)
		assert_float(float(chefe_av["raio"])).is_equal_approx(float(boss_mapa["raio_px"]), 0.0001)
		assert_float(float(chefe_av["dano"])).is_equal_approx(float(boss_mapa["dano"]), 0.0001)


func test_tree_pos_e_conexoes_dag_validas_dentro_de_0_a_8() -> void:
	# Arrange
	var pos_esperadas: Array[Vector2] = [
		Vector2(0.50, 0.86),
		Vector2(0.24, 0.72),
		Vector2(0.76, 0.72),
		Vector2(0.50, 0.56),
		Vector2(0.22, 0.42),
		Vector2(0.78, 0.42),
		Vector2(0.50, 0.30),
		Vector2(0.32, 0.17),
		Vector2(0.50, 0.08),
	]
	var conexoes_esperadas: Array = [
		[1, 2],
		[3],
		[3],
		[4, 5],
		[6],
		[6],
		[7],
		[8],
		[],
	]
	var lista: Array[Dictionary] = ArvoreDosReinos.reinos()

	# Act & Assert
	for i: int in range(lista.size()):
		var reino: Dictionary = lista[i]
		var tree_pos: Vector2 = reino["tree_pos"] as Vector2
		assert_bool(tree_pos.x > 0.0 and tree_pos.x < 1.0).is_true()
		assert_bool(tree_pos.y > 0.0 and tree_pos.y < 1.0).is_true()
		assert_vector(tree_pos).is_equal_approx(pos_esperadas[i], Vector2(0.0001, 0.0001))

		var conexoes: Array = reino["conexoes"] as Array
		var esperadas_i: Array = conexoes_esperadas[i] as Array
		assert_int(conexoes.size()).is_equal(esperadas_i.size())
		var destinos_vistos: Dictionary = {}
		for j: int in range(conexoes.size()):
			var dest: int = int(conexoes[j])
			assert_int(dest).is_equal(int(esperadas_i[j]))
			assert_bool(dest >= 0 and dest <= 8).is_true()
			assert_int(dest).is_greater(i)
			assert_bool(destinos_vistos.has(dest)).is_false()
			destinos_vistos[dest] = true

	# Alcançabilidade completa a partir da raiz (índice 0)
	var alcancados: Dictionary = {0: true}
	var fila: Array[int] = [0]
	while not fila.is_empty():
		var atual: int = int(fila.pop_front())
		var conexoes_atual: Array = lista[atual]["conexoes"] as Array
		for dest_var: Variant in conexoes_atual:
			var dest_idx: int = int(dest_var)
			if not alcancados.has(dest_idx):
				alcancados[dest_idx] = true
				fila.append(dest_idx)
	assert_int(alcancados.size()).is_equal(9)


func test_imutabilidade_por_copia_profunda_em_reinos_e_helpers() -> void:
	# Arrange
	var lista_a: Array[Dictionary] = ArvoreDosReinos.reinos()
	var reino_a: Dictionary = ArvoreDosReinos.obter_reino(8)
	var por_id_a: Dictionary = ArvoreDosReinos.obter_por_id("limiar")

	# Act — muta profundamente todas as estruturas retornadas
	lista_a[0]["nome"] = "Mutado"
	(lista_a[0]["paleta"] as Dictionary)["motif"] = "mutado"
	(lista_a[0]["pilares"] as Array).clear()
	((lista_a[0]["ondas"] as Array)[0] as Array).clear()
	(lista_a[0]["chefe"] as Dictionary)["vida"] = 1.0
	((lista_a[0]["chefe"] as Dictionary)["espolios"] as Array).clear()
	(lista_a[0]["espolios"] as Array).clear()
	(lista_a[0]["conexoes"] as Array).clear()

	reino_a["nivel"] = -99
	(reino_a["chefe"] as Dictionary)["dano"] = 9999.0
	(reino_a["espolios"] as Array).append("Espolio Falso")

	por_id_a["rank"] = "Z"
	(por_id_a["conexoes"] as Array).append(99)

	# Assert — consultas subsequentes permanecem intactas
	var lista_b: Array[Dictionary] = ArvoreDosReinos.reinos()
	var limiar_b: Dictionary = lista_b[0]
	assert_str(String(limiar_b["nome"])).is_equal("O Limiar da Beira")
	assert_str(String(limiar_b["rank"])).is_equal("D")
	assert_str(String((limiar_b["paleta"] as Dictionary)["motif"])).is_equal("limiar")
	assert_int((limiar_b["pilares"] as Array).size()).is_equal(2)
	assert_int(((limiar_b["ondas"] as Array)[0] as Array).size()).is_equal(4)
	assert_float(float((limiar_b["chefe"] as Dictionary)["vida"])).is_equal_approx(700.0, 0.0001)
	assert_int(((limiar_b["chefe"] as Dictionary)["espolios"] as Array).size()).is_equal(2)
	assert_int((limiar_b["espolios"] as Array).size()).is_equal(2)
	assert_int((limiar_b["conexoes"] as Array).size()).is_equal(2)

	var reino_b: Dictionary = ArvoreDosReinos.obter_reino(8)
	assert_int(int(reino_b["nivel"])).is_equal(90)
	assert_float(float((reino_b["chefe"] as Dictionary)["dano"])).is_equal_approx(46.0, 0.0001)
	assert_int((reino_b["espolios"] as Array).size()).is_equal(1)


func test_sistema_quests_onze_contratos_e_abates_dos_cinco_novos_chefes() -> void:
	# Arrange
	var quests: SistemaQuests = SistemaQuests.new()

	# Act
	var todas: Array[Dictionary] = quests.todas_quests()

	# Assert — 11 contratos ao todo e vínculo válido com os 9 reinos
	assert_int(todas.size()).is_equal(11)

	for reino: Dictionary in ArvoreDosReinos.reinos():
		var q_id: StringName = StringName(String(reino["quest_id"]))
		var q_reino: Dictionary = quests.quest_por_id(q_id)
		assert_bool(q_reino.is_empty()).is_false()
		assert_int(int(q_reino["meta"])).is_equal(1)
		var chefe: Dictionary = reino["chefe"] as Dictionary
		assert_str(String(q_reino["target_kind"])).is_equal(String(chefe["id"]))

	assert_bool(quests.quest_por_id(&"").is_empty()).is_true()
	assert_bool(quests.quest_por_id(&"contrato_inexistente").is_empty()).is_true()

	# Verifica metadados exatos dos 5 novos contratos
	var novos_esperados: Array[Dictionary] = [
		{
			"id": &"coroa_de_espinhos",
			"titulo": "A Coroa Sob as Raízes",
			"descricao": "Derrote o Devorador da Coroa de Espinhos na Colina das Raízes Profundas.",
			"target_kind": "devorador_coroa_espinhos",
			"recompensa_frag": 80,
		},
		{
			"id": &"mare_morta",
			"titulo": "Caça na Água Negra",
			"descricao": "Derrote o Leviatã da Maré Morta na Costa Abissal.",
			"target_kind": "leviata_mare_morta",
			"recompensa_frag": 150,
		},
		{
			"id": &"vigia_escarpa",
			"titulo": "Os Seis Olhos Quebrados",
			"descricao": "Derrube o Vigia da Coroa Partida nas Escarpas.",
			"target_kind": "vigia_coroa_partida",
			"recompensa_frag": 180,
		},
		{
			"id": &"tirano_quebrado",
			"titulo": "Grilhões Desfeitos",
			"descricao": "Contenha e derrote o Tirano Quebra-Grilhões nas Fendas Cinzentas.",
			"target_kind": "tirano_quebra_grilhoes",
			"recompensa_frag": 260,
		},
		{
			"id": &"pesadelo_selado",
			"titulo": "O Fim do Abismo",
			"descricao": "Sele o Pesadelo das Fendas Subterrâneas nas Terras Baldias.",
			"target_kind": "pesadelo_fendas_subterraneas",
			"recompensa_frag": 400,
		},
	]

	for esp: Dictionary in novos_esperados:
		var q_id: StringName = StringName(esp["id"])
		var obtida: Dictionary = quests.quest_por_id(q_id)
		assert_str(String(obtida["titulo"])).is_equal(String(esp["titulo"]))
		assert_str(String(obtida["descricao"])).is_equal(String(esp["descricao"]))
		assert_str(String(obtida["target_kind"])).is_equal(String(esp["target_kind"]))
		assert_int(int(obtida["meta"])).is_equal(1)
		assert_int(int(obtida["recompensa_frag"])).is_equal(int(esp["recompensa_frag"]))
		assert_bool(bool(obtida["concluida"])).is_false()

		# Act — abate do chefe conclui o contrato e libera resgate único
		var concluidas: Array[Dictionary] = quests.registrar_abate(String(esp["target_kind"]))
		assert_int(concluidas.size()).is_equal(1)
		assert_that(StringName(concluidas[0]["id"])).is_equal(q_id)
		assert_bool(bool(quests.quest_por_id(q_id)["concluida"])).is_true()

		var recompensa: int = quests.resgatar(q_id)
		assert_int(recompensa).is_equal(int(esp["recompensa_frag"]))
		assert_int(quests.resgatar(q_id)).is_equal(0)

	# Os 5 abates também contam para o Primeiro Juramento (5/10), e mais 5 abates comuns o concluem
	assert_int(int(quests.quest_por_id(SistemaQuests.QUEST_PRIMEIRO_JURAMENTO)["progresso"])).is_equal(5)
	for _i: int in range(4):
		var parcial: Array[Dictionary] = quests.registrar_abate("eco_perdido")
		assert_int(parcial.size()).is_equal(0)
	var concl_juramento: Array[Dictionary] = quests.registrar_abate("eco_perdido")
	assert_int(concl_juramento.size()).is_equal(1)
	assert_that(StringName(concl_juramento[0]["id"])).is_equal(SistemaQuests.QUEST_PRIMEIRO_JURAMENTO)

	# Também preserva os 4 chefes originais e selos
	for boss_orig: String in ["soberano_do_limiar", "guardiao_do_rito", "colosso_de_cinza", "arconte_da_fenda"]:
		var concl_orig: Array[Dictionary] = quests.registrar_abate(boss_orig)
		assert_int(concl_orig.size()).is_equal(1)
	for _s: int in range(3):
		quests.registrar_selo()
	assert_int(quests.total_concluidas()).is_equal(11)
	assert_bool(quests.quest_ativa().is_empty()).is_true()

	# Serialização e imutabilidade de quest_por_id()
	var copia_pesadelo: Dictionary = quests.quest_por_id(SistemaQuests.QUEST_PESADELO_SELADO)
	copia_pesadelo["concluida"] = false
	assert_bool(bool(quests.quest_por_id(SistemaQuests.QUEST_PESADELO_SELADO)["concluida"])).is_true()

	var salvo: Dictionary = quests.para_dicionario()
	var restaurado: SistemaQuests = SistemaQuests.new()
	restaurado.de_dicionario(salvo)
	assert_int(restaurado.total_concluidas()).is_equal(11)
	assert_bool(bool(restaurado.quest_por_id(SistemaQuests.QUEST_COROA_DE_ESPINHOS)["resgatada"])).is_true()
