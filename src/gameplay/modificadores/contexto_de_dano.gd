class_name ContextoDeDano
extends RefCounted
## Contexto passado por quem consulta o dano (GDD modificadores-e-atributos R4/R7;
## ADR-0009 §4). O portador nunca guarda Vida, contador de acertos nem janela
## pós-esquiva: o Combate monta o contexto no momento do uso. O contador de acertos
## entra depois, em [method DanoCongelado.m_no_impacto].
##
## Exemplo:
## [codeblock]
## var ctx := ContextoDeDano.new(jogador.vida, combate.janela_apos_esquiva_aberta(0))
## var m := portador.multiplicador_de_dano(Modificador.Slot.ATAQUE, ctx)
## [/codeblock]

## Vida atual do portador que causa o dano (para [code]vida_abaixo[/code]).
var vida_atual: float
## Janela [code]apos_esquiva[/code] aberta no disparo.
var apos_esquiva: bool


func _init(p_vida_atual: float = 0.0, p_apos_esquiva: bool = false) -> void:
	vida_atual = p_vida_atual
	apos_esquiva = p_apos_esquiva
