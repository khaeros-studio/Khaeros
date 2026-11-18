extends ConversorTelaMundo
## Câmera falsa para o consumidor de Input (AC-37): instantâneo base fixo e
## geometria fixa; impulsos/zoom guardados só para provar que não entram na F6.

var pos_ultimo_render: Vector2
var geometria: GeometriaDeViewport
var chute: Vector2 = Vector2.ZERO
var zoom: float = 1.0


func _init(p_pos: Vector2, p_geo: GeometriaDeViewport) -> void:
	pos_ultimo_render = p_pos
	geometria = p_geo


func tela_para_mundo(cursor_janela: Vector2) -> Vector2:
	return ConversorTelaMundo.converter(cursor_janela, geometria, pos_ultimo_render)
