## Eventos tipados da fatia jogável (story orquestrador-007; ADR-0002 §Migration Plan).
## Substituem o [code]Array[String][/code] que [code]GameSession.step()[/code] devolvia como canal:
## o adaptador do passo emite estas subclasses de [EventoDoPasso] na lista do passo, e a
## Apresentação as lê da lista entregue no final comum. São transitórios: cada fato migra para
## o evento definitivo do catálogo do ADR-0002 quando o módulo dono (Combate, Movimento) existir.
##
## Exemplo:
## [codeblock]
## eventos.emitir(EventosDaFatia.EvComandoExecutado.new(&"ataque"))
## for ev: EventoDoPasso in lote:
##     if ev is EventosDaFatia.EvGolpeSentido:
##         camera.impulse(ev.direcao, ev.intensidade)
## [/codeblock]
class_name EventosDaFatia
extends RefCounted


## Um comando de jogo executado neste passo ([code]esquiva[/code], [code]ataque[/code],
## [code]especial[/code]); antes era um texto do retorno de [code]step()[/code].
class EvComandoExecutado extends EventoDoPasso:
	## Tipo do evento no canal.
	const TIPO: StringName = &"comando_executado"
	## Ação do Input consumida pelo passo.
	var acao: StringName

	func _init(p_acao: StringName) -> void:
		acao = p_acao

	## Tipo do evento no canal.
	func tipo() -> StringName:
		return TIPO


## O passo feriu alguém: o jogador ([code]jogador_ferido = true[/code]) ou ao menos um inimigo.
## A Apresentação (Feedback) traduz em impulso de câmera; a regra não chama a câmera.
class EvGolpeSentido extends EventoDoPasso:
	## Tipo do evento no canal.
	const TIPO: StringName = &"golpe_sentido"
	## [code]true[/code] se o jogador perdeu vida neste passo.
	var jogador_ferido: bool
	## Direção da mira no passo (unitária ou zero).
	var direcao: Vector2

	func _init(p_jogador_ferido: bool, p_direcao: Vector2) -> void:
		jogador_ferido = p_jogador_ferido
		direcao = p_direcao

	## Tipo do evento no canal.
	func tipo() -> StringName:
		return TIPO
