class_name EscritorPorMaterial
extends EscritorDeGlobais
## Implementação de fallback (Plano B) de `EscritorDeGlobais` (ADR-0011 §3).
## Mantém um registro de `ShaderMaterial` e propaga `set_shader_parameter` em cada material registrado.

var _materiais: Array[ShaderMaterial] = []
var _historico: Dictionary = {}
var _contagem_escritas: Dictionary = {}


func registrar_material(mat: ShaderMaterial) -> void:
	if mat != null and not _materiais.has(mat):
		_materiais.append(mat)


func remover_material(mat: ShaderMaterial) -> void:
	_materiais.erase(mat)


func materiais_registrados() -> int:
	return _materiais.size()


func escrever(nome: StringName, valor: Variant) -> void:
	_historico[nome] = valor
	_contagem_escritas[nome] = int(_contagem_escritas.get(nome, 0)) + 1
	for mat: ShaderMaterial in _materiais:
		if mat != null:
			mat.set_shader_parameter(nome, valor)


func ultimo_valor(nome: StringName) -> Variant:
	return _historico.get(nome, null)


func total_escritas(nome: StringName) -> int:
	return int(_contagem_escritas.get(nome, 0))


func limpar_contadores() -> void:
	_contagem_escritas.clear()
