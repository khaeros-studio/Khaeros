## Evento [code]passo_vivo[/code] (ADR-0002, catálogo; TR-telemetria-003).
##
## Emitido pelo orquestrador no item 1, só em estado [code]JOGO[/code]. Conta
## passos vivos: não conta Pausa, Bênção nem Transição; conta hitstop.
##
## Exemplo:
## [codeblock]
## eventos.emitir(EvPassoVivo.new(n_vivos))
## [/codeblock]
class_name EvPassoVivo
extends EventoDoPasso

## Contrato do tipo.
const TIPO: StringName = &"passo_vivo"

## Número do passo vivo (contador do orquestrador). Somente leitura por convenção.
var n_vivo: int


## [param p_n_vivo]: valor do contador de passos vivos do orquestrador.
func _init(p_n_vivo: int) -> void:
	n_vivo = p_n_vivo


## Devolve [constant TIPO].
func tipo() -> StringName:
	return TIPO
