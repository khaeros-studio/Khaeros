extends RefCounted
## Fábricas de teste da Cena: tuning, câmera já cortada numa câmara e entradas.

const TuningFalso := preload("res://tests/unit/cena/doubles/camera_tuning_falso.gd")


static func tuning() -> Resource:
	return TuningFalso.new()


## Câmera com tuning, geometria da janela dada e corte (época 1) na câmara;
## consome o quadro de Corte e volta a Seguindo em t_apres = 0.
static func camera_em(jogavel: Rect2, spawn: Vector2, janela: Vector2i = Vector2i(1920, 1080), sangria: float = 370.0) -> CameraDeApresentacao:
	var cam := CameraDeApresentacao.new()
	cam.configurar_tuning(tuning())
	cam.injetar_ruido(func(_i: int) -> Vector2: return Vector2.ZERO)
	cam.definir_geometria(GeometriaDeViewport.calcular(janela))
	cam.cortar(CorteDeCamera.new(1, jogavel, sangria, spawn))
	cam.reiniciar_relogio(1, 0.0)
	var e := parado(spawn, 0.0)
	cam.atualizar_quadro(e)
	cam.atualizar_quadro(e)
	return cam


## Entrada com o jogador parado em `p`, mira automática (sem lookahead).
static func parado(p: Vector2, t: float) -> EntradaCamera:
	var e := EntradaCamera.new()
	e.p_anterior = p
	e.p_atual = p
	e.fracao = 1.0
	e.t_apres = t
	e.fonte_mira = EntradaCamera.FonteMira.AUTOMATICA
	return e


## Entrada com mira de mouse no cursor (espaço Janela).
static func com_mouse(p: Vector2, t: float, cursor: Vector2) -> EntradaCamera:
	var e := parado(p, t)
	e.fonte_mira = EntradaCamera.FonteMira.MOUSE
	e.cursor_janela = cursor
	return e
