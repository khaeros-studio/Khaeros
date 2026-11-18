extends GdUnitTestSuite
## Story combate-nucleo-004 (parte 1): AC-23, AC-24, AC-25, AC-26 (GeometriaDeAcerto, arco, passo de apoio e círculo).


func test_ac23_teste_do_arco_tabela_f4() -> void:
	var tabela: Array = [
		[Vector2(1126.5, 540.0), false, true],
		[Vector2(1126.501, 540.0), false, false],
		[Vector2(1035.0, 669.9038), false, true],
		[Vector2(986.0472, 687.7212), false, false],
		[Vector2(1012.7762, 680.4089), false, true],
		[Vector2(1012.2858, 680.5923), false, false],
		[Vector2(910.0, 540.0), false, true],
		[Vector2(903.001, 540.0), false, true],
		[Vector2(903.0, 540.0), false, false],
		[Vector2(1131.299, 540.0), true, true],
		[Vector2(1131.301, 540.0), true, false],
	]
	for linha: Array in tabela:
		var pos: Vector2 = linha[0]
		var eh_elite: bool = linha[1]
		var esperado: bool = linha[2]
		var sim := ApoioCombate.SimCombate.new(false)
		var alvo := ApoioCombate.criar_elite(1, pos) if eh_elite else ApoioCombate.criar_eco(1, pos)
		sim.ia.lista = [alvo]
		sim.passo(true)
		var atingido := sim.eventos_do_passo(0, EventosDoCombate.EvAcerto.TIPO).size() == 1
		assert_bool(atingido).is_equal(esperado)

	# d = 0: Saco móvel em (960, 540) -> u = mira (1, 0), x = 967,5 após 0
	var sim_d0 := ApoioCombate.SimCombate.new(false)
	var saco_d0 := ApoioCombate.criar_saco(1, Vector2(960.0, 540.0), true)
	sim_d0.ia.lista = [saco_d0]
	sim_d0.passo(true)
	assert_float(saco_d0.posicao.x).is_equal_approx(967.5, 0.001)


func test_ac24_varios_alvos_ordem_estavel_e_um_hitstop() -> void:
	var sim := ApoioCombate.SimCombate.new(false)
	var b := ApoioCombate.criar_eco(2, Vector2(1060.0, 480.0))
	var a := ApoioCombate.criar_eco(1, Vector2(1060.0, 540.0))
	var c := ApoioCombate.criar_eco(3, Vector2(1060.0, 600.0))
	var d := ApoioCombate.criar_eco(4, Vector2(900.0, 540.0))  # costas a 60 px >= 57 -> não atingido
	sim.ia.lista = [b, a, c, d]
	sim.passo(true)
	var acertos := sim.eventos_do_passo(0, EventosDoCombate.EvAcerto.TIPO)
	assert_int(acertos.size()).is_equal(3)
	assert_int((acertos[0] as EventosDoCombate.EvAcerto).alvo_id).is_equal(2)
	assert_int((acertos[1] as EventosDoCombate.EvAcerto).alvo_id).is_equal(1)
	assert_int((acertos[2] as EventosDoCombate.EvAcerto).alvo_id).is_equal(3)
	assert_int(sim.combate.hitstop_restante()).is_equal(3)


func test_ac25_passo_de_apoio_depois_do_teste() -> void:
	var sim := ApoioCombate.SimCombate.new(false)
	sim.ia.lista = [ApoioCombate.criar_eco(1, Vector2(1126.5, 540.0))]
	sim.passo(true)
	assert_int(sim.eventos_do_passo(0, EventosDoCombate.EvAcerto.TIPO).size()).is_equal(1)
	assert_vector(sim.mov.pos).is_equal_approx(Vector2(970.5, 540.0), Vector2(0.001, 0.001))

	# Com mira (0.6, 0.8), sem alvo -> deslocar((6.3, 8.4))
	var sim2 := ApoioCombate.SimCombate.new(false)
	sim2.combate.definir_mira(0, Vector2(0.6, 0.8))
	sim2.passo(true)
	assert_vector(sim2.mov.deslocamentos_apoio[0]).is_equal_approx(Vector2(6.3, 8.4), Vector2(0.001, 0.001))

	# Onda e Pulso (FP-R) não pedem deslocar
	var sim_r := ApoioCombate.SimCombate.new(true)
	sim_r.passo(true, false)
	sim_r.passo(false, true)
	assert_array(sim_r.mov.deslocamentos_apoio).is_empty()


func test_ac26_circulo_onda_e_onda_60() -> void:
	for par: Array in [[Vector2(1179.0, 540.0), true], [Vector2(1179.001, 540.0), false], [Vector2(741.0, 540.0), true]]:
		var sim := ApoioCombate.SimCombate.new(true)
		sim.ia.lista = [ApoioCombate.criar_saco(1, par[0])]
		sim.passo(false, true)
		var acertou := sim.eventos_do_passo(0, EventosDoCombate.EvAcerto.TIPO).size() == 1
		assert_bool(acertou).is_equal(par[1])
		assert_int(sim.eventos_do_passo(0, EventosDoCombate.EvArea.TIPO).size()).is_equal(1)

	# Onda-60 (deslocamento 60, centro em (1020, 540)): direção do empurrão é do jogador ao inimigo
	var onda60 := ApoioCombate.especial_onda()
	onda60.params[&"deslocamento_px"] = 60.0
	var sim60 := ApoioCombate.SimCombate.new(true, null, null, ApoioCombate.ataque_pulso(), onda60)
	var saco := ApoioCombate.criar_saco(1, Vector2(990.0, 640.0), true)
	sim60.ia.lista = [saco]
	sim60.passo(false, true)
	var dir_emp := saco.vel_empurrao.normalized()
	assert_vector(dir_emp).is_equal_approx(Vector2(0.2873, 0.9578), Vector2(0.001, 0.001))
