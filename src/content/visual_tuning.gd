class_name VisualTuning
extends DefinicaoBase
## Constantes do Pipeline visual (GDD pipeline-visual.md R12, Faixas seguras, VV1–VV17).
## Formato: GDD de Conteúdo R1/R1-P (ADR-0004). Significado e valores: Pipeline visual. Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"tuning"[/code].
##
## Exemplo:
## [codeblock]
## var t := VisualTuning.new()
## assert(t.tipo_do_catalogo() == &"tuning")
## [/codeblock]

@export var forca_grading_personagem: float = 0.0
@export var saturacao_bencao: float = 0.0
@export var valor_bencao: float = 0.0
@export var passo_profundidade: float = 0.0
@export var piso_profundidade: float = 0.0
@export var opacidade_max_feixes: float = 0.0
@export var ciclo_veio_s: float = 0.0
@export var amplitude_veio: float = 0.0
@export var duracao_flash_telegrafo_s: float = 0.0
@export var contorno_telegrafo_px: float = 0.0
@export var contorno_telegrafo_alto_px: float = 0.0
@export var traco_secundario_px: float = 0.0
@export var intervalo_secundario_px: float = 0.0
@export var largura_fio_px: float = 0.0
@export var opacidade_fio: float = 0.0
@export var ciclo_fio_estourado_s: float = 0.0
@export var raio_marca_virote_px: float = 0.0
@export var largura_anel_px: float = 0.0
@export var opacidade_base_telegrafo: float = 0.0
@export var largura_tracejado_px: float = 0.0
@export var traco_tracejado_px: float = 0.0
@export var intervalo_tracejado_px: float = 0.0
@export var contorno_silhueta_px: float = 0.0
@export var opacidade_oclusao: float = 0.0
@export var duracao_transicao_oclusao_s: float = 0.0
@export var margem_histerese_oclusao_px: float = 0.0
@export var duracao_wipe_s: float = 0.0
@export var duracao_fade_s: float = 0.0
@export var dt_max_apres: float = 0.0
@export var teto_drawcalls_passes: int = 0


func tipo_do_catalogo() -> StringName:
	return &"tuning"
