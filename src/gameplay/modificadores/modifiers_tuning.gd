class_name ModifiersTuning
extends DefinicaoBase
## Constantes de Modificadores e atributos (GDD modificadores-e-atributos, R2 "ModifiersTuning").
## Formato: GDD de Conteúdo R1 (ADR-0004). Valores e faixas: GDD dono (tabela da R2).
## Só leitura em execução; único por jogo; entra no manifesto como tipo [code]&"tuning"[/code].
## Os defaults ficam neutros (0); os valores reais vêm do catálogo validado. Os testes
## montam a instância com fixture.
##
## Exemplo:
## [codeblock]
## var t := ModifiersTuning.new()
## t.piso_vida_jogador = 20.0
## var p := Portador.new(1, 0, Atributos.Especie.JOGADOR, {&"vida_max": 130.0}, t)
## [/codeblock]

## Piso de [code]vida_max[/code] do jogador (F1). Faixa 1–100.
@export var piso_vida_jogador: float = 0.0
## Piso de [code]vida_max[/code] de inimigos (F1). Faixa ≥ 1.
@export var piso_vida_inimigo: float = 0.0
## Teto de [code]reducao_dano[/code] (F1/F3). Faixa 0–0,9.
@export var teto_reducao_dano: float = 0.0
## Teto do M efetivo da F2 ([code]min(M, teto)[/code]). Faixa 2–8.
@export var teto_multiplicador_dano: float = 0.0
## Multiplicador de [code]fator_empurrao[/code] da fonte [code]chefe[/code] (R10). Faixa 0–1.
@export var fator_empurrao_chefe: float = 0.0
## Piso de [code]vida_max[/code] do portador da Maldição (F1). Faixa 1–100.
@export var piso_vida_maldicao: float = 0.0
## Tipos de efeito do jogador espelhados nos portadores das Maldições (R14, F6).
@export var tipos_propagados_maldicao: Array[StringName] = []
## Fração do valor do jogador copiada para o espelho (F6). Faixa 0–1.
@export var fator_propagacao_maldicao: float = 0.0


func tipo_do_catalogo() -> StringName:
	return &"tuning"
