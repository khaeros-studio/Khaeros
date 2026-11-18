class_name ChefesTuning
extends DefinicaoBase
## Os 13 campos dos Chefes.
## Formato: GDD de Conteúdo R1/R1-P. Significado e valores: Chefes, Tabela consolidada §1 (CH1–CH8). Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"tuning"[/code].
##
## Exemplo:
## [codeblock]
## var t := {cls}.new()
## assert(t.tipo_do_catalogo() == &"tuning")
## [/codeblock]

@export var espera_inicial_chefe_s: float = 0.0
@export var espera_entre_padroes_chefe_s: float = 0.0
@export var limiar_furia_frac: float = 0.0
@export var fator_recarga_furia: float = 0.0
@export var mult_velocidade_furia: float = 0.0
@export var transicao_fase_s: float = 0.0
@export var raio_pulso_furia_px: float = 0.0
@export var empurrao_pulso_furia_px: float = 0.0
@export var raio_puxao_px: float = 0.0
@export var puxao_convergencia_px: float = 0.0
@export var max_lacaios_vivos: int = 0
@export var lacaios_por_convergencia: int = 0
@export var dist_spawn_lacaio_px: float = 0.0


func tipo_do_catalogo() -> StringName:
	return &"tuning"
