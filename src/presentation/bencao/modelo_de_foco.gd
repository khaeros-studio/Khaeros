class_name ModeloDeFoco
extends RefCounted
## Modelo autoritativo de foco único compartilhado entre teclado, gamepad e mouse (`ADR-0012 §3`, `story-001`).
## - Sem wrap-around nos extremos da fileira de cartas (`0 .. n-1`).
## - Atalhos `1/2/3` (`carta_direta = 0/1/2`) apenas movem o foco para a carta correspondente, sem confirmar.
## - Mouse parado (`mouse_moveu == false`) nunca rouba o foco inicial.
## - Clique fora do alvo em foco apenas move o foco; clique sobre o alvo já em foco confirma (`clique_confirma = true`).

const ALVO_NENHUM: int = -1
const ALVO_BOTAO_TROCAR: int = 100

class ResultadoFoco extends RefCounted:
	var mudou_foco: bool = false
	var foco_atual: int = 0
	var confirmar_carta: int = -1
	var acionar_trocar: bool = false


var _quantidade_cartas: int = 3
var _tem_botao_trocar: bool = false
var _foco_atual: int = 0
var _retangulos_cartas: Array[Rect2] = []
var _retangulo_trocar: Rect2 = Rect2()


func configurar(
	quantidade_cartas: int,
	foco_inicial: int = -1,
	tem_botao_trocar: bool = false,
	retangulos_cartas: Array[Rect2] = [],
	retangulo_trocar: Rect2 = Rect2()
) -> void:
	_quantidade_cartas = clampi(quantidade_cartas, 1, 3)
	_tem_botao_trocar = tem_botao_trocar
	if foco_inicial >= 0 and foco_inicial < _quantidade_cartas:
		_foco_atual = foco_inicial
	else:
		_foco_atual = foco_inicial_padrao(_quantidade_cartas)
	_retangulos_cartas = retangulos_cartas.duplicate()
	_retangulo_trocar = retangulo_trocar


func foco_atual() -> int:
	return _foco_atual


func definir_foco(novo_foco: int) -> bool:
	if novo_foco == ALVO_BOTAO_TROCAR and _tem_botao_trocar:
		var mudou: bool = (_foco_atual != ALVO_BOTAO_TROCAR)
		_foco_atual = ALVO_BOTAO_TROCAR
		return mudou
	var clamped: int = clampi(novo_foco, 0, _quantidade_cartas - 1)
	var mudou_c: bool = (_foco_atual != clamped)
	_foco_atual = clamped
	return mudou_c


## F2 — Foco inicial padrão da fileira:
## - `n == 3` -> carta central (`1`)
## - `n == 2` -> primeira carta (`0`)
## - `n == 1` -> única carta (`0`)
static func foco_inicial_padrao(n: int) -> int:
	if n == 3:
		return 1
	return 0


func processar(cmd: ComandosDeTela, permite_confirmar: bool) -> ResultadoFoco:
	var res: ResultadoFoco = ResultadoFoco.new()
	res.foco_atual = _foco_atual
	if cmd == null:
		return res

	var anterior: int = _foco_atual

	# 1. Atalhos 1/2/3 apenas movem o foco (nunca confirmam)
	if cmd.carta_direta >= 0 and cmd.carta_direta < _quantidade_cartas:
		_foco_atual = cmd.carta_direta

	# 2. Navegação direcional sem wrap-around na fileira de cartas
	if cmd.navegar.x != 0 and _foco_atual != ALVO_BOTAO_TROCAR:
		var passo: int = 1 if cmd.navegar.x > 0 else -1
		_foco_atual = clampi(_foco_atual + passo, 0, _quantidade_cartas - 1)
	if cmd.navegar.y > 0 and _tem_botao_trocar and _foco_atual != ALVO_BOTAO_TROCAR:
		_foco_atual = ALVO_BOTAO_TROCAR
	elif cmd.navegar.y < 0 and _foco_atual == ALVO_BOTAO_TROCAR:
		_foco_atual = foco_inicial_padrao(_quantidade_cartas)

	# 3. Movimento explícito do mouse atualiza foco se estiver sobre um alvo
	if cmd.mouse_moveu:
		var alvo_hover: int = _alvo_em_ponto(cmd.cursor_pos)
		if alvo_hover != ALVO_NENHUM:
			_foco_atual = alvo_hover

	# 4. Clique do mouse: se clicar fora do foco, apenas move o foco; se clicar no foco, confirma
	if cmd.clicou:
		var alvo_clique: int = _alvo_em_ponto(cmd.clique_pos)
		if alvo_clique != ALVO_NENHUM:
			if alvo_clique != _foco_atual:
				_foco_atual = alvo_clique
			elif permite_confirmar and cmd.aperto_apos_abertura:
				if _foco_atual == ALVO_BOTAO_TROCAR:
					res.acionar_trocar = true
				else:
					res.confirmar_carta = _foco_atual

	# 5. Tecla/botão de trocar (R) tem precedência sobre aceitar no mesmo passo
	if permite_confirmar and cmd.aperto_apos_abertura:
		if cmd.trocar and _tem_botao_trocar:
			res.acionar_trocar = true
		elif cmd.aceitar and not res.acionar_trocar and res.confirmar_carta < 0:
			if _foco_atual == ALVO_BOTAO_TROCAR:
				res.acionar_trocar = true
			elif _foco_atual >= 0 and _foco_atual < _quantidade_cartas:
				res.confirmar_carta = _foco_atual

	res.foco_atual = _foco_atual
	res.mudou_foco = (_foco_atual != anterior)
	return res


func _alvo_em_ponto(ponto: Vector2) -> int:
	for i: int in range(mini(_quantidade_cartas, _retangulos_cartas.size())):
		if _retangulos_cartas[i].has_point(ponto):
			return i
	if _tem_botao_trocar and _retangulo_trocar.size != Vector2.ZERO and _retangulo_trocar.has_point(ponto):
		return ALVO_BOTAO_TROCAR
	return ALVO_NENHUM
