## Dublê de teste: entropia com valor fixo que conta as chamadas.
class_name EntropiaFalsaRng
extends FonteDeEntropia

## Valor devolvido por [method sortear_u32].
var valor: int = 0
## Quantas vezes a entropia foi pedida.
var chamadas: int = 0


func _init(valor_fixo: int) -> void:
	valor = valor_fixo


func sortear_u32() -> int:
	chamadas += 1
	return valor
