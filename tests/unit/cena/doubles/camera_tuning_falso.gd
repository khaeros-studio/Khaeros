extends Resource
## Fixture de `CameraTuning` para testes da Cena (valores placeholder do GDD Cena F2–F5).
## Contrato duck-typed lido por `CameraDeApresentacao.configurar_tuning`.

## Preset de impulso de teste.
class PresetFalso:
	extends RefCounted
	var meia_vida: float
	var chute: float
	var tremor: float
	var zoom: float

	func _init(h: float, ak: float, a_s: float, z: float) -> void:
		meia_vida = h
		chute = ak
		tremor = a_s
		zoom = z


var meia_vida: float = 0.12
var lookahead_max: float = 120.0
var raio_mouse: float = 480.0
var teto_deslocamento: float = 40.0
var teto_zoom: float = 1.15
var limiar_descarte: float = 0.05
var max_impulsos: int = 16
var parallax_primeiro_plano: float = 1.2
var camara_minima: Vector2 = Vector2(1920, 1080)
var camara_maxima: Vector2 = Vector2(2880, 1620)
var presets_impulso: Dictionary = {
	&"leve": PresetFalso.new(0.05, 10.0, 3.0, 0.02),
	&"pesado": PresetFalso.new(0.10, 20.0, 8.0, 0.04),
	&"chefe": PresetFalso.new(0.30, 32.0, 14.0, 0.10),
}


## Fábrica: tuning padrão do GDD.
static func padrao() -> Resource:
	return load("res://tests/unit/cena/doubles/camera_tuning_falso.gd").new()
