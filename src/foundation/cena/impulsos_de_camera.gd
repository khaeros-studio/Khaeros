class_name ImpulsosDeCamera
extends RefCounted
## Impulsos de câmera (F5 do GDD Cena, ADR-0007 §8): chute, tremor e zoom.
##
## Guarda até `max_impulsos` impulsos ativos (o mais antigo sai). Idades usam o
## `t_apres` injetado; sem relógio próprio, sem RNG estrutural. O ruído cosmético
## é um `Callable(indice: int) -> Vector2` injetado (cada eixo em [−1, 1]); a
## Apresentação injeta o gerador real, testes injetam ruído fixo. Sem ruído
## injetado o tremor vale zero.
##
## Exemplo:
## [codeblock]
## var imp := ImpulsosDeCamera.new()
## imp.configurar(presets, 40.0, 1.15, 0.05, 16)
## imp.receber(pedido, epoca_atual, t_apres)
## imp.avaliar(t_apres, 1.0, false)   # imp.deslocamento, imp.zoom
## [/codeblock]

## Preset tipado lido do `CameraTuning`.
class Preset:
	## Meia-vida h_i (s).
	var meia_vida: float
	## Amplitude do chute Ak (px).
	var chute: float
	## Amplitude do tremor As (px).
	var tremor: float
	## Zoom extra Z.
	var zoom: float

	func _init(p_h: float, p_ak: float, p_as: float, p_z: float) -> void:
		meia_vida = p_h
		chute = p_ak
		tremor = p_as
		zoom = p_z


class _Ativo:
	var preset: Preset
	var escala: float
	var dir: Vector2
	var t_inicio: float


## Deslocamento do último `avaliar` (|desloc| ≤ teto).
var deslocamento: Vector2 = Vector2.ZERO
## Zoom de impulsos do último `avaliar` (1 sem impulsos), antes do zoom de intro.
var zoom: float = 1.0
## Último diagnóstico de rejeição ("" quando aceito).
var ultimo_diagnostico: String = ""

var _presets: Dictionary[StringName, Preset] = {}
var _ativos: Array[_Ativo] = []
var _teto_desloc: float = 0.0
var _teto_zoom: float = 1.0
var _limiar: float = 1.0
var _max: int = 0
var _ruido: Callable = Callable()


## Instala presets e limites vindos do `CameraTuning`.
func configurar(presets: Dictionary[StringName, Preset], teto_deslocamento: float, teto_zoom: float, limiar_descarte: float, max_impulsos: int) -> void:
	_presets = presets
	_teto_desloc = teto_deslocamento
	_teto_zoom = teto_zoom
	_limiar = limiar_descarte
	_max = max_impulsos


## Injeta o ruído cosmético `func(indice: int) -> Vector2`.
func injetar_ruido(ruido: Callable) -> void:
	_ruido = ruido


## Número de impulsos ativos.
func quantidade() -> int:
	return _ativos.size()


## Remove todos os impulsos e restaura deslocamento zero e zoom 1.
func limpar() -> void:
	_ativos.clear()
	deslocamento = Vector2.ZERO
	zoom = 1.0


## Valida e enfileira um pedido. Rejeita (com diagnóstico, sem tocar no estado)
## preset desconhecido, época diferente da atual, escala negativa/não finita,
## tempo não finito, negativo ou futuro e direção não unitária nem zero.
func receber(pedido: PedidoImpulso, epoca_atual: int, t_atual: float) -> bool:
	ultimo_diagnostico = _validar(pedido, epoca_atual, t_atual)
	if ultimo_diagnostico != "":
		return false
	var a := _Ativo.new()
	a.preset = _presets[pedido.preset]
	a.escala = pedido.escala
	a.dir = pedido.dir
	a.t_inicio = pedido.t_inicio
	_ativos.append(a)
	while _ativos.size() > _max:
		_ativos.pop_front()
	return true


## Avalia F5 no instante `t_apres`: descarta d < limiar e soma chute, tremor e
## zoom. `tremor_opcao` é s_t; `reducao_movimento` força zoom 1.
func avaliar(t_apres: float, tremor_opcao: float, reducao_movimento: bool) -> void:
	var soma := Vector2.ZERO
	var soma_zoom := 0.0
	var i := _ativos.size() - 1
	while i >= 0:
		var a := _ativos[i]
		var d := pow(2.0, -maxf(0.0, t_apres - a.t_inicio) / a.preset.meia_vida)
		if d < _limiar:
			_ativos.remove_at(i)
		i -= 1
	for indice in _ativos.size():
		var a := _ativos[indice]
		var d := pow(2.0, -maxf(0.0, t_apres - a.t_inicio) / a.preset.meia_vida)
		var ruido := Vector2.ZERO
		if _ruido.is_valid():
			ruido = (_ruido.call(indice) as Vector2).clamp(Vector2(-1.0, -1.0), Vector2.ONE)
		soma += (a.dir * a.preset.chute + ruido * a.preset.tremor) * a.escala * d
		soma_zoom += a.preset.zoom * a.escala * d
	deslocamento = (soma * clampf(tremor_opcao, 0.0, 1.0)).limit_length(_teto_desloc)
	zoom = 1.0 if reducao_movimento else minf(_teto_zoom, 1.0 + soma_zoom)


## d_i do impulso de índice `indice` em `t_apres` (para testes e depuração).
func decaimento(indice: int, t_apres: float) -> float:
	var a := _ativos[indice]
	return pow(2.0, -maxf(0.0, t_apres - a.t_inicio) / a.preset.meia_vida)


## Direção do impulso de índice `indice` (ordem de recebimento).
func direcao(indice: int) -> Vector2:
	return _ativos[indice].dir


func _validar(p: PedidoImpulso, epoca_atual: int, t_atual: float) -> String:
	if p == null:
		return "impulso nulo"
	if not _presets.has(p.preset):
		return "preset desconhecido: %s" % p.preset
	if p.epoca != epoca_atual:
		return "época %d diferente da atual %d" % [p.epoca, epoca_atual]
	if not is_finite(p.escala) or p.escala < 0.0:
		return "escala inválida: %s" % p.escala
	if not is_finite(p.t_inicio) or p.t_inicio < 0.0 or p.t_inicio > t_atual:
		return "tempo inválido: %s (agora %s)" % [p.t_inicio, t_atual]
	if not (is_finite(p.dir.x) and is_finite(p.dir.y)):
		return "direção não finita"
	if p.dir.length_squared() != 0.0 and absf(p.dir.length() - 1.0) > 1e-4:
		return "direção não unitária: %s" % p.dir
	return ""
