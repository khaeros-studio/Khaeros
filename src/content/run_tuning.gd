class_name RunTuning
extends DefinicaoBase
## Constantes da Run: câmaras jogáveis por região, Fragmentos da vitória e arma padrão (lamina, ressonancia ou pactos).
## Formato: GDD de Conteúdo R1/R1-P. Significado e valores: Run e regiões (RN1–RN3). Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"tuning"[/code].
##
## Exemplo:
## [codeblock]
## var t := {cls}.new()
## assert(t.tipo_do_catalogo() == &"tuning")
## [/codeblock]

@export var camaras_jogaveis: Dictionary[StringName, int] = {}
@export var fragmentos_vitoria: int = 0
@export var arma_padrao: StringName = &""


func tipo_do_catalogo() -> StringName:
	return &"tuning"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super(e)
	e.regra(&"arma_padrao").referencia_tipo(&"weapon")
