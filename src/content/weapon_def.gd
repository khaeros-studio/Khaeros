class_name WeaponDef
extends DefinicaoBase
## Arma de Doutrina. Exatamente 7 campos de conteúdo (ADR-0004 emenda, TR-armas-001): id, doutrina, chave_nome, vida_max, velocidade, ataque, especial (obsoleto é metadado da base).
## Formato: GDD de Conteúdo R1/R1-P (ADR-0004). Valores: GDD dono. Só leitura em execução (R3).
##
## Exemplo:
## [codeblock]
## var arma := catalogo.obter(&"weapon", &"lamina", "run") as WeaponDef
## [/codeblock]

## Id de Doutrina (token Godot, R2).
@export var doutrina: StringName = &""
@export var chave_nome: StringName = &""
@export var vida_max: int = 0
## px/s (F2).
@export var velocidade: float = 0.0
@export var ataque: AttackDef = null
@export var especial: AttackDef = null


func tipo_do_catalogo() -> StringName:
	return &"weapon"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super(e)
	e.regra(&"chave_nome").texto(PackedStringArray(["_DESC"]))
	e.regra(&"vida_max").min_excl(0.0)
	e.regra(&"velocidade").min_excl(0.0)
