class_name BencaosTuning
extends DefinicaoBase
## Constantes das Bênçãos.
## Formato: GDD de Conteúdo R1/R1-P. Significado e valores: Bênçãos (BN1–BN2). Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"tuning"[/code].
##
## Exemplo:
## [codeblock]
## var t := {cls}.new()
## assert(t.tipo_do_catalogo() == &"tuning")
## [/codeblock]

@export var tamanho_oferta: int = 0
@export var trocas_iniciais: int = 0
@export var raridade_bonus: float = 0.0


func tipo_do_catalogo() -> StringName:
	return &"tuning"
