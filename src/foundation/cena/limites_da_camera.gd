class_name LimitesDaCamera
extends RefCounted
## Limites da câmara (F4 do GDD Cena) e validação de tamanho da câmara (AC-15/16).
##
## Funções estáticas puras: sem estado, sem árvore. Os números vêm do chamador
## (retângulo jogável e sangria das Câmaras, tamanhos-limite do `CameraTuning`).
##
## Exemplo:
## [codeblock]
## var c := LimitesDaCamera.prender(alvo, Rect2(0, 0, 2880, 1080), 1920.0, 370.0)
## [/codeblock]

## Metade da altura lógica da vista (R1).
const MEIA_ALTURA: float = GeometriaDeViewport.ALTURA_LOGICA / 2.0


## F4: prende o centro `alvo` para que a vista de largura `largura_vista` fique no
## jogável, mostrando no máximo `sangria` além dele por lado (só no excesso de
## largura além de 16:9). Um eixo que cabe na vista fica centralizado.
static func prender(alvo: Vector2, jogavel: Rect2, largura_vista: float, sangria: float) -> Vector2:
	var e := clampf((largura_vista - GeometriaDeViewport.LARGURA_BASE) / 2.0, 0.0, maxf(0.0, sangria))
	var x0 := jogavel.position.x
	var x1 := jogavel.end.x
	var y0 := jogavel.position.y
	var y1 := jogavel.end.y
	var meia_largura := largura_vista / 2.0
	var cx: float
	if x1 - x0 + 2.0 * e <= largura_vista:
		cx = (x0 + x1) / 2.0
	else:
		cx = clampf(alvo.x, x0 - e + meia_largura, x1 + e - meia_largura)
	var cy: float
	if y1 - y0 <= GeometriaDeViewport.ALTURA_LOGICA:
		cy = (y0 + y1) / 2.0
	else:
		cy = clampf(alvo.y, y0 + MEIA_ALTURA, y1 - MEIA_ALTURA)
	return Vector2(cx, cy)


## Sangria que de fato aparece (`e` da F4) para a largura de vista dada.
static func sangria_visivel(largura_vista: float, sangria: float) -> float:
	return clampf((largura_vista - GeometriaDeViewport.LARGURA_BASE) / 2.0, 0.0, maxf(0.0, sangria))


## Retângulo envolvente de um jogável poligonal (AC-16). Polígono vazio → `Rect2()`.
static func retangulo_envolvente(poligono: PackedVector2Array) -> Rect2:
	if poligono.is_empty():
		return Rect2()
	var r := Rect2(poligono[0], Vector2.ZERO)
	for ponto: Vector2 in poligono:
		r = r.expand(ponto)
	return r


## Validação cruzada câmara × `CameraTuning` (AC-15). Devolve "" quando o tamanho
## está em [minimo, maximo] (limites exatos aceitos); senão, um erro que nomeia a
## câmara, para a tela de erros do catálogo.
static func validar_tamanho_camara(nome_camara: StringName, tamanho: Vector2, minimo: Vector2, maximo: Vector2) -> String:
	if tamanho.x < minimo.x or tamanho.y < minimo.y or tamanho.x > maximo.x or tamanho.y > maximo.y:
		return "Câmara '%s': jogável %dx%d fora de %dx%d a %dx%d" % [
			nome_camara, int(tamanho.x), int(tamanho.y),
			int(minimo.x), int(minimo.y), int(maximo.x), int(maximo.y)]
	return ""
