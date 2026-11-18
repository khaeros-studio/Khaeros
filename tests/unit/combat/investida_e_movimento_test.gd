extends GdUnitTestSuite
## Story combate-nucleo-005: AC-94, AC-33, AC-34, AC-35, AC-36, AC-58, AC-59, AC-84, AC-85, AC-86
## (investida, pedidos síncronos do Movimento e contrato com MovimentoDoJogador real).


func test_ac94_m_da_investida_e_do_disparo() -> void:
	for vida_disparo: int in [40, 60]:
		var port := ApoioCombate.portador_jogador(100.0)
		port.aplicar_fonte(FonteDeModificador.new(&"bencao:fundo", [
			Modificador.new(Atributos.DANO_TODO, Modificador.Operacao.PERCENTUAL, 0.4, Modificador.Condicao.VIDA_ABAIXO, 0.5)
		]))
		var sim := ApoioCombate.SimCombate.new(false, null, port)
		sim.combate.recursos(0).vida = vida_disparo
		sim.ia.lista = [ApoioCombate.criar_saco(1, Vector2(1000.0, 540.0))]
		sim.passo(false, true)
		sim.combate.recursos(0).vida = 60 if vida_disparo == 40 else 40
		sim.passo()
		var ev := sim.eventos_do_passo(1, EventosDoCombate.EvAcerto.TIPO)[0] as EventosDoCombate.EvAcerto
		assert_float(ev.dano).is_equal_approx(36.4 if vida_disparo == 40 else 26.0, 0.001)


func test_ac33_investida_deslocamento_e_invulnerabilidade() -> void:
	var sim := ApoioCombate.SimCombate.new(false)
	for k in 13:
		sim.passo(false, k == 0)
		if k == 0:
			assert_int(sim.combate.recursos(0).invulneravel).is_equal(12)
			assert_int(sim.eventos_do_passo(0, EventosDoCombate.EvInvestida.TIPO).size()).is_equal(1)
			assert_int(sim.combate.recursos(0).recarga[1]).is_equal(70)
		assert_bool(sim.combate.em_recuperacao(0)).is_false()
	assert_array(sim.mov.passos_investida_aplicados).is_equal([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
	assert_vector(sim.mov.pos).is_equal_approx(Vector2(1290.0, 540.0), Vector2(0.001, 0.001))


func test_ac34_investida_alvos_a_partir_do_passo_seguinte_e_um_acerto_por_alvo() -> void:
	var sim := ApoioCombate.SimCombate.new(false)
	sim.ia.lista = [
		ApoioCombate.criar_saco(1, Vector2(1100.0, 540.0)),
		ApoioCombate.criar_saco(2, Vector2(1250.0, 540.0)),
	]
	for k in 20:
		sim.passo(false, k == 0)
	assert_int(sim.eventos_do_passo(0, EventosDoCombate.EvAcerto.TIPO).size()).is_equal(0)
	assert_int(sim.eventos_do_passo(2, EventosDoCombate.EvAcerto.TIPO).size()).is_equal(1)
	assert_int(sim.eventos_do_passo(12, EventosDoCombate.EvAcerto.TIPO).size()).is_equal(1)
	assert_array(sim.mov.passos_investida_aplicados).is_equal([1, 2, 9, 10, 11, 12, 16, 17, 18, 19])
	assert_vector(sim.mov.pos).is_equal_approx(Vector2(1290.0, 540.0), Vector2(0.001, 0.001))


func test_ac35_esquiva_cancela_investida() -> void:
	var sim := ApoioCombate.SimCombate.new(false)
	sim.ia.lista = [
		ApoioCombate.criar_saco(1, Vector2(1000.0, 540.0)),
		ApoioCombate.criar_saco(2, Vector2(1150.0, 540.0)),
	]
	for k in 12:
		sim.passo(false, k == 0, false, false,
			func() -> void:
				if k == 9:
					sim.combate.cancelar(0))
		if k == 9:
			assert_vector(sim.mov.pos).is_equal_approx(Vector2(1026.0, 540.0), Vector2(0.001, 0.001))
			assert_int(sim.combate.recursos(0).recarga[1]).is_equal(67)
			assert_int(sim.combate.recursos(0).invulneravel).is_equal(9)
	assert_array(sim.mov.passos_investida_aplicados).is_equal([1, 8])
	assert_int(sim.todos_eventos(EventosDoCombate.EvAcerto.TIPO).size()).is_equal(1)


func test_ac36_investida_contra_a_parede_testa_na_posicao_presa() -> void:
	var sim := ApoioCombate.SimCombate.new(false)
	sim.mov.pos = Vector2(1700.0, 540.0)
	sim.mov.usa_colisao = true
	var saco := ApoioCombate.criar_saco(1, Vector2(1893.0, 633.0))
	saco.surgindo = true
	sim.ia.lista = [saco]
	for k in 12:
		if k == 10:
			saco.surgindo = false
		sim.passo(false, k == 0)
		if k >= 6 and k <= 10:
			assert_float(sim.mov.pos.x).is_equal_approx(1893.0, 0.001)
	assert_int(sim.eventos_do_passo(10, EventosDoCombate.EvAcerto.TIPO).size()).is_equal(1)


func test_ac58_ac84_ac85_ac86_pedidos_do_movimento() -> void:
	# AC-84: cancelar zera recuperação e investida sem mexer em recarga, combo, janela, invuln ou apos_esquiva
	var port := ApoioCombate.portador_jogador(100.0)
	port.aplicar_fonte(FonteDeModificador.new(&"bencao:pen", [
		Modificador.new(Atributos.DANO_TODO, Modificador.Operacao.PERCENTUAL, 0.5, Modificador.Condicao.APOS_ESQUIVA, 1.0)
	]))
	var sim := ApoioCombate.SimCombate.new(false, null, port)
	for k in 5:
		sim.passo(k == 0, false, false, false,
			func() -> void:
				if k == 0:
					sim.combate.garantir_invulneravel(0, 20)
				elif k == 1:
					sim.combate.esquiva_iniciada(0)
				elif k == 3:
					sim.combate.cancelar(0))
		if k == 3:
			var r := sim.combate.recursos(0)
			assert_int(r.recuperacao).is_equal(0)
			assert_int(r.recarga[0]).is_equal(13)
			assert_int(r.passo_combo[0]).is_equal(1)
			assert_int(r.janela_combo[0]).is_equal(31)
			assert_int(r.invulneravel).is_equal(17)
			assert_int(r.apos_esquiva).is_equal(58)

	# AC-85: aplicar_corte não sobe contador_acertos, não emite acerto_de_arma e não pede hitstop
	var port85 := ApoioCombate.portador_jogador(100.0)
	port85.aplicar_fonte(FonteDeModificador.new(&"bencao:enesimo", [
		Modificador.new(Atributos.DANO_TODO, Modificador.Operacao.MULTIPLICADOR, 1.6, Modificador.Condicao.ENESIMO_ACERTO, 1.0)
	]))
	var sim85 := ApoioCombate.SimCombate.new(false, null, port85)
	var saco85 := ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0), true)
	saco85.em_preparacao = true
	sim85.ia.lista = [saco85]
	sim85.passo(false, false, false, false,
		func() -> void:
			sim85.combate.aplicar_corte(0, 1, 10.0, Vector2.RIGHT, 360.0, 1.0))
	var ev85 := sim85.eventos_do_passo(0, EventosDoCombate.EvAcerto.TIPO)[0] as EventosDoCombate.EvAcerto
	assert_float(ev85.dano).is_equal_approx(10.0, 0.001)
	assert_bool(ev85.de_arma).is_false()
	assert_bool(ev85.enesimo_acerto).is_false()
	assert_bool(ev85.pesado).is_false()
	assert_str(String(ev85.peso_visual)).is_equal("leve")
	assert_int(sim85.combate.recursos(0).contador_acertos).is_equal(0)
	assert_int(sim85.eventos_do_passo(0, EventosDoCombate.EvAcertoDeArma.TIPO).size()).is_equal(0)
	assert_int(sim85.status.aplicados.size()).is_equal(1)
	assert_float(saco85.vel_empurrao.x).is_equal_approx(280.8, 0.001)
	assert_int(saco85.cambaleio).is_equal(7)
	assert_float(saco85.posicao.x).is_equal_approx(1066.0, 0.001)
	assert_int(sim85.combate.hitstop_restante()).is_equal(0)

	# AC-86: esquiva_iniciada reinicia a janela inteira (60 passos)
	var sim86 := ApoioCombate.SimCombate.new(false, null, port)
	for k in 11:
		sim86.passo(false, false, false, false,
			func() -> void:
				if k == 0 or k == 10:
					sim86.combate.esquiva_iniciada(0))
	assert_int(sim86.combate.recursos(0).apos_esquiva).is_equal(60)


class _AdaptadorMovParaCombate extends MovimentoParaCombate:
	var mov: MovimentoDoJogador

	func _init(p_mov: MovimentoDoJogador) -> void:
		mov = p_mov

	func posicao(_pid: int) -> Vector2:
		return mov.posicao()

	func em_esquiva(_pid: int) -> bool:
		return mov.em_esquiva()

	func raio(_pid: int) -> float:
		return mov.raio()

	func deslocar(_pid: int, v: Vector2) -> void:
		mov.deslocar(v)


class _AdaptadorCombateParaMov extends CombateParaMovimento:
	var combate: Combate

	func em_recuperacao(pid: int) -> bool:
		return combate.em_recuperacao(pid)

	func investida_ativa(pid: int) -> bool:
		return combate.investida_ativa(pid)

	func deslocamento_investida(pid: int) -> Vector2:
		return combate.deslocamento_investida(pid)

	func cancelar(pid: int) -> void:
		combate.cancelar(pid)

	func garantir_invulneravel(pid: int, passos: int) -> void:
		combate.garantir_invulneravel(pid, passos)

	func esquiva_iniciada(pid: int) -> void:
		combate.esquiva_iniciada(pid)

	func vida_atual(pid: int) -> float:
		return combate.vida_atual(pid)

	func aplicar_corte(pid: int, alvo_id: int, dano: float, dir: Vector2, empurrao: float, sang: float) -> void:
		combate.aplicar_corte(pid, alvo_id, dano, dir, empurrao, sang)


func test_ac59_e_movimento_ac56_contrato_com_movimento_real() -> void:
	# AC-59(a) e Movimento AC-56: esquiva tocada no passo 0 protege exatamente os passos 0..11 e não o 12
	for passo_golpe: int in [0, 5, 11, 12]:
		var port := ApoioCombate.portador_jogador(100.0)
		var buf := BufferDeComandos.new(10)
		var cmd_fonte := ApoioMovimento.ComandosDuble.new(buf)
		var evs := EventosDoPasso.new()
		var adapt_c_para_m := _AdaptadorCombateParaMov.new()
		var mov := MovimentoDoJogador.new(
			0, ApoioMovimento.tuning_fp(), port, adapt_c_para_m, cmd_fonte,
			GeometriaDeMovimento.new(ApoioMovimento.ARENA_FP), evs)
		mov.iniciar(Vector2(960.0, 540.0))
		var adapt_m_para_c := _AdaptadorMovParaCombate.new(mov)
		var d := DependenciasDoCombate.new()
		d.tuning = ApoioCombate.tuning_fp()
		d.movimento = adapt_m_para_c
		d.eventos = evs
		d.jogadores.append(DependenciasDoCombate.Jogador.new(port, ApoioCombate.ataque_corte(), ApoioCombate.especial_investida()))
		var combate := Combate.criar(d)
		adapt_c_para_m.combate = combate

		for k in range(passo_golpe + 1):
			var apertados: Array[StringName] = []
			if k == 0:
				apertados.append(Acoes.ESQUIVA)
			buf.atualizar(apertados, k, 0, false)
			combate.inicio_do_passo()
			var am := AmostraDeEntrada.new([], apertados, buf.visao())
			am.id_passo = k
			am.mover = Vector2.RIGHT if k == 0 else Vector2.ZERO
			am.mirar = Vector2.RIGHT
			mov.passo(am)
			combate.golpe_do_jogador([ComandosDoPasso.new(buf, [], k, 0)])
			if k == passo_golpe:
				combate.ferir_jogador(0, 9.0, 1.0)
			evs.esvaziar()

		if passo_golpe <= 11:
			assert_int(combate.recursos(0).vida).is_equal(100)
		else:
			assert_int(combate.recursos(0).vida).is_equal(91)
