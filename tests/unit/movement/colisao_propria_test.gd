extends GdUnitTestSuite
## Story movimento-005: AC-29, AC-30, AC-59, AC-31; inimigos não bloqueiam; variante informando.

const TOL := Vector2(0.001, 0.001)
const O := Vector2(1000, 540)
const R_O := 42.0
const RAIO := 27.0


func _geo(obs: Array[ObstaculoCircular]) -> GeometriaDeMovimento:
	return GeometriaDeMovimento.new(ApoioMovimento.ARENA_FP, obs)


func _sim_em(pos: Vector2, obs: Array[ObstaculoCircular] = []) -> ApoioMovimento.Sim:
	var sim := ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp(), 1, obs)
	sim.mov.iniciar(pos)
	return sim


func test_andar_contra_obstaculo_volta_ao_contato() -> void:
	var sim := _sim_em(Vector2(931, 540), [ObstaculoCircular.new(O, R_O)])
	sim.vivo(Vector2.RIGHT)
	assert_vector(sim.mov.posicao()).is_equal_approx(Vector2(931, 540), TOL)


func test_centro_coincidente_usa_normal_para_cima() -> void:
	var sim := _sim_em(O, [ObstaculoCircular.new(O, R_O)])
	sim.vivo()
	assert_vector(sim.mov.posicao()).is_equal_approx(Vector2(1000, 471), TOL)


func test_parede_prende_ao_retangulo_encolhido() -> void:
	var sim := _sim_em(Vector2(1890, 540))
	sim.vivo(Vector2.RIGHT)
	assert_vector(sim.mov.posicao()).is_equal(Vector2(1893, 540))


func test_ordem_dos_obstaculos_conta() -> void:
	var a := ObstaculoCircular.new(O, R_O)
	var b := ObstaculoCircular.new(Vector2(1000, 640), R_O)
	var p := Vector2(1000, 590)
	assert_vector(Colisao.resolver_colisao(p, RAIO, _geo([a, b]))).is_equal_approx(Vector2(1000, 571), TOL)
	assert_vector(Colisao.resolver_colisao(p, RAIO, _geo([b, a]))).is_equal_approx(Vector2(1000, 609), TOL)


func test_inimigo_nao_bloqueia_andar() -> void:
	# A geometria só recebe obstáculos de câmara; um Eco em (980, 540) não entra nela.
	var sim := _sim_em(ApoioMovimento.POS_FP)
	for i in 20:
		sim.vivo(Vector2.RIGHT)
	assert_vector(sim.mov.posicao()).is_equal_approx(Vector2(1089, 540), Vector2(0.01, 0.01))


func test_borda_exata_nao_empurra_e_dentro_empurra() -> void:
	var geo := _geo([ObstaculoCircular.new(O, R_O)])
	var r1 := Colisao.resolver_colisao_informando(Vector2(931, 540), RAIO, geo)
	assert_vector(r1.pos).is_equal(Vector2(931, 540))
	assert_bool(r1.corrigida).is_false()
	var r2 := Colisao.resolver_colisao_informando(Vector2(931.001, 540), RAIO, geo)
	assert_vector(r2.pos).is_equal_approx(Vector2(931, 540), TOL)
	assert_bool(r2.corrigida).is_true()
	assert_vector(Colisao.resolver_colisao(Vector2(931.001, 540), RAIO, geo)).is_equal(r2.pos)


func test_esquiva_nao_atravessa_obstaculo() -> void:
	var sim := _sim_em(Vector2(900, 540), [ObstaculoCircular.new(O, R_O)])
	sim.vivo(Vector2.RIGHT, true)
	assert_float(sim.mov.posicao().x).is_equal_approx(922.5, 0.001)
	for k in range(1, 9):
		sim.vivo()
		assert_float(sim.mov.posicao().x).is_equal_approx(931.0, 0.001)
		assert_bool(sim.mov.posicao().x <= 931.0 + 0.001).is_true()
	assert_bool(sim.mov.em_esquiva()).is_false()
	assert_array(sim.inicios).is_equal([0])


func test_raspar_a_borda_e_aceito() -> void:
	var sim := _sim_em(Vector2(988.75, 608.5), [ObstaculoCircular.new(O, R_O)])
	sim.vivo(Vector2.RIGHT, true)
	assert_vector(sim.mov.posicao()).is_equal_approx(Vector2(1011.25, 608.5), TOL)
	for i in 8:
		sim.vivo()
	assert_float(sim.mov.posicao().x).is_equal_approx(1191.25, 0.001)
	assert_float(sim.mov.posicao().y).is_equal_approx(608.5, 0.001)


func test_esquiva_contra_parede_dura_os_9_passos() -> void:
	var sim := _sim_em(Vector2(1880, 540))
	for k in 9:
		sim.vivo(Vector2.RIGHT if k == 0 else Vector2.ZERO, k == 0)
		assert_float(sim.mov.posicao().x).is_equal(1893.0)
		assert_int(sim.mov.esquiva_restante()).is_equal(8 - k)
		assert_bool(sim.mov.em_esquiva()).is_equal(k <= 7)
	assert_int(sim.combate.pedidos.count("inv:12")).is_equal(1)
