## Evento [code]saldo_no_teto[/code] da Economia de Fragmentos (GDD R1, F1, R8).
##
## Sai quando um crédito foi cortado pelo teto [code]saldo_max[/code]
## ([code]efetivo < pedido[/code]), inclusive com efetivo 0 (saldo já no teto).
##
## Exemplo:
## [codeblock]
## if eventos.ha(EvSaldoNoTeto.TIPO):
##     pass
## [/codeblock]
class_name EvSaldoNoTeto
extends EventoDoPasso

## Contrato do tipo.
const TIPO: StringName = &"saldo_no_teto"

## Saldo depois do crédito (igual ao teto). Somente leitura por convenção.
var saldo: int
## Quantidade pedida no [code]creditar[/code]. Somente leitura.
var pedido: int
## Quantidade efetivamente creditada (0 ou mais). Somente leitura.
var efetivo: int
## Origem do crédito cortado. Somente leitura.
var origem: StringName


## Campos do crédito cortado.
func _init(p_saldo: int, p_pedido: int, p_efetivo: int, p_origem: StringName) -> void:
	saldo = p_saldo
	pedido = p_pedido
	efetivo = p_efetivo
	origem = p_origem


## Devolve [constant TIPO].
func tipo() -> StringName:
	return TIPO
