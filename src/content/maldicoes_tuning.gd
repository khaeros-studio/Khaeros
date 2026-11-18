class_name MaldicoesTuning
extends DefinicaoBase
## Os 12 campos das Maldições.
## Formato: GDD de Conteúdo R1/R1-P. Significado e valores: Maldições §Constantes 1 (ML1–ML8). Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"tuning"[/code].
##
## Exemplo:
## [codeblock]
## var t := {cls}.new()
## assert(t.tipo_do_catalogo() == &"tuning")
## [/codeblock]

@export var alcance_fio_px: float = 0.0
@export var distancia_seguir_px: float = 0.0
@export var alcance_chamado_px: float = 0.0
@export var duracao_salto_s: float = 0.0
@export var raio_chamado_px: float = 0.0
@export var raio_atracao_px: float = 0.0
@export var duracao_imobilizar_s: float = 0.0
@export var duracao_atracao_s: float = 0.0
@export var recarga_troca_s: float = 0.0
@export var recuperacao_exausta_s: float = 0.0
@export var vida_retorno_frac: float = 0.0
@export var regen_reserva_frac_s: float = 0.0


func tipo_do_catalogo() -> StringName:
	return &"tuning"
