@abstract
class_name ConsultaDeVista
extends RefCounted
## Porta injetada na IA para ler o retângulo visível da câmera em coordenadas de mundo (GDD R11; ADR-0018 §7).


@abstract func retangulo_visivel() -> Rect2


class Fixa extends ConsultaDeVista:
	var retangulo: Rect2

	func _init(p_retangulo: Rect2 = Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0))) -> void:
		retangulo = p_retangulo

	func retangulo_visivel() -> Rect2:
		return retangulo
