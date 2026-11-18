## Base de todo evento do passo (ADR-0002).
##
## Cada tipo de evento é uma subclasse com campos definidos no construtor e
## **imutáveis depois de emitidos** — convenção (o GDScript não tem campo
## somente leitura), garantida por revisão e pelo teste de convenção em
## [code]tests/unit/orquestrador/eventos_do_passo_test.gd[/code].
##
## O payload guarda só dados (valores e ids inteiros do ADR-0003): nunca [Node],
## nunca referência viva a combatente, ao [EventosDoPasso], ao emissor ou a outro
## evento — [RefCounted] não tem coletor de ciclos.
##
## Exemplo de subclasse (em 4.7 o override tipado exige [code]return[/code] explícito
## e mantém o tipo herdado):
## [codeblock]
## class_name EvInimigoMorreu extends EventoDoPasso
## const TIPO: StringName = &"inimigo_morreu"
## var alvo_id: int
## func _init(p_alvo_id: int) -> void:
##     alvo_id = p_alvo_id
## func tipo() -> StringName:
##     return TIPO
## [/codeblock]
## Leitura por um módulo de regra (downcast antes de ler campos):
## [codeblock]
## for e: EventoDoPasso in eventos.do_tipo(EvInimigoMorreu.TIPO):
##     var m := e as EvInimigoMorreu
##     print(m.alvo_id)
## [/codeblock]
@abstract
class_name EventoDoPasso
extends RefCounted

## Valor de [member n_passo] antes de o evento ser emitido.
const N_PASSO_NAO_EMITIDO: int = -1

## Número do [code]passo_fisico()[/code] (base 0, contado pelo canal) em cuja entrega
## o evento sai. Preenchido só por [method EventosDoPasso.emitir]; somente leitura
## por convenção. Um evento de UI emitido entre dois passos recebe o número do
## passo seguinte, que é quando ele é entregue.
var n_passo: int = N_PASSO_NAO_EMITIDO


## Identificador estável do tipo do evento (o contrato com Telemetria, Áudio e testes).
## Cada subclasse devolve a própria constante [code]TIPO[/code].
@abstract func tipo() -> StringName
