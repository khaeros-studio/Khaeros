class_name CurseDef
extends DefinicaoBase
## Espécie de Maldição. Ids append-only, chave do perfil salvo (ADR-0013); a ordem no manifesto alimenta o sorteio do Vínculo F1. Nomes de campo do ataque básico, passivas, Chamado e habilidade são provisórios (GDD R1-P, OQ 9).
## Formato: GDD de Conteúdo R1/R1-P (ADR-0004). Valores: GDD dono. Só leitura em execução (R3).
##
## Exemplo:
## [codeblock]
## var especies := catalogo.listar(&"curse")
## [/codeblock]

@export var chave_nome: StringName = &""
## comum, refinado, raro, epico, primordial.
@export var raridade: StringName = &""
@export var vida_max: float = 0.0
@export var velocidade: float = 0.0
@export var raio_px: float = 0.0
## Forma do ataque básico.
@export var forma_basica: StringName = &""
@export var alcance_basico_px: float = 0.0
@export var dano_basico: float = 0.0
@export var empurrao_basico: float = 0.0
@export var preparo_s: float = 0.0
@export var execucao_s: float = 0.0
@export var recuperacao_s: float = 0.0
@export var efeito_saida: StringName = &""
@export var efeito_entrada: StringName = &""
@export var bonus_sinergia_pct: float = 0.0
@export var passivas: Array[StringName] = []
@export var efeito_chamado: StringName = &""
@export var habilidade_unica: StringName = &""
## Só Primordial (ML4).
@export var chefe_origem_id: StringName = &""
## Chaves de texto (Vínculo F5).
@export var memorias: PackedStringArray = PackedStringArray()


func tipo_do_catalogo() -> StringName:
	return &"curse"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super(e)
	e.regra(&"chave_nome").texto()
	e.regra(&"raridade").referencia_registro(&"raridades_de_especie")
	e.regra(&"vida_max").min_excl(0.0)
	e.regra(&"velocidade").min_incl(0.0)
	e.regra(&"raio_px").min_excl(0.0)
	e.regra(&"forma_basica").referencia_registro(&"formas_de_ataque")
	e.regra(&"alcance_basico_px").min_incl(0.0)
	e.regra(&"dano_basico").min_incl(0.0)
	e.regra(&"empurrao_basico").min_incl(0.0).aceita_default()
	for n: StringName in [&"preparo_s", &"execucao_s", &"recuperacao_s"]:
		e.regra(n).min_incl(0.0)
	for n: StringName in [&"efeito_saida", &"efeito_entrada", &"bonus_sinergia_pct", &"passivas", &"efeito_chamado", &"habilidade_unica"]:
		e.regra(n).opcional()
	e.regra(&"chefe_origem_id").opcional().referencia_tipo(&"enemy")
	e.regra(&"memorias").opcional().texto()
