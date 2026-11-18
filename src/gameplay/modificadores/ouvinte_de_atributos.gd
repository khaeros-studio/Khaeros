@abstract
class_name OuvinteDeAtributos
extends RefCounted
## Aviso síncrono de mudança de atributo ligado a recurso (GDD modificadores-e-atributos
## R9; ADR-0009 §6). O [Portador] chama uma vez por atributo inteiro que mudou, na ordem
## de [constant Atributos.INTEIROS], ao fim da reconstrução. Nunca sinal do Godot.
## O Main compõe o despachante (Combate: F4, escudo, recusas; Bênçãos: trocas).
##
## Exemplo:
## [codeblock]
## class Espiao extends OuvinteDeAtributos:
##     var chamadas := 0
##     func atributo_mudou(_i: int, _p: int, _a: StringName, _v0: int, _v1: int) -> void:
##         chamadas += 1
## [/codeblock]


## [param antigo]/[param novo]: valores inteiros do atributo antes e depois.
@abstract func atributo_mudou(id_combatente: int, player_id: int, atributo: StringName, antigo: int, novo: int) -> void
