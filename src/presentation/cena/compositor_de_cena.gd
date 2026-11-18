class_name CompositorDeCena
extends Node
## Ponto de composição visual da Cena (ADR-0007 §1, §4): nó fino da Apresentação,
## com interpolação de física OFF, e **único escritor** de
## `Viewport.canvas_transform`. Não existe `Camera2D` ativo concorrendo.
##
## Por quadro, nesta ordem: geometria pendente → câmera → transformação → camadas
## (parallax e ordem por pé). Relógio/corte do wipe vêm antes, do orquestrador;
## shaders e UI vêm depois (ADR-0011/0012). A transformação é reconstruída inteira
## a cada quadro; a escala da janela é da engine (não multiplica f).
##
## Exemplo:
## [codeblock]
## var comp := CompositorDeCena.new()
## comp.configurar(camera, camadas, get_viewport())
## comp.definir_camara(jogavel)            # no corte
## # em _process, depois do relógio:
## var v := comp.compor(entrada_camera)
## [/codeblock]

var _camera: CameraDeApresentacao
var _camadas: CamadasDoMundo
var _viewport: Viewport
var _centro_camara: Vector2 = Vector2.ZERO
var _geometria_pendente: GeometriaDeViewport
var _ultimo: EstadoVisualCamera


func _init() -> void:
	name = &"CompositorDeCena"
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


## Injeta a câmera (lógica pura), o módulo de camadas e o viewport alvo.
func configurar(camera: CameraDeApresentacao, camadas: CamadasDoMundo, viewport: Viewport) -> void:
	_camera = camera
	_camadas = camadas
	_viewport = viewport


## Centro da câmara atual (âncora do parallax F7); chamar no corte.
func definir_camara(jogavel: Rect2) -> void:
	_centro_camara = jogavel.get_center()


## Lê do `CameraTuning` (duck-typed) o parallax do primeiro plano, se houver
## a chave `parallax_primeiro_plano`. Sem a chave, fica 1,0.
func configurar_tuning(tuning: Object) -> void:
	if tuning == null or _camadas == null:
		return
	var p: Variant = tuning.get(&"parallax_primeiro_plano")
	if p != null:
		_camadas.definir_parallax(CamadasDoMundo.Camada.PRIMEIRO_PLANO, float(p))


## Agenda uma geometria nova (do `size_changed`), aplicada no próximo quadro
## antes da câmera.
func agendar_geometria(geometria: GeometriaDeViewport) -> void:
	_geometria_pendente = geometria


## Compõe um quadro: avalia a câmera, escreve o canvas e aplica as camadas.
## Devolve o estado visual aplicado (null se não configurado).
func compor(entrada: EntradaCamera) -> EstadoVisualCamera:
	if _camera == null or _camadas == null or _viewport == null:
		return null
	if _geometria_pendente != null:
		_camera.definir_geometria(_geometria_pendente)
		_geometria_pendente = null
	var v := _camera.atualizar_quadro(entrada)
	_viewport.canvas_transform = v.transformacao
	_camadas.aplicar_parallax(v.pos + v.deslocamento, _centro_camara)
	_camadas.atualizar_ordem()
	_ultimo = v
	return v


## Último estado visual aplicado (para diagnóstico e testes).
func ultimo_estado() -> EstadoVisualCamera:
	return _ultimo
