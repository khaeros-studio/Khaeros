class_name VerificadorDeArte
extends RefCounted
## Existência de arte importada para a V7 (GDD de Conteúdo R9). Usa
## [code]ResourceLoader.exists[/code], que enxerga o recurso importado no export
## ([code]FileAccess.file_exists[/code] não serve). Substituível por dublê nos testes.
##
## Exemplo:
## [codeblock]
## var ok := VerificadorDeArte.new().existe("res://assets/art/export/icone.png")
## [/codeblock]


## O recurso de arte existe.
func existe(caminho: String) -> bool:
	return ResourceLoader.exists(caminho) or FileAccess.file_exists(caminho)
