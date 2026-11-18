## Story RNG-005: consumo fixo (AC-34 spawn com 14 candidatos, AC-35 reforços
## no fluxo `ia`, AC-37 vínculo com 4 reais).
extends GdUnitTestSuite

const SEED_REF: int = 0x3F9A07C2
const K: int = 14
const NUMEROS_POR_CANDIDATO: int = 2
const INIMIGOS: int = 5
const DISTANCIA: float = 260.0
const ARENA: Vector2 = Vector2(1200.0, 700.0)
const N_TIPOS: int = 6
const N_CAMARAS: int = 6
const CHANCE_ENCONTRO: float = 0.25


func _fonte(pactos: bool = false) -> FonteDeFluxos:
	var fonte := FonteDeFluxos.new(RelatorGravadorRng.new())
	fonte.iniciar_run(SEED_REF, pactos)
	return fonte


func _estado_apos(estado: int, passos: int) -> int:
	for i: int in passos:
		estado = RngAritmetica.proximo_estado(estado)
	return estado


func test_spawn_14_candidatos_estado_igual_com_jogador_em_qualquer_posicao() -> void:
	var jogadores: Array[Vector2] = [Vector2(100.0, 100.0), Vector2(900.0, 500.0)]
	var estados: Array[Array] = []
	for jogador: Vector2 in jogadores:
		var fonte: FonteDeFluxos = _fonte()
		var camaras := FluxosDeCamaras.new(fonte)
		var dono := DonoSpawnFalso.new(camaras, K, ARENA, DISTANCIA)
		var depois: Array[int] = []
		for i: int in INIMIGOS:
			dono.nascer(0, 2, jogador)
			depois.append(camaras.spawn(0, 2).estado())
		estados.append(depois)
	assert_array(estados[1]).is_equal(estados[0])
	var s0: int = RngAritmetica.derivar(SEED_REF, FonteDeFluxos.SPAWN, 0, 2)
	for i: int in INIMIGOS:
		assert_int(estados[0][i]).is_equal(_estado_apos(s0, (i + 1) * K * NUMEROS_POR_CANDIDATO))
	assert_int(estados[0][INIMIGOS - 1]).is_equal(_estado_apos(s0, 140))


func test_reforcos_no_fluxo_ia_nao_alteram_ondas_spawn_layout() -> void:
	var saidas: Array[Array] = []
	for com_reforcos: bool in [false, true]:
		var fonte: FonteDeFluxos = _fonte()
		var camaras := FluxosDeCamaras.new(fonte)
		var linha: Array[int] = []
		linha.append(camaras.ondas(0, 2).proximo_u32())
		if com_reforcos:
			ConsumidorIaFalso.new(FluxosDeIa.new(fonte)).invocar_reforcos(0, 2, 3, N_TIPOS, ARENA)
		for i: int in 3:
			linha.append(camaras.ondas(0, 2).proximo_u32())
			linha.append(camaras.spawn(0, 2).proximo_u32())
			linha.append(camaras.layout(0, 2).proximo_u32())
		saidas.append(linha)
	assert_array(saidas[1]).is_equal(saidas[0])


func test_vinculo_consome_4_reais_com_garantia_ou_sem_encontro() -> void:
	var pesos: Array[float] = [1.0, 2.0, 1.0]
	var s0: int = RngAritmetica.derivar(SEED_REF, FonteDeFluxos.PACTOS, 0, 0)
	var estados: Array[int] = []
	# Garantia (G1).
	var fonte_g: FonteDeFluxos = _fonte(true)
	var com_garantia: int = DonoVinculoFalso.new(FluxosDeVinculo.new(fonte_g)).decidir(0, CHANCE_ENCONTRO, true, 1, N_CAMARAS, pesos)
	assert_int(com_garantia).is_equal(1)
	estados.append(FluxosDeVinculo.new(fonte_g).pactos(0).estado())
	# Sem encontro: chance 0 garante u0 ≥ chance.
	var fonte_s: FonteDeFluxos = _fonte(true)
	var sem_encontro: int = DonoVinculoFalso.new(FluxosDeVinculo.new(fonte_s)).decidir(0, 0.0, false, 1, N_CAMARAS, pesos)
	assert_int(sem_encontro).is_equal(-1)
	estados.append(FluxosDeVinculo.new(fonte_s).pactos(0).estado())
	assert_int(estados[0]).is_equal(_estado_apos(s0, 4))
	assert_int(estados[1]).is_equal(estados[0])
