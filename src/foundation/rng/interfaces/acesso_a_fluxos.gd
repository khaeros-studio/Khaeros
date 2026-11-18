## Interface limitada de um consumidor à [FonteDeFluxos] (ADR-0005, "Posse e
## autorização"; GDD rng-com-seed.md, Edge Cases "finalidade que não é dele").
##
## Cada consumidor recebe só a sua subclasse, que abre apenas as finalidades
## da linha dele na matriz dono × finalidade. Pedido fora da matriz devolve
## null, gera 1 registro e não cria nem consome fluxo.
class_name AcessoAFluxos
extends RefCounted

var _fonte: FonteDeFluxos
var _permitidas: Array[int] = []
var _solicitante: StringName = &""


## `permitidas`: ids de finalidade da linha do dono; `solicitante`: nome do dono
## que vai aos diagnósticos.
func _init(fonte: FonteDeFluxos, permitidas: Array[int], solicitante: StringName) -> void:
	_fonte = fonte
	_permitidas = permitidas.duplicate()
	_solicitante = solicitante


## Finalidades que este acesso pode abrir.
func finalidades_permitidas() -> Array[int]:
	return _permitidas.duplicate()


## Pede o fluxo do trio, respeitando a matriz.
func fluxo(finalidade: int, regiao: int, profundidade: int) -> FluxoRng:
	if not _permitidas.has(finalidade):
		_fonte.relator().registrar_pedido_recusado(finalidade, regiao, profundidade, _solicitante,
			"finalidade fora da matriz do dono")
		return null
	return _fonte.abrir_fluxo(finalidade, regiao, profundidade, _solicitante)
