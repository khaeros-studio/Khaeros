extends GdUnitTestSuite
## Testes unitários para [MapaMasmorra]: determinismo via RngAritmetica, grafo de 5 camadas (0..6),
## invariantes geométricas de segurança (>= 175px de spawn/portas) e atualização do minimapa.


func test_determinismo_mesma_seed_e_variacao_entre_seeds() -> void:
	var mapa_a: MapaMasmorra = MapaMasmorra.new()
	var mapa_b: MapaMasmorra = MapaMasmorra.new()
	mapa_a.gerar_regiao("limiar", 0, 0x4B484145)
	mapa_b.gerar_regiao("limiar", 0, 0x4B484145)

	var resumo_a: Dictionary = mapa_a.resumo_minimapa()
	var resumo_b: Dictionary = mapa_b.resumo_minimapa()
	var salas_a: Array = resumo_a["salas"] as Array
	var salas_b: Array = resumo_b["salas"] as Array
	assert_int(salas_a.size()).is_equal(7)
	assert_int(salas_b.size()).is_equal(7)

	for i: int in range(salas_a.size()):
		var sa: Dictionary = salas_a[i] as Dictionary
		var sb: Dictionary = salas_b[i] as Dictionary
		assert_str(String(sa["id"])).is_equal(String(sb["id"]))
		assert_str(String(sa["tipo"])).is_equal(String(sb["tipo"]))
		assert_str(String(sa["nome"])).is_equal(String(sb["nome"]))
		assert_int(int(sa["camada"])).is_equal(int(sb["camada"]))
		assert_int(int(sa["ramo"])).is_equal(int(sb["ramo"]))
		assert_float(float(sa["largura"])).is_equal(float(sb["largura"]))
		assert_float(float(sa["altura"])).is_equal(float(sb["altura"]))
		assert_bool((sa["cor_tag"] as Color).is_equal_approx(sb["cor_tag"] as Color)).is_true()

		var pil_a: Array = sa["pilares"] as Array
		var pil_b: Array = sb["pilares"] as Array
		assert_int(pil_a.size()).is_equal(pil_b.size())
		for j: int in range(pil_a.size()):
			var pa: Dictionary = pil_a[j] as Dictionary
			var pb: Dictionary = pil_b[j] as Dictionary
			assert_float(float(pa["x"])).is_equal(float(pb["x"]))
			assert_float(float(pa["y"])).is_equal(float(pb["y"]))
			assert_float(float(pa["r"])).is_equal(float(pb["r"]))

		var prop_a: Array = sa["props"] as Array
		var prop_b: Array = sb["props"] as Array
		assert_int(prop_a.size()).is_equal(prop_b.size())
		for j: int in range(prop_a.size()):
			var pra: Dictionary = prop_a[j] as Dictionary
			var prb: Dictionary = prop_b[j] as Dictionary
			assert_str(String(pra["kind"])).is_equal(String(prb["kind"]))
			assert_vector(pra["pos"] as Vector2).is_equal(prb["pos"] as Vector2)
			assert_float(float(pra["scale"])).is_equal(float(prb["scale"]))
			assert_bool(bool(pra["flip"])).is_equal(bool(prb["flip"]))

		var int_a: Array = sa["interativos"] as Array
		var int_b: Array = sb["interativos"] as Array
		assert_int(int_a.size()).is_equal(int_b.size())
		for j: int in range(int_a.size()):
			var ia: Dictionary = int_a[j] as Dictionary
			var ib: Dictionary = int_b[j] as Dictionary
			assert_str(String(ia["id"])).is_equal(String(ib["id"]))
			assert_str(String(ia["kind"])).is_equal(String(ib["kind"]))
			assert_vector(ia["pos"] as Vector2).is_equal(ib["pos"] as Vector2)
			assert_str(String(ia["eco_id"])).is_equal(String(ib["eco_id"]))

	# Seeds diferentes variam posições de props/pilares e ordem de ecos mantendo a estrutura do grafo
	var mapa_c: MapaMasmorra = MapaMasmorra.new()
	mapa_c.gerar_regiao("limiar", 0, 0x1F2E3D4C)
	var salas_c: Array = mapa_c.resumo_minimapa()["salas"] as Array
	var houve_diferenca_props_ou_pilares: bool = false
	for i: int in range(salas_a.size()):
		var sa2: Dictionary = salas_a[i] as Dictionary
		var sc2: Dictionary = salas_c[i] as Dictionary
		assert_str(String(sa2["id"])).is_equal(String(sc2["id"]))
		var pa2: Array = sa2["props"] as Array
		var pc2: Array = sc2["props"] as Array
		if pa2.size() != pc2.size():
			houve_diferenca_props_ou_pilares = true
		elif not pa2.is_empty():
			var pos_a0: Vector2 = (pa2[0] as Dictionary)["pos"] as Vector2
			var pos_c0: Vector2 = (pc2[0] as Dictionary)["pos"] as Vector2
			if not pos_a0.is_equal_approx(pos_c0):
				houve_diferenca_props_ou_pilares = true
	assert_bool(houve_diferenca_props_ou_pilares).is_true()

	# Ao longo de várias seeds, os 3 ecos da região são preservados e sua atribuição varia entre salas
	var assinaturas_ecos: Dictionary = {}
	var seeds_teste: Array[int] = [101, 202, 303, 404, 505, 606, 707, 808]
	for s: int in seeds_teste:
		var m_eco: MapaMasmorra = MapaMasmorra.new()
		m_eco.gerar_regiao("limiar", 0, s)
		var ecos_encontrados: Array[String] = _coletar_ecos_salas(m_eco.resumo_minimapa()["salas"] as Array)
		assert_int(ecos_encontrados.size()).is_equal(3)
		var unicos: Dictionary = {}
		for eid: String in ecos_encontrados:
			assert_bool(CodexHistoria.obter_eco(eid).is_empty()).is_false()
			unicos[eid] = true
		assert_int(unicos.size()).is_equal(3)
		assinaturas_ecos["|".join(ecos_encontrados)] = true
	assert_int(assinaturas_ecos.size()).is_greater(1)


func test_cinco_camadas_ramificacoes_e_progressao_completa() -> void:
	var mapa: MapaMasmorra = MapaMasmorra.new()
	mapa.gerar_regiao("veio_instavel", 1, 0x77771234)

	var resumo: Dictionary = mapa.resumo_minimapa()
	var salas: Array = resumo["salas"] as Array
	assert_int(salas.size()).is_equal(7)

	var camadas_esperadas: Array[int] = [0, 1, 1, 2, 2, 3, 4]
	var ramos_esperados: Array[int] = [0, 0, 1, 0, 1, 0, 0]
	var tipos_esperados: Array[String] = [
		"combate",
		"emboscada",
		"santuario_cura",
		"combate_denso",
		"altar_pacto",
		"elite_guarda",
		"chefe",
	]
	var nomes_esperados: Array[String] = [
		"Átrio da Fenda",
		"Corredor de Emboscada",
		"Santuário de Fluxo",
		"Salão dos Ecos",
		"Altar do Pacto Sombrio",
		"Guarda da Fenda",
		"Câmara do Chefe",
	]
	var tags_esperadas: Array[String] = [
		"BÊNÇÃO",
		"RELÍQUIA",
		"CURA",
		"RELÍQUIA",
		"PACTO",
		"ELITE",
		"CHEFE",
	]
	var proximas_esperadas: Array = [
		[1, 2],
		[3, 4],
		[3, 4],
		[5],
		[5],
		[6],
		[],
	]

	for i: int in range(7):
		var sala: Dictionary = salas[i] as Dictionary
		assert_int(int(sala["camada"])).is_equal(camadas_esperadas[i])
		assert_int(int(sala["ramo"])).is_equal(ramos_esperados[i])
		assert_str(String(sala["tipo"])).is_equal(tipos_esperados[i])
		assert_str(String(sala["nome"])).is_equal(nomes_esperados[i])
		assert_str(String(sala["recompensa_tag"])).is_equal(tags_esperadas[i])
		assert_array(sala["proximas"] as Array).is_equal(proximas_esperadas[i] as Array)

	# Verifica interativos obrigatórios por sala
	assert_array(_tipos_interativos(salas[0] as Dictionary)).is_equal(["monolito_lore"])
	assert_array(_tipos_interativos(salas[1] as Dictionary)).is_equal(["bau_reliquia"])
	assert_array(_tipos_interativos(salas[2] as Dictionary)).is_equal(["fonte_cura", "monolito_lore"])
	assert_array(_tipos_interativos(salas[3] as Dictionary)).is_equal(["bau_reliquia"])
	assert_array(_tipos_interativos(salas[4] as Dictionary)).is_equal(["altar_pacto", "monolito_lore"])
	assert_array(_tipos_interativos(salas[5] as Dictionary)).is_equal(["fonte_cura"])
	assert_array(_tipos_interativos(salas[6] as Dictionary)).is_empty()

	# Câmara do Chefe tem props majestosos nas laterais esquerda e direita
	var props_chefe: Array = (salas[6] as Dictionary)["props"] as Array
	assert_int(props_chefe.size()).is_greater_equal(6)
	var tem_esq: bool = false
	var tem_dir: bool = false
	for pr_var: Variant in props_chefe:
		var pr: Dictionary = pr_var as Dictionary
		var p_pos: Vector2 = pr["pos"] as Vector2
		assert_float(float(pr["scale"])).is_greater_equal(1.2)
		if p_pos.x < 1500.0:
			tem_esq = true
		else:
			tem_dir = true
	assert_bool(tem_esq).is_true()
	assert_bool(tem_dir).is_true()

	# Destino inválido não altera a sala atual
	var invalido: Dictionary = mapa.avancar_para(3)
	assert_bool(invalido.is_empty()).is_true()
	assert_int(int(mapa.resumo_minimapa()["indice_atual"])).is_equal(0)

	# Progressão pelo Ramo A (0 -> 1 -> 3 -> 5 -> 6)
	var portas0: Array[Dictionary] = mapa.portas_da_sala_atual()
	assert_int(portas0.size()).is_equal(2)
	assert_vector(portas0[0]["pos"] as Vector2).is_equal(Vector2(2800.0 * 0.34, 78.0))
	assert_vector(portas0[1]["pos"] as Vector2).is_equal(Vector2(2800.0 * 0.66, 78.0))
	assert_int(int(portas0[0]["destino_idx"])).is_equal(1)
	assert_int(int(portas0[1]["destino_idx"])).is_equal(2)

	var s1: Dictionary = mapa.avancar_para(1)
	assert_str(String(s1["tipo"])).is_equal("emboscada")
	assert_int(mapa.portas_da_sala_atual().size()).is_equal(2)

	var s3: Dictionary = mapa.avancar_para(3)
	assert_str(String(s3["tipo"])).is_equal("combate_denso")
	var portas3: Array[Dictionary] = mapa.portas_da_sala_atual()
	assert_int(portas3.size()).is_equal(1)
	assert_vector(portas3[0]["pos"] as Vector2).is_equal(Vector2(2900.0 * 0.5, 78.0))

	var s5: Dictionary = mapa.avancar_para(5)
	assert_str(String(s5["tipo"])).is_equal("elite_guarda")
	assert_int(mapa.portas_da_sala_atual().size()).is_equal(1)

	var s6: Dictionary = mapa.avancar_para(6)
	assert_str(String(s6["tipo"])).is_equal("chefe")
	assert_int(int(s6["camada"])).is_equal(4)
	assert_array(mapa.portas_da_sala_atual()).is_empty()

	# Ao limpar o chefe em regiões 0..2, aparece o portal dourado PRÓXIMA REGIÃO
	mapa.marcar_limpa()
	var portas_chefe: Array[Dictionary] = mapa.portas_da_sala_atual()
	assert_int(portas_chefe.size()).is_equal(1)
	assert_bool(bool(portas_chefe[0]["is_region_portal"])).is_true()
	assert_str(String(portas_chefe[0]["nome"])).is_equal("PRÓXIMA REGIÃO")
	assert_vector(portas_chefe[0]["pos"] as Vector2).is_equal(Vector2(3000.0 * 0.5, 78.0))

	# Progressão pelo Ramo B na região final (reg_index 3): sem portal regional após chefe
	var mapa_final: MapaMasmorra = MapaMasmorra.new()
	mapa_final.gerar_regiao("santuario_partido", 3, 999)
	assert_str(String(mapa_final.avancar_para(2)["tipo"])).is_equal("santuario_cura")
	assert_str(String(mapa_final.avancar_para(4)["tipo"])).is_equal("altar_pacto")
	assert_str(String(mapa_final.avancar_para(5)["tipo"])).is_equal("elite_guarda")
	assert_str(String(mapa_final.avancar_para(6)["tipo"])).is_equal("chefe")
	mapa_final.marcar_limpa()
	assert_array(mapa_final.portas_da_sala_atual()).is_empty()


func test_geometria_segura_sem_sobreposicao_com_spawn_e_portas() -> void:
	var regioes: Array[String] = [
		"limiar",
		"veio_instavel",
		"fosso_das_cinzas",
		"santuario_partido",
		"regiao_custom",
	]
	var seeds_teste: Array[int] = [0x4B484145, 1, 42, 987654321]

	for reg_idx: int in range(regioes.size()):
		var reg_id: String = regioes[reg_idx]
		for s: int in seeds_teste:
			var mapa: MapaMasmorra = MapaMasmorra.new()
			mapa.gerar_regiao(reg_id, reg_idx % 4, s)
			var salas: Array = mapa.resumo_minimapa()["salas"] as Array

			for sala_var: Variant in salas:
				var sala: Dictionary = sala_var as Dictionary
				var largura: float = float(sala["largura"])
				var altura: float = float(sala["altura"])
				var spawn_pos: Vector2 = Vector2(largura * 0.5, altura - 220.0)
				var proximas: Array = sala["proximas"] as Array
				var qtd_portas: int = maxi(1, proximas.size())
				var portas_norte: Array[Vector2] = MapaMasmorra.posicoes_portas_norte(largura, qtd_portas)

				var objetos_sala: Array[Dictionary] = []

				var pilares: Array = sala["pilares"] as Array
				for pil_var: Variant in pilares:
					var pil: Dictionary = pil_var as Dictionary
					var pil_pos: Vector2 = Vector2(float(pil["x"]), float(pil["y"]))
					var pil_r: float = float(pil["r"])
					assert_float(pil_pos.distance_to(spawn_pos)).is_greater_equal(175.0)
					assert_float(pil_pos.distance_to(spawn_pos) - pil_r).is_greater_equal(175.0)
					for porta_pos: Vector2 in portas_norte:
						assert_float(pil_pos.distance_to(porta_pos)).is_greater_equal(175.0)
						assert_float(pil_pos.distance_to(porta_pos) - pil_r).is_greater_equal(175.0)
					assert_float(pil_pos.x).is_greater(pil_r)
					assert_float(pil_pos.x).is_less(largura - pil_r)
					assert_float(pil_pos.y).is_greater(pil_r)
					assert_float(pil_pos.y).is_less(altura - pil_r)
					objetos_sala.append({"pos": pil_pos, "r": pil_r})

				var props: Array = sala["props"] as Array
				for pr_var: Variant in props:
					var pr: Dictionary = pr_var as Dictionary
					var pr_pos: Vector2 = pr["pos"] as Vector2
					var pr_kind: String = String(pr["kind"])
					assert_bool(pr_kind == "estatua_guardiao" or pr_kind == "coluna_correntes").is_true()
					assert_float(pr_pos.distance_to(spawn_pos)).is_greater_equal(175.0)
					for porta_pos2: Vector2 in portas_norte:
						assert_float(pr_pos.distance_to(porta_pos2)).is_greater_equal(175.0)
					objetos_sala.append({"pos": pr_pos, "r": 30.0})

				var interativos: Array = sala["interativos"] as Array
				for it_var: Variant in interativos:
					var it: Dictionary = it_var as Dictionary
					var it_pos: Vector2 = it["pos"] as Vector2
					assert_bool(bool(it["usado"])).is_false()
					assert_float(it_pos.distance_to(spawn_pos)).is_greater_equal(175.0)
					for porta_pos3: Vector2 in portas_norte:
						assert_float(it_pos.distance_to(porta_pos3)).is_greater_equal(175.0)
					objetos_sala.append({"pos": it_pos, "r": 35.0})

				# Garante ausência de sobreposição entre quaisquer dois objetos na mesma sala
				for a_idx: int in range(objetos_sala.size()):
					var obj_a: Dictionary = objetos_sala[a_idx]
					var pos_a: Vector2 = obj_a["pos"] as Vector2
					var r_a: float = float(obj_a["r"])
					for b_idx: int in range(a_idx + 1, objetos_sala.size()):
						var obj_b: Dictionary = objetos_sala[b_idx]
						var pos_b: Vector2 = obj_b["pos"] as Vector2
						var r_b: float = float(obj_b["r"])
						assert_float(pos_a.distance_to(pos_b)).is_greater(r_a + r_b)


func test_resumo_minimapa_atualiza_visitada_limpa_e_protege_copia() -> void:
	var mapa: MapaMasmorra = MapaMasmorra.new()
	mapa.gerar_regiao("fosso_das_cinzas", 2, 0xCAFEBABE)

	var inicial: Dictionary = mapa.resumo_minimapa()
	assert_str(String(inicial["reg_id"])).is_equal("fosso_das_cinzas")
	assert_int(int(inicial["indice_atual"])).is_equal(0)
	assert_int(int(inicial["camada_atual"])).is_equal(0)

	var salas_ini: Array = inicial["salas"] as Array
	assert_int(salas_ini.size()).is_equal(7)
	assert_bool(bool((salas_ini[0] as Dictionary)["visitada"])).is_true()
	assert_bool(bool((salas_ini[0] as Dictionary)["limpa"])).is_false()
	assert_bool(bool((salas_ini[2] as Dictionary)["limpa"])).is_true()
	assert_bool(bool((salas_ini[4] as Dictionary)["limpa"])).is_true()
	assert_bool(bool((salas_ini[1] as Dictionary)["visitada"])).is_false()
	assert_bool(bool((salas_ini[6] as Dictionary)["visitada"])).is_false()

	# Mutações externas no resumo não afetam o estado interno do MapaMasmorra
	(salas_ini[0] as Dictionary)["limpa"] = true
	(salas_ini[5] as Dictionary)["visitada"] = true
	var apos_mutacao: Array = mapa.resumo_minimapa()["salas"] as Array
	assert_bool(bool((apos_mutacao[0] as Dictionary)["limpa"])).is_false()
	assert_bool(bool((apos_mutacao[5] as Dictionary)["visitada"])).is_false()

	mapa.marcar_limpa()
	mapa.avancar_para(2)
	mapa.avancar_para(4)
	mapa.avancar_para(5)
	mapa.marcar_limpa()
	mapa.avancar_para(6)

	var final: Dictionary = mapa.resumo_minimapa()
	assert_int(int(final["indice_atual"])).is_equal(6)
	assert_int(int(final["camada_atual"])).is_equal(4)
	var salas_fin: Array = final["salas"] as Array
	assert_bool(bool((salas_fin[0] as Dictionary)["visitada"])).is_true()
	assert_bool(bool((salas_fin[0] as Dictionary)["limpa"])).is_true()
	assert_bool(bool((salas_fin[2] as Dictionary)["visitada"])).is_true()
	assert_bool(bool((salas_fin[4] as Dictionary)["visitada"])).is_true()
	assert_bool(bool((salas_fin[5] as Dictionary)["visitada"])).is_true()
	assert_bool(bool((salas_fin[5] as Dictionary)["limpa"])).is_true()
	assert_bool(bool((salas_fin[6] as Dictionary)["visitada"])).is_true()
	assert_bool(bool((salas_fin[6] as Dictionary)["limpa"])).is_false()

	# Sala não visitada no ramo A continua marcada como não visitada
	assert_bool(bool((salas_fin[1] as Dictionary)["visitada"])).is_false()
	assert_bool(bool((salas_fin[3] as Dictionary)["visitada"])).is_false()


func _coletar_ecos_salas(salas: Array) -> Array[String]:
	var ecos: Array[String] = []
	for sala_var: Variant in salas:
		var sala: Dictionary = sala_var as Dictionary
		var interativos: Array = sala["interativos"] as Array
		for it_var: Variant in interativos:
			var it: Dictionary = it_var as Dictionary
			if String(it["kind"]) == "monolito_lore":
				ecos.append(String(it["eco_id"]))
	return ecos


func _tipos_interativos(sala: Dictionary) -> Array[String]:
	var tipos: Array[String] = []
	var interativos: Array = sala["interativos"] as Array
	for it_var: Variant in interativos:
		var it: Dictionary = it_var as Dictionary
		tipos.append(String(it["kind"]))
	return tipos
