class_name EnemyDef
extends DefinicaoBase
## Inimigo ou chefe (comportamento chefe). padroes é obrigatório para chefe ativo de região (CH1, dono).
## Formato: GDD de Conteúdo R1/R1-P (ADR-0004). Valores: GDD dono. Só leitura em execução (R3).
##
## Exemplo:
## [codeblock]
## var eco := catalogo.obter(&"enemy", &"eco_perdido", "ia") as EnemyDef
## [/codeblock]

@export var chave_nome: StringName = &""
## corpo_a_corpo, distancia, arremetida, chefe.
@export var comportamento: StringName = &""
@export var vida: float = 0.0
## px/s.
@export var velocidade: float = 0.0
@export var raio_px: float = 0.0
@export var dano: float = 0.0
@export var alcance_px: float = 0.0
@export var preparo_s: float = 0.0
@export var recarga_s: float = 0.0
## px/s (opcional).
@export var velocidade_projetil: float = 0.0
@export var custo_onda: int = 0
## Padrões do chefe (opcional).
@export var padroes: Array[BossPatternDef] = []


func tipo_do_catalogo() -> StringName:
	return &"enemy"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super(e)
	e.regra(&"chave_nome").texto()
	e.regra(&"comportamento").referencia_registro(&"comportamentos")
	e.regra(&"vida").min_excl(0.0)
	e.regra(&"velocidade").min_incl(0.0)
	e.regra(&"raio_px").min_excl(0.0)
	e.regra(&"dano").min_incl(0.0)
	e.regra(&"alcance_px").min_incl(0.0)
	e.regra(&"preparo_s").min_incl(0.0)
	e.regra(&"recarga_s").min_incl(0.0)
	e.regra(&"velocidade_projetil").opcional().min_incl(0.0)
	e.regra(&"custo_onda").min_incl(0.0)
	e.regra(&"padroes").opcional()
