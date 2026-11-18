class_name DefinicaoBase
extends DadoDeConteudo
## Definição de conteúdo com identidade (tipo do catálogo, id). Ver GDD de Conteúdo
## R1–R3 e ADR-0004. O estado vivo nunca mora aqui (ADR-0003): quem precisa de
## cópia mutável usa [code]duplicate_deep(Resource.DEEP_DUPLICATE_ALL)[/code].
##
## [member obsoleto] é metadado comum a todas as definições (R10): continua
## resolvendo por id, sai de listar/filtrar por padrão e entra na impressão.
##
## Exemplo:
## [codeblock]
## var arma := WeaponDef.new()
## arma.id = &"lamina"
## assert(arma.tipo_do_catalogo() == &"weapon")
## [/codeblock]

## Id snake_case ASCII, único dentro do tipo, append-only (R2).
@export var id: StringName = &""
## Definição aposentada: resolve por id, mas listar/filtrar a excluem por padrão.
@export var obsoleto: bool = false


## Tipo da entrada no manifesto e no índice (ex.: [code]&"weapon"[/code]).
## Toda subclasse concreta sobrescreve.
func tipo_do_catalogo() -> StringName:
	return &""


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	e.regra(&"obsoleto").opcional()
