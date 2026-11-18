## Parte do Combate que o orquestrador consulta no item 2 (ADR-0001 decisão 4; ADR-0010 §5).
##
## O contador de hitstop é do Combate (R10). O orquestrador só consulta
## [method hitstop_ativo] uma vez por passo em [code]JOGO[/code] e, se ativo, chama
## [method passo_congelado_do_combate] (desconta 1). Um pedido de hitstop feito no
## passo s só passa a valer no item 2 do passo s+1.
##
## Exemplo:
## [codeblock]
## class_name HitstopDoCombate extends ControleDeHitstop
## var _combate: ModuloDeCombate
## func hitstop_ativo() -> bool:
##     return _combate.hitstop_ativo()
## func passo_congelado_do_combate() -> void:
##     _combate.passo_congelado_do_combate()
## [/codeblock]
## Não é seguro entre threads.
@abstract
class_name ControleDeHitstop
extends RefCounted


## [code]true[/code] se o passo corrente é congelado por hitstop.
@abstract func hitstop_ativo() -> bool


## Desconta 1 do hitstop (item 2, passo congelado em [code]JOGO[/code]).
@abstract func passo_congelado_do_combate() -> void
