class_name AdaptadorDeEntradaGodot
extends Node
## Fronteira fina com a engine (GDD input-e-controle R2, R3; ADR-0006 §1). Único lugar que lê `InputEvent`.
##
## Converte cada evento em `DescritorDeEntrada` e reduz tudo a estado limitado: entradas físicas seguradas,
## uma borda por entrada física no intervalo (a primeira), soma dos módulos dos movimentos do mouse, cursor
## válido em px de janela e eixos de cada gamepad. `drenar()` entrega um `Lote` e zera as bordas; quem chama
## é o `ProvedorDeEntrada`, uma vez por passo. Não há `_physics_process`, `Autoload` nem fila de eventos.
##
## `Input.use_accumulated_input` deve ser desativado no ponto de composição (Main), não aqui.

## Uma borda de subida no intervalo entre duas amostras.
class Borda extends RefCounted:
	## Entrada física que subiu.
	var descritor: DescritorDeEntrada
	## Ordem de chegada (crescente na sessão).
	var ordem: int
	## Posição de janela no instante do aperto (cliques); só vale se `tem_posicao`.
	var posicao_janela: Vector2
	## Verdadeiro para cliques com posição registrada.
	var tem_posicao: bool

	func _init(p_descritor: DescritorDeEntrada, p_ordem: int, p_posicao: Vector2 = Vector2.ZERO,
			p_tem_posicao: bool = false) -> void:
		descritor = p_descritor
		ordem = p_ordem
		posicao_janela = p_posicao
		tem_posicao = p_tem_posicao


## Lote reduzido entregue ao provedor a cada passo (valores; o provedor nunca vê `InputEvent`).
class Lote extends RefCounted:
	## Entradas físicas seguradas agora.
	var segurados: Array[DescritorDeEntrada] = []
	## Bordas do intervalo, em ordem de chegada (no máximo uma por entrada física).
	var bordas: Array[Borda] = []
	## Soma de √(dx²+dy²) dos movimentos do mouse no intervalo, em px de tela (F5).
	var deslocamento_mouse: float = 0.0
	## Houve qualquer movimento de mouse no intervalo.
	var mouse_moveu: bool = false
	## Última posição válida do cursor, em px de janela.
	var cursor_janela: Vector2 = Vector2.ZERO
	## Falso até o cursor ter uma posição válida.
	var tem_cursor: bool = false
	## Eixos brutos por gamepad: id → Vector4(lx, ly, rx, ry).
	var analogicos: Dictionary = {}
	## Gamepads com atividade significativa no intervalo: id → ordem da última atividade.
	var gamepads_significativos: Dictionary = {}

	## Ordem da última borda de teclado/mouse no lote; -1 se não houve.
	func ordem_teclado_mouse() -> int:
		var ordem := -1
		for borda: Borda in bordas:
			if borda.descritor.familia() == Acoes.DISPOSITIVO_TECLADO:
				ordem = maxi(ordem, borda.ordem)
		return ordem


## Conversão da posição do evento (espaço do viewport) para px de janela. Injetável pela Cena (ADR-0007).
var conversor_para_janela: Callable = Callable()
## Tamanho da janela em px, para descartar cursor fora dela. Injetável; padrão lê a janela do nó.
var tamanho_janela: Callable = Callable()

var _segurados: Dictionary = {}          # chave_fisica -> DescritorDeEntrada
var _bordas: Dictionary = {}             # chave_fisica -> Borda (a primeira do intervalo)
var _ordem: int = 0
var _deslocamento_mouse: float = 0.0
var _mouse_moveu: bool = false
var _cursor_janela: Vector2 = Vector2.ZERO
var _tem_cursor: bool = false
var _eixos: Dictionary = {}              # id gamepad -> Vector4(lx, ly, rx, ry)
var _pads_significativos: Dictionary = {} # id gamepad -> ordem
var _analogicos_ativos: bool = false
var _zona_morta: float = 0.0
var _gatilho_aperta: float = 0.0
var _gatilho_solta: float = 0.0


## Ativa analógicos e gatilhos com os limiares do `InputTuning` (R12). Sem chamar isto, só botões, teclas,
## cliques e movimento do cursor funcionam (ADR-0006 §4: operação digital sem catálogo).
func configurar_limiares(zona_morta: float, gatilho_aperta: float, gatilho_solta: float) -> void:
	_zona_morta = zona_morta
	_gatilho_aperta = gatilho_aperta
	_gatilho_solta = gatilho_solta
	_analogicos_ativos = true


## Retira os limiares: analógicos e gatilhos param e seus resíduos são limpos.
func retirar_limiares() -> void:
	_analogicos_ativos = false
	_eixos.clear()
	for chave: StringName in _segurados.keys():
		if (_segurados[chave] as DescritorDeEntrada).tipo == DescritorDeEntrada.GATILHO:
			_segurados.erase(chave)


func _input(event: InputEvent) -> void:
	receber_evento(event)


## Reduz um evento da engine ao estado limitado. Público para o teste `[I]` e para a composição.
func receber_evento(event: InputEvent) -> void:
	if event is InputEventKey:
		var tecla := event as InputEventKey
		if tecla.echo:
			return
		var codigo: int = tecla.physical_keycode if tecla.physical_keycode != KEY_NONE else tecla.keycode
		registrar_botao(DescritorDeEntrada.new(DescritorDeEntrada.TECLA_FISICA, codigo, int(tecla.location)),
				tecla.pressed)
	elif event is InputEventMouseMotion:
		var movimento := event as InputEventMouseMotion
		registrar_movimento_mouse(movimento.screen_relative.length())
		registrar_cursor(_para_janela(movimento.position))
	elif event is InputEventMouseButton:
		var botao := event as InputEventMouseButton
		var janela := _para_janela(botao.position)
		registrar_cursor(janela)
		registrar_botao(DescritorDeEntrada.new(DescritorDeEntrada.MOUSE, int(botao.button_index)),
				botao.pressed, janela, true)
	elif event is InputEventJoypadButton:
		var botao_pad := event as InputEventJoypadButton
		registrar_botao(DescritorDeEntrada.new(DescritorDeEntrada.BOTAO_GAMEPAD, int(botao_pad.button_index),
				DescritorDeEntrada.LOCALIZACAO_NENHUMA, botao_pad.device), botao_pad.pressed)
	elif event is InputEventJoypadMotion:
		var eixo := event as InputEventJoypadMotion
		registrar_eixo(eixo.device, int(eixo.axis), eixo.axis_value)


## Registra aperto/soltura de uma entrada física. Aperto de entrada já segurada não gera borda; só a
## primeira borda de cada entrada física no intervalo é guardada (aperto, soltura e aperto = 1 toque).
func registrar_botao(descritor: DescritorDeEntrada, apertado: bool, posicao_janela: Vector2 = Vector2.ZERO,
		tem_posicao: bool = false) -> void:
	var chave := descritor.chave_fisica()
	if not apertado:
		_segurados.erase(chave)
		return
	if _segurados.has(chave):
		return
	_segurados[chave] = descritor
	_ordem += 1
	if descritor.familia() == Acoes.DISPOSITIVO_GAMEPAD:
		_pads_significativos[descritor.dispositivo] = _ordem
	if not _bordas.has(chave):
		_bordas[chave] = Borda.new(descritor, _ordem, posicao_janela, tem_posicao)


## Soma o módulo de um movimento do mouse (px de tela) ao deslocamento do intervalo (F5).
func registrar_movimento_mouse(modulo_px: float) -> void:
	_deslocamento_mouse += modulo_px
	_mouse_moveu = true


## Registra a posição do cursor em px de janela; fora da janela conserva a última válida (Edge Cases).
func registrar_cursor(posicao_janela: Vector2) -> void:
	var tamanho: Vector2 = _tamanho_da_janela()
	if tamanho.x > 0.0 and tamanho.y > 0.0 and not Rect2(Vector2.ZERO, tamanho).has_point(posicao_janela):
		return
	_cursor_janela = posicao_janela
	_tem_cursor = true


## Consulta de cursor (R5): última posição válida em px de janela. Só leitura; não drena nada.
func consultar_cursor() -> Vector2:
	return _cursor_janela


## Registra um eixo de gamepad. Sem limiares configurados, analógicos e gatilhos são ignorados.
func registrar_eixo(dispositivo: int, eixo: int, valor: float) -> void:
	if not _analogicos_ativos:
		return
	if eixo == JOY_AXIS_TRIGGER_LEFT or eixo == JOY_AXIS_TRIGGER_RIGHT:
		var descritor := DescritorDeEntrada.new(DescritorDeEntrada.GATILHO, eixo,
				DescritorDeEntrada.LOCALIZACAO_NENHUMA, dispositivo)
		var segurado := _segurados.has(descritor.chave_fisica())
		# Histerese (R12): aperta em >= aperta; continua apertado enquanto >= solta.
		var abaixo := valor >= _gatilho_solta if segurado else valor >= _gatilho_aperta
		registrar_botao(descritor, abaixo)
		return
	var v: Vector4 = _eixos.get(dispositivo, Vector4.ZERO)
	match eixo:
		JOY_AXIS_LEFT_X: v.x = valor
		JOY_AXIS_LEFT_Y: v.y = valor
		JOY_AXIS_RIGHT_X: v.z = valor
		JOY_AXIS_RIGHT_Y: v.w = valor
		_: return
	_eixos[dispositivo] = v
	if Vector2(v.x, v.y).length() > _zona_morta or Vector2(v.z, v.w).length() > _zona_morta:
		_ordem += 1
		_pads_significativos[dispositivo] = _ordem


## Esquece um gamepad desconectado (eixos e botões dele).
func esquecer_gamepad(dispositivo: int) -> void:
	_eixos.erase(dispositivo)
	_pads_significativos.erase(dispositivo)
	for chave: StringName in _segurados.keys():
		if (_segurados[chave] as DescritorDeEntrada).dispositivo == dispositivo:
			_segurados.erase(chave)


## Solta todo o estado lógico (perda de foco): segurados, bordas, deslocamento e eixos.
func soltar_tudo() -> void:
	_segurados.clear()
	_bordas.clear()
	_eixos.clear()
	_pads_significativos.clear()
	_deslocamento_mouse = 0.0
	_mouse_moveu = false


## Entrega o lote do intervalo e zera bordas, deslocamento e atividade. Segurados e eixos continuam.
func drenar() -> Lote:
	var lote := Lote.new()
	for descritor: DescritorDeEntrada in _segurados.values():
		lote.segurados.append(descritor)
	for borda: Borda in _bordas.values():
		lote.bordas.append(borda)
	lote.bordas.sort_custom(func(a: Borda, b: Borda) -> bool: return a.ordem < b.ordem)
	lote.deslocamento_mouse = _deslocamento_mouse
	lote.mouse_moveu = _mouse_moveu
	lote.cursor_janela = _cursor_janela
	lote.tem_cursor = _tem_cursor
	lote.analogicos = _eixos.duplicate()
	lote.gamepads_significativos = _pads_significativos.duplicate()
	_bordas.clear()
	_pads_significativos.clear()
	_deslocamento_mouse = 0.0
	_mouse_moveu = false
	return lote


func _para_janela(posicao: Vector2) -> Vector2:
	if conversor_para_janela.is_valid():
		return conversor_para_janela.call(posicao)
	# Padrão herdado da fatia (stretch canvas_items com barras): a Cena deve injetar a conversão oficial.
	if not is_inside_tree():
		return posicao
	var logico := get_viewport().get_visible_rect().size
	var janela := Vector2(get_window().size)
	if logico.x <= 0.0 or logico.y <= 0.0 or janela.x <= 0.0 or janela.y <= 0.0:
		return posicao
	var escala := minf(janela.x / logico.x, janela.y / logico.y)
	return posicao * escala + (janela - logico * escala) / 2.0


func _tamanho_da_janela() -> Vector2:
	if tamanho_janela.is_valid():
		return tamanho_janela.call()
	if is_inside_tree():
		return Vector2(get_window().size)
	return Vector2.ZERO
