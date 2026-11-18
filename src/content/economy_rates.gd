class_name EconomyRates
extends DefinicaoBase
## Taxas da Economia de Fragmentos (único).
## Formato: GDD de Conteúdo R1/R1-P (ADR-0004). Valores: GDD dono
## (design/gdd/economia-de-fragmentos.md, Tuning Knobs). Só leitura em execução (R3).
## Só guarda as duas taxas de que a Economia é dona (R2): as de porta, vitória e chefe
## ficam em [RewardTable], [RunTuning] e [RegionDef] (dono único por número).
## Valores de fábrica em [code]res://assets/data/economy_rates/economy_rates.tres[/code].
##
## Exemplo:
## [codeblock]
## var t := catalogo.obter(&"economy_rates", &"economy_rates", "economia") as EconomyRates
## [/codeblock]

## Fragmentos de uma Provação (cânone TRIAL_FRAGMENTS; padrão 3, faixa 0–10). Reservada:
## Provação fora do MVP; a conta não a lê.
@export var fragmentos_provacao: int = 0
## Teto do saldo (padrão 999 999, faixa 9 999–2 147 483 647; F1). Só evita estouro de inteiro.
@export var saldo_max: int = 0


func tipo_do_catalogo() -> StringName:
	return &"economy_rates"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super(e)
	e.regra(&"fragmentos_provacao").faixa(0.0, 10.0).aceita_default()
	e.regra(&"saldo_max").faixa(9999.0, 2147483647.0)
