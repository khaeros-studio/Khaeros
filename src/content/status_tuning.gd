class_name StatusTuning
extends DefinicaoBase
## Constantes dos status (sangramento, queimadura, abalo).
## Formato: GDD de Conteúdo R1/R1-P. Significado e valores: Efeitos de status R9 (ST1–ST11). Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"tuning"[/code].
##
## Exemplo:
## [codeblock]
## var t := {cls}.new()
## assert(t.tipo_do_catalogo() == &"tuning")
## [/codeblock]

@export var duracao_sangramento_s: float = 0.0
@export var dano_sangramento_s: float = 0.0
@export var max_acumulos_sangramento: int = 0
@export var duracao_queimadura_s: float = 0.0
@export var dano_queimadura_s: float = 0.0
@export var max_acumulos_queimadura: int = 0
@export var duracao_abalo_s: float = 0.0
@export var reducao_dano_causado: float = 0.0
@export var intervalo_numero_s: float = 0.0


func tipo_do_catalogo() -> StringName:
	return &"tuning"
