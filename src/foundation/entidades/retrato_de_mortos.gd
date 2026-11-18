## Retrato para a varredura de mortes (ADR-0003; Combate R14).
##
## Cada passe da varredura começa com uma cópia ordenada (ordem da lista viva =
## ordem de surgimento = ordem de id) dos inimigos com Vida ≤ 0. Mortes geradas
## durante o passe não entram no retrato em curso, só no do passe seguinte; a
## lista viva pode ser alterada (remoção pela IA) sem afetar o retrato.
##
## Exemplo:
## [codeblock]
## var mortos := RetratoDeMortos.retrato_de_mortos(inimigos)
## while not mortos.is_empty():
##     for m: InimigoRef in mortos:
##         ia.remover(m.id)
##     mortos = RetratoDeMortos.retrato_de_mortos(inimigos)
## [/codeblock]
class_name RetratoDeMortos
extends RefCounted


## Cópia nova, na ordem de [param lista], dos inimigos com [member InimigoRef.vida] ≤ 0.
static func retrato_de_mortos(lista: Array[InimigoRef]) -> Array[InimigoRef]:
	var r: Array[InimigoRef] = []
	for i: InimigoRef in lista:
		if i.vida <= 0.0:
			r.append(i)
	return r
