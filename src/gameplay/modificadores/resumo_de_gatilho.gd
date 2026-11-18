class_name ResumoDeGatilho
extends RefCounted
## Resumo cacheado de um tipo de gatilho no portador (GDD modificadores-e-atributos R11;
## ADR-0009 §5). Montado na reconstrução do cache; somente leitura para o executor.
##
## Exemplo:
## [codeblock]
## var r := portador.gatilhos(&"recusas_morte")
## if r.total > 0.0: ...
## [/codeblock]

## Uma entrada por fonte, em ordem canônica.
class Entrada:
	extends RefCounted
	## Valor do gatilho nesta fonte.
	var valor: float
	## Params do gatilho (somente leitura).
	var params: Dictionary[StringName, float]
	## Id da fonte.
	var fonte: StringName

	func _init(p_valor: float, p_params: Dictionary[StringName, float], p_fonte: StringName) -> void:
		valor = p_valor
		params = p_params
		fonte = p_fonte

## Resumo vazio compartilhado (tipo sem gatilho ativo).
static var _vazio: ResumoDeGatilho = null

## Tipo de efeito.
var tipo: StringName
## Soma dos valores, em ordem canônica.
var total: float = 0.0
## Entradas por fonte, em ordem canônica.
var entradas: Array[Entrada] = []
## Params (iguais entre fontes por V11; os da primeira entrada).
var params: Dictionary[StringName, float] = {}


func _init(p_tipo: StringName = &"") -> void:
	tipo = p_tipo


## Resumo vazio (sem entradas, total 0).
static func vazio() -> ResumoDeGatilho:
	if _vazio == null:
		_vazio = ResumoDeGatilho.new()
		_vazio.entradas.make_read_only()
		_vazio.params.make_read_only()
	return _vazio


## Verdadeiro se nenhuma fonte registra este tipo.
func esta_vazio() -> bool:
	return entradas.is_empty()
