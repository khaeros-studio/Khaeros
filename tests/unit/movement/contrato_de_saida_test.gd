extends GdUnitTestSuite
## Story movimento-008: AC-55 (contrato de saída para HUD/Pipeline) e AC-42 (sem invulnerabilidade própria).


func _roteiro() -> ApoioMovimento.Sim:
	var sim := ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp())
	while sim.n < 100:
		sim.vivo()
	sim.vivo(Vector2.RIGHT, true)
	return sim


func test_evento_esquiva_leva_direcao_e_posicao_de_inicio() -> void:
	var sim := _roteiro()
	var achados: Array = []
	for par: Array in sim.log_eventos:
		if par[1] == EvEsquiva.TIPO:
			achados.append(par)
	assert_int(achados.size()).is_equal(1)
	assert_int(achados[0][0]).is_equal(100)
	var ev := achados[0][2] as EvEsquiva
	assert_vector(ev.direcao).is_equal(Vector2.RIGHT)
	assert_vector(ev.posicao_inicio).is_equal(Vector2(960, 540))
	assert_int(ev.player_id).is_equal(0)


func test_fracao_de_recarga_meio_no_121_e_zero_cheio() -> void:
	var sim := _roteiro()
	while sim.n <= 121:
		sim.vivo()
	assert_float(sim.mov.progresso_recarga_normalizado()).is_equal_approx(0.5, 0.001)
	while sim.n <= 142:
		sim.vivo()
	assert_int(sim.mov.cargas()).is_equal(sim.mov.cargas_max())
	assert_float(sim.mov.progresso_recarga_normalizado()).is_equal(0.0)


func test_hitstop_congela_fracao_e_atrasa_carga_para_147() -> void:
	var sim := _roteiro()
	while sim.n <= 124:
		sim.vivo()
	var f := sim.mov.progresso_recarga_normalizado()
	assert_float(f).is_equal_approx(24.0 / 42.0, 0.001)
	while sim.n <= 129:
		sim.congelado()
		assert_float(sim.mov.progresso_recarga_normalizado()).is_equal(f)
	while sim.n <= 146:
		sim.vivo()
	assert_int(sim.mov.cargas()).is_equal(0)
	sim.vivo()
	assert_int(sim.mov.cargas()).is_equal(1)


func test_movimento_nao_guarda_invulnerabilidade() -> void:
	var sim := ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp())
	sim.vivo(Vector2.RIGHT, true)
	assert_str(sim.combate.pedidos[1]).is_equal("inv:12")
	for nome: String in ["invulneravel", "invulnerabilidade", "passos_invulneravel", "em_invulnerabilidade"]:
		assert_bool(sim.mov.has_method(nome)).is_false()
