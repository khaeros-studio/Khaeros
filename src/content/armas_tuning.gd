class_name ArmasTuning
extends DefinicaoBase
## Metas de paridade das Armas (p_max é só alias de Câmaras R3).
## Formato: GDD de Conteúdo R1/R1-P. Significado e valores: Armas das Doutrinas (AV). Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"tuning"[/code].
##
## Exemplo:
## [codeblock]
## var t := {cls}.new()
## assert(t.tipo_do_catalogo() == &"tuning")
## [/codeblock]

@export var meta_paridade: float = 0.0
@export var margem_fragil: int = 0
@export var g_max_fragil: int = 0
@export var periodos_trava: int = 0
@export var f_esp_min: float = 0.0
@export var f_esp_max: float = 0.0
@export var vel_media_min: float = 0.0
@export var vel_media_max: float = 0.0
@export var p_max: int = 0


func tipo_do_catalogo() -> StringName:
	return &"tuning"
