class_name VinculoTuning
extends DefinicaoBase
## Parâmetros de vínculo e de encontro.
## Formato: GDD de Conteúdo R1/R1-P. Significado e valores: Vínculo e pactos, Tabela consolidada (VP1–VP9). Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"tuning"[/code].
##
## Exemplo:
## [codeblock]
## var t := {cls}.new()
## assert(t.tipo_do_catalogo() == &"tuning")
## [/codeblock]

@export var especie_primeiro_pacto: StringName = &""
@export var chance_encontro: float = 0.0
@export var pity_runs: int = 0
@export var indices_encontro: PackedInt64Array = PackedInt64Array()
@export var chance_nao_pactuada: float = 0.0
@export var peso_raridade: PackedFloat64Array = PackedFloat64Array()
@export var pontos_acuada: int = 0
@export var frac_vida_acuada: float = 0.0
@export var encontros_para_consentir: PackedInt64Array = PackedInt64Array()
@export var pts_camara: int = 0
@export var pts_abate: int = 0
@export var pts_tecnica: int = 0
@export var pts_vitoria: int = 0
@export var teto_abates_run: int = 0
@export var teto_tecnicas_run: int = 0
@export var pts_reafirmar: int = 0
@export var pts_reafirmar_chefe: int = 0
@export var limiares_nivel: PackedInt64Array = PackedInt64Array()
@export var nivel_max: int = 0
@export var pontos_teto: int = 0
@export var bonus_vida: float = 0.0
@export var mult_recuperacao: float = 0.0
@export var bonus_dano_basico: float = 0.0
@export var memorias_por_raridade: PackedInt64Array = PackedInt64Array()


func tipo_do_catalogo() -> StringName:
	return &"tuning"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super(e)
	e.regra(&"especie_primeiro_pacto").referencia_tipo(&"curse")
	e.regra(&"peso_raridade").tabela_de_pesos()
