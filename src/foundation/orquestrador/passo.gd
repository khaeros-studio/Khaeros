## Contrato de um módulo do passo vivo (architecture.md, API 1; ADR-0001).
##
## O orquestrador chama [method passo] só em [code]EstadoDeJogo.Valor.JOGO[/code], no
## máximo uma vez por [code]passo_fisico()[/code], na ordem de [OrdemDoPasso].
## [method passo_congelado] é chamado no hitstop e fora de [code]JOGO[/code] — hoje só o
## do Movimento (Movimento R2). Os dois retornam [code]void[/code]; em 4.7 um override com
## retorno não-void exigiria [code]return[/code] explícito.
##
## Como o GDScript tem herança única, um módulo que já estende outra base expõe
## [Passo] por um adaptador (ex.: os itens 3/5/8/9 do Combate, ADR-0010).
##
## Exemplo:
## [codeblock]
## class_name PassoDoSelo extends Passo
## var _selo: ModuloDoSelo
## func _init(selo: ModuloDoSelo) -> void:
##     _selo = selo
## func passo(amostra: AmostraDeEntrada) -> void:
##     _selo.passo(amostra)
## [/codeblock]
## Invariante: nenhum módulo lê [code]Input[/code], [code]Engine.time_scale[/code], [code]Time[/code]
## nem [code]OS[/code]. Não é seguro entre threads (só a thread principal).
@abstract
class_name Passo
extends RefCounted


## Item do passo vivo. [param amostra]: entrada do passo, somente leitura.
@abstract func passo(amostra: AmostraDeEntrada) -> void


## Passo congelado (hitstop ou fora de [code]JOGO[/code]): anterior = atual. Padrão: nada.
func passo_congelado() -> void:
	pass
