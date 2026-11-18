class_name ObstaculoCircular
extends RefCounted
## Obstáculo circular imutável da câmara (GDD movimento-e-esquiva R10; ADR-0008 §6). Imutável por convenção.

## Centro em px de mundo.
var centro: Vector2
## Raio em px.
var raio: float


func _init(p_centro: Vector2, p_raio: float) -> void:
	centro = p_centro
	raio = p_raio
