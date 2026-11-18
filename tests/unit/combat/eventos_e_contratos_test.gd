extends GdUnitTestSuite
## Story combate-nucleo-008: AC-97, AC-91, AC-66, AC-72, AC-80b (durações visuais, campos dos eventos, peso_visual, DPS de referência F11, impulso V14 e áudio A1).


func test_ac97_duracoes_visuais_nos_eventos() -> void:
	# 1º Corte -> flash_passos = 5
	var s1 := ApoioCombate.SimCombate.new(false)
	s1.ia.lista = [ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0))]
	s1.passo(true)
	var ev_ac := s1.eventos_do_passo(0, EventosDoCombate.EvAcerto.TIPO)[0] as EventosDoCombate.EvAcerto
	assert_int(ev_ac.flash_passos).is_equal(5)

	# jogador_atingido -> inversao_passos = 10, invuln_passos = 40; recusou_morte -> impact_passos = 18
	var port := ApoioCombate.portador_jogador(100.0)
	port.aplicar_fonte(FonteDeModificador.new(&"bencao:rec", [], [
		GatilhoAtivo.new(&"recusas_morte", 1.0, {&"vida_ao_voltar": 0.4, &"invuln_s": 2.0})
	]))
	var s2 := ApoioCombate.SimCombate.new(false, null, port)
	s2.combate.recursos(0).vida = 5
	s2.combate.recursos(0).recusas = 1
	s2.combate.ferir_jogador(0, 9.0, 1.0)
	var ev_ja := s2.eventos.do_tipo(EventosDoCombate.EvJogadorAtingido.TIPO)[0] as EventosDoCombate.EvJogadorAtingido
	assert_int(ev_ja.inversao_passos).is_equal(10)
	assert_int(ev_ja.invuln_passos).is_equal(40)
	var ev_rm := s2.eventos.do_tipo(EventosDoCombate.EvRecusouMorte.TIPO)[0] as EventosDoCombate.EvRecusouMorte
	assert_int(ev_rm.impact_passos).is_equal(18)
	assert_int(ev_rm.invuln_passos).is_equal(120)

	# inimigo_morreu do Chefe -> impact_passos = 12; do Eco -> 0
	var s3 := ApoioCombate.SimCombate.new(true)
	s3.ia.lista = [ApoioCombate.criar_chefe(1, Vector2(1100.0, 540.0), 30.0), ApoioCombate.criar_eco(2, Vector2(1100.0, 560.0), 30.0)]
	s3.passo(false, true)
	var mortes := s3.eventos_do_passo(0, EventosDoCombate.EvInimigoMorreu.TIPO)
	assert_int((mortes[0] as EventosDoCombate.EvInimigoMorreu).impact_passos).is_equal(12)
	assert_int((mortes[1] as EventosDoCombate.EvInimigoMorreu).impact_passos).is_equal(0)


func test_ac91_campos_dos_eventos_e_peso_visual() -> void:
	# Pulso com dano_enesimo_acerto (a_cada 1, valor 1.6): pesado = verdadeiro, mas peso_visual = leve no projétil!
	var port := ApoioCombate.portador_jogador(100.0)
	port.aplicar_fonte(FonteDeModificador.new(&"bencao:4o", [
		Modificador.new(Atributos.DANO_TODO, Modificador.Operacao.MULTIPLICADOR, 1.6, Modificador.Condicao.ENESIMO_ACERTO, 1.0)
	]))
	var sim := ApoioCombate.SimCombate.new(true, null, port)
	sim.ia.lista = [ApoioCombate.criar_saco(1, Vector2(1100.0, 540.0))]
	for k in 5:
		sim.passo(k == 0)
	var ev_p := sim.todos_eventos(EventosDoCombate.EvAcerto.TIPO)[0] as EventosDoCombate.EvAcerto
	assert_float(ev_p.dano).is_equal_approx(19.2, 0.001)
	assert_bool(ev_p.enesimo_acerto).is_true()
	assert_bool(ev_p.pesado).is_true()
	assert_str(String(ev_p.peso_visual)).is_equal("leve")

	#inimigo_morreu guarda vel_empurrao total do momento da morte
	var sim_m := ApoioCombate.SimCombate.new(false)
	sim_m.ia.lista = [ApoioCombate.criar_eco(1, Vector2(1060.0, 540.0), 14.0)]
	sim_m.passo(true)
	var ev_m := sim_m.eventos_do_passo(0, EventosDoCombate.EvInimigoMorreu.TIPO)[0] as EventosDoCombate.EvInimigoMorreu
	assert_vector(ev_m.vel_empurrao).is_equal_approx(Vector2(450.0, 0.0), Vector2(0.001, 0.001))


func test_ac66_dps_de_referencia_f11() -> void:
	# 1. Corte, Ataque segurado, passos 0..299 -> 15 golpes, 60 congelados, dano 266,0
	var s1 := ApoioCombate.SimCombate.new(false)
	s1.mov.executa_deslocar = false
	var saco1 := ApoioCombate.criar_saco(1, Vector2(1060.0, 540.0))
	s1.ia.lista = [saco1]
	for k in 300:
		s1.passo(false, false, true, false)
	assert_float(1000.0 - saco1.vida).is_equal_approx(266.0, 0.01)
	assert_int(s1.passos_congelados.size()).is_equal(60)

	# 2. Pulso, Ataque segurado, passos 0..839 -> 60 disparos, 60 acertos, dano 720,0
	var s2 := ApoioCombate.SimCombate.new(true)
	var saco2 := ApoioCombate.criar_saco(1, Vector2(1100.0, 540.0), false, 2000.0)
	s2.ia.lista = [saco2]
	for k in 840:
		s2.passo(false, false, true, false)
	assert_float(2000.0 - saco2.vida).is_equal_approx(720.0, 0.01)

	# 3. Onda, Especial segurado, passos 0..959 -> 10 golpes, dano 300,0
	var s3 := ApoioCombate.SimCombate.new(true)
	var saco3 := ApoioCombate.criar_saco(1, Vector2(1100.0, 540.0))
	s3.ia.lista = [saco3]
	for k in 960:
		s3.passo(false, false, false, true)
	assert_float(1000.0 - saco3.vida).is_equal_approx(300.0, 0.01)

	# 4. Investida, Especial segurado, passos 0..759 -> 10 acertos, dano 260,0
	var s4 := ApoioCombate.SimCombate.new(false)
	s4.mov.executa_investida = false
	var saco4 := ApoioCombate.criar_saco(1, Vector2(1000.0, 540.0))
	s4.ia.lista = [saco4]
	for k in 760:
		s4.passo(false, false, false, true)
	assert_float(1000.0 - saco4.vida).is_equal_approx(260.0, 0.01)


func test_ac72_um_impulso_de_camera_por_passo_v14() -> void:
	# Golpe sem alvo -> nenhum
	var evs_vazio: Array[EventoDoPasso] = [
		EventosDoCombate.EvGolpe.new(0, Vector2.ZERO, Vector2.RIGHT, &"ataque", 142.5, 69.51, false, 0)
	]
	assert_bool(FormulasDeCombate.escolher_impulso_camera_do_passo(evs_vazio).is_empty()).is_true()

	# Corte leve que mata Eco (leve 1,0 mira vence leve 0,6 da morte)
	var evs_morte_leve: Array[EventoDoPasso] = [
		EventosDoCombate.EvAcerto.new(1, Vector2.ZERO, Vector2.RIGHT, 14.0, false, false, true, &"ataque", &"arco", &"leve", 5),
		EventosDoCombate.EvInimigoMorreu.new(1, Vector2.ZERO, false, false, Vector2.ZERO, 0),
	]
	var imp1 := FormulasDeCombate.escolher_impulso_camera_do_passo(evs_morte_leve)
	assert_str(String(imp1["preset"])).is_equal("leve")
	assert_float(float(imp1["escala"])).is_equal_approx(1.0, 0.001)
	assert_vector(imp1["direcao"]).is_equal(Vector2.RIGHT)

	# recusou_morte vence jogador_atingido no mesmo passo
	var evs_rec: Array[EventoDoPasso] = [
		EventosDoCombate.EvJogadorAtingido.new(0, 9, Vector2.LEFT, 10, 40),
		EventosDoCombate.EvRecusouMorte.new(0, 40, 18, 120),
	]
	var imp_rec := FormulasDeCombate.escolher_impulso_camera_do_passo(evs_rec)
	assert_str(String(imp_rec["preset"])).is_equal("pesado")
	assert_bool(bool(imp_rec["zoom_principal"])).is_true()
	assert_vector(imp_rec["direcao"]).is_equal(Vector2.ZERO)


func test_ac80b_eventos_iguais_no_mesmo_passo_soam_como_um() -> void:
	# 3 acertos leves no passo -> 1 pedido de sfx_acerto_leve
	var evs_3: Array[EventoDoPasso] = [
		EventosDoCombate.EvAcerto.new(1, Vector2.ZERO, Vector2.RIGHT, 14.0, false, false, true, &"ataque", &"arco", &"leve", 5),
		EventosDoCombate.EvAcerto.new(2, Vector2.ZERO, Vector2.RIGHT, 14.0, false, false, true, &"ataque", &"arco", &"leve", 5),
		EventosDoCombate.EvAcerto.new(3, Vector2.ZERO, Vector2.RIGHT, 14.0, false, false, true, &"ataque", &"arco", &"leve", 5),
	]
	assert_array(FormulasDeCombate.pedidos_de_som_do_passo(evs_3)).is_equal([&"sfx_acerto_leve"])

	# 2 leves e 1 acerto marcado (4º acerto pesado) -> 1 leve, 1 pesado e 1 crítico
	var evs_misto: Array[EventoDoPasso] = [
		EventosDoCombate.EvAcerto.new(1, Vector2.ZERO, Vector2.RIGHT, 17.5, false, false, true, &"ataque", &"arco", &"leve", 5),
		EventosDoCombate.EvAcerto.new(2, Vector2.ZERO, Vector2.RIGHT, 17.5, false, false, true, &"ataque", &"arco", &"leve", 5),
		EventosDoCombate.EvAcerto.new(3, Vector2.ZERO, Vector2.RIGHT, 28.0, true, true, true, &"ataque", &"arco", &"pesado", 5),
	]
	assert_array(FormulasDeCombate.pedidos_de_som_do_passo(evs_misto)).is_equal([
		&"sfx_acerto_leve", &"sfx_acerto_pesado", &"sfx_acerto_critico"
	])
