extends GdUnitTestSuite
## Story movimento-003: AC-06..AC-13, AC-49 (largada, direção, buffer, pedidos síncronos, sem carga).

const TOL := Vector2(0.001, 0.001)


func _sim(cargas_max: int = 1) -> ApoioMovimento.Sim:
	return ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp(), cargas_max)


func test_esquiva_desloca_22_5_por_passo_e_em_esquiva_ate_o_7() -> void:
	var sim := _sim()
	for k in 9:
		if k == 0:
			sim.vivo(Vector2.RIGHT, true)
		else:
			sim.vivo()
		assert_float(sim.mov.posicao().x).is_equal_approx(982.5 + 22.5 * k, 0.001)
		assert_bool(sim.mov.em_esquiva()).is_equal(k <= 7)
	sim.vivo()
	assert_vector(sim.mov.posicao()).is_equal_approx(Vector2(1162.5, 540), TOL)


func test_largada_pedidos_na_ordem_uma_vez_no_passo_0() -> void:
	var sim := _sim()
	sim.vivo(Vector2.RIGHT, true)
	assert_array(sim.combate.pedidos).is_equal(["cancelar", "inv:12", "iniciada"])
	assert_int(sim.mov.cargas()).is_equal(0)
	assert_int(sim.mov.esquiva_restante()).is_equal(8)
	assert_bool(sim.buffer.contem(Acoes.ESQUIVA, 0)).is_false()
	assert_int(sim.eventos_em(EvEsquiva.TIPO, 0)).is_equal(1)
	for i in 8:
		sim.vivo()
	assert_int(sim.mov.esquiva_restante()).is_equal(0)
	assert_int(sim.combate.pedidos.size()).is_equal(3)
	assert_int(sim.total(EvEsquiva.TIPO)).is_equal(1)


func test_direcao_da_esquiva_tabela_ac08() -> void:
	var casos: Array = [
		[Vector2.ZERO, Vector2(0, -1), Vector2(0, -22.5)],
		[Vector2(0.2, 0), Vector2(1, 0), Vector2(22.5, 0)],
		[Vector2(-1, 0), Vector2(1, 0), Vector2(-22.5, 0)],
		[Vector2(0.6, 0.8), Vector2(1, 0), Vector2(13.5, 18)],
	]
	for c: Array in casos:
		var sim := _sim()
		sim.vivo(c[0], true, c[1])
		assert_vector(sim.mov.posicao() - ApoioMovimento.POS_FP).is_equal_approx(c[2], TOL)


func test_direcao_fixada_na_largada_mesmo_com_mover_mudando() -> void:
	var sim := _sim()
	sim.vivo(Vector2(0.2, 0), true)
	for k in range(1, 9):
		sim.vivo(Vector2(0, 1) if k >= 4 else Vector2.ZERO)
	assert_vector(sim.mov.posicao()).is_equal_approx(Vector2(1162.5, 540), TOL)


func test_diagonal_total_apos_8() -> void:
	var sim := _sim()
	sim.vivo(Vector2(0.6, 0.8), true)
	for i in 8:
		sim.vivo()
	assert_vector(sim.mov.posicao() - ApoioMovimento.POS_FP).is_equal_approx(Vector2(121.5, 162), TOL)


func test_esquiva_segurada_sem_borda_nao_sai() -> void:
	var sim := _sim()
	for i in 31:
		sim.vivo(Vector2.ZERO, false, Vector2.RIGHT, true)
	assert_int(sim.total(EvEsquiva.TIPO)).is_equal(0)
	assert_int(sim.total(EvEsquivaSemCarga.TIPO)).is_equal(0)
	assert_array(sim.combate.pedidos).is_empty()


func test_esquiva_independe_de_velocidade() -> void:
	for v: float in [580.5, 0.0]:
		var sim := _sim()
		sim.atributos.velocidade = v
		sim.vivo(Vector2.RIGHT, true)
		for i in 8:
			sim.vivo()
		assert_float(sim.mov.posicao().x - 960.0).is_equal_approx(202.5, 0.001)


func test_invulnerabilidade_soma_inteiros_mv3() -> void:
	var t := ApoioMovimento.tuning_fp()
	t.invuln_extra_s = 0.0
	var sim := ApoioMovimento.Sim.new(t)
	sim.vivo(Vector2.RIGHT, true)
	assert_str(sim.combate.pedidos[1]).is_equal("inv:9")
	var t2 := ApoioMovimento.tuning_fp()
	t2.duracao_esquiva_s = 0.158
	t2.invuln_extra_s = 0.058
	var sim2 := ApoioMovimento.Sim.new(t2)
	sim2.vivo(Vector2.RIGHT, true)
	assert_str(sim2.combate.pedidos[1]).is_equal("inv:12")


func test_sem_carga_emite_um_evento_por_toque_e_sai_quando_carga_volta() -> void:
	var sim := _sim()
	for p in 143:
		sim.vivo(Vector2.ZERO, p == 100 or p == 135 or p == 138)
	assert_int(sim.eventos_em(EvEsquivaSemCarga.TIPO, 135)).is_equal(1)
	assert_int(sim.eventos_em(EvEsquivaSemCarga.TIPO, 136)).is_equal(0)
	assert_int(sim.eventos_em(EvEsquivaSemCarga.TIPO, 137)).is_equal(0)
	assert_int(sim.eventos_em(EvEsquivaSemCarga.TIPO, 138)).is_equal(1)
	assert_int(sim.total(EvEsquivaSemCarga.TIPO)).is_equal(2)
	assert_array(sim.inicios).is_equal([100, 142])
	for i in 20:
		sim.vivo()
	assert_int(sim.total(EvEsquivaSemCarga.TIPO)).is_equal(2)


func test_sem_carga_variante_buffer_vence_antes_da_recarga() -> void:
	var sim := _sim()
	for p in 50:
		sim.vivo(Vector2.ZERO, p == 0 or p == 10)
	assert_int(sim.eventos_em(EvEsquivaSemCarga.TIPO, 10)).is_equal(1)
	assert_int(sim.total(EvEsquivaSemCarga.TIPO)).is_equal(1)
	assert_array(sim.inicios).is_equal([0])


func test_toque_sem_carga_no_hitstop_emite_no_primeiro_passo_vivo() -> void:
	var sim := _sim()
	sim.vivo(Vector2.ZERO, true)   # 0: gasta a carga
	for i in 15:
		sim.vivo()                 # 1–15
	sim.congelado(true)            # 16: toque durante hitstop
	sim.congelado()                # 17
	assert_int(sim.total(EvEsquivaSemCarga.TIPO)).is_equal(0)
	sim.vivo()                     # 18
	assert_int(sim.eventos_em(EvEsquivaSemCarga.TIPO, 18)).is_equal(1)
	sim.vivo()
	assert_int(sim.total(EvEsquivaSemCarga.TIPO)).is_equal(1)


func test_esquiva_encadeada_separada_por_d() -> void:
	var sim := _sim(2)
	for p in 19:
		sim.vivo(Vector2.RIGHT, p == 0 or p == 4)
		if p == 8:
			assert_float(sim.mov.posicao().x).is_equal_approx(1162.5, 0.001)
		if p == 9:
			assert_int(sim.mov.cargas()).is_equal(0)
		if p == 17:
			assert_float(sim.mov.posicao().x).is_equal_approx(1365.0, 0.001)
	assert_float(sim.mov.posicao().x).is_equal_approx(1371.45, 0.001)
	assert_array(sim.inicios).is_equal([0, 9])


func test_toque_durante_esquiva_sem_carga_emite_uma_vez_e_vence_prazo() -> void:
	var sim := _sim()
	for p in 43:
		sim.vivo(Vector2.ZERO, p == 0 or p == 4)
	assert_int(sim.eventos_em(EvEsquivaSemCarga.TIPO, 4)).is_equal(1)
	assert_int(sim.total(EvEsquivaSemCarga.TIPO)).is_equal(1)
	assert_array(sim.inicios).is_equal([0])
