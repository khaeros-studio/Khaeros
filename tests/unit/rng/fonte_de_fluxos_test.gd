## Story RNG-003: fonte de fluxos — posse, matriz dono × finalidade e ciclo de vida.
extends GdUnitTestSuite

const SEED_REF: int = 0x3F9A07C2
## Vetor de referência de (pactos, 0, 0) com a seed 3F9A07C2, calculado pelo
## script de paridade independente (Python, mesma fórmula F1/F2 do GDD).
const PACTOS_S0_REF: int = 0x930387A6
const PACTOS_U_REF: Array[int] = [0x0602A893, 0x34D3D1BA, 0x5A2B71C3, 0x8E90077B]

var _relator: RelatorGravadorRng
var _fonte: FonteDeFluxos


func before_test() -> void:
	_relator = RelatorGravadorRng.new()
	_fonte = FonteDeFluxos.new(_relator)


func _sequencia(finalidade: int, regiao: int, profundidade: int, quantos: int) -> Array[int]:
	var avulso := FluxoRng.new(RngAritmetica.derivar(SEED_REF, finalidade, regiao, profundidade), RelatorGravadorRng.new())
	var saidas: Array[int] = []
	for i: int in quantos:
		saidas.append(avulso.proximo_u32())
	return saidas


func test_mesmo_trio_devolve_mesmo_fluxo_que_continua() -> void:
	_fonte.iniciar_run(SEED_REF, false)
	var portas := FluxosDePortas.new(_fonte)
	var a: FluxoRng = portas.portas(0, 2)
	for i: int in 3:
		a.proximo_u32()
	var b: FluxoRng = portas.portas(0, 2)
	assert_bool(is_same(a, b)).is_true()
	assert_int(b.proximo_u32()).is_equal(_sequencia(FonteDeFluxos.PORTAS, 0, 2, 4)[3])


func test_matriz_dono_por_finalidade_permite_so_a_linha_do_dono() -> void:
	_fonte.iniciar_run(SEED_REF, true)
	var acessos: Array[AcessoAFluxos] = [FluxosDeCamaras.new(_fonte), FluxosDeIa.new(_fonte),
		FluxosDePortas.new(_fonte), FluxosDeBencaos.new(_fonte), FluxosDeVinculo.new(_fonte)]
	var permitidas: Array[Array] = [[1, 3, 8], [2, 7], [4], [5, 6], [9]]
	for i: int in acessos.size():
		for finalidade: int in range(1, 10):
			var antes_fluxos: int = _fonte.fluxos_abertos()
			var antes_erros: int = _relator.total()
			var fluxo: FluxoRng = acessos[i].fluxo(finalidade, 0, 0)
			if permitidas[i].has(finalidade):
				assert_object(fluxo).is_not_null()
			else:
				assert_object(fluxo).is_null()
				assert_int(_relator.total()).is_equal(antes_erros + 1)
				assert_int(_fonte.fluxos_abertos()).is_equal(antes_fluxos)


func test_consumir_ia_nao_altera_ondas_nem_portas() -> void:
	_fonte.iniciar_run(SEED_REF, false)
	var ia: FluxoRng = FluxosDeIa.new(_fonte).ia(0, 2)
	for i: int in 1000:
		ia.proximo_u32()
	var ondas: FluxoRng = FluxosDeCamaras.new(_fonte).ondas(0, 2)
	var portas: FluxoRng = FluxosDePortas.new(_fonte).portas(0, 3)
	var saidas_ondas: Array[int] = []
	var saidas_portas: Array[int] = []
	for i: int in 5:
		saidas_ondas.append(ondas.proximo_u32())
		saidas_portas.append(portas.proximo_u32())
	assert_array(saidas_ondas).is_equal(_sequencia(FonteDeFluxos.ONDAS, 0, 2, 5))
	assert_array(saidas_portas).is_equal(_sequencia(FonteDeFluxos.PORTAS, 0, 3, 5))


func test_sem_run_pedido_devolve_null_com_trio_e_solicitante_e_sem_seed() -> void:
	var fluxo: FluxoRng = FluxosDeCamaras.new(_fonte).ondas(0, 0)
	assert_object(fluxo).is_null()
	assert_array(_relator.pedidos).is_equal([[1, 0, 0]])
	assert_array(_relator.solicitantes).is_equal([&"camaras"])
	assert_bool(_fonte.tem_seed()).is_false()
	assert_int(_fonte.seed()).is_equal(FonteDeFluxos.SEM_SEED)


func test_run_ativa_chaves_invalidas_recusadas_sem_criar_fluxo() -> void:
	_fonte.iniciar_run(SEED_REF, false)
	var trios: Array[Array] = [[0, 0, 0], [9, 0, 0], [1, -1, 0], [1, 256, 0], [1, 0, -1], [1, 0, 1024]]
	for trio: Array in trios:
		assert_object(_fonte.abrir_fluxo(trio[0], trio[1], trio[2], &"teste")).is_null()
	assert_int(_relator.pedidos.size()).is_equal(trios.size())
	assert_int(_fonte.fluxos_abertos()).is_equal(0)


func test_encerrada_seed_legivel_pedidos_recusados_e_retido_preserva_estado() -> void:
	_fonte.iniciar_run(SEED_REF, false)
	var camaras := FluxosDeCamaras.new(_fonte)
	var retido: FluxoRng = camaras.ondas(0, 0)
	retido.proximo_u32()
	var estado_antes: int = retido.estado()
	_fonte.encerrar_run()
	assert_int(_fonte.seed()).is_equal(SEED_REF)
	assert_object(camaras.ondas(0, 0)).is_null()
	assert_object(camaras.layout(0, 1)).is_null()
	assert_int(_relator.pedidos.size()).is_equal(2)
	assert_int(retido.inteiro(10)).is_equal(0)
	assert_float(retido.real_unitario()).is_equal(0.0)
	assert_int(retido.estado()).is_equal(estado_antes)
	assert_int(_relator.operacoes.size()).is_equal(2)
	_fonte.descartar_run()
	assert_int(_fonte.fluxos_abertos()).is_equal(0)
	assert_bool(_fonte.tem_seed()).is_false()


func test_nova_run_mesma_seed_marcador_novo_e_retido_antigo_invalido() -> void:
	_fonte.iniciar_run(SEED_REF, false)
	var antigo: FluxoRng = FluxosDeCamaras.new(_fonte).ondas(0, 0)
	_fonte.descartar_run()
	_fonte.iniciar_run(SEED_REF, false)
	var novo: FluxoRng = FluxosDeCamaras.new(_fonte).ondas(0, 0)
	assert_bool(is_same(antigo, novo)).is_false()
	assert_bool(antigo.esta_valido()).is_false()
	assert_bool(novo.esta_valido()).is_true()
	assert_int(novo.proximo_u32()).is_equal(_sequencia(FonteDeFluxos.ONDAS, 0, 0, 1)[0])


func test_pactos_finalidade_9_deriva_por_f2_bate_vetor_e_continua() -> void:
	_fonte.iniciar_run(SEED_REF, true)
	var vinculo := FluxosDeVinculo.new(_fonte)
	var pactos: FluxoRng = vinculo.pactos(0)
	assert_int(pactos.estado()).is_equal(PACTOS_S0_REF)
	for finalidade: int in range(1, 9):
		assert_int(RngAritmetica.derivar(SEED_REF, finalidade, 0, 0)).is_not_equal(PACTOS_S0_REF)
	assert_int(pactos.proximo_u32()).is_equal(PACTOS_U_REF[0])
	var de_novo: FluxoRng = vinculo.pactos(0)
	for i: int in range(1, 4):
		assert_int(de_novo.proximo_u32()).is_equal(PACTOS_U_REF[i])


func test_pactos_sem_autorizacao_recusado() -> void:
	_fonte.iniciar_run(SEED_REF, false)
	assert_object(FluxosDeVinculo.new(_fonte).pactos(0)).is_null()
	assert_int(_relator.pedidos.size()).is_equal(1)
	assert_int(_fonte.fluxos_abertos()).is_equal(0)


func test_iniciar_run_fora_de_sem_run_recusado() -> void:
	_fonte.iniciar_run(SEED_REF, false)
	assert_bool(_fonte.iniciar_run(5, false)).is_false()
	assert_int(_fonte.seed()).is_equal(SEED_REF)
	assert_int(_relator.avisos.size()).is_equal(1)
