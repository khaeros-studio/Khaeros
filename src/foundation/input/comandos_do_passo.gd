class_name ComandosDoPasso
extends RefCounted
## Capacidade de consumo do buffer num passo (GDD input-e-controle R6, R7; ADR-0006 §2, Key Interfaces).
##
## Ligada ao buffer vivo, ao passo e à época. `quer` consulta sem consumir; `consumir` remove só a ação
## executada, sem mexer no prazo. O provedor invalida a capacidade no fim do passo ou na troca de contexto;
## capacidade inválida responde falso e não altera o buffer.

var _buffer: BufferDeComandos
var _segurados: Dictionary = {}   # acao -> true
var _id_passo: int
var _epoca: int
var _valida: bool = true


func _init(buffer: BufferDeComandos, segurados: Array[StringName], id_passo: int, epoca: int) -> void:
	_buffer = buffer
	for acao: StringName in segurados:
		_segurados[acao] = true
	_id_passo = id_passo
	_epoca = epoca


## Ataque/Especial: segurado ou no buffer. Esquiva/Selo/Troca: só no buffer. Outras ações: falso.
func quer(acao: StringName) -> bool:
	if not _valida:
		return false
	if Acoes.SEGURAR_REPETE.has(acao) and _segurados.has(acao):
		return true
	return _buffer.contem(acao, _epoca)


## Remove `acao` do buffer depois de executada com sucesso. Verdadeiro se removeu.
func consumir(acao: StringName) -> bool:
	if not _valida:
		return false
	return _buffer.remover(acao, _epoca)


## Passo a que a capacidade pertence.
func id_passo() -> int:
	return _id_passo


## Época a que a capacidade pertence.
func epoca() -> int:
	return _epoca


## Verdadeiro enquanto o passo e a época continuam correntes.
func valida() -> bool:
	return _valida


## Chamado pelo provedor no fim do passo ou na troca de contexto.
func invalidar() -> void:
	_valida = false
