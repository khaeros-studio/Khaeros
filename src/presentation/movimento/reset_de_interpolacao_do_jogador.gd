class_name ResetDeInterpolacaoDoJogador
extends Node
## Nó de apresentação que reseta a interpolação do jogador no teleporte (GDD movimento-e-esquiva R1;
## Cena R7; ADR-0007 "reset no teleporte", ADR-0008 §2). Lê a consulta por valor
## [method MovimentoDoJogador.contador_teleportes] e, quando ela muda, chama
## [code]reset_physics_interpolation()[/code] no [member alvo] — depois de a posição já ter sido atribuída
## (ADR-0007, verificação de 2026-11-16). A lógica do Movimento nunca chama a engine.
##
## Exemplo:
## [codeblock]
## var r := ResetDeInterpolacaoDoJogador.new()
## r.configurar(movimento, sprite_do_jogador)
## add_child(r)   # sincroniza em _physics_process, depois do passo
## [/codeblock]

## Emitido logo depois de cada reset (telemetria/testes).
signal interpolacao_resetada

## Nó visual do jogador cujo histórico de interpolação é descartado.
var alvo: Node = null
var _movimento: MovimentoDoJogador = null
var _visto: int = 0


## Liga ao Movimento e ao nó visual; teleportes anteriores não disparam reset.
func configurar(movimento: MovimentoDoJogador, p_alvo: Node) -> void:
	_movimento = movimento
	alvo = p_alvo
	_visto = movimento.contador_teleportes()


## Confere a consulta e reseta uma vez por teleporte novo. Devolve verdadeiro se resetou.
func sincronizar() -> bool:
	if _movimento == null or alvo == null:
		return false
	var atual := _movimento.contador_teleportes()
	if atual == _visto:
		return false
	_visto = atual
	alvo.reset_physics_interpolation()
	interpolacao_resetada.emit()
	return true


func _physics_process(_delta: float) -> void:
	sincronizar()
