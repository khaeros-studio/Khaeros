class_name RegionDef
extends DefinicaoBase
## Região: sequência de câmaras (tipos de sala), pool de inimigos, chefe e Fragmentos do chefe. Dono: Run e regiões.
## Formato: GDD de Conteúdo R1/R1-P (ADR-0004). Valores: GDD dono. Só leitura em execução (R3).
##
## Exemplo:
## [codeblock]
## var limiar := catalogo.obter(&"region", &"limiar", "run") as RegionDef
## [/codeblock]

@export var chave_nome: StringName = &""
## Tipos de sala por índice.
@export var camaras: Array[StringName] = []
@export var pool_inimigos: Array[StringName] = []
## Id do EnemyDef chefe (opcional).
@export var chefe: StringName = &""
@export var fragmentos_chefe: int = 0


func tipo_do_catalogo() -> StringName:
	return &"region"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super(e)
	e.regra(&"chave_nome").texto()
	e.regra(&"camaras").referencia_registro(&"tipos_de_sala")
	e.regra(&"pool_inimigos").referencia_tipo(&"enemy")
	e.regra(&"chefe").opcional().referencia_tipo(&"enemy")
	e.regra(&"fragmentos_chefe").opcional().min_incl(0.0)
