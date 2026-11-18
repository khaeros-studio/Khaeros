@abstract
class_name ConsultaDeAtributos
extends RefCounted
## O que os consumidores recebem por injeção (GDD modificadores-e-atributos R11; ADR-0009).
## Leitura O(1)/O(k ≤ 3), sem recálculo. Implementação: [Portador].
##
## Exemplo:
## [codeblock]
## func _init(consulta: ConsultaDeAtributos) -> void:
##     _velocidade = consulta.valor(Atributos.VELOCIDADE)
## [/codeblock]


## Valor F1 de um atributo derivado (inteiros devolvem o float do inteiro).
## Acumuladores [code]dano_*[/code] são erro: use [method multiplicador_de_dano].
@abstract func valor(atributo: StringName) -> float

## Valor inteiro de um dos 5 inteiros por natureza (AC-05).
@abstract func inteiro(atributo: StringName) -> int

## F2 no disparo; o 4º acerto e o teto entram em [method DanoCongelado.m_no_impacto].
@abstract func congelar_dano(slot: Modificador.Slot, ctx: ContextoDeDano) -> DanoCongelado

## F2 de um tempo só (sem 4º acerto), já com teto.
@abstract func multiplicador_de_dano(slot: Modificador.Slot, ctx: ContextoDeDano) -> float

## Resumo cacheado de um tipo de gatilho.
@abstract func gatilhos(tipo: StringName) -> ResumoDeGatilho
