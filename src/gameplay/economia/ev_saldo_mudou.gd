## Evento [code]saldo_mudou(saldo, delta, origem)[/code] da Economia de Fragmentos
## (GDD economia-de-fragmentos R3, R5, R8; ADR-0002).
##
## Sai no canal do passo a cada crédito com efetivo > 0 e a cada gasto aceito.
## HUD, Telemetria e tela final só leem.
##
## Exemplo:
## [codeblock]
## for e: EventoDoPasso in eventos.do_tipo(EvSaldoMudou.TIPO):
##     var m := e as EvSaldoMudou
##     print(m.saldo, m.delta, m.origem)
## [/codeblock]
class_name EvSaldoMudou
extends EventoDoPasso

## Contrato do tipo.
const TIPO: StringName = &"saldo_mudou"

## Saldo depois da mudança. Somente leitura por convenção.
var saldo: int
## Variação aplicada: positiva no crédito (efetivo), negativa no gasto. Somente leitura.
var delta: int
## Origem do crédito ([code]porta[/code], [code]vitoria[/code], [code]chefe[/code],
## [code]provacao[/code]) ou motivo do gasto. Somente leitura.
var origem: StringName


## [param p_saldo]: saldo novo; [param p_delta]: variação; [param p_origem]: origem ou motivo.
func _init(p_saldo: int, p_delta: int, p_origem: StringName) -> void:
	saldo = p_saldo
	delta = p_delta
	origem = p_origem


## Devolve [constant TIPO].
func tipo() -> StringName:
	return TIPO
