extends GdUnitTestSuite
## Story camaras-e-ondas/008: Santuário e portas físicas (posição, alcance, interação).
## Cobre AC-CO-17, AC-CO-18, AC-CO-19, AC-CO-20, AC-CO-39 e AC-CO-40.


func test_ac_co_17_santuario_cura_40_por_cento_pedra_fixa_e_limpa_direto() -> void:
	var wr := FabricasDeCatalogo.wave_rules()
	var rt := FabricasDeCatalogo.room_tuning()
	var reg := Run._regiao_limiar_padrao()
	var eventos := EventosDoPasso.new()
	var cam := Camaras.new(wr, rt, reg, null, eventos)

	var mod_tun := FabricaDaRun._modifiers_tuning_padrao()
	var port := Portador.new(1, 0, Atributos.Especie.JOGADOR, {Atributos.VIDA_MAX: 100.0}, mod_tun)
	var vida: Array[int] = [70]
	cam.configurar_jogador(port, Callable(), Callable(), func() -> int: return vida[0], func(nv: int) -> void: vida[0] = nv)

	# Vida 70/100 -> cura 40 limitada a 100 (ganho 30)
	cam.trocar(3, &"", 0, true)
	assert_int(vida[0]).is_equal(100)
	assert_int(cam.fase()).is_equal(Camaras.Fase.LIMPA)
	assert_bool(cam.em_combate()).is_false()
	assert_int(cam.obstaculos().size()).is_equal(1)
	assert_that(cam.obstaculos()[0].centro).is_equal(Vector2(960.0, 495.0))
	assert_float(cam.obstaculos()[0].raio).is_equal(63.0)

	# Vida 40/100 -> cura 40 -> 80
	vida[0] = 40
	cam.trocar(3, &"", 0, true)
	assert_int(vida[0]).is_equal(80)


func test_ac_co_18_19_20_39_40_posicoes_alcance_111_e_interacao_portas() -> void:
	var rt := FabricasDeCatalogo.room_tuning()
	var pf := PortasFisicas.new(rt)
	assert_bool(pf.estao_abertas()).is_false()

	# 2 portas: x = 735 e 1185, y = 177
	pf.abrir([&"bencao", &"fragmentos"], [3, 2])
	assert_bool(pf.estao_abertas()).is_true()
	var l2 := pf.listar()
	assert_that(l2[0].posicao).is_equal(Vector2(735.0, 177.0))
	assert_that(l2[1].posicao).is_equal(Vector2(1185.0, 177.0))

	# 3 portas: x = 510, 960 e 1410, y = 177
	pf.abrir([&"bencao", &"fragmentos", &"cura"], [3, 2, 30])
	var l3 := pf.listar()
	assert_that(l3[0].posicao).is_equal(Vector2(510.0, 177.0))
	assert_that(l3[1].posicao).is_equal(Vector2(960.0, 177.0))
	assert_that(l3[2].posicao).is_equal(Vector2(1410.0, 177.0))

	# 1 porta forçada (`santuario` ou `chefe`): x = 960, y = 177
	pf.abrir([&"chefe"], [0])
	var l1 := pf.listar()
	assert_that(l1[0].posicao).is_equal(Vector2(960.0, 177.0))

	# Alcance de 111 px: a 112 px nada acontece; a 111 px escolhe a porta
	assert_int(pf.tentar_interagir(Vector2(960.0, 177.0 + 112.0), true)).is_equal(-1)
	# Em hitstop (em_passo_vivo = false): nada acontece
	assert_int(pf.tentar_interagir(Vector2(960.0, 177.0 + 111.0), false)).is_equal(-1)
	assert_int(pf.tentar_interagir(Vector2(960.0, 177.0 + 111.0), true)).is_equal(0)
