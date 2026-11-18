class_name Esquiva
extends RefCounted
## Regras puras da largada da esquiva (GDD movimento-e-esquiva R5 item 1; ADR-0008 §3).


## Direção fixada: [param mover] normalizado se não zero; senão [param mirar] (unitária). Velocidade cheia
## independe do módulo do analógico.
static func direcao(mover: Vector2, mirar: Vector2) -> Vector2:
	if mover.length_squared() > 0.0:
		return mover.normalized()
	return mirar
