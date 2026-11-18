class_name ConsumidorDeAjustes
extends RefCounted
## Contrato de consumidor persistente de ajustes do catálogo (GDD de Conteúdo R3, R4;
## ADR-0006 "Sem catálogo"; story 009 AC-06 e AC-51).
## Sistemas que sobrevivem à recarga (ex.: [code]InputPorPasso[/code]) registram um
## consumidor no [CarregadorDeCatalogo]. Na entrada em [code]PRONTO[/code], recebem o
## catálogo publicado; ao sair de [code]PRONTO[/code] (início de recarga ou falha),
## têm seus ajustes revogados antes da primeira leitura.
##
## Exemplo:
## [codeblock]
## class MeuConsumidor extends ConsumidorDeAjustes:
##     var ativo := false
##     func receber_ajustes(_cat: Catalogo) -> void: ativo = true
##     func revogar_ajustes() -> void: ativo = false
## [/codeblock]


## Chamado quando o catálogo entra em [code]PRONTO[/code] (carga inicial ou recarga com 0 erros).
func receber_ajustes(_catalogo: Catalogo) -> void:
	pass


## Chamado imediatamente ao sair de [code]PRONTO[/code] (antes de ler qualquer arquivo na recarga).
func revogar_ajustes() -> void:
	pass
