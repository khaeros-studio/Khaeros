## Dublê de teste: relator de erros do RNG que só grava os registros.
class_name RelatorGravadorRng
extends RelatorDeErrosRng

## Registros de operação recusada: "operacao|motivo".
var operacoes: Array[String] = []
## Registros de pedido recusado: [finalidade, regiao, profundidade].
var pedidos: Array[Array] = []
## Solicitantes dos pedidos recusados, na mesma ordem de `pedidos`.
var solicitantes: Array[StringName] = []
## Avisos registrados.
var avisos: Array[String] = []


## Total de registros de qualquer tipo.
func total() -> int:
	return operacoes.size() + pedidos.size() + avisos.size()


func registrar_operacao_invalida(operacao: StringName, motivo: String) -> void:
	operacoes.append("%s|%s" % [operacao, motivo])


func registrar_pedido_recusado(finalidade: int, regiao: int, profundidade: int, solicitante: StringName, _motivo: String) -> void:
	pedidos.append([finalidade, regiao, profundidade])
	solicitantes.append(solicitante)


func registrar_aviso(mensagem: String) -> void:
	avisos.append(mensagem)
