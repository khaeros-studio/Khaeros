class_name FeedbackTuning
extends DefinicaoBase
## Constantes do Feedback de combate.
## Formato: GDD de Conteúdo R1/R1-P. Significado e valores: Feedback de combate (FB1–FB3). Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"tuning"[/code].
##
## Exemplo:
## [codeblock]
## var t := {cls}.new()
## assert(t.tipo_do_catalogo() == &"tuning")
## [/codeblock]

@export var janela_soma_s: float = 0.0
@export var teto_numeros: int = 0
@export var limiar_degradacao: float = 0.0
@export var limiar_retorno: float = 0.0
@export var limiar_nivel2: float = 0.0
@export var retorno_nivel2: float = 0.0
@export var vozes_max_gancho: int = 0
@export var vozes_max_total: int = 0
@export var assenta_camara_s: float = 0.0


func tipo_do_catalogo() -> StringName:
	return &"tuning"
