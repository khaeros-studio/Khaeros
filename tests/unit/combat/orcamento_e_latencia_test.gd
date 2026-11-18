extends GdUnitTestSuite
## Story combate-nucleo-010: AC-81 (orçamento de desempenho dos itens 3, 5, 7, 8 e 9), AC-92 (latência de 1 passo) e invariantes de feel P3.


func test_ac81_orcamento_do_combate_1000_passos_com_9_inimigos_e_6_projeteis() -> void:
	var sim := ApoioCombate.SimCombate.new(false)
	sim.mov.executa_deslocar = false
	for i in 6:
		sim.ia.lista.append(ApoioCombate.criar_saco(i + 1, Vector2(1020.0 + float(i) * 8.0, 520.0 + float(i) * 6.0), true, 1e9))
	for i in 2:
		sim.ia.lista.append(ApoioCombate.criar_elite(10 + i, Vector2(1030.0, 530.0 + float(i) * 15.0), 1e9))
	sim.ia.lista.append(ApoioCombate.criar_chefe(99, Vector2(1040.0, 540.0), 1e9))

	var tempos_us: Array[int] = []
	var buf := BufferDeComandos.new(10)
	for k in 1060:
		# Mantém 3 projéteis do jogador e 3 de inimigo em voo
		while sim.combate.projeteis_em_voo().size() < 6:
			if (sim.combate.projeteis_em_voo().size() % 2) == 0:
				var p_j := ProjetilRegistro.new()
				p_j.id = k * 10 + sim.combate.projeteis_em_voo().size()
				p_j.do_jogador = true
				p_j.player_id = 0
				p_j.posicao = Vector2(996.0, 540.0)
				p_j.direcao = Vector2.RIGHT
				p_j.passo_px = 16.5
				p_j.raio_px = 15.0
				p_j.vida_restante = 50
				p_j.dano_golpe = 12.0
				sim.combate.projeteis_em_voo().append(p_j)
			else:
				sim.combate.disparar_projetil(1, Vector2(1400.0, 540.0), Vector2.LEFT, 540.0, 12.0, 1.0, 9.0, 1.0)
		buf.atualizar([], k, 0, false)
		var cmd := ComandosDoPasso.new(buf, [Acoes.ATAQUE, Acoes.ESPECIAL], k, 0)

		var t0 := Time.get_ticks_usec()
		sim.combate.inicio_do_passo()
		sim.combate.golpe_do_jogador([cmd])
		for ini in sim.ia.lista:
			sim.combate.impacto_do_inimigo(ini.id)
		sim.combate.projeteis()
		sim.combate.varredura_de_mortes()
		var t1 := Time.get_ticks_usec()

		if k >= 60:
			tempos_us.append(t1 - t0)
		sim.eventos.esvaziar()
		for ini in sim.ia.lista:
			ini.posicao = Vector2(1020.0, 540.0)

	tempos_us.sort()
	var p99_us: int = tempos_us[int(floor(float(tempos_us.size()) * 0.99))]
	# Orçamento solicitado: <= 0,8 ms (800 us) em debug headless (0,3 ms em release exportado).
	assert_int(p99_us).is_less_equal(800)


func test_ac92_e_ac82_latencia_de_1_passo_e_nenhum_golpe_engolido() -> void:
	var sim := ApoioCombate.SimCombate.new(false)
	sim.ia.lista = [ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0))]
	var toques_elegiveis := 0
	var disparos_no_mesmo_passo := 0
	for k in 400:
		var r := sim.combate.recursos(0)
		var elegivel_antes := (not sim.combate.hitstop_ativo()) and r.recarga[0] <= 1 and r.investida == 0 and (not sim.mov.esquiva)
		var tocar := elegivel_antes and (k % 5 == 0)
		if tocar:
			toques_elegiveis += 1
		sim.passo(tocar)
		if tocar and sim.eventos_do_passo(k, EventosDoCombate.EvGolpe.TIPO).size() == 1:
			disparos_no_mesmo_passo += 1
	assert_int(toques_elegiveis).is_greater(10)
	assert_int(disparos_no_mesmo_passo).is_equal(toques_elegiveis)
