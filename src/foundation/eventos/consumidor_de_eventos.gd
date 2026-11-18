## Contrato de um consumidor da Apresentação (ADR-0002): Telemetria, HUD,
## Feedback, Telas e Áudio, entregues nesta ordem fixa registrada pelo [code]Main[/code].
##
## O consumidor é somente leitura: nunca chama [method EventosDoPasso.emitir]
## (há [code]assert[/code] em debug), nunca escreve em estado de jogo e nunca
## guarda o evento nem o array além do passo — copia os valores de que precisa.
## O array recebido é somente leitura ([method Array.make_read_only]).
##
## Exemplo:
## [codeblock]
## class_name ConsumidorDoHud extends ConsumidorDeEventos
## var _ultimo_dano: float = 0.0
## func consumir(eventos: Array[EventoDoPasso]) -> void:
##     for e: EventoDoPasso in eventos:
##         if e.tipo() == &"jogador_atingido":
##             _ultimo_dano = (e as EvJogadorAtingido).dano
## [/codeblock]
## Não é seguro entre threads: chamado só pela thread principal, no fim do passo.
@abstract
class_name ConsumidorDeEventos
extends RefCounted


## Recebe a lista esvaziada do passo, inclusive vazia e inclusive fora de [code]JOGO[/code].
@abstract func consumir(eventos: Array[EventoDoPasso]) -> void
