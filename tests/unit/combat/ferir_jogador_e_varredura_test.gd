extends GdUnitTestSuite
## Story combate-nucleo-007: AC-48..AC-57, AC-87, AC-88 (ferir_jogador, escudo, refletir, recusa, em_combate e varredura de mortes em até 4 passes).


func test_ac48_formula_f10_dano_no_jogador() -> void:
	var tabela: Array = [
		[9.0, 1.0, 0.0, false, 0.5, 9, 91],
		[13.0, 1.25, 0.0, false, 0.5, 16, 84],
		[13.0, 1.25, 0.12, false, 0.5, 14, 86],
		[9.0, 1.0, 0.0, true, 0.5, 5, 95],
		[1.0, 0.4, 0.0, false, 0.5, 1, 99],
		[9.0, 1.0, -0.2, false, 0.5, 9, 91],
		[9.0, 1.0, 0.0, true, 0.0, 1, 99],
		[9.0, 1.0, 0.0, true, 1.0, 9, 91],
	]
	for linha: Array in tabela:
		var t := ApoioCombate.tuning_fp()
		t.fator_guarda = float(linha[4])
		var port := ApoioCombate.portador_jogador(100.0)
		if float(linha[2]) != 0.0:
			port.aplicar_fonte(FonteDeModificador.new(&"bencao:red", [
				Modificador.new(Atributos.REDUCAO_DANO, Modificador.Operacao.PLANO, float(linha[2]))
			]))
		var sim := ApoioCombate.SimCombate.new(false, t, port)
		if bool(linha[3]):
			sim.combate.recursos(0).guarda = 6
		sim.passo(false, false, false, false,
			func() -> void:
				sim.combate.ferir_jogador(0, float(linha[0]), float(linha[1])))
		var r := sim.combate.recursos(0)
		assert_int(r.vida).is_equal(int(linha[6]))
		assert_int(r.invulneravel).is_equal(40)
		assert_int(sim.combate.hitstop_restante()).is_equal(6)
		var ev := sim.eventos_do_passo(0, EventosDoCombate.EvJogadorAtingido.TIPO)[0] as EventosDoCombate.EvJogadorAtingido
		assert_int(ev.vida_perdida).is_equal(int(linha[5]))


func test_ac49_e_ac50_escudo_e_dois_inimigos_no_mesmo_passo() -> void:
	# Escudo 10, dano 14 -> absorve 10, Vida perdida 4, Vida 96, escudo 0
	var s1 := ApoioCombate.SimCombate.new(false)
	s1.combate.recursos(0).escudo = 10
	s1.combate.ferir_jogador(0, 14.0, 1.0)
	assert_int(s1.combate.recursos(0).vida).is_equal(96)
	assert_int(s1.combate.recursos(0).escudo).is_equal(0)

	# Escudo 20, dano 9 com refletir_dano 3,0 -> Vida perdida 0, escudo 11, Vida 100, invuln 40, hitstop 6, nada refletido
	var port_ref := ApoioCombate.portador_jogador(100.0)
	port_ref.aplicar_fonte(FonteDeModificador.new(&"bencao:ref", [], [GatilhoAtivo.new(&"refletir_dano", 3.0)]))
	var s2 := ApoioCombate.SimCombate.new(false, null, port_ref)
	s2.combate.recursos(0).escudo = 20
	var eco := ApoioCombate.criar_eco(1, Vector2(990.0, 540.0), 30.0)
	s2.ia.lista = [eco]
	s2.combate.ferir_jogador(0, 9.0, 1.0, 1)
	assert_int(s2.combate.recursos(0).vida).is_equal(100)
	assert_int(s2.combate.recursos(0).escudo).is_equal(11)
	assert_int(s2.combate.recursos(0).invulneravel).is_equal(40)
	assert_float(eco.vida).is_equal_approx(30.0, 0.001)

	# AC-50: dois inimigos no passo 10 -> só o 1º fere; no passo 55 nada; no 56 tira 9
	var s50 := ApoioCombate.SimCombate.new(false)
	s50.ia.lista = [ApoioCombate.criar_eco(1, Vector2(990.0, 540.0)), ApoioCombate.criar_eco(2, Vector2(990.0, 550.0))]
	s50.ia.acao_no_turno = func(p: int, ini: ContratosDoCombate.InimigoCombate, c: Combate) -> void:
		if p == 10 or (ini.id == 2 and (p == 55 or p == 56)):
			c.ferir_jogador(0, 9.0, 1.0, ini.id)
	for k in 57:
		s50.passo()
		if k == 10:
			assert_int(s50.combate.recursos(0).vida).is_equal(91)
		elif k == 55:
			assert_int(s50.combate.recursos(0).vida).is_equal(91)
		elif k == 56:
			assert_int(s50.combate.recursos(0).vida).is_equal(82)


func test_ac51_e_ac52_refletir_antes_da_morte() -> void:
	# AC-51: refletir_dano 3,0, dano 13 * 1,25 com redução 0,12 e escudo 10 -> Vida perdida 4, A recebe 12
	var port := ApoioCombate.portador_jogador(100.0)
	port.aplicar_fonte(FonteDeModificador.new(&"bencao:red_ref", [
		Modificador.new(Atributos.REDUCAO_DANO, Modificador.Operacao.PLANO, 0.12)
	], [GatilhoAtivo.new(&"refletir_dano", 3.0)]))
	var sim := ApoioCombate.SimCombate.new(false, null, port)
	sim.combate.recursos(0).escudo = 10
	var eco := ApoioCombate.criar_eco(1, Vector2(990.0, 580.0), 30.0)
	sim.ia.lista = [eco]
	sim.ia.acao_no_turno = func(p: int, ini: ContratosDoCombate.InimigoCombate, c: Combate) -> void:
		if p == 0:
			c.ferir_jogador(0, 13.0, 1.25, ini.id)
	sim.passo()
	assert_int(sim.combate.recursos(0).vida).is_equal(96)
	assert_float(eco.vida).is_equal_approx(18.0, 0.001)
	assert_int(eco.cambaleio).is_equal(0)

	# AC-52: refletir mata o atacante antes da morte do jogador; ordem dos eventos
	var port52 := ApoioCombate.portador_jogador(100.0)
	port52.aplicar_fonte(FonteDeModificador.new(&"bencao:ref", [], [GatilhoAtivo.new(&"refletir_dano", 3.0)]))
	var sim52 := ApoioCombate.SimCombate.new(false, null, port52)
	sim52.combate.recursos(0).vida = 5
	var eco52 := ApoioCombate.criar_eco(1, Vector2(990.0, 580.0), 20.0)
	sim52.ia.lista = [eco52]
	sim52.ia.acao_no_turno = func(p: int, ini: ContratosDoCombate.InimigoCombate, c: Combate) -> void:
		if p == 0:
			c.ferir_jogador(0, 9.0, 1.0, ini.id)
	sim52.passo()
	var tipos: Array[StringName] = []
	for item in sim52.log_eventos:
		tipos.append(item[1])
	assert_array(tipos).is_equal([
		EventosDoCombate.EvJogadorAtingido.TIPO,
		EventosDoCombate.EvAcerto.TIPO,
		EventosDoCombate.EvJogadorMorreu.TIPO,
		EventosDoCombate.EvInimigoMorreu.TIPO,
	])


func test_ac53_e_ac87_recusa_de_morte_e_em_combate() -> void:
	var port := ApoioCombate.portador_jogador(100.0)
	port.aplicar_fonte(FonteDeModificador.new(&"bencao:rec", [], [
		GatilhoAtivo.new(&"recusas_morte", 1.0, {&"vida_ao_voltar": 0.4, &"invuln_s": 2.0})
	]))
	var sim := ApoioCombate.SimCombate.new(false, null, port)
	sim.combate.recursos(0).vida = 5
	sim.combate.recursos(0).recusas = 1
	for k in 140:
		sim.passo(false, false, false, false,
			func() -> void:
				if k == 0:
					sim.combate.ferir_jogador(0, 9.0, 1.0)
				elif k == 137 or k == 138:
					sim.combate.ferir_jogador(0, 50.0, 1.0))
		if k == 0:
			var r0 := sim.combate.recursos(0)
			assert_int(r0.vida).is_equal(40)
			assert_int(r0.invulneravel).is_equal(120)
			assert_int(r0.recusas).is_equal(0)
			assert_int(sim.combate.hitstop_restante()).is_equal(18)
			assert_int(sim.eventos_do_passo(0, EventosDoCombate.EvRecusouMorte.TIPO).size()).is_equal(1)
			assert_int(sim.eventos_do_passo(0, EventosDoCombate.EvJogadorMorreu.TIPO).size()).is_equal(0)
		elif k == 137:
			assert_int(sim.combate.recursos(0).vida).is_equal(40)
		elif k == 138:
			assert_int(sim.combate.recursos(0).vida).is_equal(0)
			assert_int(sim.eventos_do_passo(138, EventosDoCombate.EvJogadorMorreu.TIPO).size()).is_equal(1)

	# AC-87(b): em_combate falso recusa o dano no jogador
	var sim87 := ApoioCombate.SimCombate.new(false)
	sim87.camaras.combate_ativo = false
	sim87.combate.ferir_jogador(0, 9.0, 1.0)
	assert_int(sim87.combate.recursos(0).vida).is_equal(100)
	assert_int(sim87.combate.hitstop_restante()).is_equal(0)


func test_ac54_ac55_ac56_ac57_ac88_varredura_de_mortes() -> void:
	# AC-55: morte do chefe zera os outros inimigos e soma os abates no 2º passe
	var port_cura := ApoioCombate.portador_jogador(100.0)
	port_cura.aplicar_fonte(FonteDeModificador.new(&"bencao:cura", [], [GatilhoAtivo.new(&"cura_ao_abater", 5.0)]))
	var sim55 := ApoioCombate.SimCombate.new(true, null, port_cura)
	sim55.combate.recursos(0).vida = 80
	sim55.ia.lista = [
		ApoioCombate.criar_chefe(1, Vector2(1100.0, 540.0), 30.0),
		ApoioCombate.criar_eco(2, Vector2(500.0, 540.0), 30.0),
		ApoioCombate.criar_eco(3, Vector2(300.0, 300.0), 30.0),
	]
	sim55.passo(false, true)
	assert_int(sim55.combate.recursos(0).abates).is_equal(3)
	assert_int(sim55.combate.recursos(0).vida).is_equal(95)
	assert_int(sim55.combate.hitstop_restante()).is_equal(36)
	assert_int(sim55.ia.lista.size()).is_equal(0)

	# AC-56: cadeia de mais de 4 passes (Eco1..Eco6) -> 4 morrem no passo 0, os 2 últimos no passo 5
	var port_exp := ApoioCombate.portador_jogador(100.0)
	port_exp.aplicar_fonte(FonteDeModificador.new(&"bencao:exp", [], [
		GatilhoAtivo.new(&"explosao_ao_abater", 30.0, {&"raio_px": 60.0, &"empurrao": 0.0})
	]))
	var sim56 := ApoioCombate.SimCombate.new(false, null, port_exp)
	var eco1 := ApoioCombate.criar_eco(1, Vector2(1060.0, 540.0), 14.0)
	var eco2 := ApoioCombate.criar_eco(2, Vector2(1140.0, 540.0), 30.0)
	var eco3 := ApoioCombate.criar_eco(3, Vector2(1220.0, 540.0), 30.0)
	var eco4 := ApoioCombate.criar_eco(4, Vector2(1300.0, 540.0), 30.0)
	var eco5 := ApoioCombate.criar_eco(5, Vector2(1380.0, 540.0), 30.0)
	var eco6 := ApoioCombate.criar_eco(6, Vector2(1460.0, 540.0), 30.0)
	sim56.ia.lista = [eco6, eco5, eco4, eco3, eco2, eco1]
	for k in 7:
		sim56.passo(k == 0)
		if k == 0:
			assert_int(sim56.combate.recursos(0).abates).is_equal(4)
			assert_float(eco5.vida).is_equal_approx(0.0, 0.001)
		elif k == 5:
			assert_int(sim56.combate.recursos(0).abates).is_equal(6)
			assert_int(sim56.ia.lista.size()).is_equal(0)

	# AC-88: jogador morto neste passo não cura nem revive na varredura
	var sim88 := ApoioCombate.SimCombate.new(false, null, port_cura)
	sim88.combate.recursos(0).vida = 5
	var e1 := ApoioCombate.criar_eco(1, Vector2(1060.0, 540.0), 14.0)
	var eb := ApoioCombate.criar_eco(2, Vector2(700.0, 540.0), 30.0)
	sim88.ia.lista = [e1, eb]
	sim88.ia.acao_no_turno = func(p: int, ini: ContratosDoCombate.InimigoCombate, c: Combate) -> void:
		if p == 0 and ini.id == 2:
			c.ferir_jogador(0, 9.0, 1.0, ini.id)
	sim88.passo(true)
	assert_int(sim88.combate.recursos(0).vida).is_equal(0)
	assert_bool(sim88.combate.jogador_morto(0)).is_true()
	assert_array(sim88.estados_pedidos).is_equal([EstadoDeJogo.Valor.MORTE])
