@abstract
class_name ValidadorDeRegra
extends RefCounted
## Contrato de um validador de uma regra (V1, V2, ...): recebe os itens lidos do
## manifesto e devolve diagnósticos. Composto pelo [ValidadorDeCatalogo].
##
## Exemplo:
## [codeblock]
## var diags := V8Pesos.new().validar(itens)
## [/codeblock]


## Diagnósticos da regra para os itens (vazio = passou).
@abstract func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]


## Rótulo "Classe id" de um item, para mensagens.
static func rotulo(item: ItemDoCatalogo) -> String:
	return "%s %s" % [item.definicao.nome_da_classe(), item.definicao.id]


## Valores de um campo como lista (escalar, Array, Packed*Array ou chaves de Dictionary).
static func como_lista(valor: Variant, chaves_do_dicionario: bool = true) -> Array:
	if valor is Dictionary:
		var d: Dictionary = valor
		return d.keys() if chaves_do_dicionario else d.values()
	if valor is Array:
		return valor
	if typeof(valor) >= TYPE_PACKED_BYTE_ARRAY and typeof(valor) <= TYPE_PACKED_VECTOR4_ARRAY:
		return Array(valor)
	return [valor]
