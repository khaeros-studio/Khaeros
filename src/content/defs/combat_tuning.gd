class_name CombatTuning
extends DefinicaoBase
## Knobs do Combate núcleo (GDD combate-nucleo R15; faixas em Formulas › Faixas do
## [code]CombatTuning[/code]; ADR-0010 §1, ADR-0004). Valores em segundos, px e px/s;
## a conversão s → passos é feita uma vez, na carga ([ParametrosDoCombate]). Só leitura
## em execução. Os padrões são 0 de propósito: valor jogável vem sempre do dado
## ([code]assets/data/combat_tuning.tres[/code]; em teste, de fixture). As faixas abaixo
## são o V2 do Conteúdo; as regras CV1–CV22 ficam em [ValidadorCombatTuning].
##
## Exemplo:
## [codeblock]
## var t := catalogo.obter(&"tuning", &"combat_tuning", "combate") as CombatTuning
## var p := ParametrosDoCombate.de(t)   # p.hitstop_leve == 3
## [/codeblock]

@export var hitstop_leve_s: float = 0.0
@export var hitstop_pesado_s: float = 0.0
@export var hitstop_abate_s: float = 0.0
@export var hitstop_atingido_s: float = 0.0
@export var hitstop_abate_chefe_s: float = 0.0
@export var hitstop_recusa_s: float = 0.0
## px/s.
@export var empurrao_pesado: float = 0.0
@export var limiar_finalizador: float = 0.0
@export var janela_combo_s: float = 0.0
@export var recuperacao_max_s: float = 0.0
@export var fator_recuperacao_golpe: float = 0.0
@export var passo_apoio_px: float = 0.0
@export var folga_encostado_px: float = 0.0
@export var nascimento_projetil_px: float = 0.0
@export var invuln_extra_investida_s: float = 0.0
@export var cambaleio_s: float = 0.0
@export var fator_cambaleio: float = 0.0
@export var quebrou_recuperacao_s: float = 0.0
## px/s.
@export var parede_vel_min: float = 0.0
@export var parede_dano: float = 0.0
## Fator por passo.
@export var queda_empurrao: float = 0.0
## px/s.
@export var empurrao_zero: float = 0.0
@export var invuln_atingido_s: float = 0.0
## Inteiro (1–8).
@export var passes_varredura: int = 0
@export var fator_guarda: float = 0.0
@export var giro_leque_graus: float = 0.0
@export var fator_raio_obstaculo_projetil: float = 0.0
@export var flash_acerto_s: float = 0.0
@export var extra_inversao_s: float = 0.0
@export var impact_chefe_s: float = 0.0


func tipo_do_catalogo() -> StringName:
	return &"tuning"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super(e)
	e.regra(&"hitstop_leve_s").faixa(0.0167, 0.1)
	e.regra(&"hitstop_pesado_s").faixa(0.05, 0.2)
	e.regra(&"hitstop_abate_s").faixa(0.0167, 0.2)
	e.regra(&"hitstop_atingido_s").faixa(0.0333, 0.25)
	e.regra(&"hitstop_abate_chefe_s").faixa(0.2, 1.5)
	e.regra(&"hitstop_recusa_s").faixa(0.1, 0.6)
	e.regra(&"empurrao_pesado").faixa(460.0, 1080.0)
	e.regra(&"limiar_finalizador").faixa(1.0, 1.45)
	e.regra(&"janela_combo_s").faixa(0.5167, 1.0)
	e.regra(&"recuperacao_max_s").faixa(0.0167, 0.5)
	e.regra(&"fator_recuperacao_golpe").faixa(0.0, 1.0).aceita_default()
	e.regra(&"passo_apoio_px").faixa(0.0, 24.0).aceita_default()
	e.regra(&"folga_encostado_px").faixa(0.0, 20.0).aceita_default()
	e.regra(&"nascimento_projetil_px").faixa(27.0, 60.0)
	e.regra(&"invuln_extra_investida_s").faixa(0.0, 0.1).aceita_default()
	e.regra(&"cambaleio_s").faixa(0.0167, 0.15)
	e.regra(&"fator_cambaleio").faixa(0.0, 1.0).aceita_default()
	e.regra(&"quebrou_recuperacao_s").faixa(0.1667, 0.8)
	e.regra(&"parede_vel_min").faixa(460.0, 900.0)
	e.regra(&"parede_dano").faixa(0.0, 30.0).aceita_default()
	e.regra(&"queda_empurrao").faixa(0.5, 0.95)
	e.regra(&"empurrao_zero").faixa(0.9, 30.0)
	e.regra(&"invuln_atingido_s").faixa(0.25, 1.5)
	e.regra(&"passes_varredura").faixa(1.0, 8.0)
	e.regra(&"fator_guarda").faixa(0.0, 1.0).aceita_default()
	e.regra(&"giro_leque_graus").faixa(3.0, 45.0)
	e.regra(&"fator_raio_obstaculo_projetil").faixa(0.0, 1.0).aceita_default()
	e.regra(&"flash_acerto_s").faixa(0.0167, 0.1667)
	e.regra(&"extra_inversao_s").faixa(0.0333, 0.1667)
	e.regra(&"impact_chefe_s").faixa(0.0833, 0.6)
