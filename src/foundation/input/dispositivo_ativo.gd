class_name DispositivoAtivo
extends RefCounted
## Dispositivo ativo (GDD input-e-controle R3, F5; ADR-0006 §4): o último com entrada significativa.
##
## - Teclado/mouse significativo: tecla ou clique, ou deslocamento do mouse no passo ≥ `L_mouse` (px de tela).
## - Gamepad significativo: botão ou analógico fora da zona morta (decidido pelo adaptador, com ordem).
## - Os dois no mesmo passo: conserva o dispositivo atual.
## - Entre gamepads: vence o último significativo na ordem de recebimento (proposta técnica a validar).
##   O id do gamepad corrente acompanha esse desempate mesmo quando o teclado vence o passo, para que dados
##   de gamepads distintos nunca sejam somados.

## `teclado` (inclui o mouse) ou `gamepad`.
var atual: StringName = Acoes.DISPOSITIVO_TECLADO
## Id do gamepad corrente; -1 enquanto nenhum foi usado.
var gamepad: int = -1


## Atualiza com a atividade de um passo. `gamepads_significativos`: id → ordem da última atividade.
func atualizar(teclado_mouse_significativo: bool, gamepads_significativos: Dictionary) -> void:
	var pad_significativo := not gamepads_significativos.is_empty()
	if pad_significativo:
		var melhor_ordem := -1
		for id: int in gamepads_significativos:
			var ordem: int = gamepads_significativos[id]
			if ordem > melhor_ordem:
				melhor_ordem = ordem
				gamepad = id
	if teclado_mouse_significativo and pad_significativo:
		return
	if teclado_mouse_significativo:
		atual = Acoes.DISPOSITIVO_TECLADO
	elif pad_significativo:
		atual = Acoes.DISPOSITIVO_GAMEPAD


## F5: deslocamento total do mouse no passo é significativo quando ≥ limiar.
static func mouse_significativo(deslocamento_px: float, limiar_px: float) -> bool:
	return deslocamento_px >= limiar_px


## Esquece o gamepad corrente (desconexão); o dispositivo ativo não muda aqui.
func esquecer_gamepad(id: int) -> void:
	if gamepad == id:
		gamepad = -1
