extends GdUnitTestSuite
## Story combate-nucleo-003: AC-12..AC-19, AC-21, AC-22, AC-112 (disparo do golpe, combo por slot, guarda, recuperação e forma chamado).


func _passos_com_evento(sim: ApoioCombate.SimCombate, tipo: StringName) -> Array[int]:
	var r: Array[int] = []
	for item in sim.log_eventos:
		if item[1] == tipo:
			r.append(item[0])
	return r


func test_ac12_sai_no_passo_do_toque_e_borda_do_buffer() -> void:
	# Segurado em 0..40 -> golpes em 0, 16 e 32
	var s1 := ApoioCombate.SimCombate.new(false)
	for k in 41:
		s1.passo(false, false, true, false)
	assert_array(_passos_com_evento(s1, EventosDoCombate.EvGolpe.TIPO)).is_equal([0, 16, 32])

	# Toques em 0 e 6 -> só o golpe do 0 (no passo 16 o toque de 6 já expirou no buffer de 10)
	var s2 := ApoioCombate.SimCombate.new(false)
	for k in 41:
		s2.passo(k == 0 or k == 6)
	assert_array(_passos_com_evento(s2, EventosDoCombate.EvGolpe.TIPO)).is_equal([0])

	# Toques em 0 e 7 -> golpes em 0 e 16 (no passo 16 faz 9 passos desde o 7, dentro do prazo de 10)
	var s3 := ApoioCombate.SimCombate.new(false)
	for k in 41:
		s3.passo(k == 0 or k == 7)
	assert_array(_passos_com_evento(s3, EventosDoCombate.EvGolpe.TIPO)).is_equal([0, 16])


func test_ac13_especial_primeiro() -> void:
	var sim := ApoioCombate.SimCombate.new(true)
	sim.passo(true, true)
	assert_int(sim.eventos_do_passo(0, EventosDoCombate.EvArea.TIPO).size()).is_equal(1)
	assert_int(sim.eventos_do_passo(0, EventosDoCombate.EvDisparo.TIPO).size()).is_equal(0)
	assert_int(sim.combate.recursos(0).recarga[1]).is_equal(90)
	sim.passo()
	assert_int(sim.eventos_do_passo(1, EventosDoCombate.EvDisparo.TIPO).size()).is_equal(1)
	assert_int(sim.combate.recursos(0).recarga[0]).is_equal(14)


func test_ac14_esquiva_e_investida_bloqueiam() -> void:
	# Em esquiva nos passos 0..7, Ataque tocado em 2 -> sai no 8
	var s1 := ApoioCombate.SimCombate.new(false)
	for k in 15:
		s1.mov.esquiva = k <= 7
		s1.passo(k == 2)
	assert_array(_passos_com_evento(s1, EventosDoCombate.EvGolpe.TIPO)).is_equal([8])

	# Especial tocado em 0 (Investida, N=10) e Ataque tocado em 3 -> Corte sai no passo 10
	var s2 := ApoioCombate.SimCombate.new(false)
	for k in 15:
		s2.passo(k == 3, k == 0)
	assert_array(_passos_com_evento(s2, EventosDoCombate.EvGolpe.TIPO)).is_equal([10])


func test_ac15_golpe_sem_alvo_e_camara_limpa() -> void:
	var sim := ApoioCombate.SimCombate.new(false)
	sim.camaras.combate_ativo = false
	sim.combate.recursos(0).apos_esquiva = 30
	sim.passo(true)
	var r := sim.combate.recursos(0)
	assert_int(sim.eventos_do_passo(0, EventosDoCombate.EvGolpe.TIPO).size()).is_equal(1)
	assert_int(sim.combate.hitstop_restante()).is_equal(0)
	assert_int(r.recarga[0]).is_equal(16)
	assert_int(r.recuperacao).is_equal(8)
	assert_int(r.passo_combo[0]).is_equal(1)
	assert_int(r.janela_combo[0]).is_equal(34)
	assert_int(r.apos_esquiva).is_equal(0)
	assert_int(sim.mov.deslocamentos_apoio.size()).is_equal(1)
	assert_vector(sim.mov.deslocamentos_apoio[0]).is_equal_approx(Vector2(10.5, 0.0), Vector2(0.001, 0.001))


func test_ac16_combo_e_janela_x49_e_x50() -> void:
	for x_alvo: int in [49, 50]:
		var sim := ApoioCombate.SimCombate.new(false)
		sim.mov.executa_deslocar = false
		var saco := ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0))
		saco.surgindo = true
		sim.ia.lista = [saco]
		for k in 52:
			if k == x_alvo:
				saco.surgindo = false
			sim.passo(k == 0 or k == 16 or k == x_alvo)
		var acertos := sim.eventos_do_passo(x_alvo, EventosDoCombate.EvAcerto.TIPO)
		assert_int(acertos.size()).is_equal(1)
		var ev := acertos[0] as EventosDoCombate.EvAcerto
		if x_alvo == 49:
			assert_float(ev.dano).is_equal_approx(25.2, 0.001)
			assert_bool(ev.pesado).is_true()
		else:
			assert_float(ev.dano).is_equal_approx(14.0, 0.001)
			assert_bool(ev.pesado).is_false()


func test_ac17_combo_por_slot() -> void:
	var onda_combo := ApoioCombate.especial_onda()
	onda_combo.multiplicadores_combo = PackedFloat64Array([1.0, 2.0])
	var sim := ApoioCombate.SimCombate.new(false, null, null, ApoioCombate.ataque_corte(), onda_combo)
	sim.mov.executa_deslocar = false
	var saco := ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0))
	saco.surgindo = true
	sim.ia.lista = [saco]
	for k in 35:
		if k == 32:
			saco.surgindo = false
		sim.passo(false, k == 8, k <= 40, false)
		if k == 8:
			assert_int(sim.combate.recursos(0).passo_combo[1]).is_equal(1)
			assert_int(sim.combate.recursos(0).passo_combo[0]).is_equal(1)
	var ev := sim.eventos_do_passo(32, EventosDoCombate.EvAcerto.TIPO)[0] as EventosDoCombate.EvAcerto
	assert_float(ev.dano).is_equal_approx(25.2, 0.001)


func test_ac18_e_ac19_m_no_disparo_e_janela_apos_esquiva() -> void:
	var port := ApoioCombate.portador_jogador(100.0)
	port.aplicar_fonte(FonteDeModificador.new(&"bencao:penumbra", [
		Modificador.new(Atributos.DANO_TODO, Modificador.Operacao.PERCENTUAL, 0.5, Modificador.Condicao.APOS_ESQUIVA, 1.0)
	]))
	var sim := ApoioCombate.SimCombate.new(false, null, port)
	sim.mov.executa_deslocar = false
	sim.ia.lista = [ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0))]
	sim.passo(true, false, false, false, func() -> void: sim.combate.esquiva_iniciada(0))
	var ev0 := sim.eventos_do_passo(0, EventosDoCombate.EvAcerto.TIPO)[0] as EventosDoCombate.EvAcerto
	assert_float(ev0.dano).is_equal_approx(21.0, 0.001)
	for k in range(1, 20):
		sim.passo(k == 19)
	var ev19 := sim.eventos_do_passo(19, EventosDoCombate.EvAcerto.TIPO)[0] as EventosDoCombate.EvAcerto
	assert_float(ev19.dano).is_equal_approx(14.0, 0.001)

	# AC-19: golpe no último passo da esquiva (passo 8), com bônus
	var port2 := ApoioCombate.portador_jogador(100.0)
	port2.aplicar_fonte(FonteDeModificador.new(&"bencao:penumbra", [
		Modificador.new(Atributos.DANO_TODO, Modificador.Operacao.PERCENTUAL, 0.5, Modificador.Condicao.APOS_ESQUIVA, 1.0)
	]))
	var sim2 := ApoioCombate.SimCombate.new(false, null, port2)
	sim2.mov.executa_deslocar = false
	sim2.ia.lista = [ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0))]
	for k in 9:
		sim2.mov.esquiva = k <= 7
		sim2.passo(k == 2, false, false, false,
			func() -> void:
				if k == 0:
					sim2.combate.esquiva_iniciada(0))
	var ev8 := sim2.eventos_do_passo(8, EventosDoCombate.EvAcerto.TIPO)[0] as EventosDoCombate.EvAcerto
	assert_float(ev8.dano).is_equal_approx(21.0, 0.001)
	assert_int(sim2.combate.recursos(0).apos_esquiva).is_equal(0)


func test_ac21_guarda_reduz_dano_pela_metade() -> void:
	for passo_dano: int in [0, 5, 6]:
		var corte_g := ApoioCombate.ataque_corte()
		corte_g.guarda_s = 0.1  # 6 passos
		var sim := ApoioCombate.SimCombate.new(false, null, null, corte_g, ApoioCombate.especial_investida())
		var eco := ApoioCombate.criar_eco(1, Vector2(700.0, 540.0))
		sim.ia.lista = [eco]
		sim.ia.acao_no_turno = func(p: int, ini: ContratosDoCombate.InimigoCombate, c: Combate) -> void:
			if p == passo_dano:
				c.ferir_jogador(0, 9.0, 1.0, ini.id)
		for k in range(passo_dano + 1):
			sim.passo(k == 0)
		var vida_esperada := 95 if passo_dano <= 5 else 91
		assert_int(sim.combate.recursos(0).vida).is_equal(vida_esperada)


func test_ac22_recuperacao_tabela_f2() -> void:
	# Corte (FP): rec = 8 -> verdadeiro nos passos 1..7, falso no 0 e no 8
	var s1 := ApoioCombate.SimCombate.new(false)
	for k in 10:
		s1.passo(k == 0)
	assert_bool(s1.mov.leituras_recuperacao[0]).is_false()
	for k in range(1, 8):
		assert_bool(s1.mov.leituras_recuperacao[k]).is_true()
	assert_bool(s1.mov.leituras_recuperacao[8]).is_false()

	# Onda (FP-R): min(12, round(45)) = 12 -> verdadeiro nos passos 1..11, falso no 12
	var s2 := ApoioCombate.SimCombate.new(true)
	for k in 14:
		s2.passo(false, k == 0)
	for k in range(1, 12):
		assert_bool(s2.mov.leituras_recuperacao[k]).is_true()
	assert_bool(s2.mov.leituras_recuperacao[12]).is_false()


func test_ac112_forma_chamado_recusa_e_disparo() -> void:
	var port := ApoioCombate.portador_jogador(90.0)
	port.aplicar_fonte(FonteDeModificador.new(&"bencao:esp", [
		Modificador.new(Atributos.DANO_ESPECIAL, Modificador.Operacao.PERCENTUAL, 0.25)
	]))
	var sim := ApoioCombate.SimCombate.new(false, null, port, ApoioCombate.ataque_pulso(), ApoioCombate.especial_chamado())
	# (a) sem Maldição em campo -> 1 chamado_indisponivel no toque, 0 a mais segurando, e Ataque tocado no mesmo passo dispara
	sim.maldicoes.disponivel = false
	sim.passo(true, true, false, true)
	assert_int(sim.eventos_do_passo(0, EventosDoCombate.EvChamadoIndisponivel.TIPO).size()).is_equal(1)
	assert_int(sim.eventos_do_passo(0, EventosDoCombate.EvDisparo.TIPO).size()).is_equal(1)
	assert_int(sim.combate.recursos(0).recarga[1]).is_equal(0)
	for k in range(1, 10):
		sim.passo(false, false, false, true)
		assert_int(sim.eventos_do_passo(k, EventosDoCombate.EvChamadoIndisponivel.TIPO).size()).is_equal(0)

	# (c) com Maldição disponível em campo -> recarga 120, pedir_chamado com dano 17 e M_sem 1,25, recuperação 0
	var sim_ok := ApoioCombate.SimCombate.new(false, null, port, ApoioCombate.ataque_pulso(), ApoioCombate.especial_chamado())
	sim_ok.maldicoes.disponivel = true
	sim_ok.combate.definir_mira(0, Vector2.RIGHT, Vector2(1200.0, 540.0))
	sim_ok.passo(false, true)
	assert_int(sim_ok.combate.recursos(0).recarga[1]).is_equal(120)
	assert_int(sim_ok.combate.recursos(0).recuperacao).is_equal(0)
	assert_int(sim_ok.combate.hitstop_restante()).is_equal(0)
	assert_int(sim_ok.maldicoes.chamados.size()).is_equal(1)
	assert_float(sim_ok.maldicoes.chamados[0][2]).is_equal_approx(17.0, 0.001)
	assert_float(sim_ok.maldicoes.chamados[0][3]).is_equal_approx(1.25, 0.001)
	assert_int(sim_ok.eventos_do_passo(0, EventosDoCombate.EvChamado.TIPO).size()).is_equal(1)
