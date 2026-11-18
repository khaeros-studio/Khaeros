## Fonte de fluxos de uma run (GDD rng-com-seed.md R3, R9, States and
## Transitions, Emenda Pactos; ADR-0005 "Posse e autorização" e "Ciclo de vida").
##
## Criada no ponto de composição e injetada nos consumidores só por meio das
## interfaces limitadas (`interfaces/`), nunca como singleton. Mantém o mapa
## chave → fluxo: o mesmo trio devolve o mesmo objeto, que continua de onde
## parou. O mapa nunca é iterado para sortear (R4). Estados: Sem run, Run ativa,
## Encerrada. Referências: fonte → fluxos → marcador (uma direção só).
class_name FonteDeFluxos
extends RefCounted

## Estados da fonte (GDD, States and Transitions).
enum Estado { SEM_RUN, RUN_ATIVA, ENCERRADA }

## Ids fixos das finalidades (R3, R3-P). Nunca renumerar.
const ONDAS: int = 1
const ELITES: int = 2
const SPAWN: int = 3
const PORTAS: int = 4
const BENCAOS: int = 5
const RARIDADE: int = 6
const IA: int = 7
const LAYOUT: int = 8
const PACTOS: int = 9

## Valor de [method seed] quando não há seed ("sem seed").
const SEM_SEED: int = -1

var _relator: RelatorDeErrosRng
var _estado: Estado = Estado.SEM_RUN
var _seed: int = SEM_SEED
var _pactos_autorizado: bool = false
var _marcador: MarcadorDeValidade = null
var _sessao: int = 0
var _fluxos: Dictionary[int, FluxoRng] = {}


## A fonte nasce em Sem run. `relator` recebe todos os diagnósticos.
func _init(relator: RelatorDeErrosRng) -> void:
	_relator = relator


## Relator injetado (as interfaces limitadas registram por ele).
func relator() -> RelatorDeErrosRng:
	return _relator


## Estado atual da fonte.
func estado() -> Estado:
	return _estado


## Verdadeiro em Run ativa e Encerrada.
func tem_seed() -> bool:
	return _seed != SEM_SEED


## Seed u32 da run, ou [constant SEM_SEED] em Sem run.
func seed() -> int:
	return _seed


## Verdadeiro se a run atual autoriza a finalidade 9 (Doutrina `pactos`).
func pactos_autorizado() -> bool:
	return _pactos_autorizado


## Sem run → Run ativa. A seed passa pela máscara u32 (fronteira) e fica fixa.
## `pactos_autorizado` libera a finalidade 9 (só runs da Doutrina `pactos`).
## Cada run recebe um marcador novo, mesmo com a mesma seed. Fora de Sem run,
## registra um aviso e devolve false sem mudar nada.
func iniciar_run(seed_da_run: int, pactos_autorizado: bool) -> bool:
	if _estado != Estado.SEM_RUN:
		_relator.registrar_aviso("iniciar_run recusado: fonte nao esta em Sem run")
		return false
	_sessao += 1
	_marcador = MarcadorDeValidade.new(_sessao)
	_seed = RngAritmetica.mascarar_u32(seed_da_run)
	_pactos_autorizado = pactos_autorizado
	_fluxos = {}
	_estado = Estado.RUN_ATIVA
	return true


## Run ativa → Encerrada (morte, vitória, abandono). Invalida o marcador antes
## de devolver o controle; a seed continua legível.
func encerrar_run() -> void:
	if _estado != Estado.RUN_ATIVA:
		return
	_marcador.invalidar()
	_estado = Estado.ENCERRADA


## Encerrada → Sem run (Campus ou `nova_run`). Descarta os fluxos e a seed.
func descartar_run() -> void:
	if _estado == Estado.RUN_ATIVA:
		encerrar_run()
	_fluxos = {}
	_seed = SEM_SEED
	_pactos_autorizado = false
	_estado = Estado.SEM_RUN


## Abre (ou devolve o já aberto) fluxo do trio. Só as interfaces limitadas
## devem chamar: a matriz dono × finalidade é verificada nelas. Recusa (null e
## 1 registro com o solicitante) fora de Run ativa, com chave fora das faixas
## ou com a finalidade 9 sem autorização.
func abrir_fluxo(finalidade: int, regiao: int, profundidade: int, solicitante: StringName) -> FluxoRng:
	var motivo: String = _motivo_de_recusa(finalidade, regiao, profundidade)
	if not motivo.is_empty():
		_relator.registrar_pedido_recusado(finalidade, regiao, profundidade, solicitante, motivo)
		return null
	var chave: int = (finalidade << 18) | (regiao << 10) | profundidade
	var existente: FluxoRng = _fluxos.get(chave, null)
	if existente != null:
		return existente
	var s0: int = RngAritmetica.derivar(_seed, finalidade, regiao, profundidade)
	var fluxo := FluxoRng.new(s0, _relator, _marcador)
	_fluxos[chave] = fluxo
	return fluxo


## Quantos fluxos a run atual já abriu (para testes de "nenhum fluxo criado").
func fluxos_abertos() -> int:
	return _fluxos.size()


func _motivo_de_recusa(finalidade: int, regiao: int, profundidade: int) -> String:
	match _estado:
		Estado.SEM_RUN:
			return "pedido de fluxo em Sem run"
		Estado.ENCERRADA:
			return "pedido de fluxo em run Encerrada"
	if not RngAritmetica.chave_valida(finalidade, regiao, profundidade):
		return "chave fora das faixas"
	if finalidade == PACTOS and not _pactos_autorizado:
		return "finalidade pactos fora de run de Pactos"
	return ""
