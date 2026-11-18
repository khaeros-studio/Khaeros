extends GdUnitTestSuite
## Story movimento-002: AC-03, AC-04, AC-05, AC-52 (andar F1, sem inércia, passo congelado).


func test_andar_direita_apos_0_e_apos_59_conforme_gdd() -> void:
	var sim := ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp())
	sim.vivo(Vector2.RIGHT)
	assert_float(sim.mov.posicao().x).is_equal_approx(966.45, 0.001)
	for i in 59:
		sim.vivo(Vector2.RIGHT)
	assert_float(sim.mov.posicao().x).is_equal_approx(1347.0, 0.01)
	assert_float(sim.mov.posicao().y).is_equal(540.0)


func test_deslocamento_de_um_passo_tabela_ac04() -> void:
	# [mover, velocidade, recuperacao, fator, esperado]
	var casos: Array = [
		[Vector2(0.6, 0.8), 387.0, false, 0.45, Vector2(3.87, 5.16)],
		[Vector2(0.3, 0.4), 387.0, false, 0.45, Vector2(1.935, 2.58)],
		[Vector2(1, 0), 433.44, false, 0.45, Vector2(7.224, 0)],
		[Vector2(1, 0), 387.0, true, 0.45, Vector2(2.9025, 0)],
		[Vector2(0.5, 0), 387.0, true, 0.45, Vector2(1.45125, 0)],
		[Vector2(1, 0), 387.0, true, 0.0, Vector2.ZERO],
		[Vector2(1, 0), 387.0, true, 1.0, Vector2(6.45, 0)],
		[Vector2.ZERO, 387.0, false, 0.45, Vector2.ZERO],
		[Vector2(1, 0), 0.0, false, 0.45, Vector2.ZERO],
	]
	for c: Array in casos:
		var t := ApoioMovimento.tuning_fp()
		t.fator_recuperacao = c[3]
		var sim := ApoioMovimento.Sim.new(t)
		sim.atributos.velocidade = c[1]
		sim.combate.recuperacao = c[2]
		sim.vivo(c[0])
		var d: Vector2 = sim.mov.posicao() - ApoioMovimento.POS_FP
		assert_vector(d).is_equal_approx(c[4], Vector2(0.001, 0.001))


func test_parada_sem_inercia_posicao_igual_apos_9_e_10() -> void:
	var sim := ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp())
	for i in 10:
		sim.vivo(Vector2.LEFT)
	var apos_9 := sim.mov.posicao()
	sim.vivo(Vector2.ZERO)
	assert_vector(sim.mov.posicao()).is_equal(apos_9)


func test_passo_congelado_so_iguala_anterior_e_nao_avanca_contadores() -> void:
	var sim := ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp())
	sim.vivo(Vector2.RIGHT, true)
	sim.vivo()
	sim.vivo()
	var restante := sim.mov.esquiva_restante()
	var progresso := sim.mov.progresso_recarga()
	for i in 5:   # hitstop 3–7
		sim.congelado()
		assert_vector(sim.mov.posicao_anterior()).is_equal_approx(Vector2(1027.5, 540), Vector2(0.001, 0.001))
		assert_vector(sim.mov.posicao()).is_equal(sim.mov.posicao_anterior())
	assert_int(sim.mov.esquiva_restante()).is_equal(restante)
	assert_int(sim.mov.progresso_recarga()).is_equal(progresso)
	sim.vivo()   # passo 8
	assert_vector(sim.mov.posicao_anterior()).is_equal_approx(Vector2(1027.5, 540), Vector2(0.001, 0.001))
	assert_vector(sim.mov.posicao()).is_equal_approx(Vector2(1050, 540), Vector2(0.001, 0.001))


func test_investida_ativa_aplica_vetor_do_combate_no_lugar_de_andar() -> void:
	var sim := ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp())
	sim.combate.investida = true
	sim.combate.d_investida = Vector2(10, 0)
	sim.vivo(Vector2.UP)
	assert_vector(sim.mov.posicao()).is_equal(Vector2(970, 540))
