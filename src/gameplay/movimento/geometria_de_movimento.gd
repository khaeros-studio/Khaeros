class_name GeometriaDeMovimento
extends RefCounted
## Geometria da câmara para o Movimento (GDD movimento-e-esquiva R10; ADR-0008 §6): retângulo jogável e
## array **ordenado** de obstáculos circulares (a ordem do dado conta, AC-29). Inimigos nunca entram aqui.

## Retângulo jogável em px de mundo.
var jogavel: Rect2
var _obstaculos: Array[ObstaculoCircular] = []


func _init(p_jogavel: Rect2, p_obstaculos: Array[ObstaculoCircular] = []) -> void:
	jogavel = p_jogavel
	_obstaculos = p_obstaculos.duplicate()


## Obstáculos na ordem do dado (array interno; não mutar).
func obstaculos() -> Array[ObstaculoCircular]:
	return _obstaculos
