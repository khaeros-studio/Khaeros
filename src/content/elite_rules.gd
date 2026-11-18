class_name EliteRules
extends DefinicaoBase
## Regras de elite (único). Dono: IA de inimigos e elites.
## Formato: GDD de Conteúdo R1/R1-P (ADR-0004). Valores: GDD dono. Só leitura em execução (R3).
##
## Exemplo:
## [codeblock]
## var r := catalogo.obter(&"elite_rules", &"elite_rules", "ia") as EliteRules
## [/codeblock]

@export var mult_vida: float = 0.0
@export var mult_dano: float = 0.0
@export var mult_raio: float = 0.0
@export var resistencia_empurrao: float = 0.0
@export var profundidade_minima: int = 0
@export var max_elites_onda: int = 0
@export var curva_chance: LinearCurveDef = null


func tipo_do_catalogo() -> StringName:
	return &"elite_rules"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super(e)
	e.regra(&"mult_vida").min_excl(0.0)
	e.regra(&"mult_dano").min_excl(0.0)
	e.regra(&"mult_raio").min_excl(0.0)
	e.regra(&"resistencia_empurrao").min_incl(0.0).aceita_default()
	e.regra(&"profundidade_minima").min_incl(0.0).aceita_default()
	e.regra(&"max_elites_onda").min_incl(0.0).aceita_default()
