class_name EscritorGlobalRS
extends EscritorDeGlobais
## Implementação primária de `EscritorDeGlobais` via `RenderingServer.global_shader_parameter_set`
## (ADR-0011 §3, verificado em EX-0001-3 e EX-0011-E2).

var _historico: Dictionary = {}
var _contagem_escritas: Dictionary = {}


func escrever(nome: StringName, valor: Variant) -> void:
	_historico[nome] = valor
	_contagem_escritas[nome] = int(_contagem_escritas.get(nome, 0)) + 1
	RenderingServer.global_shader_parameter_set(nome, valor)


func ultimo_valor(nome: StringName) -> Variant:
	return _historico.get(nome, null)


func total_escritas(nome: StringName) -> int:
	return int(_contagem_escritas.get(nome, 0))


func limpar_contadores() -> void:
	_contagem_escritas.clear()
