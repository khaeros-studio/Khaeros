class_name TelemetriaTuning
extends DefinicaoBase
## Constantes da Telemetria local.
## Formato: GDD de Conteúdo R1/R1-P. Significado e valores: Telemetria local (TL1–TL3). Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"tuning"[/code].
##
## Exemplo:
## [codeblock]
## var t := {cls}.new()
## assert(t.tipo_do_catalogo() == &"tuning")
## [/codeblock]

@export var max_bytes_sessao: int = 0
@export var max_sessoes: int = 0
@export var orcamento_linha_ms: float = 0.0
@export var orcamento_passo_ms: float = 0.0
@export var casas_decimais_duracao: int = 0


func tipo_do_catalogo() -> StringName:
	return &"tuning"
