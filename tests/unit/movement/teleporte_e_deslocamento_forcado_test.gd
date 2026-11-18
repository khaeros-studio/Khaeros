extends GdUnitTestSuite
## Story movimento-006: AC-32, AC-58, AC-27, AC-28 (teleporte, deslocar(v), investida e cancelamento).

const TOL := Vector2(0.001, 0.001)
const ECO_RAIO: float = 24.0


func _sim(cargas_max: int = 1, obstaculos: Array[ObstaculoCircular] = []) -> ApoioMovimento.Sim:
	return ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp(), cargas_max, obstaculos)


func test_teleportar_andando_iguala_atual_e_anterior_e_emite_um_aviso() -> void:
	var sim := _sim()
	sim.vivo(Vector2.RIGHT)
	sim.mov.teleportar(Vector2(400, 300))
	assert_vector(sim.mov.posicao()).is_equal(Vector2(400, 300))
	assert_vector(sim.mov.posicao_anterior()).is_equal(Vector2(400, 300))
	assert_int(sim.eventos.do_tipo(EvTeleporteDoJogador.TIPO).size()).is_equal(1)
	assert_int(sim.mov.contador_teleportes()).is_equal(1)


func test_teleportar_em_esquiva_cancela_esquiva_e_corte_preserva_cargas() -> void:
	var sim := _sim()
	sim.atributos.resumo_corte = ApoioMovimento.resumo_fp_corte()
	sim.alvos.lista = [AlvoDoCorte.new(5, Vector2(430, 300), ECO_RAIO)]
	sim.vivo(Vector2.RIGHT, true)
	sim.vivo()
	sim.vivo()
	sim.mov.teleportar(Vector2(400, 300))
	assert_bool(sim.mov.em_esquiva()).is_false()
	sim.vivo()  # passo 3, mover 0
	assert_vector(sim.mov.posicao()).is_equal_approx(Vector2(400, 300), TOL)
	assert_int(sim.mov.cargas()).is_equal(0)
	while sim.n < 42:
		sim.vivo()
	assert_int(sim.mov.cargas()).is_equal(0)  # após 41
	sim.vivo()  # passo 42
	assert_int(sim.mov.cargas()).is_equal(1)
	assert_array(sim.combate.pedidos).is_equal(["cancelar", "inv:12", "iniciada"])
	assert_int(sim.combate.cortes.size()).is_equal(0)


func test_deslocar_soma_v_sem_mudar_anterior_nem_contadores() -> void:
	var sim := _sim()
	sim.vivo()
	var cargas := sim.mov.cargas()
	var prog := sim.mov.progresso_recarga()
	sim.mov.deslocar(Vector2(10.5, 0))
	assert_vector(sim.mov.posicao()).is_equal_approx(Vector2(970.5, 540), TOL)
	assert_vector(sim.mov.posicao_anterior()).is_equal(Vector2(960, 540))
	assert_int(sim.mov.cargas()).is_equal(cargas)
	assert_int(sim.mov.progresso_recarga()).is_equal(prog)
	assert_int(sim.mov.esquiva_restante()).is_equal(0)


func test_deslocar_contra_obstaculo_resolve_colisao_para_931() -> void:
	var obs: Array[ObstaculoCircular] = [ObstaculoCircular.new(Vector2(1000, 540), 42.0)]
	var sim := _sim(1, obs)
	sim.mov.iniciar(Vector2(925, 540))
	sim.vivo()
	sim.mov.deslocar(Vector2(10.5, 0))
	assert_vector(sim.mov.posicao()).is_equal_approx(Vector2(931, 540), TOL)


func test_deslocar_durante_esquiva_nao_repete_corte_nem_esquiva() -> void:
	var sim := _sim()
	sim.atributos.resumo_corte = ApoioMovimento.resumo_fp_corte()
	sim.alvos.lista = [AlvoDoCorte.new(5, Vector2(1100, 540), ECO_RAIO)]
	sim.vivo(Vector2.RIGHT, true)
	var restante := sim.mov.esquiva_restante()
	sim.mov.deslocar(Vector2(100, 0))  # agora a 17,5 px do Eco
	assert_int(sim.combate.cortes.size()).is_equal(0)
	assert_int(sim.mov.esquiva_restante()).is_equal(restante)


func test_investida_desloca_sozinha_e_depois_anda() -> void:
	var sim := _sim()
	sim.combate.investida = true
	sim.combate.d_investida = Vector2(12, 0)
	for i in 5:
		sim.vivo(Vector2(0, 1))
	assert_vector(sim.mov.posicao()).is_equal_approx(Vector2(1020, 540), TOL)
	sim.combate.investida = false
	sim.vivo(Vector2(0, 1))
	assert_vector(sim.mov.posicao()).is_equal_approx(Vector2(1020, 546.45), TOL)


func test_esquiva_cancela_investida_no_mesmo_passo() -> void:
	var sim := _sim()
	sim.combate.investida = true
	sim.combate.d_investida = Vector2(12, 0)
	sim.vivo()
	sim.vivo()
	assert_float(sim.mov.posicao().x).is_equal_approx(984.0, 0.001)
	sim.vivo(Vector2.ZERO, true)
	assert_int(sim.combate.pedidos.count("cancelar")).is_equal(1)
	assert_float(sim.mov.posicao().x).is_equal_approx(1006.5, 0.001)
	while sim.n <= 10:
		sim.vivo()
	assert_float(sim.mov.posicao().x).is_equal_approx(1186.5, 0.001)


func test_esquiva_em_recuperacao_cancela_e_anda_velocidade_cheia() -> void:
	var sim := _sim()
	sim.combate.recuperacao = true
	sim.vivo(Vector2.RIGHT, true)
	assert_int(sim.combate.pedidos.count("cancelar")).is_equal(1)
	assert_float(sim.mov.posicao().x).is_equal_approx(982.5, 0.001)
	sim.vivo()
	assert_float(sim.mov.posicao().x).is_equal_approx(1005.0, 0.001)
