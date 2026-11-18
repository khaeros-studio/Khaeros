class_name WaveRules
extends DefinicaoBase
## Parâmetros do orçamento de onda e limites de onda (GDD camaras-e-ondas.md R15, WV1–WV11).
## Formato: GDD de Conteúdo R1/R1-P (ADR-0004). Significado e valores: Câmaras e ondas. Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"wave_rules"[/code].
##
## Exemplo:
## [codeblock]
## var w := WaveRules.new()
## assert(w.tipo_do_catalogo() == &"wave_rules")
## [/codeblock]

@export var orcamento_base: float = 0.0
@export var orcamento_por_prof: float = 0.0
@export var orcamento_por_regiao: float = 0.0
@export var ondas_limites: PackedInt64Array = PackedInt64Array()
@export var max_inimigos_onda: int = 0
@export var intervalo_onda_s: float = 0.0


func tipo_do_catalogo() -> StringName:
	return &"wave_rules"
