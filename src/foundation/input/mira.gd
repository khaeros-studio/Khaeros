class_name Mira
extends RefCounted
## Mira do passo (GDD input-e-controle R5, F4, R1b; ADR-0006 §4). Lógica pura: recebe valores já
## convertidos (cursor em mundo, alvos por valor em ordem estável de spawn) e guarda só a última mira.
##
## Resultado de `calcular`: `mirar` (unitário), `fonte_mira`, `intensidade_mira` e `ponto_mira`/`tem_ponto_mira`.

## Mira inicial e de último recurso (critério 5).
const MIRA_PADRAO := Vector2(0.0, -1.0)

## Mira do passo, sempre unitária.
var mirar: Vector2 = MIRA_PADRAO
## Fonte da mira (`AmostraDeEntrada.FONTE_*`).
var fonte_mira: StringName = AmostraDeEntrada.FONTE_AUTOMATICA
## Intensidade do analógico direito (só com fonte `analogico`).
var intensidade_mira: float = 0.0
## Ponto de mira em mundo (válido se `tem_ponto_mira`).
var ponto_mira: Vector2 = Vector2.ZERO
## Falso = ponto vazio.
var tem_ponto_mira: bool = false


## Mira do mouse: vetor do personagem até o cursor em mundo. Cursor sobre o personagem conserva a mira
## anterior. `tem_cursor` falso (nunca houve posição válida) também conserva e deixa o ponto vazio.
func calcular_mouse(cursor_mundo: Vector2, tem_cursor: bool, pos_jogador: Vector2) -> void:
	fonte_mira = AmostraDeEntrada.FONTE_MOUSE
	intensidade_mira = 0.0
	tem_ponto_mira = tem_cursor
	ponto_mira = cursor_mundo if tem_cursor else Vector2.ZERO
	if not tem_cursor:
		return
	var delta := cursor_mundo - pos_jogador
	if delta != Vector2.ZERO:
		mirar = delta.normalized()


## Mira do gamepad (F4, critérios 1–5). `analogico_direito` já passou por F2. `alvos`: Array de
## `{pos: Vector2, surgindo: bool}` em ordem estável. `raio_px` é inclusivo.
func calcular_gamepad(analogico_direito: Vector2, alvos: Array, pos_jogador: Vector2, raio_px: float,
		mover: Vector2, olhar: Vector2) -> void:
	if analogico_direito != Vector2.ZERO:
		fonte_mira = AmostraDeEntrada.FONTE_ANALOGICO
		intensidade_mira = analogico_direito.length()
		mirar = analogico_direito.normalized()
		tem_ponto_mira = false
		ponto_mira = Vector2.ZERO
		return
	fonte_mira = AmostraDeEntrada.FONTE_AUTOMATICA
	intensidade_mira = 0.0
	tem_ponto_mira = false
	ponto_mira = Vector2.ZERO
	var indice := alvo_mais_proximo(alvos, pos_jogador, raio_px)
	if indice >= 0:
		var pos_alvo: Vector2 = (alvos[indice] as Dictionary)["pos"]
		mirar = (pos_alvo - pos_jogador).normalized()
		ponto_mira = pos_alvo
		tem_ponto_mira = true
	elif mover != Vector2.ZERO:
		mirar = mover.normalized()
	elif olhar != Vector2.ZERO:
		mirar = olhar.normalized()
	else:
		mirar = MIRA_PADRAO


## F4 critério 2: índice do alvo de menor d² com 0 < d² ≤ R², ignorando os que estão surgindo; empate
## exato mantém o primeiro da lista. −1 se nenhum.
static func alvo_mais_proximo(alvos: Array, pos_jogador: Vector2, raio_px: float) -> int:
	var raio2 := raio_px * raio_px
	var melhor := -1
	var melhor_d2 := 0.0
	for i: int in alvos.size():
		var alvo: Dictionary = alvos[i]
		if bool(alvo.get("surgindo", false)):
			continue
		var d2 := ((alvo["pos"] as Vector2) - pos_jogador).length_squared()
		if d2 <= 0.0 or d2 > raio2:
			continue
		if melhor < 0 or d2 < melhor_d2:
			melhor = i
			melhor_d2 = d2
	return melhor
