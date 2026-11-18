extends GdUnitTestSuite
## Story movimento-001: AC-01 (derivados), AC-02 (módulo puro injetado, determinismo bit a bit).


func test_derivados_fixture_padrao_conferem_com_gdd() -> void:
	var p := ParametrosDoMovimento.de(ApoioMovimento.tuning_fp())
	assert_int(p.d).is_equal(9)
	assert_int(p.e).is_equal(3)
	assert_int(p.r).is_equal(42)
	assert_float(p.d_passo).is_equal_approx(22.5, 0.001)
	assert_int(p.inv_esquiva).is_equal(12)
	assert_float(p.dist_total).is_equal_approx(202.5, 0.001)


func test_derivados_duracao_0_14_da_8_passos_e_180_px() -> void:
	var t := ApoioMovimento.tuning_fp()
	t.duracao_esquiva_s = 0.14
	var p := ParametrosDoMovimento.de(t)
	assert_int(p.d).is_equal(8)
	assert_float(p.dist_total).is_equal_approx(180.0, 0.001)


func test_movimento_criado_sem_scenetree_comeca_na_posicao_e_no_maximo() -> void:
	var sim := ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp(), 2)
	assert_vector(sim.mov.posicao()).is_equal(ApoioMovimento.POS_FP)
	assert_vector(sim.mov.posicao_anterior()).is_equal(ApoioMovimento.POS_FP)
	assert_int(sim.mov.cargas()).is_equal(2)
	assert_int(sim.mov.player_id()).is_equal(0)
	assert_bool(sim.mov.em_esquiva()).is_false()


func test_publicar_em_jogador_ref_espelha_campos_do_movimento() -> void:
	var sim := ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp())
	var ref := JogadorRef.new(0, null)
	sim.mov.publicar_em(ref)
	sim.vivo(Vector2.RIGHT, true)
	assert_vector(ref.posicao).is_equal(sim.mov.posicao())
	assert_int(ref.cargas).is_equal(0)
	assert_int(ref.esquiva_passos).is_equal(8)


## Roteiro determinístico de 1000 passos (andar, mira, toques, hitstop) gerado por padrão fixo.
func _rodar_roteiro() -> Array:
	var sim := ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp(), 2)
	var saida: Array = []
	for i in 1000:
		var mover := Vector2(cos(i * 0.05), sin(i * 0.031)) * (0.3 + 0.7 * float(i % 7) / 6.0)
		var mirar := Vector2.from_angle(i * 0.017)
		var toque := i % 23 == 0 or i % 37 == 5
		if i % 97 >= 90:
			sim.congelado(toque)
		else:
			sim.vivo(mover, toque, mirar)
		saida.append([sim.mov.posicao(), sim.mov.cargas(), sim.mov.progresso_recarga(), sim.log_eventos.size()])
	saida.append(sim.log_eventos)
	return saida


func test_duas_instancias_mesmo_roteiro_identicas_bit_a_bit() -> void:
	var a := _rodar_roteiro()
	var b := _rodar_roteiro()
	assert_int(a.size()).is_equal(b.size())
	for i in a.size():
		assert_bool(a[i] == b[i]).override_failure_message("divergiu no passo %d" % i).is_true()
