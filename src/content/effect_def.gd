class_name EffectDef
extends DadoDeConteudo
## Efeito de bênção ou melhoria. valor escala com a raridade se escala_com_raridade; params nunca escalam. Dono: Modificadores.
## Formato: GDD de Conteúdo R1/R1-P (ADR-0004). Valores: GDD dono. Só leitura em execução (R3).
##
## Exemplo:
## [codeblock]
## var ef := EffectDef.new(); ef.tipo = &"recusas_morte"
## [/codeblock]

## Tipo de efeito registrado (Modificadores R5).
@export var tipo: StringName = &""
@export var valor: float = 0.0
@export var escala_com_raridade: bool = false
## Constantes nomeadas.
@export var params: Dictionary[StringName, float] = {}


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	e.regra(&"tipo").referencia_registro(&"tipos_de_efeito")
	e.regra(&"valor").aceita_default()
	e.regra(&"escala_com_raridade").opcional()
	e.regra(&"params").opcional()
