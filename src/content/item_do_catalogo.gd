class_name ItemDoCatalogo
extends RefCounted
## Uma definição lida do manifesto, com o contexto que a validação precisa: tipo,
## caminho, posição no manifesto e, quando a etapa de preparo a conhece, a lista de
## campos efetivamente gravados no arquivo (campo ausente × default do script).
##
## Exemplo:
## [codeblock]
## var item := ItemDoCatalogo.new(&"enemy", "res://assets/data/enemy/eco_perdido.tres", 0, def)
## item.definir_campos_gravados(PackedStringArray(["id", "vida"]))
## [/codeblock]

var tipo: StringName
var caminho: String
var posicao: int
var definicao: DefinicaoBase
## [code]true[/code] quando [member campos_gravados] veio do arquivo de origem.
var presenca_conhecida: bool = false
var campos_gravados: PackedStringArray = PackedStringArray()


func _init(p_tipo: StringName, p_caminho: String, p_posicao: int, p_definicao: DefinicaoBase) -> void:
	tipo = p_tipo
	caminho = p_caminho
	posicao = p_posicao
	definicao = p_definicao


## Informa os campos gravados no arquivo de origem (etapa de preparo).
func definir_campos_gravados(campos: PackedStringArray) -> void:
	campos_gravados = campos
	presenca_conhecida = true
