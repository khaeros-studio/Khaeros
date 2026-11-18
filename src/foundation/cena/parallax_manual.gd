class_name ParallaxManual
extends RefCounted
## Parallax manual ancorado no centro da câmara (GDD Cena F7, ADR-0007 §5).
##
## Funções puras. Toda distância está em px de mundo; não há conversão 1,5 aqui.
## Não combinar com `Parallax2D` nem com follow automático de `CanvasLayer`.
##
## Exemplo:
## [codeblock]
## var d := ParallaxManual.deslocamento(1.2, camera_final, jogavel.get_center())
## raiz_primeiro_plano.position = posicao_original + d   # atribuído, não somado
## var margem := ParallaxManual.deriva(1.2, jogavel.size, tuning.teto_deslocamento)
## [/codeblock]


## F7: deriva máxima por lado de uma camada com parallax `p` numa câmara de
## jogável `tamanho`; `teto_chute` é o teto do deslocamento de impulsos (F5).
## `deriva = |1 − p| × ((L − tela) / 2 + teto_chute)`, por eixo.
static func deriva(p: float, tamanho: Vector2, teto_chute: float) -> Vector2:
	var k := absf(1.0 - p)
	return Vector2(
		k * (maxf(0.0, tamanho.x - GeometriaDeViewport.LARGURA_BASE) / 2.0 + teto_chute),
		k * (maxf(0.0, tamanho.y - GeometriaDeViewport.ALTURA_LOGICA) / 2.0 + teto_chute))


## F7: deslocamento da camada em relação ao mundo,
## `(1 − p) × (câmera_final − centro_da_câmara)`. p = 1 dá zero.
static func deslocamento(p: float, camera_final: Vector2, centro_camara: Vector2) -> Vector2:
	if p == 1.0:
		return Vector2.ZERO
	return (1.0 - p) * (camera_final - centro_camara)
