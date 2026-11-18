## Story RNG-002: operações F5–F8 e erros que não consomem.
extends GdUnitTestSuite

const ESTADO_PORTAS_P3: int = 0xB0B08409


func _fluxo(relator: RelatorGravadorRng) -> FluxoRng:
	return FluxoRng.new(ESTADO_PORTAS_P3, relator)


func test_f5_inteiro_5_a_10_u_meio_devolve_8() -> void:
	assert_int(RngAritmetica.inteiro_entre(0x80000000, 5, 10)).is_equal(8)


func test_f5_real_2_a_4_u_quarto_devolve_2_5() -> void:
	assert_float(RngAritmetica.real_entre(0x40000000, 2.0, 4.0)).is_equal(2.5)


func test_f5_extremos_iguais_devolve_a_e_consome_um() -> void:
	var relator := RelatorGravadorRng.new()
	var fluxo := _fluxo(relator)
	assert_int(fluxo.inteiro_entre(7, 7)).is_equal(7)
	assert_int(fluxo.estado()).is_equal(0x1DDBFDFE)
	var fluxo_real := _fluxo(relator)
	assert_float(fluxo_real.real_entre(7.0, 7.0)).is_equal(7.0)
	assert_int(fluxo_real.estado()).is_equal(0x1DDBFDFE)
	assert_int(relator.total()).is_equal(0)


func test_f5_real_u_maximo_fica_abaixo_de_b() -> void:
	assert_bool(RngAritmetica.real_entre(0xFFFFFFFF, 2.0, 4.0) < 4.0).is_true()
	# Caso de borda de arredondamento (vetor próprio): b − a minúsculo perto de |a|.
	var a: float = 1.0e16
	var b: float = 1.0e16 + 2.0
	assert_float(RngAritmetica.real_entre(0xFFFFFFFF, a, b)).is_equal(a)


func test_f6_inteiro_a_partir_de_b0b08409_vetores_e_consome_um() -> void:
	var fluxo := _fluxo(RelatorGravadorRng.new())
	var pesos_a: Array[int] = [3, 2, 1]
	assert_int(fluxo.escolha_ponderada_inteira(pesos_a)).is_equal(0)
	assert_int(fluxo.estado()).is_equal(0x1DDBFDFE)
	var outro := _fluxo(RelatorGravadorRng.new())
	var pesos_b: Array[int] = [0, 5, 0, 1]
	assert_int(outro.escolha_ponderada_inteira(pesos_b)).is_equal(1)


func test_f6_inteiro_u_extremos_nunca_escolhe_peso_zero() -> void:
	var pesos: Array[int] = [0, 5, 0, 1]
	assert_int(RngAritmetica.escolha_ponderada_inteira(0, pesos)).is_equal(1)
	assert_int(RngAritmetica.escolha_ponderada_inteira(0xFFFFFFFF, pesos)).is_equal(3)


func test_f6_inteiro_soma_2_a_31_no_limite_escolhe_ultimo_positivo() -> void:
	var pesos: Array[int] = [0x7FFFFFFF, 1]
	assert_int(RngAritmetica.escolha_ponderada_inteira(0xFFFFFFFF, pesos)).is_equal(1)


func test_f6_real_pesos_1_e_2_5_vai_pelo_caminho_real() -> void:
	var pesos: Array[float] = [1.0, 2.5]
	# r·W com W = 3,5: u = 0 → 0; u = 0x40000000 (r = 0,25 → x = 0,875) → 0;
	# u = 0x80000000 (x = 1,75) → 1.
	assert_int(RngAritmetica.escolha_ponderada_real(0, pesos)).is_equal(0)
	assert_int(RngAritmetica.escolha_ponderada_real(0x40000000, pesos)).is_equal(0)
	assert_int(RngAritmetica.escolha_ponderada_real(0x80000000, pesos)).is_equal(1)
	var fluxo := _fluxo(RelatorGravadorRng.new())
	assert_int(fluxo.escolha_ponderada_real(pesos)).is_between(0, 1)
	assert_int(fluxo.estado()).is_equal(0x1DDBFDFE)


func test_f6_real_arredondamento_alcanca_w_devolve_ultimo_positivo() -> void:
	# Vetor próprio do caso de borda (ADR-0005): x ≥ W devolve o último índice positivo.
	var pesos: Array[float] = [0.0, 0.1, 0.2, 0.0]
	assert_int(RngAritmetica.escolha_ponderada_real_de_x(0.30000000000000004, pesos)).is_equal(2)


func test_f7_n8_k3_devolve_1_6_7_estado_f832f1e8() -> void:
	var fluxo := _fluxo(RelatorGravadorRng.new())
	assert_array(fluxo.k_distintos(8, 3)).is_equal([1, 6, 7])
	assert_int(fluxo.estado()).is_equal(0xF832F1E8)


func test_f7_k_maior_que_n_devolve_n_distintos_e_consome_n() -> void:
	var fluxo := _fluxo(RelatorGravadorRng.new())
	var resultado: Array[int] = fluxo.k_distintos(2, 5)
	assert_int(resultado.size()).is_equal(2)
	assert_bool(resultado[0] != resultado[1]).is_true()
	assert_int(fluxo.estado()).is_equal(_estado_apos(2))


func test_f7_k0_ou_n0_devolve_vazio_sem_consumir() -> void:
	var relator := RelatorGravadorRng.new()
	var fluxo := _fluxo(relator)
	assert_array(fluxo.k_distintos(8, 0)).is_empty()
	assert_array(fluxo.k_distintos(0, 3)).is_empty()
	assert_int(fluxo.estado()).is_equal(ESTADO_PORTAS_P3)
	assert_int(relator.total()).is_equal(0)


func test_f7_n200_k200_consome_exatamente_200() -> void:
	var fluxo := _fluxo(RelatorGravadorRng.new())
	var resultado: Array[int] = fluxo.k_distintos(200, 200)
	assert_int(resultado.size()).is_equal(200)
	assert_int(fluxo.estado()).is_equal(_estado_apos(200))


func test_f8_zero_a_nove_vetor_estado_8737cda6_original_intacta() -> void:
	var fluxo := _fluxo(RelatorGravadorRng.new())
	var original: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
	var embaralhada: Array = fluxo.embaralhar_copia(original)
	assert_array(embaralhada).is_equal([3, 6, 2, 4, 0, 5, 9, 8, 7, 1])
	assert_int(fluxo.estado()).is_equal(0x8737CDA6)
	assert_array(original).is_equal([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])


func test_f8_n_ate_um_devolve_copia_sem_consumir() -> void:
	var fluxo := _fluxo(RelatorGravadorRng.new())
	var um: Array[int] = [42]
	var copia: Array = fluxo.embaralhar_copia(um)
	assert_array(copia).is_equal([42])
	assert_bool(is_same(copia, um)).is_false()
	assert_array(fluxo.embaralhar_copia([])).is_empty()
	assert_int(fluxo.estado()).is_equal(ESTADO_PORTAS_P3)


func test_erros_nao_consomem_um_registro_e_proxima_saida_intacta() -> void:
	var casos: Array[Callable] = [
		func(f: FluxoRng) -> Variant: return f.inteiro(0),
		func(f: FluxoRng) -> Variant: return f.inteiro((1 << 21) + 1),
		func(f: FluxoRng) -> Variant: return f.inteiro_entre(10, 5),
		func(f: FluxoRng) -> Variant: return f.inteiro_entre(0, 1 << 21),
		func(f: FluxoRng) -> Variant: return f.inteiro_entre(-0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF),
		func(f: FluxoRng) -> Variant: return f.real_entre(4.0, 2.0),
		func(f: FluxoRng) -> Variant: return f.escolha_ponderada_inteira([] as Array[int]),
		func(f: FluxoRng) -> Variant: return f.escolha_ponderada_inteira([1, -1] as Array[int]),
		func(f: FluxoRng) -> Variant: return f.escolha_ponderada_inteira([0, 0] as Array[int]),
		func(f: FluxoRng) -> Variant: return f.escolha_ponderada_inteira([0x80000000, 1] as Array[int]),
		func(f: FluxoRng) -> Variant: return f.escolha_ponderada_real([] as Array[float]),
		func(f: FluxoRng) -> Variant: return f.escolha_ponderada_real([1.0, -0.5] as Array[float]),
		func(f: FluxoRng) -> Variant: return f.escolha_ponderada_real([1.0, NAN] as Array[float]),
		func(f: FluxoRng) -> Variant: return f.escolha_ponderada_real([1.0, INF] as Array[float]),
		func(f: FluxoRng) -> Variant: return f.escolha_ponderada_real([-INF, 1.0] as Array[float]),
		func(f: FluxoRng) -> Variant: return f.escolha_ponderada_real([0.0, 0.0] as Array[float]),
	]
	var esperados: Array = [0, 0, 10, 0, -0x7FFFFFFFFFFFFFFF, 4.0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]
	var referencia := _fluxo(RelatorGravadorRng.new())
	var proxima_saida: int = referencia.proximo_u32()
	for i: int in casos.size():
		var relator := RelatorGravadorRng.new()
		var fluxo := _fluxo(relator)
		var valor: Variant = casos[i].call(fluxo)
		assert_that(valor).override_failure_message("caso %d" % i).is_equal(esperados[i])
		assert_int(relator.operacoes.size()).override_failure_message("caso %d" % i).is_equal(1)
		assert_int(fluxo.estado()).is_equal(ESTADO_PORTAS_P3)
		assert_int(fluxo.proximo_u32()).is_equal(proxima_saida)


func test_erros_f7_negativos_devolvem_vazio_sem_consumir() -> void:
	var relator := RelatorGravadorRng.new()
	var fluxo := _fluxo(relator)
	assert_array(fluxo.k_distintos(-1, 3)).is_empty()
	assert_array(fluxo.k_distintos(3, -1)).is_empty()
	assert_array(fluxo.k_distintos((1 << 21) + 1, 1)).is_empty()
	assert_int(relator.operacoes.size()).is_equal(3)
	assert_int(fluxo.estado()).is_equal(ESTADO_PORTAS_P3)


func _estado_apos(passos: int) -> int:
	var estado: int = ESTADO_PORTAS_P3
	for i: int in passos:
		estado = RngAritmetica.proximo_estado(estado)
	return estado
