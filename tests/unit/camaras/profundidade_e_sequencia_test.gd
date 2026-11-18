extends GdUnitTestSuite
## Story camaras-e-ondas/002: Profundidade p, p_max, fonte `profundidade` e chave do RNG pelo índice.
## Cobre AC-CO-01, AC-CO-28 e TR-camaras-001.


func test_ac_co_01_e_28_sequencia_limiar_profundidade_e_p_max() -> void:
	var reg := Run._regiao_limiar_padrao()
	assert_array(reg.camaras).is_equal([
		&"combate", &"combate", &"combate", &"santuario", &"combate", &"combate", &"chefe"
	])
	assert_int(ProfundidadeCamara.calcular_p_max(reg.camaras)).is_equal(4)

	# Câmaras de combate nos índices 0, 1, 2, 4, 5 têm p = 0, 1, 2, 3, 4
	assert_int(ProfundidadeCamara.profundidade_no_indice(reg.camaras, 0)).is_equal(0)
	assert_int(ProfundidadeCamara.profundidade_no_indice(reg.camaras, 1)).is_equal(1)
	assert_int(ProfundidadeCamara.profundidade_no_indice(reg.camaras, 2)).is_equal(2)
	assert_int(ProfundidadeCamara.profundidade_no_indice(reg.camaras, 4)).is_equal(3)
	assert_int(ProfundidadeCamara.profundidade_no_indice(reg.camaras, 5)).is_equal(4)

	# Santuário (3) usa p=2 da última câmara de combate anterior; Chefe (6) usa p=4
	assert_bool(ProfundidadeCamara.eh_camara_de_combate(reg.camaras, 3)).is_false()
	assert_int(ProfundidadeCamara.profundidade_no_indice(reg.camaras, 3)).is_equal(2)
	assert_bool(ProfundidadeCamara.eh_camara_de_combate(reg.camaras, 6)).is_false()
	assert_int(ProfundidadeCamara.profundidade_no_indice(reg.camaras, 6)).is_equal(4)


func test_tr_camaras_001_chave_rng_usa_indice_da_camara_e_nao_p() -> void:
	var fonte := FonteDeFluxos.new(RelatorDeErrosRng.new())
	fonte.iniciar_run(0x12345678, false)
	var fc := FluxosDeCamaras.new(fonte)

	# Índice 2 (p=2) e índice 4 (p=3) têm chaves (0, 2) e (0, 4), não (0, p)
	var f_idx3 := fc.layout(0, 3)
	var f_idx4 := fc.layout(0, 4)
	assert_int(f_idx3.estado()).is_not_equal(f_idx4.estado())
	assert_that(ProfundidadeCamara.chave_rng(0, 4)).is_equal(Vector2i(0, 4))


func test_fonte_profundidade_escala_5_por_cento_por_p() -> void:
	var mod_tun := FabricaDaRun._modifiers_tuning_padrao()
	var port := Portador.new(1, 0, Atributos.Especie.INIMIGO, {Atributos.VIDA_MAX: 100.0}, mod_tun)
	port.aplicar_fonte(ProfundidadeCamara.criar_fonte_profundidade(4))
	# +20% em p=4 -> 120
	assert_int(port.inteiro(Atributos.VIDA_MAX)).is_equal(120)
