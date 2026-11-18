extends GdUnitTestSuite
## Story movimento-006: AC-44a — nó de apresentação real reseta a interpolação uma vez por teleporte.


func _montar() -> Array:
	var sim := ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp())
	var sprite := auto_free(Node2D.new()) as Node2D
	add_child(sprite)
	var reset := auto_free(ResetDeInterpolacaoDoJogador.new()) as ResetDeInterpolacaoDoJogador
	reset.set_physics_process(false)  # o teste sincroniza à mão, depois de cada passo
	add_child(reset)
	reset.configurar(sim.mov, sprite)
	var contagem := [0]
	reset.interpolacao_resetada.connect(func() -> void: contagem[0] += 1)
	return [sim, reset, contagem]


func test_teleporte_reseta_interpolacao_exatamente_uma_vez() -> void:
	var m := _montar()
	var sim: ApoioMovimento.Sim = m[0]
	var reset: ResetDeInterpolacaoDoJogador = m[1]
	for i in 3:
		sim.vivo(Vector2.RIGHT)
		reset.sincronizar()
	sim.mov.teleportar(Vector2(400, 300))
	reset.sincronizar()
	assert_vector(sim.mov.posicao()).is_equal(Vector2(400, 300))
	assert_vector(sim.mov.posicao_anterior()).is_equal(Vector2(400, 300))
	assert_int(sim.eventos.do_tipo(EvTeleporteDoJogador.TIPO).size()).is_equal(1)
	for i in 3:
		sim.vivo(Vector2.RIGHT)
		reset.sincronizar()
	assert_int(m[2][0]).is_equal(1)


func test_sem_teleporte_nenhum_reset() -> void:
	var m := _montar()
	var sim: ApoioMovimento.Sim = m[0]
	var reset: ResetDeInterpolacaoDoJogador = m[1]
	for i in 10:
		sim.vivo(Vector2.RIGHT, i == 2)
		reset.sincronizar()
	assert_int(m[2][0]).is_equal(0)
