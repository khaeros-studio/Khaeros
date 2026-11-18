class_name BoonDef
extends DefinicaoBase
## Tradição (id canônico trad_*). Dono: Bênçãos.
## Formato: GDD de Conteúdo R1/R1-P (ADR-0004). Valores: GDD dono. Só leitura em execução (R3).
##
## Exemplo:
## [codeblock]
## var lista := catalogo.listar(&"boon")
## [/codeblock]

@export var doutrina: StringName = &""
@export var chave_nome: StringName = &""
## Texto com marcadores R7.
@export var chave_descricao: StringName = &""
@export var efeitos: Array[EffectDef] = []
## Token do glifo (opcional).
@export var glifo: StringName = &""
## Caminho em res://assets/art/export/ (V7).
@export var icone_ganho: String = ""
## Texto do preço com {valor} (opcional).
@export var chave_preco: StringName = &""


func tipo_do_catalogo() -> StringName:
	return &"boon"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super(e)
	e.regra(&"chave_nome").texto()
	e.regra(&"chave_descricao").texto_com_marcadores()
	e.regra(&"glifo").opcional()
	e.regra(&"icone_ganho").opcional().caminho_de_arte()
	e.regra(&"chave_preco").opcional().texto_com_marcadores()
