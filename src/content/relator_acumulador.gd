class_name RelatorAcumulador
extends RelatorDeErros
## Relator dos testes (GDD de Conteúdo R10, AC-21): só acumula as entradas, sem
## [code]push_error[/code] nem [code]assert[/code].
##
## Exemplo:
## [codeblock]
## var r := RelatorAcumulador.new()
## r.relatar(RelatorDeErros.Entrada.new(&"enemy", &"x", "teste"))
## assert(r.entradas.size() == 1)
## [/codeblock]

## Entradas recebidas, na ordem.
var entradas: Array[RelatorDeErros.Entrada] = []


func relatar(entrada: RelatorDeErros.Entrada) -> void:
	entradas.append(entrada)
