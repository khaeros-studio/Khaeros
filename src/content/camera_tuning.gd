class_name CameraTuning
extends DefinicaoBase
## Ajustes da câmera e projeção 3:4 (GDD cena-3-4-e-camera F2–F7; GDD de Conteúdo R1).
## Único por jogo (`id = &"camera_tuning"`, tipo `&"tuning"`). Só leitura em execução (R3).
##
## Exemplo:
## [codeblock]
## var c := CameraTuning.new()
## assert(c.tipo_do_catalogo() == &"tuning")
## [/codeblock]

@export var meia_vida: float = 0.0
@export var lookahead_max: float = 0.0
@export var raio_mouse: float = 0.0
@export var teto_deslocamento: float = 0.0
@export var teto_zoom: float = 0.0
@export var limiar_descarte: float = 0.0
@export var max_impulsos: int = 0
@export var parallax_primeiro_plano: float = 0.0


func tipo_do_catalogo() -> StringName:
	return &"tuning"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super._declarar_regras(e)
	e.regra(&"meia_vida").faixa(0.02, 0.50)
	e.regra(&"lookahead_max").faixa(0.0, 360.0)
	e.regra(&"raio_mouse").min_excl(0.0)
	e.regra(&"teto_deslocamento").faixa(0.0, 120.0)
	e.regra(&"teto_zoom").faixa(1.0, 1.5)
	e.regra(&"limiar_descarte").faixa(0.001, 0.25)
	e.regra(&"max_impulsos").faixa(1.0, 32.0)
	e.regra(&"parallax_primeiro_plano").faixa(1.0, 2.0)
