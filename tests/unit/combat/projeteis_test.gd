extends GdUnitTestSuite
## Story combate-nucleo-004 (parte 2): AC-20, AC-27, AC-28, AC-29, AC-30, AC-31, AC-32, AC-93 (projéteis do jogador e de inimigos).


func test_ac20_projetil_leva_m_do_disparo() -> void:
	for vida_disparo: int in [60, 40]:
		var port := ApoioCombate.portador_jogador(100.0)
		port.aplicar_fonte(FonteDeModificador.new(&"bencao:fundo", [
			Modificador.new(Atributos.DANO_TODO, Modificador.Operacao.PERCENTUAL, 0.4, Modificador.Condicao.VIDA_ABAIXO, 0.5)
		]))
		var sim := ApoioCombate.SimCombate.new(true, null, port)
		sim.combate.recursos(0).vida = vida_disparo
		sim.ia.lista = [ApoioCombate.criar_saco(1, Vector2(1100.0, 540.0))]
		sim.passo(true)
		sim.combate.recursos(0).vida = 40 if vida_disparo == 60 else 60
		for k in range(1, 10):
			sim.passo()
		var acertos := sim.todos_eventos(EventosDoCombate.EvAcerto.TIPO)
		assert_int(acertos.size()).is_equal(1)
		var dano_esp := 12.0 if vida_disparo == 60 else 16.8
		assert_float((acertos[0] as EventosDoCombate.EvAcerto).dano).is_equal_approx(dano_esp, 0.001)


func test_ac27_nascimento_e_leque_de_projeteis() -> void:
	var pulso_leque := ApoioCombate.ataque_pulso()
	pulso_leque.leque = PackedFloat64Array([0.0, 1.0, 2.0, 3.0])
	var sim := ApoioCombate.SimCombate.new(true, null, null, pulso_leque, ApoioCombate.especial_onda())
	sim.combate.inicio_do_passo()
	var buf := BufferDeComandos.new(10)
	buf.atualizar([Acoes.ATAQUE], 0, 0, false)
	sim.combate.golpe_do_jogador([ComandosDoPasso.new(buf, [], 0, 0)])
	var voando := sim.combate.projeteis_em_voo()
	assert_int(voando.size()).is_equal(4)
	assert_vector(voando[0].posicao).is_equal_approx(Vector2(996.0, 540.0), Vector2(0.001, 0.001))
	assert_vector(voando[1].posicao).is_equal_approx(Vector2(995.2133, 547.4848), Vector2(0.001, 0.001))
	assert_vector(voando[2].posicao).is_equal_approx(Vector2(995.2133, 532.5152), Vector2(0.001, 0.001))
	assert_vector(voando[3].posicao).is_equal_approx(Vector2(992.8876, 554.6425), Vector2(0.001, 0.001))
	for p in voando:
		assert_float(p.dano_golpe).is_equal_approx(12.0, 0.001)
		assert_float(p.empurrao).is_equal_approx(270.0, 0.001)


func test_ac28_alcance_testado_844_5_px() -> void:
	for x_eco: float in [1843.5, 1843.501]:
		var sim := ApoioCombate.SimCombate.new(true)
		sim.ia.lista = [ApoioCombate.criar_eco(1, Vector2(x_eco, 540.0))]
		for k in 52:
			sim.passo(k == 0)
		var acertos := sim.todos_eventos(EventosDoCombate.EvAcerto.TIPO)
		if x_eco == 1843.5:
			assert_int(acertos.size()).is_equal(1)
			assert_float((acertos[0] as EventosDoCombate.EvAcerto).dano).is_equal_approx(12.0, 0.001)
		else:
			assert_int(acertos.size()).is_equal(0)
		assert_int(sim.combate.projeteis_em_voo().size()).is_equal(0)


func test_ac29_projetil_some_em_obstaculo_e_fora_do_retangulo() -> void:
	# Obstáculo (1010, 540, r 42) e Saco em (1030, 540) -> some no passo 0 sem atingir o Saco
	var sim := ApoioCombate.SimCombate.new(true)
	sim.camaras.geo = GeometriaDeMovimento.new(
		Rect2(0.0, 0.0, 1920.0, 1080.0),
		[ObstaculoCircular.new(Vector2(1010.0, 540.0), 42.0)])
	sim.ia.lista = [ApoioCombate.criar_saco(1, Vector2(1030.0, 540.0))]
	sim.passo(true)
	assert_int(sim.combate.projeteis_em_voo().size()).is_equal(0)
	assert_int(sim.todos_eventos(EventosDoCombate.EvAcerto.TIPO).size()).is_equal(0)

	# Jogador em (1893, 540): projétil nasce fora do retângulo e some no passo 0
	var sim_fora := ApoioCombate.SimCombate.new(true)
	sim_fora.mov.pos = Vector2(1893.0, 540.0)
	sim_fora.passo(true)
	assert_int(sim_fora.combate.projeteis_em_voo().size()).is_equal(0)


func test_ac30_atravessa_e_inimigo_surgindo() -> void:
	# Pulso-atravessa atinge os 2 Sacos 1 vez cada
	var pulso_at := ApoioCombate.ataque_pulso()
	pulso_at.atravessa = true
	var sim := ApoioCombate.SimCombate.new(true, null, null, pulso_at, ApoioCombate.especial_onda())
	sim.ia.lista = [
		ApoioCombate.criar_saco(1, Vector2(1100.0, 540.0)),
		ApoioCombate.criar_saco(2, Vector2(1200.0, 540.0)),
	]
	for k in 25:
		sim.passo(k == 0)
	var acertos := sim.todos_eventos(EventosDoCombate.EvAcerto.TIPO)
	assert_int(acertos.size()).is_equal(2)

	# Pulso normal com o 1º Saco surgindo: ignora o 1º e atinge o 2º
	var sim2 := ApoioCombate.SimCombate.new(true)
	var s1 := ApoioCombate.criar_saco(1, Vector2(1100.0, 540.0))
	s1.surgindo = true
	var s2 := ApoioCombate.criar_saco(2, Vector2(1200.0, 540.0))
	sim2.ia.lista = [s1, s2]
	for k in 25:
		sim2.passo(k == 0)
	var ac2 := sim2.todos_eventos(EventosDoCombate.EvAcerto.TIPO)
	assert_int(ac2.size()).is_equal(1)
	assert_int((ac2[0] as EventosDoCombate.EvAcerto).alvo_id).is_equal(2)


func test_ac31_empurrao_do_dado_e_finalizador_no_projetil() -> void:
	var pulso_combo := ApoioCombate.ataque_pulso()
	pulso_combo.multiplicadores_combo = PackedFloat64Array([1.0, 1.0, 1.8])
	var sim := ApoioCombate.SimCombate.new(true, null, null, pulso_combo, ApoioCombate.especial_onda())
	var saco := ApoioCombate.criar_saco(1, Vector2(1100.0, 540.0), true)
	saco.em_preparacao = true
	sim.ia.lista = [saco]
	for k in 40:
		sim.passo(false, false, k <= 30, false)
	var acertos := sim.todos_eventos(EventosDoCombate.EvAcerto.TIPO)
	assert_int(acertos.size()).is_equal(3)
	assert_bool((acertos[0] as EventosDoCombate.EvAcerto).pesado).is_false()
	assert_bool((acertos[1] as EventosDoCombate.EvAcerto).pesado).is_false()
	var ac3 := acertos[2] as EventosDoCombate.EvAcerto
	assert_float(ac3.dano).is_equal_approx(21.6, 0.001)
	assert_bool(ac3.pesado).is_true()
	assert_int(sim.ia.quebras.size()).is_equal(1)
	assert_array(sim.ia.quebras[0]).is_equal([1, 24])


func test_ac32_e_ac93_projetil_inimigo_e_disparar_projetil() -> void:
	# AC-32: projétil inimigo em (1100, 540), (-1, 0), 540 px/s, r 12, 120 passos, dano 9, M 1,25
	var sim := ApoioCombate.SimCombate.new(false)
	sim.combate.disparar_projetil(10, Vector2(1100.0, 540.0), Vector2.LEFT, 540.0, 12.0, 2.0, 9.0, 1.25, false)
	sim.eventos.esvaziar()
	for k in 15:
		sim.passo()
		if k == 11:
			assert_int(sim.combate.recursos(0).vida).is_equal(89)
			assert_int(sim.combate.projeteis_em_voo().size()).is_equal(0)

	# Com garantir_invulneravel(12) no passo 0: no 11 atravessa sem dano; acerta no 12
	var sim_inv := ApoioCombate.SimCombate.new(false)
	sim_inv.combate.disparar_projetil(10, Vector2(1100.0, 540.0), Vector2.LEFT, 540.0, 12.0, 2.0, 9.0, 1.25, false)
	sim_inv.eventos.esvaziar()
	for k in 15:
		sim_inv.passo(false, false, false, false,
			func() -> void:
				if k == 0:
					sim_inv.combate.garantir_invulneravel(0, 12))
		if k == 11:
			assert_int(sim_inv.combate.recursos(0).vida).is_equal(100)
		elif k == 12:
			assert_int(sim_inv.combate.recursos(0).vida).is_equal(89)

	# AC-93: IA chama disparar_projetil((1100, 540), (-1, 0), 600, 9, 4.0, 9, 1.0, false) no passo 0 -> acerta no passo 10
	var sim93 := ApoioCombate.SimCombate.new(false)
	sim93.ia.lista = [ApoioCombate.criar_eco(1, Vector2(1100.0, 540.0))]
	sim93.ia.acao_no_turno = func(p: int, ini: ContratosDoCombate.InimigoCombate, c: Combate) -> void:
		if p == 0:
			c.disparar_projetil(ini.id, Vector2(1100.0, 540.0), Vector2.LEFT, 600.0, 9.0, 4.0, 9.0, 1.0, false)
	for k in 12:
		sim93.passo()
		if k == 0:
			assert_float(sim93.combate.projeteis_em_voo()[0].posicao.x).is_equal_approx(1090.0, 0.001)
		elif k == 10:
			assert_int(sim93.combate.recursos(0).vida).is_equal(91)
