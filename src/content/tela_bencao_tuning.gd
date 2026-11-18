class_name TelaBencaoTuning
extends DefinicaoBase
## Constantes da Tela de bênção.
## Formato: GDD de Conteúdo R1/R1-P. Significado e valores: Tela de bênção e carta (TB1–TB10). Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"tuning"[/code].
##
## Exemplo:
## [codeblock]
## var t := {cls}.new()
## assert(t.tipo_do_catalogo() == &"tuning")
## [/codeblock]

@export var trava_confirmar_ms: int = 0
@export var trava_troca_ms: int = 0
@export var entrada_s: float = 0.0
@export var anim_troca_s: float = 0.0
@export var anim_confirmar_s: float = 0.0
@export var foco_escala: float = 0.0
@export var foco_sobe_px: int = 0
@export var valor_nao_focada: float = 0.0
@export var intervalo_cartas_px: int = 0
@export var tremor_botao_ms: int = 0


func tipo_do_catalogo() -> StringName:
	return &"tuning"
