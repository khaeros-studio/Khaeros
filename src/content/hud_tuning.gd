class_name HudTuning
extends DefinicaoBase
## Constantes do HUD (17 campos, emenda Pactos).
## Formato: GDD de Conteúdo R1/R1-P. Significado e valores: HUD (17 campos; HU1–HU17). Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"tuning"[/code].
##
## Exemplo:
## [codeblock]
## var t := {cls}.new()
## assert(t.tipo_do_catalogo() == &"tuning")
## [/codeblock]

@export var vida_por_segmento: int = 0
@export var segmento_px: int = 0
@export var barra_max_frac: float = 0.0
@export var vida_baixa_pct: float = 0.0
@export var vida_baixa_histerese: float = 0.0
@export var vinheta_max_borda: float = 0.0
@export var vinheta_opacidade_max: float = 0.0
@export var janela_ganho_s: float = 0.0
@export var fio_visivel_s: float = 0.0
@export var largura_fio: int = 0
@export var fio_elite_escala: float = 0.0
@export var esquiva_tremor_ms: int = 0
@export var fade_estado_s: float = 0.0
@export var margem_segura_px: int = 0
@export var pacto_tremor_px: int = 0
@export var pacto_tremor_s: float = 0.0
@export var pacto_intervalo_px: int = 0


func tipo_do_catalogo() -> StringName:
	return &"tuning"
