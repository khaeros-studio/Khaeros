class_name FilaDeSonsDeInterface
extends RefCounted
## Fila pré-alocada de pedidos de som de interface (`ui_*`) emitidos pelo HUD e Telas (ADR-0016 §1).

const CAPACIDADE_PADRAO: int = 32

var _pool: Array[PedidoDeSom] = []
var _quantidade: int = 0


func _init(capacidade: int = CAPACIDADE_PADRAO) -> void:
	var cap: int = maxi(4, capacidade)
	_pool.resize(cap)
	for i: int in range(cap):
		_pool[i] = PedidoDeSom.new()
	_quantidade = 0


func pedir(gancho: StringName, prioridade: int = 2, player_id: int = -1) -> bool:
	if gancho == &"":
		return false
	if _quantidade >= _pool.size():
		return false
	var slot: PedidoDeSom = _pool[_quantidade]
	slot.configurar(gancho, prioridade, player_id)
	_quantidade += 1
	return true


func quantidade_pendente() -> int:
	return _quantidade


func limpar() -> void:
	_quantidade = 0


func drenar_para(saida: Array[PedidoDeSom]) -> int:
	var drenados: int = _quantidade
	for i: int in range(_quantidade):
		var src: PedidoDeSom = _pool[i]
		saida.append(PedidoDeSom.new(src.gancho, src.prioridade, src.player_id))
	_quantidade = 0
	return drenados
