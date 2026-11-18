## Fluxo de números de uma chave (finalidade, região, profundidade)
## (GDD rng-com-seed.md R3, R5, F1–F8; ADR-0005).
##
## Lógica pura: guarda só o estado u32 e consome números pelas operações F3–F8.
## Toda operação valida argumentos e a validade da run ANTES do primeiro avanço;
## pedido inválido gera exatamente um registro no relator, devolve o valor de
## erro da operação (0 / a / −1 / lista vazia / cópia) e conserva o estado.
class_name FluxoRng
extends RefCounted

var _estado: int = 0
var _relator: RelatorDeErrosRng
var _marcador: MarcadorDeValidade


## `estado_inicial` passa pela máscara u32. `marcador` nulo = fluxo avulso
## (testes e ferramentas), sempre válido; fluxos da fonte sempre têm marcador.
func _init(estado_inicial: int, relator: RelatorDeErrosRng, marcador: MarcadorDeValidade = null) -> void:
	_estado = RngAritmetica.mascarar_u32(estado_inicial)
	_relator = relator
	_marcador = marcador


## Estado atual de 32 bits (para testes, telemetria e um futuro save).
func estado() -> int:
	return _estado


## Verdadeiro enquanto o marcador da run continuar válido.
func esta_valido() -> bool:
	return _marcador == null or _marcador.esta_valido()


## F1: avança 1 passo e devolve u. Consome 1 número. Em fluxo inválido,
## registra e devolve 0 sem avançar.
func proximo_u32() -> int:
	if not _pode_sortear(&"F1"):
		return 0
	return _avancar()


## F3: real em [0, 1). Consome 1. Erro (fluxo inválido): 0.0.
func real_unitario() -> float:
	if not _pode_sortear(&"F3"):
		return 0.0
	return RngAritmetica.real_unitario(_avancar())


## F4: inteiro em [0, n), 1 ≤ n ≤ 2²¹. Consome 1 (inclusive n = 1). Erro: 0.
func inteiro(n: int) -> int:
	if n < 1 or n > RngAritmetica.N_MAXIMO:
		_recusar(&"F4", "n fora de 1..2^21: %d" % n)
		return 0
	if not _pode_sortear(&"F4"):
		return 0
	return RngAritmetica.inteiro_limitado(_avancar(), n)


## F5 inteiro: [a, b], com b − a + 1 ≤ 2²¹. Consome 1 (inclusive a = b). Erro: a.
func inteiro_entre(a: int, b: int) -> int:
	if not RngAritmetica.intervalo_inteiro_valido(a, b):
		_recusar(&"F5i", "intervalo inteiro invalido: [%d, %d]" % [a, b])
		return a
	if not _pode_sortear(&"F5i"):
		return a
	return RngAritmetica.inteiro_entre(_avancar(), a, b)


## F5 real: [a, b), limites finitos. Consome 1 (inclusive a = b). Erro: a.
func real_entre(a: float, b: float) -> float:
	if not RngAritmetica.intervalo_real_valido(a, b):
		_recusar(&"F5r", "intervalo real invalido: [%s, %s)" % [str(a), str(b)])
		return a
	if not _pode_sortear(&"F5r"):
		return a
	return RngAritmetica.real_entre(_avancar(), a, b)


## F6, caminho inteiro exato (pesos inteiros, soma ≤ 2³¹). Consome 1. Erro: −1.
func escolha_ponderada_inteira(pesos: Array[int]) -> int:
	if RngAritmetica.soma_de_pesos_inteiros(pesos) < 0:
		_recusar(&"F6i", "pesos inteiros invalidos (vazio, negativo, soma 0 ou > 2^31)")
		return -1
	if not _pode_sortear(&"F6i"):
		return -1
	return RngAritmetica.escolha_ponderada_inteira(_avancar(), pesos)


## F6, caminho real (há algum peso real). Consome 1. Erro (vazio, negativo,
## NaN, ±INF, soma 0 ou não finita): −1.
func escolha_ponderada_real(pesos: Array[float]) -> int:
	if RngAritmetica.soma_de_pesos_reais(pesos) < 0.0:
		_recusar(&"F6r", "pesos reais invalidos (vazio, negativo, NaN, INF ou soma 0)")
		return -1
	if not _pode_sortear(&"F6r"):
		return -1
	return RngAritmetica.escolha_ponderada_real(_avancar(), pesos)


## F7: k índices distintos de [0, n), Fisher–Yates parcial. Consome min(k, n).
## k = 0 ou n = 0: [] sem consumir. Erro (n ou k negativo, n > 2²¹, fluxo
## inválido): [].
func k_distintos(n: int, k: int) -> Array[int]:
	var resultado: Array[int] = []
	if n < 0 or k < 0 or n > RngAritmetica.N_MAXIMO:
		_recusar(&"F7", "n ou k invalido: n=%d k=%d" % [n, k])
		return resultado
	if n == 0 or k == 0:
		return resultado
	if not _pode_sortear(&"F7"):
		return resultado
	var indices: Array[int] = []
	indices.resize(n)
	for i: int in n:
		indices[i] = i
	var quantos: int = mini(k, n)
	for i: int in quantos:
		var j: int = i + RngAritmetica.inteiro_limitado(_avancar(), n - i)
		var troca: int = indices[i]
		indices[i] = indices[j]
		indices[j] = troca
	resultado = indices.slice(0, quantos)
	return resultado


## F8: devolve uma cópia embaralhada (Fisher–Yates de trás para frente) e não
## muda `lista`. Aceita Array tipado de qualquer tipo; a cópia mantém o tipo.
## Consome max(n − 1, 0). Erro (n > 2²¹, fluxo inválido): cópia intacta.
func embaralhar_copia(lista: Array) -> Array:
	var copia: Array = lista.duplicate()
	var n: int = copia.size()
	if n > RngAritmetica.N_MAXIMO:
		_recusar(&"F8", "lista acima de 2^21: %d" % n)
		return copia
	if n <= 1:
		return copia
	if not _pode_sortear(&"F8"):
		return copia
	for i: int in range(n - 1, 0, -1):
		var j: int = RngAritmetica.inteiro_limitado(_avancar(), i + 1)
		var troca: Variant = copia[i]
		copia[i] = copia[j]
		copia[j] = troca
	return copia


func _avancar() -> int:
	_estado = RngAritmetica.proximo_estado(_estado)
	return RngAritmetica.saida_do_estado(_estado)


func _pode_sortear(operacao: StringName) -> bool:
	if esta_valido():
		return true
	_recusar(operacao, "fluxo de run encerrada (marcador invalido)")
	return false


func _recusar(operacao: StringName, motivo: String) -> void:
	if _relator != null:
		_relator.registrar_operacao_invalida(operacao, motivo)
