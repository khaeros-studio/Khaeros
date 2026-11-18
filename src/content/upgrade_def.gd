class_name UpgradeDef
extends DefinicaoBase
## Melhoria da Oficina: custos por nível e efeitos. Dono: Oficina de Reforja.
## Formato: GDD de Conteúdo R1/R1-P (ADR-0004). Valores: GDD dono. Só leitura em execução (R3).
##
## Exemplo:
## [codeblock]
## var melhorias := catalogo.listar(&"upgrade")
## [/codeblock]

@export var chave_nome: StringName = &""
@export var custos: PackedInt64Array = PackedInt64Array()
@export var efeitos: Array[EffectDef] = []


func tipo_do_catalogo() -> StringName:
	return &"upgrade"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super(e)
	e.regra(&"chave_nome").texto()
	e.regra(&"custos").min_incl(0.0)
