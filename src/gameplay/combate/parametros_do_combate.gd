class_name ParametrosDoCombate
extends RefCounted
## [CombatTuning] convertido para passos na carga (GDD combate-nucleo R15; Conteúdo F7;
## ADR-0010 §1). Feito uma vez, nunca a cada passo. Os campos sem sufixo [code]_s[/code]
## são copiados como estão.
##
## Exemplo:
## [codeblock]
## var p := ParametrosDoCombate.de(tuning)
## p.janela_combo   # 34 com 0,5667 s
## [/codeblock]

var hitstop_leve: int
var hitstop_pesado: int
var hitstop_abate: int
var hitstop_atingido: int
var hitstop_abate_chefe: int
var hitstop_recusa: int
var janela_combo: int
var recuperacao_max: int
var invuln_extra_investida: int
var cambaleio: int
var quebrou_recuperacao: int
var invuln_atingido: int
var flash_acerto: int
var extra_inversao: int
var impact_chefe: int
## O tuning de origem (cópia profunda, só leitura).
var tuning: CombatTuning


## Converte [param t] (F7: [method Unidades.duracao_para_passos]).
static func de(t: CombatTuning) -> ParametrosDoCombate:
	var p := ParametrosDoCombate.new()
	p.tuning = t
	p.hitstop_leve = Unidades.duracao_para_passos(t.hitstop_leve_s)
	p.hitstop_pesado = Unidades.duracao_para_passos(t.hitstop_pesado_s)
	p.hitstop_abate = Unidades.duracao_para_passos(t.hitstop_abate_s)
	p.hitstop_atingido = Unidades.duracao_para_passos(t.hitstop_atingido_s)
	p.hitstop_abate_chefe = Unidades.duracao_para_passos(t.hitstop_abate_chefe_s)
	p.hitstop_recusa = Unidades.duracao_para_passos(t.hitstop_recusa_s)
	p.janela_combo = Unidades.duracao_para_passos(t.janela_combo_s)
	p.recuperacao_max = Unidades.duracao_para_passos(t.recuperacao_max_s)
	p.invuln_extra_investida = Unidades.duracao_para_passos(t.invuln_extra_investida_s)
	p.cambaleio = Unidades.duracao_para_passos(t.cambaleio_s)
	p.quebrou_recuperacao = Unidades.duracao_para_passos(t.quebrou_recuperacao_s)
	p.invuln_atingido = Unidades.duracao_para_passos(t.invuln_atingido_s)
	p.flash_acerto = Unidades.duracao_para_passos(t.flash_acerto_s)
	p.extra_inversao = Unidades.duracao_para_passos(t.extra_inversao_s)
	p.impact_chefe = Unidades.duracao_para_passos(t.impact_chefe_s)
	return p
