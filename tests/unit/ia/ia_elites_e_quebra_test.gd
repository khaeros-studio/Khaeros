extends GdUnitTestSuite
## Story ia-005: Elites (sorteio e números), armadura e quebra dos comuns (AC-IA-11, AC-IA-15, AC-IA-16, AC-IA-17, AC-IA-18, AC-IA-30).


func test_ac_ia_15_17_30_curva_de_chance_e_sorteio_com_consumo_fixo() -> void:
	var regras := RegrasDeElite.de_fabrica()
	# AC-IA-30: curva de chance
	assert_float(RegrasDeElite.chance_elite(2, regras)).is_equal_approx(0.0, 1e-9)
	assert_float(RegrasDeElite.chance_elite(3, regras)).is_equal_approx(0.11, 1e-9)
	assert_float(RegrasDeElite.chance_elite(4, regras)).is_equal_approx(0.13, 1e-9)
	assert_float(RegrasDeElite.chance_elite(9, regras)).is_equal_approx(0.23, 1e-9)
	assert_float(RegrasDeElite.chance_elite(10, regras)).is_equal_approx(0.25, 1e-9)
	assert_float(RegrasDeElite.chance_elite(12, regras)).is_equal_approx(0.25, 1e-9)

	# AC-IA-15: onda de 4 em p 4 (chance 0.13): 4 reais consumidos; 1º (0.12) é elite; seguintes não, mesmo com < 0.13
	var f := FixtureIA.FluxoRoteirizado.new()
	f.reais_fila.assign([0.12, 0.05, 0.01, 0.13])
	var ja_ha := false
	var resultados: Array[bool] = []
	for k in 4:
		var eh_el := RegrasDeElite.sortear_elite(4, ja_ha, f, regras)
		if eh_el:
			ja_ha = true
		resultados.append(eh_el)
	assert_array(resultados).is_equal([true, false, false, false])
	assert_int(f.chamadas_real).is_equal(4)

	# r = 0.13 exato em p 4 não é elite; em p 1 consome 4 reais e nenhum elite
	f.reais_fila.assign([0.13, 0.0, 0.0, 0.0])
	assert_bool(RegrasDeElite.sortear_elite(4, false, f, regras)).is_false()
	for k in 3:
		assert_bool(RegrasDeElite.sortear_elite(1, false, f, regras)).is_false()
	assert_int(f.chamadas_real).is_equal(8)


func test_ac_ia_11_16_18_numeros_do_elite_armadura_e_quebra() -> void:
	var ctx := FixtureIA.ContextoTeste.new()
	var eco := FixtureTelegrafos.eco_perdido()

	# AC-IA-16: Eco elite p 0 -> Vida 72, raio 28.8, dano 11.25 (11 no golpe); p 4 -> Vida 86
	var id_el0 := ctx.ia.criar_inimigo(eco, Vector2(200.0, 0.0), OpcoesDeNascimento.de_elite(-1, 0))
	var el0 := ctx.ia.estado_de(id_el0)
	assert_float(el0.vida_max).is_equal_approx(72.0, 1e-5)
	assert_float(el0.raio).is_equal_approx(28.8, 1e-5)
	assert_float(el0.dano_base).is_equal_approx(11.25, 1e-5)

	var id_el4 := ctx.ia.criar_inimigo(eco, Vector2(300.0, 0.0), OpcoesDeNascimento.de_elite(-1, 4))
	assert_float(ctx.ia.estado_de(id_el4).vida_max).is_equal_approx(86.0, 1e-5)

	# AC-IA-11: golpe pesado em comum em preparo -> recuperação de 24 passos, telégrafo quebrado
	var id_comum := ctx.ia.criar_inimigo(eco, Vector2(60.0, 0.0))
	var e_comum := ctx.ia.estado_de(id_comum)
	e_comum.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	e_comum.timer = 0
	ctx.ia.passo(id_comum)
	assert_int(int(e_comum.fase)).is_equal(int(EstadoDeInimigoIA.Fase.PREPARO))
	assert_bool(ctx.ia.pedir_recuperacao(id_comum)).is_true()
	assert_int(int(e_comum.fase)).is_equal(int(EstadoDeInimigoIA.Fase.RECUPERACAO))
	assert_int(e_comum.timer).is_equal(24)
	assert_int(int(ctx.telegrafos.estado_de(id_comum))).is_equal(int(TelegrafoTipos.Estado.QUEBRADO))

	# AC-IA-18: elite com armadura permanente não cambaleia nem quebra
	el0.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	el0.timer = 0
	el0.posicao = Vector2(60.0, 0.0)
	ctx.ia.passo(id_el0)
	assert_bool(ctx.ia.pedir_recuperacao(id_el0)).is_false()
	assert_int(int(el0.fase)).is_equal(int(EstadoDeInimigoIA.Fase.PREPARO))
	ctx.ia.aplicar_impacto_combate(id_el0, Vector2(100.0, 0.0), 12)
	assert_int(el0.ref.impacto_passos).is_equal(0)

	# Armadura de Elite quebrável por hits: absorve 1º hit e quebra no 2º com evento "quebrou" e hitstop
	var opt_q := OpcoesDeNascimento.de_elite(-1, 3)
	opt_q.armadura_hits = 2
	var id_el_q := ctx.ia.criar_inimigo(eco, Vector2(60.0, 0.0), opt_q)
	var eq := ctx.ia.estado_de(id_el_q)
	eq.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	eq.timer = 0
	ctx.ia.passo(id_el_q)
	assert_bool(ctx.ia.pedir_recuperacao(id_el_q)).is_false() # absorveu o 1º
	assert_bool(ctx.ia.pedir_recuperacao(id_el_q)).is_true() # quebrou no 2º!
	assert_bool(ctx.eventos.ha(EventosDeIA.EvQuebrouArmadura.TIPO)).is_true()
	assert_bool(ctx.combate.hitstops_pedidos.size() >= 1).is_true()
