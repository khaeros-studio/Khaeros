class_name BossPatternDef
extends DadoDeConteudo
## Padrão de chefe, embutido em EnemyDef.padroes; identificado por (id do chefe, índice). Dono: Chefes.
## Formato: GDD de Conteúdo R1/R1-P (ADR-0004). Valores: GDD dono. Só leitura em execução (R3).
##
## Exemplo:
## [codeblock]
## var forma := (inimigo.padroes[0] as BossPatternDef).forma_telegrafo
## [/codeblock]

@export var chave_nome: StringName = &""
## setor, retangulo, anel ou circulo.
@export var forma_telegrafo: StringName = &""
## Dimensões do telégrafo por forma (px/graus).
@export var dimensoes: Dictionary[StringName, float] = {}
@export var preparo_s: float = 0.0
@export var execucao_s: float = 0.0
@export var recarga_s: float = 0.0
@export var dano: float = 0.0
## Efeitos do padrão (puxão, lacaios...).
@export var efeitos: Array[StringName] = []
## Contorno secundário; 0 = nenhum (CH8).
@export var raio_secundario_px: float = 0.0


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	e.regra(&"chave_nome").texto()
	e.regra(&"forma_telegrafo").referencia_registro(&"formas_de_telegrafo")
	e.regra(&"preparo_s").min_excl(0.0)
	e.regra(&"execucao_s").min_excl(0.0)
	e.regra(&"recarga_s").min_excl(0.0)
	e.regra(&"dano").min_incl(0.0).aceita_default()
	e.regra(&"efeitos").opcional()
	e.regra(&"raio_secundario_px").opcional()
