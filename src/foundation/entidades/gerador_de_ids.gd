## Sequência única de ids de combatente da run (ADR-0003).
##
## Um só gerador por run, injetado em quem cria combatentes: a IA (inimigos, na
## ordem de surgimento, inclusive em Surgindo) e as Maldições ([code]MaldicaoRef[/code],
## ADR-0017) compartilham o contador, para que eventos, telégrafos e projéteis com
## [code]alvo_id[/code] nunca confundam dois combatentes. Ids nunca se reaproveitam
## na run; [method reiniciar] só na fronteira de nova run.
##
## Exemplo:
## [codeblock]
## var ids := GeradorDeIds.new()
## var inimigo := InimigoRef.new(ids.proximo(), def)
## [/codeblock]
## Não é seguro entre threads.
class_name GeradorDeIds
extends RefCounted

## Id que nunca é gerado (valor de "sem alvo").
const ID_INVALIDO: int = 0
## Primeiro id de cada run.
const PRIMEIRO_ID: int = 1

var _proximo: int = PRIMEIRO_ID


## Devolve um id novo, maior que todos os já gerados nesta run.
func proximo() -> int:
	var id: int = _proximo
	_proximo += 1
	return id


## Recomeça a sequência. Só na criação de uma run nova.
func reiniciar() -> void:
	_proximo = PRIMEIRO_ID
