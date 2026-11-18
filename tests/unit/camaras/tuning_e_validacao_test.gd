extends GdUnitTestSuite
## Story camaras-e-ondas/001: WaveRules, RoomTuning, EliteRules e RegionDef no catálogo (WV1–WV12).
## Cobre AC-CO-22, AC-CO-23, AC-CO-24 e AC-CO-42.


func _def(itens: Array[ItemDoCatalogo], id: StringName, tipo: StringName) -> DefinicaoBase:
	for i in itens:
		if i.definicao.id == id and i.tipo == tipo:
			return i.definicao
	return null


func _codigos(diags: Array[Diagnostico]) -> Array[StringName]:
	var r: Array[StringName] = []
	for d in diags:
		r.append(d.regra)
	return r


func test_ac_co_22_tamanho_da_camara_wv2() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	var rt := _def(itens, &"room_tuning", &"tuning") as RoomTuning
	rt.camara_largura_px = 1920.0
	rt.camara_altura_px = 1080.0
	assert_bool(_codigos(ValidadorCamaras.validar_tudo(itens)).has(&"WV2")).is_false()

	rt.camara_largura_px = 2880.0
	rt.camara_altura_px = 1620.0
	assert_bool(_codigos(ValidadorCamaras.validar_tudo(itens)).has(&"WV2")).is_false()

	rt.camara_largura_px = 1900.0
	rt.camara_altura_px = 1080.0
	assert_bool(_codigos(ValidadorCamaras.validar_tudo(itens)).has(&"WV2")).is_true()

	rt.camara_largura_px = 2881.0
	rt.camara_altura_px = 1620.0
	assert_bool(_codigos(ValidadorCamaras.validar_tudo(itens)).has(&"WV2")).is_true()


func test_ac_co_23_erros_wv1_wv3_wv4_wv12() -> void:
	# WV1: orcamento_base <= 0, max_inimigos_onda < 1, spawn_candidatos < 1 ou ondas_limites não crescente
	var itens := FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"wave_rules", &"wave_rules") as WaveRules).orcamento_base = 0.0
	assert_bool(_codigos(ValidadorCamaras.validar_tudo(itens)).has(&"WV1")).is_true()

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"wave_rules", &"wave_rules") as WaveRules).ondas_limites = PackedInt64Array([4, 4])
	assert_bool(_codigos(ValidadorCamaras.validar_tudo(itens)).has(&"WV1")).is_true()

	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"room_tuning", &"tuning") as RoomTuning).spawn_candidatos = 0
	assert_bool(_codigos(ValidadorCamaras.validar_tudo(itens)).has(&"WV1")).is_true()

	# WV3: entrada dentro de pedra fixa do santuário (960, 495)
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"room_tuning", &"tuning") as RoomTuning).entrada_px = PackedFloat64Array([960.0, 495.0])
	assert_bool(_codigos(ValidadorCamaras.validar_tudo(itens)).has(&"WV3")).is_true()

	# WV4: pool sem inimigo com custo <= orcamento_base
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"eco_perdido", &"enemy") as EnemyDef).custo_onda = 5
	assert_bool(_codigos(ValidadorCamaras.validar_tudo(itens)).has(&"WV4")).is_true()

	# WV12: EliteRules com mult_raio <= 1,0
	itens = FabricasDeCatalogo.itens_mvp()
	var er := EliteRules.new()
	er.id = &"elite_rules"
	er.mult_vida = 1.6
	er.mult_dano = 1.25
	er.mult_raio = 1.0
	er.max_elites_onda = 1
	itens.append(ItemDoCatalogo.new(&"elite_rules", "res://t/er.tres", itens.size(), er))
	assert_bool(_codigos(ValidadorCamaras.validar_tudo(itens)).has(&"WV12")).is_true()


func test_ac_co_24_avisos_wv5_a_wv9_e_fabrica_limpa() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	assert_array(ValidadorCamaras.validar_tudo(itens)).is_empty()

	# WV5: max_inimigos_onda = 5 (em p=4 orçamento=6,6 -> 6 Ecos > 5)
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"wave_rules", &"wave_rules") as WaveRules).max_inimigos_onda = 5
	assert_bool(_codigos(ValidadorCamaras.validar_tudo(itens)).has(&"WV5")).is_true()

	# WV6: spawn_dist_jogador_px = 600 (> 540)
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"room_tuning", &"tuning") as RoomTuning).spawn_dist_jogador_px = 600.0
	assert_bool(_codigos(ValidadorCamaras.validar_tudo(itens)).has(&"WV6")).is_true()

	# WV7: obstaculo_raio_min_px = 150 (cobertura máxima > 15%)
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"room_tuning", &"tuning") as RoomTuning).obstaculo_raio_min_px = 150.0
	assert_bool(_codigos(ValidadorCamaras.validar_tudo(itens)).has(&"WV7")).is_true()

	# WV8: ArmasTuning.p_max = 5 (!= 4 do Limiar)
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"armas_tuning", &"tuning") as ArmasTuning).p_max = 5
	assert_bool(_codigos(ValidadorCamaras.validar_tudo(itens)).has(&"WV8")).is_true()

	# WV9: orcamento_base = 6 (fora da faixa 2..5)
	itens = FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"wave_rules", &"wave_rules") as WaveRules).orcamento_base = 6.0
	assert_bool(_codigos(ValidadorCamaras.validar_tudo(itens)).has(&"WV9")).is_true()


func test_ac_co_42_wv10_e_wv11_emenda_pactos() -> void:
	# WV10: spawn_dist_acuada_px = 400 (> spawn_dist_jogador_px 390)
	var itens := FabricasDeCatalogo.itens_mvp()
	(_def(itens, &"room_tuning", &"tuning") as RoomTuning).spawn_dist_acuada_px = 400.0
	assert_bool(_codigos(ValidadorCamaras.validar_tudo(itens)).has(&"WV10")).is_true()

	# WV11: chefe no índice 4 (fora do último índice jogável)
	itens = FabricasDeCatalogo.itens_mvp()
	var reg := _def(itens, &"limiar", &"region") as RegionDef
	reg.camaras[4] = &"chefe"
	assert_bool(_codigos(ValidadorCamaras.validar_tudo(itens)).has(&"WV11")).is_true()
