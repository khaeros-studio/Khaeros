class_name EstadoVisualCamera
extends RefCounted
## Resultado de um quadro da câmera, aplicado pelo `CompositorDeCena` (único
## escritor de `canvas_transform`). Valores somente leitura na fronteira.
##
## Exemplo:
## [codeblock]
## var v := camera.atualizar_quadro(entrada)
## get_viewport().canvas_transform = v.transformacao
## [/codeblock]

## Câmera base da mira (sem impulsos).
var pos: Vector2
## Câmera base sem lookahead (usada só no lookahead).
var pos_seguir: Vector2
## Vetor de lookahead aplicado ao alvo (alvo − P antes da F4).
var lookahead: Vector2
## Deslocamento de impulsos (chute + tremor), |desloc| ≤ teto.
var deslocamento: Vector2
## Zoom total (intro × impulsos), limitado ao teto.
var zoom: float
## Largura lógica W usada neste quadro.
var largura: float
## Estado da máquina da câmera (`EstadosDaCamera.Estado`).
var estado: int
## Transformação lógica completa: tela = (W/2, 540) + z·(X − (pos + desloc)).
var transformacao: Transform2D


func _init(p_pos: Vector2, p_seguir: Vector2, p_look: Vector2, p_desloc: Vector2, p_zoom: float, p_largura: float, p_estado: int) -> void:
	pos = p_pos
	pos_seguir = p_seguir
	lookahead = p_look
	deslocamento = p_desloc
	zoom = p_zoom
	largura = p_largura
	estado = p_estado
	var centro := p_pos + p_desloc
	transformacao = Transform2D(Vector2(p_zoom, 0.0), Vector2(0.0, p_zoom),
		Vector2(p_largura / 2.0, LimitesDaCamera.MEIA_ALTURA) - centro * p_zoom)
