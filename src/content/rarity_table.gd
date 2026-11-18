class_name RarityTable
extends DefinicaoBase
## Raridades das bênçãos (Comum, Rara, Épica): escala e peso de sorteio, na mesma ordem. Dono: Bênçãos.
## Formato: GDD de Conteúdo R1/R1-P (ADR-0004). Valores: GDD dono. Só leitura em execução (R3).
##
## Exemplo:
## [codeblock]
## var t := catalogo.obter(&"rarity_table", &"rarity_table", "bencaos") as RarityTable
## [/codeblock]

@export var escalas: PackedFloat64Array = PackedFloat64Array()
## Tabela de peso (V8).
@export var pesos: PackedFloat64Array = PackedFloat64Array()


func tipo_do_catalogo() -> StringName:
	return &"rarity_table"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super(e)
	e.regra(&"escalas").min_excl(0.0)
	e.regra(&"pesos").tabela_de_pesos()
