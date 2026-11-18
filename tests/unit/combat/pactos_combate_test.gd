extends GdUnitTestSuite
## Story combate-nucleo-009: AC-98..AC-111, AC-113..AC-119 (Pactos: Maldição aliada, sem fogo amigo, aplicar_golpe_maldicao, ferir_maldicao, Exaustão síncrona, ferir_acuada, lacaios e chefe Subjugado).


func _portador_maldicao(vida_max: float = 110.0, reducao: float = 0.0) -> Portador:
	var bases: Dictionary[StringName, float] = {
		Atributos.VIDA_MAX: vida_max,
		Atributos.VELOCIDADE: 405.0,
		Atributos.RAIO: 24.0,
		Atributos.REDUCAO_DANO: reducao,
	}
	return Portador.new(50, 0, Atributos.Especie.MALDICAO, bases, ApoioCombate.FabMod.tuning())


func test_ac98_e_ac115_sem_fogo_amigo_em_maldicao_e_acuada() -> void:
	var sim := ApoioCombate.SimCombate.new(false)
	sim.mov.pos = Vector2(560.0, 540.0)
	sim.maldicoes.pos = Vector2(600.0, 540.0)
	sim.maldicoes.vida = 110
	sim.vinculo.atingivel = true
	sim.vinculo.pos = Vector2(610.0, 540.0)
	sim.vinculo.vida = 114
	var eco := ApoioCombate.criar_eco(1, Vector2(640.0, 540.0), 30.0)
	sim.ia.lista = [eco]
	sim.passo(true)
	assert_float(eco.vida).is_equal_approx(16.0, 0.001)
	assert_int(sim.maldicoes.vida).is_equal(110)
	assert_int(sim.vinculo.vida).is_equal(114)
	assert_int(sim.eventos_do_passo(0, EventosDoCombate.EvMaldicaoAtingida.TIPO).size()).is_equal(0)
	assert_int(sim.eventos_do_passo(0, EventosDoCombate.EvAcuadaAtingida.TIPO).size()).is_equal(0)
	var ev_g := sim.eventos_do_passo(0, EventosDoCombate.EvGolpe.TIPO)[0] as EventosDoCombate.EvGolpe
	assert_int(ev_g.n_alvos).is_equal(1)


func test_ac99_ac100_ac101_ac102_golpe_da_maldicao_e_abate_do_dono() -> void:
	# AC-99: golpe leve da Maldição -> sem acerto_de_arma, sem contador_acertos, sem hitstop, cambaleio = 8 antes do item 7 (7 após)
	var sim := ApoioCombate.SimCombate.new(false)
	var eco := ApoioCombate.criar_eco(1, Vector2(640.0, 540.0), 30.0)
	sim.ia.lista = [eco]
	sim.combate.aplicar_golpe_maldicao(0, &"vulto_mudo", [1], 10.0, 1.0, Vector2.RIGHT, 360.0, &"", false)
	assert_float(eco.vida).is_equal_approx(20.0, 0.001)
	assert_int(eco.cambaleio).is_equal(8)
	assert_int(sim.combate.recursos(0).contador_acertos).is_equal(0)
	assert_int(sim.combate.hitstop_restante()).is_equal(0)
	var ev := sim.eventos.do_tipo(EventosDoCombate.EvAcerto.TIPO)[0] as EventosDoCombate.EvAcerto
	assert_str(String(ev.slot)).is_equal("nenhum")
	assert_str(String(ev.forma)).is_equal("maldicao")
	assert_str(String(ev.peso_visual)).is_equal("leve")

	# AC-100: golpe pesado da Maldição (empurrão 900) quebra preparo sem pedir hitstop
	var sim100 := ApoioCombate.SimCombate.new(false)
	var eco100 := ApoioCombate.criar_eco(1, Vector2(640.0, 540.0), 30.0)
	eco100.em_preparacao = true
	sim100.ia.lista = [eco100]
	sim100.combate.aplicar_golpe_maldicao(0, &"baluarte_de_cinza", [1], 14.0, 1.0, Vector2.RIGHT, 900.0, &"", true)
	assert_float(eco100.vida).is_equal_approx(16.0, 0.001)
	assert_int(sim100.ia.quebras.size()).is_equal(1)
	assert_int(sim100.combate.hitstop_restante()).is_equal(0)

	# AC-102: abate da Maldição credita autor_player_id = 0, cura_ao_abater, explosao_ao_abater e hitstop 4
	var port_j := ApoioCombate.portador_jogador(90.0)
	port_j.aplicar_fonte(FonteDeModificador.new(&"bencao:abate", [], [
		GatilhoAtivo.new(&"cura_ao_abater", 4.0),
		GatilhoAtivo.new(&"explosao_ao_abater", 12.0, {&"raio_px": 120.0, &"empurrao": 0.0}),
	]))
	var sim102 := ApoioCombate.SimCombate.new(false, null, port_j)
	sim102.combate.recursos(0).vida = 70
	var e_morto := ApoioCombate.criar_eco(1, Vector2(640.0, 540.0), 8.0)
	var e_viz := ApoioCombate.criar_eco(2, Vector2(700.0, 540.0), 30.0)
	sim102.ia.lista = [e_morto, e_viz]
	sim102.maldicoes.acao_no_item_6_1 = func(p: int, c: Combate) -> void:
		if p == 0:
			c.aplicar_golpe_maldicao(0, &"vulto_mudo", [1], 10.0, 1.0, Vector2.RIGHT, 360.0)
	sim102.passo()
	assert_int(sim102.combate.recursos(0).abates).is_equal(1)
	assert_int(sim102.combate.recursos(0).vida).is_equal(74)
	assert_int(sim102.combate.hitstop_restante()).is_equal(4)
	assert_float(e_viz.vida).is_equal_approx(18.0, 0.001)
	var ev_m := sim102.eventos_do_passo(0, EventosDoCombate.EvInimigoMorreu.TIPO)[0] as EventosDoCombate.EvInimigoMorreu
	assert_int(ev_m.autor_player_id).is_equal(0)


func test_ac103_ac104_ac105_dano_na_maldicao_e_exaustao_sincrona() -> void:
	var sim := ApoioCombate.SimCombate.new(false)
	sim.maldicoes.vida = 135
	sim.maldicoes.portador = _portador_maldicao(135.0, 0.15)
	sim.combate.ferir_maldicao(&"baluarte_de_cinza", 9.0, 1.0, 1, &"golpe_eco")
	assert_int(sim.maldicoes.vida).is_equal(127)
	sim.combate.ferir_maldicao(&"baluarte_de_cinza", 9.0, 1.0, 1, &"golpe_eco")
	assert_int(sim.maldicoes.vida).is_equal(119)
	assert_int(sim.eventos.do_tipo(EventosDoCombate.EvMaldicaoAtingida.TIPO).size()).is_equal(2)
	assert_int(sim.combate.hitstop_restante()).is_equal(0)

	# AC-105: Exaustão síncrona com Vida 5 -> Vida 0, exaurir chamado antes do retorno, 2º golpe ignorado
	var sim105 := ApoioCombate.SimCombate.new(false)
	sim105.maldicoes.vida = 5
	sim105.maldicoes.portador = _portador_maldicao(135.0, 0.15)
	sim105.combate.ferir_maldicao(&"baluarte_de_cinza", 9.0, 1.0, 1, &"golpe_eco")
	assert_int(sim105.maldicoes.vida).is_equal(0)
	assert_array(sim105.maldicoes.exauridas).is_equal([&"baluarte_de_cinza"])
	assert_int(sim105.eventos.do_tipo(EventosDoCombate.EvMaldicaoExausta.TIPO).size()).is_equal(1)
	assert_int(sim105.eventos.do_tipo(EventosDoCombate.EvJogadorMorreu.TIPO).size()).is_equal(0)
	sim105.combate.ferir_maldicao(&"baluarte_de_cinza", 9.0, 1.0, 1, &"golpe_eco")
	assert_int(sim105.eventos.do_tipo(EventosDoCombate.EvMaldicaoAtingida.TIPO).size()).is_equal(1)


func test_ac106_ac107_ac116_projetil_so_testa_o_seu_alvo() -> void:
	# Projétil com alvo JOGADOR cruza a Maldição e a acuada sem feri-las
	var sim := ApoioCombate.SimCombate.new(false)
	sim.mov.pos = Vector2(960.0, 540.0)
	sim.maldicoes.pos = Vector2(900.0, 540.0)
	sim.maldicoes.vida = 110
	sim.maldicoes.portador = _portador_maldicao(110.0)
	sim.vinculo.atingivel = true
	sim.vinculo.pos = Vector2(920.0, 540.0)
	sim.vinculo.vida = 114
	sim.combate.disparar_projetil(1, Vector2(850.0, 540.0), Vector2.RIGHT, 600.0, 12.0, 2.0, 9.0, 1.0, false,
		ContratosDoCombate.Faccao.JOGADOR, 0)
	for k in 15:
		sim.passo()
	assert_int(sim.maldicoes.vida).is_equal(110)
	assert_int(sim.vinculo.vida).is_equal(114)
	assert_int(sim.combate.recursos(0).vida).is_equal(91)

	# Projétil com alvo ALIADO cruza o jogador sem feri-lo e fere a Maldição
	var sim_m := ApoioCombate.SimCombate.new(false)
	sim_m.mov.pos = Vector2(900.0, 540.0)
	sim_m.maldicoes.pos = Vector2(960.0, 540.0)
	sim_m.maldicoes.vida = 110
	sim_m.maldicoes.portador = _portador_maldicao(110.0)
	sim_m.combate.disparar_projetil(1, Vector2(850.0, 540.0), Vector2.RIGHT, 600.0, 12.0, 2.0, 9.0, 1.0, false,
		ContratosDoCombate.Faccao.ALIADO, 0, &"vulto_mudo")
	for k in 15:
		sim_m.passo()
	assert_int(sim_m.combate.recursos(0).vida).is_equal(100)
	assert_int(sim_m.maldicoes.vida).is_equal(101)


func test_ac108_ac109_ac110_ac111_ordem_6_1_lacaios_e_chefe_subjugado() -> void:
	# AC-108: golpe da Maldição no 6.1 move o Eco já no item 7 do mesmo passo (+6 px)
	var sim108 := ApoioCombate.SimCombate.new(false)
	var eco108 := ApoioCombate.criar_eco(1, Vector2(640.0, 540.0), 30.0)
	sim108.ia.lista = [eco108]
	sim108.maldicoes.acao_no_item_6_1 = func(p: int, c: Combate) -> void:
		if p == 0:
			c.aplicar_golpe_maldicao(0, &"vulto_mudo", [1], 10.0, 1.0, Vector2.RIGHT, 360.0)
	sim108.passo()
	assert_float(eco108.posicao.x).is_equal_approx(646.0, 0.001)

	# AC-109: lacaios invocado_pelo_chefe saem sem abate, sem cura e sem explosão; projéteis inimigos somem
	var port_j := ApoioCombate.portador_jogador(90.0)
	port_j.aplicar_fonte(FonteDeModificador.new(&"bencao:abate", [], [
		GatilhoAtivo.new(&"cura_ao_abater", 4.0),
		GatilhoAtivo.new(&"explosao_ao_abater", 12.0, {&"raio_px": 120.0, &"empurrao": 0.0}),
	]))
	var sim109 := ApoioCombate.SimCombate.new(true, null, port_j)
	sim109.combate.recursos(0).vida = 70
	var chefe := ApoioCombate.criar_chefe(1, Vector2(1100.0, 540.0), 5.0)
	var lac1 := ApoioCombate.criar_eco(2, Vector2(500.0, 540.0), 30.0)
	lac1.invocado_pelo_chefe = true
	var lac2 := ApoioCombate.criar_eco(3, Vector2(520.0, 540.0), 30.0)
	lac2.invocado_pelo_chefe = true
	sim109.ia.lista = [chefe, lac1, lac2]
	sim109.combate.disparar_projetil(1, Vector2(1100.0, 540.0), Vector2.LEFT, 540.0, 12.0, 2.0, 9.0, 1.0)
	sim109.passo(false, true)
	assert_int(sim109.combate.recursos(0).abates).is_equal(1)
	assert_int(sim109.combate.recursos(0).vida).is_equal(74)
	assert_int(sim109.combate.projeteis_em_voo().size()).is_equal(0)
	assert_int(sim109.combate.hitstop_restante()).is_equal(36)

	# AC-110 e AC-111: chefe subjugavel fica Subjugado na lista; Exorcizar dá abate e cura, Pactuar não
	for escolha: StringName in [&"exorcizar", &"pactuar"]:
		var sim110 := ApoioCombate.SimCombate.new(false, null, port_j)
		sim110.combate.recursos(0).vida = 70
		var ch_sub := ApoioCombate.criar_chefe(1, Vector2(700.0, 540.0), 5.0)
		ch_sub.subjugavel = true
		sim110.ia.lista = [ch_sub]
		sim110.maldicoes.acao_no_item_6_1 = func(p: int, c: Combate) -> void:
			if p == 0:
				c.aplicar_golpe_maldicao(0, &"vulto_mudo", [1], 10.0, 1.0, Vector2.RIGHT, 360.0)
		sim110.passo()
		assert_int(sim110.ia.lista.size()).is_equal(1)
		assert_bool(sim110.combate.atingivel(1)).is_false()
		assert_array(sim110.ia.subjugados).is_equal([1])
		assert_int(sim110.combate.recursos(0).abates).is_equal(0)
		assert_int(sim110.combate.recursos(0).vida).is_equal(70)
		assert_int(sim110.eventos_do_passo(0, EventosDoCombate.EvChefeVencido.TIPO).size()).is_equal(1)

		sim110.combate.resolver_subjugado(1, escolha)
		assert_int(sim110.ia.lista.size()).is_equal(0)
		if escolha == &"exorcizar":
			assert_int(sim110.combate.recursos(0).abates).is_equal(1)
			assert_int(sim110.combate.recursos(0).vida).is_equal(74)
		else:
			assert_int(sim110.combate.recursos(0).abates).is_equal(0)
			assert_int(sim110.combate.recursos(0).vida).is_equal(70)


func test_ac113_ac114_ac117_ac118_ac119_acuada_dano_e_falha_sincrona() -> void:
	# AC-113: ferir_acuada(9, 1.0) duas vezes -> 114 -> 105 -> 96, 2 acuada_atingida, 0 hitstop
	var sim := ApoioCombate.SimCombate.new(false)
	sim.vinculo.atingivel = true
	sim.vinculo.vida = 114
	sim.combate.ferir_acuada(9.0, 1.0, 1, &"golpe_eco")
	assert_int(sim.vinculo.vida).is_equal(105)
	sim.combate.ferir_acuada(9.0, 1.0, 1, &"golpe_eco")
	assert_int(sim.vinculo.vida).is_equal(96)
	sim.combate.ferir_acuada(9.0, 0.7, 1, &"golpe_eco")
	assert_int(sim.vinculo.vida).is_equal(90)
	assert_int(sim.combate.hitstop_restante()).is_equal(0)

	# AC-114 & AC-117: falha síncrona no item 7 antes da varredura (item 9) e da câmara limpa (item 10)
	var sim117 := ApoioCombate.SimCombate.new(true)
	sim117.vinculo.atingivel = true
	sim117.vinculo.vida = 5
	var eco_ult := ApoioCombate.criar_eco(1, Vector2(1010.0, 540.0), 1.0)
	sim117.ia.lista = [eco_ult]
	var estado_acuada_na_varredura: Array[StringName] = []
	sim117.ia.acao_no_turno = func(p: int, ini: ContratosDoCombate.InimigoCombate, c: Combate) -> void:
		if p == 0:
			c.ferir_acuada(9.0, 1.0, ini.id, &"golpe_eco")
			estado_acuada_na_varredura.append(sim117.vinculo.estado)
	sim117.passo(true)  # Pulso no item 8 mata o Eco de Vida 1
	assert_int(sim117.vinculo.vida).is_equal(0)
	assert_int(sim117.vinculo.falhas).is_equal(1)
	assert_array(estado_acuada_na_varredura).is_equal([&"Fugiu"])
	assert_int(sim117.ia.lista.size()).is_equal(0)
