extends GdUnitTestSuite
## Story movimento-008: AC-43 (Pausa/Bênção esvaziam o buffer real; o Movimento não roda nem gasta carga).
## AC-56 (invulnerabilidade de fato com Combate real) fica pendente até o épico combate-nucleo.


func test_pausa_ou_bencao_congela_e_perde_o_toque_do_buffer() -> void:
	var sim := ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp(), 2)
	sim.vivo(Vector2.RIGHT, true)
	sim.vivo()
	sim.vivo(Vector2.ZERO, true)  # toque no 2 (fica no buffer)
	while sim.n <= 40:
		sim.fora_de_jogo()  # Pausa e Bênção: mesma troca de contexto (buffer esvaziado)
	assert_float(sim.mov.posicao().x).is_equal_approx(1027.5, 0.001)
	assert_int(sim.mov.esquiva_restante()).is_equal(6)
	assert_int(sim.mov.progresso_recarga()).is_equal(2)
	while sim.n <= 46:
		sim.vivo()
	assert_float(sim.mov.posicao().x).is_equal_approx(1162.5, 0.001)
	assert_bool(sim.mov.em_esquiva()).is_false()
	while sim.n <= 80:
		sim.vivo()
	assert_array(sim.inicios).is_equal([0])
	assert_int(sim.total(EvEsquiva.TIPO)).is_equal(1)
