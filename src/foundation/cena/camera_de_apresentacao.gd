class_name CameraDeApresentacao
extends ConversorTelaMundo
## Câmera própria de apresentação (ADR-0007; GDD Cena R6–R12, F2–F6).
##
## Lógica pura em `RefCounted`: não lê dispositivos, relógio de parede nem árvore.
## Guarda as duas bases (`pos` para a mira, `pos_seguir` sem lookahead), os
## impulsos e a época da câmara. O relógio é `t_apres`, injetado em cada
## `EntradaCamera`. Substitui `src/presentation/game_camera.gd` (fatia de 2026-11-14).
##
## Contrato duck-typed do `CameraTuning` (esquema do épico Conteúdo), lido por
## `Object.get` em `configurar_tuning`: `meia_vida`, `lookahead_max`, `raio_mouse`,
## `teto_deslocamento`, `teto_zoom`, `limiar_descarte`, `max_impulsos` e
## `presets_impulso` (Dictionary nome → objeto com `meia_vida`, `chute`, `tremor`, `zoom`).
##
## Exemplo:
## [codeblock]
## var cam := CameraDeApresentacao.new()
## cam.configurar_tuning(catalogo.camera_tuning)
## cam.definir_geometria(GeometriaDeViewport.calcular(janela.size))
## cam.cortar(CorteDeCamera.new(1, camara.jogavel, camara.sangria, camara.spawn, entrada))
## var visual := cam.atualizar_quadro(entrada)   # a cada render
## var mundo := cam.tela_para_mundo(cursor_janela) # Input, último render
## [/codeblock]

## Câmera base da mira (F3 sobre o alvo com lookahead), sem impulsos.
var pos: Vector2:
	get: return _pos
## Câmera base sem lookahead (usada só no cálculo do lookahead).
var pos_seguir: Vector2:
	get: return _pos_seguir
## Época da câmara atual (−1 antes do primeiro corte).
var epoca: int:
	get: return _epoca
## Estado da máquina (`EstadosDaCamera.Estado`).
var estado: EstadosDaCamera.Estado:
	get: return _estados.atual
## Geometria vigente.
var geometria: GeometriaDeViewport:
	get: return _geo
## Último diagnóstico de impulso rejeitado.
var diagnostico_impulso: String:
	get: return _diag

var _geo: GeometriaDeViewport = GeometriaDeViewport.calcular(
	Vector2i(int(GeometriaDeViewport.LARGURA_BASE), int(GeometriaDeViewport.ALTURA_LOGICA)))
var _snap_geo: GeometriaDeViewport = _geo
var _snap_pos: Vector2 = Vector2.ZERO
var _jogavel: Rect2 = Rect2()
var _sangria: float = 0.0
var _pos: Vector2 = Vector2.ZERO
var _pos_seguir: Vector2 = Vector2.ZERO
var _epoca: int = -1
var _epoca_relogio: int = -1
var _t_anterior: float = 0.0
var _t_atual: float = 0.0
var _t_valido: bool = false
var _corte_no_quadro: bool = false
var _estados: EstadosDaCamera = EstadosDaCamera.new()
var _impulsos: ImpulsosDeCamera = ImpulsosDeCamera.new()
var _diag: String = ""
# Tuning (ausente => câmera congelada, impulsos descartados, lookahead zero).
var _tem_tuning: bool = false
var _meia_vida: float = 1.0
var _lookahead_max: float = 0.0
var _raio_mouse: float = 1.0
var _teto_zoom: float = 1.0


## Instala o `CameraTuning` validado; `null` retira (congela as bases e limpa impulsos).
func configurar_tuning(tuning: Resource) -> void:
	_impulsos.limpar()
	if tuning == null:
		_tem_tuning = false
		return
	_meia_vida = float(tuning.get(&"meia_vida"))
	_lookahead_max = float(tuning.get(&"lookahead_max"))
	_raio_mouse = float(tuning.get(&"raio_mouse"))
	_teto_zoom = float(tuning.get(&"teto_zoom"))
	var presets: Dictionary[StringName, ImpulsosDeCamera.Preset] = {}
	var fonte: Dictionary = tuning.get(&"presets_impulso")
	for nome: Variant in fonte:
		var p: Object = fonte[nome]
		presets[StringName(nome)] = ImpulsosDeCamera.Preset.new(
			float(p.get(&"meia_vida")), float(p.get(&"chute")), float(p.get(&"tremor")), float(p.get(&"zoom")))
	_impulsos.configurar(presets, float(tuning.get(&"teto_deslocamento")), _teto_zoom,
		float(tuning.get(&"limiar_descarte")), int(tuning.get(&"max_impulsos")))
	_tem_tuning = true


## Injeta o ruído cosmético `func(indice: int) -> Vector2` (gerador da Apresentação).
func injetar_ruido(ruido: Callable) -> void:
	_impulsos.injetar_ruido(ruido)


## Publica uma geometria nova (resize). Prende as duas bases pela F4 já com o novo
## W, sem suavização, inclusive em Pausa, e atualiza o instantâneo do Input.
## `null` (janela minimizada) ou a mesma geometria: nada muda (idempotente).
func definir_geometria(nova: GeometriaDeViewport) -> void:
	if nova == null or nova == _geo:
		return
	_geo = nova
	_pos = _prender(_pos)
	_pos_seguir = _prender(_pos_seguir)
	_publicar_snapshot()


## Muda o estado da câmera (Pausa, Bênção, Morte, Transição, Intro de chefe…).
## Entrar num estado congelado limpa os impulsos. Devolve `false` se a transição
## não é permitida.
func mudar_estado(novo: EstadosDaCamera.Estado) -> bool:
	if not _estados.entrar(novo):
		return false
	if _estados.congelada():
		_impulsos.limpar()
	return true


## Sai da Pausa (ou do Corte) para o estado de retorno.
func retomar() -> void:
	_estados.retomar()


## Recebe um impulso do Feedback. Rejeita sem tuning, fora de Seguindo/Intro de
## chefe, de outra época ou inválido; o diagnóstico fica em `diagnostico_impulso`.
func receber_impulso(pedido: PedidoImpulso) -> bool:
	if not _tem_tuning:
		_diag = "sem CameraTuning"
		return false
	if not _estados.aceita_impulsos():
		_diag = "estado %s descarta impulsos" % EstadosDaCamera.Estado.keys()[_estados.atual]
		return false
	var ok := _impulsos.receber(pedido, _epoca, _t_atual)
	_diag = _impulsos.ultimo_diagnostico
	return ok


## Número de impulsos ativos.
func quantidade_impulsos() -> int:
	return _impulsos.quantidade()


## Corte atômico na troca de câmara (ADR-0007 §7). Um pedido com época já vista
## é ignorado (não teleporta, não limpa, não corta de novo). Devolve `true` se cortou.
func cortar(pedido: CorteDeCamera) -> bool:
	if pedido.epoca <= _epoca:
		return false
	_epoca = pedido.epoca
	_jogavel = pedido.jogavel
	_sangria = pedido.sangria
	var p := pedido.spawn
	_pos_seguir = _prender(p)
	var look := Vector2.ZERO
	if pedido.entrada != null:
		look = _lookahead(pedido.entrada, p)
	_pos = _prender(p + look)
	_impulsos.limpar()
	_estados.entrar(EstadosDaCamera.Estado.CORTE)
	_corte_no_quadro = true
	_publicar_snapshot()
	return true


## Reinicia a base temporal depois do zero de `t_apres` na troca. Aceito só para
## a época atual e uma vez por corte; pedidos repetidos ou antigos são ignorados.
func reiniciar_relogio(p_epoca: int, t_apres: float) -> bool:
	if p_epoca != _epoca or _epoca_relogio == p_epoca:
		return false
	_epoca_relogio = p_epoca
	_t_anterior = t_apres
	_t_atual = t_apres
	_t_valido = true
	return true


## Avança um quadro de render e devolve o resultado visual (ordem F2 → F4 → F3).
func atualizar_quadro(e: EntradaCamera) -> EstadoVisualCamera:
	var dt := maxf(0.0, e.t_apres - _t_anterior) if _t_valido else 0.0
	_t_anterior = e.t_apres
	_t_atual = e.t_apres
	_t_valido = true
	if _estados.atual == EstadosDaCamera.Estado.CORTE:
		if _corte_no_quadro:
			_corte_no_quadro = false
			return _visual(Vector2.ZERO, Vector2.ZERO, 1.0)
		_estados.retomar()
	if _estados.congelada() or not _tem_tuning:
		_impulsos.limpar()
		return _visual(Vector2.ZERO, Vector2.ZERO, 1.0)
	var p := interpolar(e.p_anterior, e.p_atual, e.fracao)
	_pos_seguir = suavizar_f3(_pos_seguir, _prender(p), dt, _meia_vida)
	var look := _lookahead(e, p)
	_pos = suavizar_f3(_pos, _prender(p + look), dt, _meia_vida)
	_publicar_snapshot()
	_impulsos.avaliar(e.t_apres, e.tremor, e.reducao_movimento)
	var zoom_total := 1.0
	if not e.reducao_movimento:
		var zi := e.zoom_intro if _estados.atual == EstadosDaCamera.Estado.INTRO_CHEFE else 1.0
		zoom_total = minf(_teto_zoom, zi * _impulsos.zoom)
	return _visual(look, _impulsos.deslocamento, zoom_total)


## F6 pelo último instantâneo base (pos do último render + geometria vigente).
func tela_para_mundo(cursor_janela: Vector2) -> Vector2:
	return ConversorTelaMundo.converter(cursor_janela, _snap_geo, _snap_pos)


## P = lerp(P_anterior, P_atual, f_i), com f_i preso a [0, 1].
static func interpolar(p_anterior: Vector2, p_atual: Vector2, fracao: float) -> Vector2:
	return p_anterior.lerp(p_atual, clampf(fracao, 0.0, 1.0))


## F2: alvo = P + normaliza(m)·L·a, com normaliza(0) = 0.
static func alvo_f2(p: Vector2, m: Vector2, lookahead_max: float, a: float) -> Vector2:
	if m.length_squared() == 0.0:
		return p
	return p + m.normalized() * lookahead_max * clampf(a, 0.0, 1.0)


## Intensidade do mouse: a = min(1, |m| / R_mouse).
static func intensidade_mouse(m: Vector2, raio_mouse: float) -> float:
	return minf(1.0, m.length() / raio_mouse)


## F3: pos + (alvo − pos)·(1 − 2^(−Δt/h)); independente da fatia de Δt.
static func suavizar_f3(atual: Vector2, alvo: Vector2, dt: float, meia_vida: float) -> Vector2:
	return atual + (alvo - atual) * (1.0 - pow(2.0, -maxf(0.0, dt) / meia_vida))


func _lookahead(e: EntradaCamera, p: Vector2) -> Vector2:
	if not _tem_tuning or e.reducao_movimento:
		return Vector2.ZERO
	match e.fonte_mira:
		EntradaCamera.FonteMira.MOUSE:
			var m := ConversorTelaMundo.converter(e.cursor_janela, _geo, _pos_seguir) - p
			return alvo_f2(p, m, _lookahead_max, intensidade_mouse(m, _raio_mouse)) - p
		EntradaCamera.FonteMira.ANALOGICO:
			return alvo_f2(p, e.mira_analogico, _lookahead_max, e.intensidade_mira) - p
	return Vector2.ZERO


func _prender(alvo: Vector2) -> Vector2:
	if _jogavel.size == Vector2.ZERO:
		return alvo
	return LimitesDaCamera.prender(alvo, _jogavel, _geo.largura_logica, _sangria)


func _publicar_snapshot() -> void:
	_snap_pos = _pos
	_snap_geo = _geo


func _visual(look: Vector2, desloc: Vector2, zoom_total: float) -> EstadoVisualCamera:
	return EstadoVisualCamera.new(_pos, _pos_seguir, look, desloc, zoom_total, _geo.largura_logica, _estados.atual)
