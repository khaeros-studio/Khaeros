extends GdUnitTestSuite
## Story movimento-004: AC-14, AC-15, AC-16, AC-17 (parte de cargas), AC-50.


func _sim(cargas_max: int = 1) -> ApoioMovimento.Sim:
	return ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp(), cargas_max)


func test_carga_volta_r_passos_depois_do_gasto() -> void:
	var sim := _sim()
	for p in 150:
		sim.vivo(Vector2.ZERO, p == 100)
		if p >= 100 and p <= 141:
			assert_int(sim.mov.cargas()).is_equal(0)
		if p >= 142:
			assert_int(sim.mov.cargas()).is_equal(1)
			assert_int(sim.mov.progresso_recarga()).is_equal(0)


func test_gastar_nao_zera_contador() -> void:
	var sim := _sim(3)
	var em: Dictionary[int, int] = {}
	for p in 130:
		sim.vivo(Vector2.ZERO, p == 0 or p == 9 or p == 18)
		em[p] = sim.mov.cargas()
	assert_int(em[18]).is_equal(0)
	assert_int(em[41]).is_equal(0)
	assert_int(em[42]).is_equal(1)
	assert_int(em[83]).is_equal(1)
	assert_int(em[84]).is_equal(2)
	assert_int(em[125]).is_equal(2)
	assert_int(em[126]).is_equal(3)
	assert_int(sim.mov.progresso_recarga()).is_equal(0)


func test_atributo_sobe_cheio_ganha_diferenca_contador_zero() -> void:
	var sim := _sim(1)
	sim.atributos.cargas_max = 2
	sim.vivo()
	assert_int(sim.mov.cargas()).is_equal(2)
	assert_int(sim.mov.progresso_recarga()).is_equal(0)


func test_atributo_sobe_no_meio_da_recarga_mantem_progresso() -> void:
	var sim := _sim(2)
	for p in 21:
		sim.vivo(Vector2.ZERO, p == 0)
	assert_int(sim.mov.progresso_recarga()).is_equal(20)
	sim.atributos.cargas_max = 3
	for p in range(21, 43):
		sim.vivo()
		if p == 21:
			assert_int(sim.mov.cargas()).is_equal(2)
		if p == 41:
			assert_int(sim.mov.cargas()).is_equal(2)
	assert_int(sim.mov.cargas()).is_equal(3)


func test_atributo_desce_ate_cheio_zera_contador_divergencia_do_canone() -> void:
	var sim := _sim(2)
	for p in 21:
		sim.vivo(Vector2.ZERO, p == 0)
	sim.atributos.cargas_max = 1
	for p in range(21, 73):
		sim.vivo(Vector2.ZERO, p == 30)
		if p == 21:
			assert_int(sim.mov.cargas()).is_equal(1)
			assert_int(sim.mov.progresso_recarga()).is_equal(0)
		if p == 71:
			assert_int(sim.mov.cargas()).is_equal(0)
	assert_int(sim.mov.cargas()).is_equal(1)


func test_atributo_desce_durante_esquiva_nao_interrompe() -> void:
	var sim := _sim(3)
	sim.vivo(Vector2.RIGHT, true)
	sim.vivo()
	sim.vivo()
	sim.atributos.cargas_max = 1
	for i in range(3, 9):
		sim.vivo()
	assert_int(sim.mov.cargas()).is_equal(1)
	assert_float(sim.mov.posicao().x).is_equal_approx(1162.5, 0.001)


func test_comeco_da_run_cargas_no_maximo() -> void:
	var sim := _sim(2)
	assert_int(sim.mov.cargas()).is_equal(2)
	var fp := _sim(1)
	for p in 16:
		fp.vivo(Vector2.ZERO, p == 0)
	assert_int(fp.mov.cargas()).is_equal(0)
	assert_int(fp.mov.progresso_recarga()).is_equal(15)


func test_maximo_muda_na_bencao_aplica_no_primeiro_passo_vivo() -> void:
	var sim := _sim(1)
	for p in 10:
		sim.vivo(Vector2.ZERO, p == 0)
	sim.atributos.cargas_max = 2
	for p in range(10, 21):
		sim.fora_de_jogo()
		assert_int(sim.mov.cargas()).is_equal(0)
		assert_int(sim.mov.progresso_recarga()).is_equal(9)
	sim.vivo()   # 21
	assert_int(sim.mov.cargas_max()).is_equal(2)
	assert_int(sim.mov.cargas()).is_equal(1)
	for p in range(22, 54):
		sim.vivo()
		if p == 52:
			assert_int(sim.mov.cargas()).is_equal(1)
	assert_int(sim.mov.cargas()).is_equal(2)
	assert_int(sim.mov.progresso_recarga()).is_equal(0)
