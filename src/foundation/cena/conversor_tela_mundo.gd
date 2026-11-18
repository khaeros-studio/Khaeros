@abstract
class_name ConversorTelaMundo
extends RefCounted
## Interface injetável de conversão tela → mundo (F6, ADR-0007 §3), consumida pelo
## provedor de Input. Implementada por `CameraDeApresentacao`; testes usam câmera falsa.
##
## Exemplo:
## [codeblock]
## var mira_bruta := conversor.tela_para_mundo(cursor_janela) - p_atual_fisica
## [/codeblock]


## Converte um cursor no espaço Janela para mundo, pelo último instantâneo base
## válido (sem chute, tremor nem zoom). Não recalcula a câmera.
@abstract func tela_para_mundo(cursor_janela: Vector2) -> Vector2


## F6 pura: Janela → Vista lógica (presa a [0,W]×[0,1080]) → Mundo com a base `c`.
## Exemplo: janela 1280×720, cursor (960,180), c (1500,800) → (1980,530).
static func converter(cursor_janela: Vector2, geometria: GeometriaDeViewport, c: Vector2) -> Vector2:
	var w := geometria.largura_logica
	var logico := ((cursor_janela - geometria.origem) / geometria.fator).clamp(
		Vector2.ZERO, Vector2(w, GeometriaDeViewport.ALTURA_LOGICA))
	return c + logico - Vector2(w / 2.0, LimitesDaCamera.MEIA_ALTURA)
