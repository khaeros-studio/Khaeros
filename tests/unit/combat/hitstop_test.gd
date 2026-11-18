extends GdUnitTestSuite
## Story combate-nucleo-002: AC-05, AC-06, AC-07, AC-08, AC-09, AC-10, AC-95, AC-96, AC-11 (ordem do passo, hitstop, câmara nova e transição).


func test_ac06_passo_do_pedido_termina_e_seguintes_congelam() -> void:
	var sim := ApoioCombate.SimCombate.new(false)
	var saco := ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0), true)
	sim.ia.lista = [saco]
	for k in 20:
		sim.passo(false, false, true, false)
		if k == 0:
			assert_float(saco.posicao.x).is_equal_approx(1067.5, 0.001)
		elif k >= 1 and k <= 3:
			assert_float(saco.posicao.x).is_equal_approx(1067.5, 0.001)
			assert_int(sim.combate.recursos(0).recarga[0]).is_equal(16)
		elif k == 4:
			assert_float(saco.posicao.x).is_equal_approx(1073.35, 0.001)
			assert_int(sim.combate.recursos(0).recarga[0]).is_equal(15)
	assert_array(sim.passos_congelados.slice(0, 3)).is_equal([1, 2, 3])
	assert_int(sim.eventos_do_passo(19, EventosDoCombate.EvGolpe.TIPO).size()).is_equal(1)


func test_ac07_tabela_do_hitstop() -> void:
	# 1. Corte com 1 alvo -> 1..3 congelados
	var s1 := ApoioCombate.SimCombate.new(false)
	s1.ia.lista = [ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0))]
	for k in 6:
		s1.passo(k == 0)
	assert_array(s1.passos_congelados).is_equal([1, 2, 3])

	# 2. Corte sem alvo -> nenhum
	var s2 := ApoioCombate.SimCombate.new(false)
	for k in 6:
		s2.passo(k == 0)
	assert_array(s2.passos_congelados).is_empty()

	# 3. 3º Corte (finalizador) no passo 32 -> 33..38 congelados
	var s3 := ApoioCombate.SimCombate.new(false)
	var saco3 := ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0))
	saco3.surgindo = true
	s3.ia.lista = [saco3]
	for k in 42:
		if k == 32:
			saco3.surgindo = false
		s3.passo(false, false, true, false)
	assert_array(s3.passos_congelados).is_equal([33, 34, 35, 36, 37, 38])

	# 4. Onda (FP-R) com alvo -> 1..6
	var s4 := ApoioCombate.SimCombate.new(true)
	s4.ia.lista = [ApoioCombate.criar_saco(1, Vector2(1100.0, 540.0))]
	for k in 9:
		s4.passo(false, k == 0)
	assert_array(s4.passos_congelados).is_equal([1, 2, 3, 4, 5, 6])

	# 5. Pulso (FP-R) acerta no passo 3 -> nenhum congelado
	var s5 := ApoioCombate.SimCombate.new(true)
	s5.ia.lista = [ApoioCombate.criar_saco(1, Vector2(1100.0, 540.0))]
	for k in 8:
		s5.passo(k == 0)
	assert_array(s5.passos_congelados).is_empty()
	assert_int(s5.eventos_do_passo(3, EventosDoCombate.EvAcerto.TIPO).size()).is_equal(1)

	# 6. Investida com 2 alvos: 3..8 e 13..15
	var s6 := ApoioCombate.SimCombate.new(false)
	s6.ia.lista = [
		ApoioCombate.criar_saco(1, Vector2(1100.0, 540.0)),
		ApoioCombate.criar_saco(2, Vector2(1250.0, 540.0)),
	]
	for k in 20:
		s6.passo(false, k == 0)
	assert_array(s6.passos_congelados).is_equal([3, 4, 5, 6, 7, 8, 13, 14, 15])

	# 7. Corte que mata Eco ferido (14): max(3, 4) -> 1..4
	var s7 := ApoioCombate.SimCombate.new(false)
	s7.ia.lista = [ApoioCombate.criar_eco(1, Vector2(1060.0, 540.0), 14.0)]
	for k in 7:
		s7.passo(k == 0)
	assert_array(s7.passos_congelados).is_equal([1, 2, 3, 4])

	# 8. Onda que mata Chefe com Vida 30 -> 1..36
	var s9 := ApoioCombate.SimCombate.new(true)
	s9.ia.lista = [ApoioCombate.criar_chefe(1, Vector2(1100.0, 540.0), 30.0)]
	for k in 40:
		s9.passo(false, k == 0)
	assert_int(s9.passos_congelados.size()).is_equal(36)
	assert_int(s9.passos_congelados[0]).is_equal(1)
	assert_int(s9.passos_congelados[35]).is_equal(36)

	# 9. Recusa de morte: max(6, 18) -> 1..18
	var port_rec := ApoioCombate.portador_jogador(100.0)
	var gat_rec: Array[GatilhoAtivo] = [GatilhoAtivo.new(&"recusas_morte", 1.0, {&"vida_ao_voltar": 0.4, &"invuln_s": 2.0})]
	port_rec.aplicar_fonte(FonteDeModificador.new(&"bencao:recusa", [], gat_rec))
	var s11 := ApoioCombate.SimCombate.new(false, null, port_rec)
	s11.combate.recursos(0).vida = 5
	s11.combate.recursos(0).recusas = 1
	s11.ia.lista = [ApoioCombate.criar_eco(1, Vector2(700.0, 540.0))]
	s11.ia.acao_no_turno = func(p: int, ini: ContratosDoCombate.InimigoCombate, c: Combate) -> void:
		if p == 0:
			c.ferir_jogador(0, 9.0, 1.0, ini.id)
	for k in 22:
		s11.passo()
	assert_int(s11.passos_congelados.size()).is_equal(18)


func test_ac08_combo_da_lamina_num_eco_38_passos() -> void:
	var sim := ApoioCombate.SimCombate.new(false)
	var eco := ApoioCombate.criar_eco(1, Vector2(1060.0, 540.0), 30.0)
	sim.ia.lista = [eco]
	for k in 46:
		sim.passo(false, false, k <= 40, false)
		if k == 0:
			assert_float(eco.vida).is_equal_approx(16.0, 0.001)
		elif k == 19:
			assert_float(eco.vida).is_equal_approx(2.0, 0.001)
		elif k == 38:
			assert_float(eco.vida).is_equal_approx(-23.2, 0.001)
			assert_int(sim.eventos_do_passo(38, EventosDoCombate.EvInimigoMorreu.TIPO).size()).is_equal(1)
	assert_array(sim.passos_congelados).is_equal([1, 2, 3, 20, 21, 22, 39, 40, 41, 42, 43, 44])


func test_ac09_congelado_nao_desconta_contadores() -> void:
	var sim := ApoioCombate.SimCombate.new(false)
	var saco := ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0), true)
	sim.ia.lista = [saco]
	sim.passo(true, false, false, false, func() -> void: sim.combate.garantir_invulneravel(0, 12))
	for k in range(1, 5):
		if k <= 3:
			var r0 := sim.combate.recursos(0)
			assert_int(r0.invulneravel).is_equal(12)
			assert_int(r0.recarga[0]).is_equal(16)
			assert_int(r0.recuperacao).is_equal(8)
			assert_int(r0.janela_combo[0]).is_equal(34)
			assert_int(saco.cambaleio).is_equal(7)
			assert_float(saco.vel_empurrao.x).is_equal_approx(351.0, 0.001)
			assert_float(saco.posicao.x).is_equal_approx(1067.5, 0.001)
		sim.passo()
	var r4 := sim.combate.recursos(0)
	assert_int(r4.invulneravel).is_equal(11)
	assert_int(r4.recarga[0]).is_equal(15)
	assert_int(r4.recuperacao).is_equal(7)
	assert_int(r4.janela_combo[0]).is_equal(33)
	assert_int(saco.cambaleio).is_equal(6)
	assert_float(saco.posicao.x).is_equal_approx(1073.35, 0.001)


func test_ac10_e_ac95_camara_nova_zera_e_camara_limpa_espera_hitstop() -> void:
	var sim := ApoioCombate.SimCombate.new(true)
	sim.ia.lista = [ApoioCombate.criar_chefe(1, Vector2(1100.0, 540.0), 30.0)]
	for k in 38:
		sim.passo(false, k == 0)
	# AC-95: câmara limpa só avaliada no passo 37 (com hitstop em 0)
	assert_array(sim.camaras.avaliacoes_camara_limpa).is_equal([37])

	# AC-10(b): camara_nova() zera hitstop, investida e recuperação, preservando recarga e invulnerabilidade
	var sim_b := ApoioCombate.SimCombate.new(false)
	var r := sim_b.combate.recursos(0)
	sim_b.combate._pedir_hitstop(36)
	r.investida = 5
	r.recuperacao = 8
	r.recarga[0] = 9
	r.invulneravel = 20
	sim_b.combate.camara_nova()
	assert_int(sim_b.combate.hitstop_restante()).is_equal(0)
	assert_int(r.investida).is_equal(0)
	assert_int(r.recuperacao).is_equal(0)
	assert_int(r.recarga[0]).is_equal(9)
	assert_int(r.invulneravel).is_equal(20)
	assert_int(sim_b.status.limpezas).is_equal(1)


func test_ac11_buffer_congelado_por_36_passos_dispara_no_37() -> void:
	var sim := ApoioCombate.SimCombate.new(true)
	sim.ia.lista = [ApoioCombate.criar_chefe(1, Vector2(1100.0, 540.0), 30.0)]
	for k in 39:
		sim.passo(k == 2, k == 0)
	assert_int(sim.eventos_do_passo(37, EventosDoCombate.EvDisparo.TIPO).size()).is_equal(1)
