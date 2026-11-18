class_name RewardTable
extends DefinicaoBase
## Pesos das portas por tipo de recompensa e regras de porta (único). Dono: Portas e recompensas.
## Formato: GDD de Conteúdo R1/R1-P (ADR-0004). Valores: GDD dono. Só leitura em execução (R3).
##
## Exemplo:
## [codeblock]
## var pesos := (catalogo.obter(&"reward_table", &"reward_table", "portas") as RewardTable).pesos_portas
## [/codeblock]

## Tipo de recompensa -> peso (V8; chaves V4).
@export var pesos_portas: Dictionary[StringName, float] = {}
@export var chance_tres_portas: float = 0.0
@export var primeira_recompensa: StringName = &""
## Reservada.
@export var profundidade_min_provacao: int = 0
@export var cura_porta: float = 0.0
@export var fragmentos_porta_base: int = 0
@export var fragmentos_porta_passo: int = 0


func tipo_do_catalogo() -> StringName:
	return &"reward_table"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super(e)
	e.regra(&"pesos_portas").tabela_de_pesos().referencia_registro(&"tipos_de_recompensa")
	e.regra(&"chance_tres_portas").faixa(0.0, 1.0).aceita_default()
	e.regra(&"primeira_recompensa").referencia_registro(&"tipos_de_recompensa")
	e.regra(&"profundidade_min_provacao").opcional().min_incl(0.0)
	e.regra(&"cura_porta").min_incl(0.0).aceita_default()
	e.regra(&"fragmentos_porta_base").min_incl(0.0).aceita_default()
	e.regra(&"fragmentos_porta_passo").min_incl(0.0).aceita_default()
