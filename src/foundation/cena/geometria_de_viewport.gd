class_name GeometriaDeViewport
extends RefCounted
## Geometria imutável da janela em três faixas de proporção (ADR-0007 §2, GDD Cena R1).
##
## Publica tamanho da janela, largura lógica W, altura lógica 1080, fator f (px de
## janela por px lógico), origem das faixas e retângulo útil, além do aspecto e do
## tamanho base que a janela deve usar. Valores de viewport (não de gameplay): a
## altura lógica, a base 16:9 e o teto 43:18 são o contrato do R1.
##
## Exemplo:
## [codeblock]
## var g := GeometriaDeViewport.calcular(Vector2i(3840, 1080))
## # g.largura_logica == 2580.0, g.fator == 1.0, g.origem == Vector2(630, 0)
## g.aplicar_na_janela(get_window())   # só no Main/ponto de composição
## [/codeblock]

## Aspecto de stretch pedido à janela.
enum Aspecto { KEEP, KEEP_HEIGHT }

## Altura lógica fixa da vista (R1).
const ALTURA_LOGICA: float = 1080.0
## Largura lógica da base 16:9 (R1).
const LARGURA_BASE: float = 1920.0
## Largura lógica máxima, atingida em 43:18 (R1).
const LARGURA_MAXIMA: float = 2580.0

## Tamanho da janela em pixels (área de conteúdo).
var janela: Vector2i:
	get: return _janela
## Largura lógica visível W (1920–2580).
var largura_logica: float:
	get: return _largura
## Altura lógica (sempre 1080).
var altura_logica: float:
	get: return ALTURA_LOGICA
## Pixels de janela por pixel lógico.
var fator: float:
	get: return _fator
## Deslocamento das faixas (pillarbox/letterbox) em pixels de janela.
var origem: Vector2:
	get: return _origem
## Retângulo útil (sem faixas) em pixels de janela.
var retangulo_util: Rect2:
	get: return Rect2(_origem, Vector2(_largura, ALTURA_LOGICA) * _fator)
## Aspecto de stretch correspondente à faixa.
var aspecto: Aspecto:
	get: return _aspecto
## Tamanho lógico base pedido à janela (`content_scale_size`).
var tamanho_base: Vector2i:
	get: return _tamanho_base

var _janela: Vector2i
var _largura: float
var _fator: float
var _origem: Vector2
var _aspecto: Aspecto
var _tamanho_base: Vector2i


func _init(p_janela: Vector2i, p_largura: float, p_fator: float, p_aspecto: Aspecto, p_base: Vector2i) -> void:
	_janela = p_janela
	_largura = p_largura
	_fator = p_fator
	_aspecto = p_aspecto
	_tamanho_base = p_base
	_origem = (Vector2(p_janela) - Vector2(p_largura, ALTURA_LOGICA) * p_fator) / 2.0


## Calcula a geometria para um tamanho de janela. Devolve `null` para dimensão
## não positiva (janela minimizada): o chamador mantém o último instantâneo válido.
## A classificação usa aritmética inteira para que 43:18 exato (3440×1440) caia na
## faixa do meio sem erro de arredondamento.
static func calcular(tamanho: Vector2i) -> GeometriaDeViewport:
	if tamanho.x <= 0 or tamanho.y <= 0:
		return null
	var base_16_9 := Vector2i(int(LARGURA_BASE), int(ALTURA_LOGICA))
	# r < 16:9  <=>  largura*9 < altura*16
	if tamanho.x * 9 < tamanho.y * 16:
		return GeometriaDeViewport.new(tamanho, LARGURA_BASE, float(tamanho.x) / LARGURA_BASE, Aspecto.KEEP, base_16_9)
	var f := float(tamanho.y) / ALTURA_LOGICA
	# r > 43:18  <=>  largura*18 > altura*43
	if tamanho.x * 18 > tamanho.y * 43:
		return GeometriaDeViewport.new(tamanho, LARGURA_MAXIMA, f, Aspecto.KEEP, Vector2i(int(LARGURA_MAXIMA), int(ALTURA_LOGICA)))
	var w := ALTURA_LOGICA * float(tamanho.x) / float(tamanho.y)
	return GeometriaDeViewport.new(tamanho, w, f, Aspecto.KEEP_HEIGHT, base_16_9)


## Rotina idempotente do `size_changed` e de antes de input/render: devolve
## `anterior` quando o tamanho não mudou ou é zero; senão, a geometria nova.
##
## Exemplo: [code]_geo = GeometriaDeViewport.atualizar(janela.size, _geo)[/code]
static func atualizar(tamanho: Vector2i, anterior: GeometriaDeViewport) -> GeometriaDeViewport:
	if anterior != null and anterior.janela == tamanho:
		return anterior
	var nova := calcular(tamanho)
	return anterior if nova == null else nova


## Aplica modo, escala, aspecto e tamanho base na janela, escrevendo só as
## propriedades que diferem (sem ciclo de notificações). Chamado apenas pelo `Main`.
## Devolve `true` se alguma propriedade mudou.
func aplicar_na_janela(janela_alvo: Window) -> bool:
	var mudou := false
	if janela_alvo.content_scale_mode != Window.CONTENT_SCALE_MODE_CANVAS_ITEMS:
		janela_alvo.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		mudou = true
	if janela_alvo.content_scale_stretch != Window.CONTENT_SCALE_STRETCH_FRACTIONAL:
		janela_alvo.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
		mudou = true
	var aspecto_janela := Window.CONTENT_SCALE_ASPECT_KEEP if _aspecto == Aspecto.KEEP else Window.CONTENT_SCALE_ASPECT_KEEP_HEIGHT
	if janela_alvo.content_scale_aspect != aspecto_janela:
		janela_alvo.content_scale_aspect = aspecto_janela
		mudou = true
	if janela_alvo.content_scale_size != _tamanho_base:
		janela_alvo.content_scale_size = _tamanho_base
		mudou = true
	return mudou
