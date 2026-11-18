extends GdUnitTestSuite
## Story combate-nucleo-006: AC-37..AC-47, AC-89, AC-90 (ferir_inimigo, enésimo acerto, finalizador, cambaleio, Quebrou!, empurrão F7 e parede F8).


func test_ac37_dano_contador_e_enesimo_acerto() -> void:
	var port := ApoioCombate.portador_jogador(100.0)
	port.aplicar_fonte(FonteDeModificador.new(&"bencao:atk_e_4o", [
		Modificador.new(Atributos.DANO_ATAQUE, Modificador.Operacao.PERCENTUAL, 0.25),
		Modificador.new(Atributos.DANO_TODO, Modificador.Operacao.MULTIPLICADOR, 1.6, Modificador.Condicao.ENESIMO_ACERTO, 4.0),
	]))
	var sim := ApoioCombate.SimCombate.new(false, null, port)
	sim.mov.executa_deslocar = false
	var b := ApoioCombate.criar_saco(2, Vector2(1060.0, 480.0))
	var a := ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0))
	var c := ApoioCombate.criar_saco(3, Vector2(1060.0, 600.0))
	b.surgindo = true
	c.surgindo = true
	sim.ia.lista = [b, a, c]
	for k in 20:
		if k == 19:
			b.surgindo = false
			c.surgindo = false
		sim.passo(false, false, true, false)
	var ev0 := sim.eventos_do_passo(0, EventosDoCombate.EvAcerto.TIPO)[0] as EventosDoCombate.EvAcerto
	assert_float(ev0.dano).is_equal_approx(17.5, 0.001)
	var evs19 := sim.eventos_do_passo(19, EventosDoCombate.EvAcerto.TIPO)
	assert_int(evs19.size()).is_equal(3)
	assert_float((evs19[0] as EventosDoCombate.EvAcerto).dano).is_equal_approx(17.5, 0.001)
	assert_float((evs19[1] as EventosDoCombate.EvAcerto).dano).is_equal_approx(17.5, 0.001)
	var ev_c := evs19[2] as EventosDoCombate.EvAcerto
	assert_float(ev_c.dano).is_equal_approx(28.0, 0.001)
	assert_bool(ev_c.enesimo_acerto).is_true()
	assert_bool(ev_c.pesado).is_true()
	assert_str(String(ev_c.peso_visual)).is_equal("pesado")
	assert_int(sim.combate.hitstop_restante()).is_equal(3)


func test_ac38_e_ac42_finalizador_fator_do_alvo_e_quebrou() -> void:
	# Saco móvel em preparação no 3º Corte (passo 32) -> desloca 15 px, pesado, cambaleia, 1 Quebrou!(24)
	var sim := ApoioCombate.SimCombate.new(false)
	var saco := ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0), true)
	saco.surgindo = true
	saco.em_preparacao = true
	sim.ia.lista = [saco]
	for k in 33:
		if k == 32:
			saco.surgindo = false
		sim.passo(false, false, true, false)
	assert_float(saco.posicao.x).is_equal_approx(1075.0, 0.001)
	assert_int(sim.ia.quebras.size()).is_equal(1)
	assert_array(sim.ia.quebras[0]).is_equal([1, 24])
	assert_int(sim.eventos_do_passo(32, EventosDoCombate.EvQuebrou.TIPO).size()).is_equal(1)

	# Elite e Chefe em preparação -> deslocam 6,0 e 1,8 px, sem cambaleio e sem Quebrou!
	for eh_chefe: bool in [false, true]:
		var s_arm := ApoioCombate.SimCombate.new(false)
		var alvo := ApoioCombate.criar_chefe(1, Vector2(1060.0, 540.0)) if eh_chefe else ApoioCombate.criar_elite(1, Vector2(1060.0, 540.0))
		alvo.surgindo = true
		alvo.em_preparacao = true
		s_arm.ia.lista = [alvo]
		for k in 33:
			if k == 32:
				alvo.surgindo = false
			s_arm.passo(false, false, true, false)
		assert_float(alvo.posicao.x).is_equal_approx(1061.8 if eh_chefe else 1066.0, 0.001)
		assert_int(alvo.cambaleio).is_equal(0)
		assert_int(s_arm.ia.quebras.size()).is_equal(0)


func test_ac39_empurroes_opostos_se_anulam_e_mesmo_sentido_somam() -> void:
	# Direção (-1, 0) no item 6 anula o 450 do Corte -> x = 1060
	var s1 := ApoioCombate.SimCombate.new(false)
	var saco1 := ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0), true)
	s1.ia.lista = [saco1]
	s1.selo.acao_no_item_6 = func(p: int, c: Combate) -> void:
		if p == 0:
			c.ferir_inimigo(1, 0.0, Vector2.LEFT, 450.0, &"", false, false)
	s1.passo(true)
	assert_float(saco1.vel_empurrao.length()).is_equal_approx(0.0, 0.001)
	assert_float(saco1.posicao.x).is_equal_approx(1060.0, 0.001)
	assert_int(saco1.cambaleio).is_equal(7)

	# Direção (1, 0) no item 6 soma 450 + 450 = 900 -> x = 1075 após 0, e 1127,8936 após 24
	var s2 := ApoioCombate.SimCombate.new(false)
	var saco2 := ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0), true)
	s2.ia.lista = [saco2]
	s2.selo.acao_no_item_6 = func(p: int, c: Combate) -> void:
		if p == 0:
			c.ferir_inimigo(1, 0.0, Vector2.RIGHT, 450.0, &"", false, false)
	for k in 26:
		s2.passo(k == 0)
		if k == 0:
			assert_float(saco2.posicao.x).is_equal_approx(1075.0, 0.001)
		elif k == 24:
			assert_float(saco2.posicao.x).is_equal_approx(1127.8936, 0.01)


func test_ac40_ac41_ac43_ac44_dano_zero_cambaleio_atingivel_e_morto_nao_age() -> void:
	# AC-40(a): M = 0 ainda aplica empurrão, cambaleio, status e acerto_de_arma
	var port0 := ApoioCombate.portador_jogador(100.0)
	port0.aplicar_fonte(FonteDeModificador.new(&"debuff:zero", [
		Modificador.new(Atributos.DANO_ATAQUE, Modificador.Operacao.PERCENTUAL, -1.0)
	]))
	var corte_s := ApoioCombate.ataque_corte()
	corte_s.status = &"sangramento"
	var sim0 := ApoioCombate.SimCombate.new(false, null, port0, corte_s, ApoioCombate.especial_investida())
	var saco0 := ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0), true)
	sim0.ia.lista = [saco0]
	sim0.passo(true)
	assert_float(saco0.vida).is_equal_approx(1000.0, 0.001)
	assert_int(sim0.eventos_do_passo(0, EventosDoCombate.EvAcertoDeArma.TIPO).size()).is_equal(1)
	assert_float(saco0.posicao.x).is_equal_approx(1067.5, 0.001)
	assert_int(saco0.cambaleio).is_equal(7)
	assert_int(sim0.status.aplicados.size()).is_equal(1)

	# AC-44: morto no item 5 não é empurrado e não age no item 7
	var sim44 := ApoioCombate.SimCombate.new(false)
	var eco44 := ApoioCombate.criar_eco(1, Vector2(1060.0, 540.0), 14.0)
	sim44.ia.lista = [eco44]
	sim44.ia.acao_no_turno = func(_p: int, ini: ContratosDoCombate.InimigoCombate, c: Combate) -> void:
		c.ferir_jogador(0, 9.0, 1.0, ini.id)
	sim44.passo(true)
	assert_int(sim44.combate.recursos(0).vida).is_equal(100)
	assert_int(sim44.ia.turnos.size()).is_equal(0)
	assert_int(sim44.ia.lista.size()).is_equal(0)


func test_ac89_e_ac90_hitstop_x_pesado_e_dano_de_status() -> void:
	# AC-89 linha 1: Onda-270 -> hitstop 6 (Especial), pesado no acerto = falso, peso_visual = pesado, sem Quebrou!
	var onda270 := ApoioCombate.especial_onda()
	onda270.empurrao = 270.0
	var sim1 := ApoioCombate.SimCombate.new(true, null, null, ApoioCombate.ataque_pulso(), onda270)
	var saco1 := ApoioCombate.criar_saco(1, Vector2(1100.0, 540.0), true)
	saco1.em_preparacao = true
	sim1.ia.lista = [saco1]
	sim1.passo(false, true)
	var ev1 := sim1.eventos_do_passo(0, EventosDoCombate.EvAcerto.TIPO)[0] as EventosDoCombate.EvAcerto
	assert_int(sim1.combate.hitstop_restante()).is_equal(6)
	assert_bool(ev1.pesado).is_false()
	assert_str(String(ev1.peso_visual)).is_equal("pesado")
	assert_int(sim1.ia.quebras.size()).is_equal(0)
	assert_float(saco1.posicao.x).is_equal_approx(1104.5, 0.001)

	# AC-90: ferir_inimigo_de_status (dano 5) -> sem acerto, sem empurrão, sem cambaleio, sem hitstop
	var sim90 := ApoioCombate.SimCombate.new(false)
	var saco90 := ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0), true)
	saco90.em_preparacao = true
	sim90.ia.lista = [saco90]
	sim90.status.acao_no_tick = func(p: int, ini: ContratosDoCombate.InimigoCombate, c: Combate) -> void:
		if p == 0:
			c.ferir_inimigo_de_status(ini.id, 5.0)
	sim90.passo()
	assert_float(saco90.vida).is_equal_approx(995.0, 0.001)
	assert_int(sim90.eventos_do_passo(0, EventosDoCombate.EvAcerto.TIPO).size()).is_equal(0)
	assert_int(sim90.combate.hitstop_restante()).is_equal(0)


func test_ac45_ac46_ac47_percurso_do_empurrao_e_impacto_na_parede() -> void:
	# AC-45: tabela de percurso do empurrão
	var casos: Array = [
		[false, false, 270.0, 4.5, 17, 20.1550],
		[false, false, 450.0, 7.5, 19, 33.7872],
		[false, false, 900.0, 15.0, 22, 67.8936],
		[false, false, 1080.0, 18.0, 23, 81.5484],
		[false, false, 1260.0, 21.0, 23, 95.1398],
		[true, false, 900.0, 6.0, 18, 26.9612],
		[false, true, 900.0, 1.8, 13, 7.8582],
	]
	for c: Array in casos:
		var sim := ApoioCombate.SimCombate.new(false)
		var alvo: ContratosDoCombate.InimigoCombate
		if c[1]:
			alvo = ApoioCombate.criar_chefe(1, Vector2(500.0, 300.0))
		elif c[0]:
			alvo = ApoioCombate.criar_elite(1, Vector2(500.0, 300.0))
		else:
			alvo = ApoioCombate.criar_saco(1, Vector2(500.0, 300.0), true)
		sim.ia.lista = [alvo]
		sim.selo.acao_no_item_6 = func(p: int, comb: Combate) -> void:
			if p == 0:
				comb.ferir_inimigo(1, 0.0, Vector2.RIGHT, float(c[2]), &"", false, false)
		var n_esp: int = c[4]
		for k in range(n_esp + 2):
			sim.passo()
			if k == 0:
				assert_float(alvo.posicao.x - 500.0).is_equal_approx(float(c[3]), 0.001)
			elif k == n_esp - 1:
				assert_float(alvo.vel_empurrao.length()).is_equal_approx(0.0, 0.001)
		assert_float(alvo.posicao.x - 500.0).is_equal_approx(float(c[5]), 0.01)

	# AC-46(a): Saco móvel em (1846, 540), E = 1260 -> bate na parede no passo 2, dano 8, hitstop 3
	var sim_p := ApoioCombate.SimCombate.new(false)
	var saco_p := ApoioCombate.criar_saco(1, Vector2(1846.0, 540.0), true)
	sim_p.ia.lista = [saco_p]
	sim_p.selo.acao_no_item_6 = func(p: int, comb: Combate) -> void:
		if p == 0:
			comb.ferir_inimigo(1, 0.0, Vector2.RIGHT, 1260.0, &"", false, false)
	for k in 7:
		sim_p.passo()
		if k == 0:
			assert_float(saco_p.posicao.x).is_equal_approx(1867.0, 0.001)
		elif k == 1:
			assert_float(saco_p.posicao.x).is_equal_approx(1883.38, 0.01)
		elif k == 2:
			assert_float(saco_p.posicao.x).is_equal_approx(1896.0, 0.001)
			assert_float(saco_p.vida).is_equal_approx(992.0, 0.001)
			assert_int(sim_p.eventos_do_passo(2, EventosDoCombate.EvParede.TIPO).size()).is_equal(1)
	assert_array(sim_p.passos_congelados).is_equal([3, 4, 5])
