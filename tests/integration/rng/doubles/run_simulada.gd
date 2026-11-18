## Dublê: run com donos falsos das finalidades de estrutura, para o contrato R7.
## Cada profundidade abre os fluxos na ordem fixa dos donos e registra, por
## finalidade, o estado final e as saídas inteiras. Valores de fixture abaixo.
class_name RunSimulada
extends RefCounted

const N_TIPOS_INIMIGO: int = 6
const ONDAS_POR_CAMARA: int = 3
const ELITES_POR_CAMARA: int = 2
const INIMIGOS_POR_CAMARA: int = 5
const K_CANDIDATOS: int = 14
const ARENA: Vector2 = Vector2(1200.0, 700.0)
const DISTANCIA_MINIMA: float = 260.0
const OBSTACULOS_MIN: int = 2
const OBSTACULOS_MAX: int = 5
const RAIO_MIN: float = 16.0
const RAIO_MAX: float = 48.0
const PORTAS_MIN: int = 1
const PORTAS_MAX: int = 3
const PESOS_RECOMPENSA: Array[int] = [3, 2, 1]
const BENCAOS_DO_MANIFESTO: Array[StringName] = [&"b0", &"b1", &"b2", &"b3", &"b4", &"b5", &"b6", &"b7", &"b8", &"b9"]
const OFERTAS: int = 3

var _camaras: FluxosDeCamaras
var _ia: FluxosDeIa
var _portas: FluxosDePortas
var _bencaos: FluxosDeBencaos
var _spawn: DonoSpawnFalso
var _consumidor_ia: ConsumidorIaFalso
var _pegas: Array[StringName] = []
## Log: finalidade → uma linha por profundidade.
var log_por_finalidade: Dictionary[int, Array] = {}
## Caminho registrado (R7).
var caminho := EstadoInicialDaRun.CaminhoDaRun.new()


func _init(fonte: FonteDeFluxos) -> void:
	_camaras = FluxosDeCamaras.new(fonte)
	_ia = FluxosDeIa.new(fonte)
	_portas = FluxosDePortas.new(fonte)
	_bencaos = FluxosDeBencaos.new(fonte)
	_spawn = DonoSpawnFalso.new(_camaras, K_CANDIDATOS, ARENA, DISTANCIA_MINIMA)
	_consumidor_ia = ConsumidorIaFalso.new(_ia)


## Joga as profundidades 0..n−1. `consumo_ia[p]` números de `ia` por câmara;
## `trocas`: profundidades com "Trocar ofertas"; `sem_ondas`: Santuários;
## `escolha_bencao[p]`: índice escolhido na oferta final; `jogador`: posição.
func jogar(n: int, consumo_ia: Array[int], trocas: Array[int], sem_ondas: Array[int],
		escolha_bencao: Array[int], jogador: Vector2) -> void:
	for p: int in n:
		_layout(p)
		if not sem_ondas.has(p):
			_ondas_e_elites(p)
			_spawns(p, jogador)
		_consumidor_ia.consumir(0, p, consumo_ia[p])
		_portas_da_camara(p)
		_bencaos_da_camara(p, trocas.has(p), escolha_bencao[p])


## Linhas do log de uma finalidade.
func linhas(finalidade: int) -> Array:
	return log_por_finalidade.get(finalidade, [])


func _registrar(finalidade: int, p: int, fluxo: FluxoRng, saidas: Array[int]) -> void:
	if not log_por_finalidade.has(finalidade):
		log_por_finalidade[finalidade] = []
	log_por_finalidade[finalidade].append("p%d:%08X:%s" % [p, fluxo.estado(), str(saidas)])


func _layout(p: int) -> void:
	var fluxo: FluxoRng = _camaras.layout(0, p)
	var n: int = fluxo.inteiro_entre(OBSTACULOS_MIN, OBSTACULOS_MAX)
	for i: int in n:
		fluxo.real_entre(0.0, ARENA.x)
		fluxo.real_entre(0.0, ARENA.y)
		fluxo.real_entre(RAIO_MIN, RAIO_MAX)
	_registrar(FonteDeFluxos.LAYOUT, p, fluxo, [n] as Array[int])


func _ondas_e_elites(p: int) -> void:
	var ondas: FluxoRng = _camaras.ondas(0, p)
	var tipos: Array[int] = []
	for i: int in ONDAS_POR_CAMARA:
		tipos.append(ondas.inteiro(N_TIPOS_INIMIGO))
	_registrar(FonteDeFluxos.ONDAS, p, ondas, tipos)
	var elites: FluxoRng = _ia.elites(0, p)
	var quais: Array[int] = elites.k_distintos(INIMIGOS_POR_CAMARA, ELITES_POR_CAMARA)
	_registrar(FonteDeFluxos.ELITES, p, elites, quais)


func _spawns(p: int, jogador: Vector2) -> void:
	for i: int in INIMIGOS_POR_CAMARA:
		_spawn.nascer(0, p, jogador)
	_registrar(FonteDeFluxos.SPAWN, p, _camaras.spawn(0, p), [] as Array[int])


func _portas_da_camara(p: int) -> void:
	var fluxo: FluxoRng = _portas.portas(0, p)
	var n: int = fluxo.inteiro_entre(PORTAS_MIN, PORTAS_MAX)
	var recompensas: Array[int] = []
	for i: int in n:
		recompensas.append(fluxo.escolha_ponderada_inteira(PESOS_RECOMPENSA))
	caminho.registrar_porta(p, 0)
	_registrar(FonteDeFluxos.PORTAS, p, fluxo, recompensas)


func _bencaos_da_camara(p: int, com_troca: bool, escolha: int) -> void:
	var disponiveis: Array[StringName] = []
	for id: StringName in BENCAOS_DO_MANIFESTO:
		if not _pegas.has(id):
			disponiveis.append(id)
	var oferta: Array[int] = _oferta(p, disponiveis.size())
	if com_troca:
		caminho.registrar_troca(p)
		oferta = _oferta(p, disponiveis.size())
	var escolhida: StringName = disponiveis[oferta[escolha]]
	_pegas.append(escolhida)
	caminho.registrar_bencao(p, escolhida)
	_registrar(FonteDeFluxos.BENCAOS, p, _bencaos.bencaos(0, p), oferta)
	_registrar(FonteDeFluxos.RARIDADE, p, _bencaos.raridade(0, p), [] as Array[int])


func _oferta(p: int, n_disponiveis: int) -> Array[int]:
	var oferta: Array[int] = _bencaos.bencaos(0, p).k_distintos(n_disponiveis, OFERTAS)
	var raridade: FluxoRng = _bencaos.raridade(0, p)
	for i: int in oferta.size():
		raridade.real_unitario()
	return oferta
