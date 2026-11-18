class_name ManifestoDoCatalogo
extends Resource
## Manifesto único e explícito do catálogo (GDD de Conteúdo R4;
## [code]res://assets/data/content_catalog.tres[/code]). Só o que está aqui existe no
## jogo; não há varredura de pastas em execução. Entradas (tipo, caminho) em listas
## paralelas, na ordem que vale para listar, sortear e imprimir (R10, R10-P, R12).
## Ids de [CurseDef] só crescem no fim (append-only).
##
## Exemplo:
## [codeblock]
## var m := ManifestoDoCatalogo.new()
## m.acrescentar(&"weapon", "res://assets/data/weapon/lamina.tres")
## [/codeblock]

## Tipo de cada entrada (ex.: [code]weapon[/code], [code]enemy[/code], [code]tuning[/code]).
@export var tipos: Array[StringName] = []
## Caminho [code]res://[/code] de cada entrada, na mesma posição de [member tipos].
@export var caminhos: PackedStringArray = PackedStringArray()


## Acrescenta uma entrada no fim.
func acrescentar(tipo: StringName, caminho: String) -> void:
	tipos.append(tipo)
	caminhos.append(caminho)


## Número de entradas válidas (o menor dos dois tamanhos).
func tamanho() -> int:
	return mini(tipos.size(), caminhos.size())
