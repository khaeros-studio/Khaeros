## Story RNG-001: núcleo mulberry32, derivação F2 e máscara u32.
## Vetores de referência: design/gdd/rng-com-seed.md, "Vetores de referência".
extends GdUnitTestSuite

const SEED_REF: int = 0x3F9A07C2
const ESTADO_PORTAS_P3: int = 0xB0B08409


func _passos(estado_inicial: int, quantos: int) -> Array[int]:
	var fluxo := FluxoRng.new(estado_inicial, RelatorGravadorRng.new())
	var saidas: Array[int] = []
	for i: int in quantos:
		saidas.append(fluxo.proximo_u32())
	return saidas


func test_f1_estado_zero_cinco_passos_bate_estados_e_saidas() -> void:
	var estados_esperados: Array[int] = [0x6D2B79F5, 0xDA56F3EA, 0x47826DDF, 0xB4ADE7D4, 0x21D961C9]
	var saidas_esperadas: Array[int] = [0x4434B462, 0x00159C37, 0x39285B08, 0x256D8104, 0x77A2CBD4]
	var fluxo := FluxoRng.new(0, RelatorGravadorRng.new())
	for i: int in 5:
		var u: int = fluxo.proximo_u32()
		assert_int(fluxo.estado()).is_equal(estados_esperados[i])
		assert_int(u).is_equal(saidas_esperadas[i])


func test_f1_estado_3f9a07c2_cinco_passos_bate_saidas() -> void:
	var esperadas: Array[int] = [0x0865C80A, 0xD260910A, 0xB37DB9FA, 0x91FD7BCE, 0x7A515CDF]
	assert_array(_passos(SEED_REF, 5)).is_equal(esperadas)


func test_imul_maximos_devolve_um() -> void:
	assert_int(RngAritmetica.imul(0xFFFFFFFF, 0xFFFFFFFF)).is_equal(1)


func test_f3_real_unitario_vetores_dentro_de_zero_e_um() -> void:
	assert_float(RngAritmetica.real_unitario(0x4434B462)).is_equal_approx(0.266429208685, 1e-12)
	assert_bool(RngAritmetica.real_unitario(0xFFFFFFFF) < 1.0).is_true()
	assert_float(RngAritmetica.real_unitario(0)).is_equal(0.0)


func test_f4_n100_limiares_devolve_0_1_50_99() -> void:
	assert_int(RngAritmetica.inteiro_limitado(42949672, 100)).is_equal(0)
	assert_int(RngAritmetica.inteiro_limitado(42949673, 100)).is_equal(1)
	assert_int(RngAritmetica.inteiro_limitado(0x80000000, 100)).is_equal(50)
	assert_int(RngAritmetica.inteiro_limitado(0xFFFFFFFF, 100)).is_equal(99)


func test_f4_a_partir_de_b0b08409_n6_0_e_n100_13_estado_1ddbfdfe() -> void:
	var a := FluxoRng.new(ESTADO_PORTAS_P3, RelatorGravadorRng.new())
	assert_int(a.inteiro(6)).is_equal(0)
	var b := FluxoRng.new(ESTADO_PORTAS_P3, RelatorGravadorRng.new())
	assert_int(b.inteiro(100)).is_equal(13)
	assert_int(b.estado()).is_equal(0x1DDBFDFE)


func test_f4_n1_devolve_zero_e_consome_um() -> void:
	var fluxo := FluxoRng.new(ESTADO_PORTAS_P3, RelatorGravadorRng.new())
	assert_int(fluxo.inteiro(1)).is_equal(0)
	assert_int(fluxo.estado()).is_equal(0x1DDBFDFE)


func test_f4_produto_deslocado_igual_a_floor_para_lista_fixa() -> void:
	var us: Array[int] = [0, 1, 42949672, 42949673, 0x7FFFFFFF, 0x80000000, 0xB0B08409, 0xFFFFFFFE, 0xFFFFFFFF]
	var ns: Array[int] = [1, 2, 3, 6, 7, 100, 1 << 21]
	for u: int in us:
		for n: int in ns:
			# floor(u/2³²·n) exato em float64: u·n < 2⁵³.
			var esperado: int = floori(float(u) / 4294967296.0 * float(n))
			assert_int(RngAritmetica.inteiro_limitado(u, n)).is_equal(esperado)


func test_fmix32_vetores_de_referencia() -> void:
	assert_int(RngAritmetica.fmix32(0)).is_equal(0)
	assert_int(RngAritmetica.fmix32(1)).is_equal(0x514E28B7)
	assert_int(RngAritmetica.fmix32(0xFFFFFFFF)).is_equal(0x81F16F39)


func test_f2_portas_regiao0_profundidades_0_a_4_batem_vetor() -> void:
	var esperados: Array[int] = [0x0EC3245B, 0x3043CE64, 0xCFBE45BC, 0xB0B08409, 0x83C51646]
	for p: int in 5:
		assert_int(RngAritmetica.derivar(SEED_REF, 4, 0, p)).is_equal(esperados[p])
	assert_int(RngAritmetica.derivar(0, 1, 0, 0)).is_equal(0xE8A7E13D)


func test_f2_profundidades_0_a_1023_dao_estados_distintos() -> void:
	var seeds: Array[int] = [0, SEED_REF, 0xFFFFFFFF]
	for s: int in seeds:
		var vistos: Dictionary[int, bool] = {}
		for p: int in 1024:
			vistos[RngAritmetica.derivar(s, 1, 0, p)] = true
		assert_int(vistos.size()).is_equal(1024)


func test_fronteira_seed_negativa_e_acima_de_32_bits_mascara() -> void:
	assert_int(RngAritmetica.derivar(-1, 1, 0, 0)).is_equal(RngAritmetica.derivar(0xFFFFFFFF, 1, 0, 0))
	assert_int(RngAritmetica.derivar((1 << 32) + 5, 1, 0, 0)).is_equal(RngAritmetica.derivar(5, 1, 0, 0))
	assert_int(RngAritmetica.mascarar_u32(-1)).is_equal(0xFFFFFFFF)


func test_chave_valida_faixas_fora_recusadas() -> void:
	assert_bool(RngAritmetica.chave_valida(9, 255, 1023)).is_true()
	assert_bool(RngAritmetica.chave_valida(0, 0, 0)).is_false()
	assert_bool(RngAritmetica.chave_valida(10, 0, 0)).is_false()
	assert_bool(RngAritmetica.chave_valida(1, 256, 0)).is_false()
	assert_bool(RngAritmetica.chave_valida(1, 0, -1)).is_false()
	assert_bool(RngAritmetica.chave_valida(1, 0, 1024)).is_false()
