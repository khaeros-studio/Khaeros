## Funções puras do gerador (GDD rng-com-seed.md, Formulas F1–F6; ADR-0005).
##
## Não guarda estado: o dono do estado é [FluxoRng]. Tudo é inteiro de 64 bits
## com máscara de 32 bits; o [method imul] em metades de 16 bits nunca passa de
## 2⁴⁸. As constantes e os algoritmos fazem parte da versão do jogo (R7): mudar
## qualquer um muda todas as seeds e exige atualizar a versão e os vetores dos
## testes. Não são valores de gameplay, e por isso ficam aqui como constantes.
class_name RngAritmetica
extends RefCounted

## Máscara de 32 bits (M).
const MASCARA_U32: int = 0xFFFFFFFF
## Incremento do mulberry32 (W do F1, igual ao cânone).
const INCREMENTO: int = 0x6D2B79F5
## Constante de mistura da derivação (G do F2).
const MISTURA_DOURADA: int = 0x9E3779B9
## Constantes do fmix32.
const FMIX_C1: int = 0x85EBCA6B
const FMIX_C2: int = 0xC2B2AE35
## 2³², divisor exato do F3.
const DOIS_A_32: float = 4294967296.0
## Maior n aceito pelo F4 (2²¹).
const N_MAXIMO: int = 1 << 21
## Maior soma aceita no caminho inteiro do F6 (2³¹).
const SOMA_INTEIRA_MAXIMA: int = 1 << 31

## Faixas da chave de derivação (F2).
const FINALIDADE_MINIMA: int = 1
const FINALIDADE_MAXIMA: int = 9
const REGIAO_MAXIMA: int = 255
const PROFUNDIDADE_MAXIMA: int = 1023


## Aplica a máscara u32 na fronteira (seed recebida, leitura de save).
static func mascarar_u32(valor: int) -> int:
	return valor & MASCARA_U32


## Multiplicação 32×32 → 32 bits baixos, como `Math.imul` do cânone.
static func imul(a: int, b: int) -> int:
	a &= MASCARA_U32
	b &= MASCARA_U32
	return (a * (b & 0xFFFF) + (((a * (b >> 16)) & 0xFFFF) << 16)) & MASCARA_U32


## F1, metade do estado: devolve s' = (s + W) & M.
static func proximo_estado(estado: int) -> int:
	return (estado + INCREMENTO) & MASCARA_U32


## F1, metade da saída: a partir do estado novo s', devolve u.
static func saida_do_estado(estado_novo: int) -> int:
	var t: int = imul(estado_novo ^ (estado_novo >> 15), estado_novo | 1)
	t = t ^ ((t + imul(t ^ (t >> 7), t | 61)) & MASCARA_U32)
	return (t ^ (t >> 14)) & MASCARA_U32


## Finalizador fmix32 (bijeção de 32 bits).
static func fmix32(valor: int) -> int:
	var h: int = valor & MASCARA_U32
	h ^= h >> 16
	h = imul(h, FMIX_C1)
	h ^= h >> 13
	h = imul(h, FMIX_C2)
	return h ^ (h >> 16)


## mix(h, x) = fmix32(((h ^ x) + G) & M).
static func mix(h: int, x: int) -> int:
	return fmix32(((h ^ x) + MISTURA_DOURADA) & MASCARA_U32)


## Diz se o trio (finalidade, região, profundidade) está nas faixas do F2.
## Não decide autorização (isso é da [FonteDeFluxos]).
static func chave_valida(finalidade: int, regiao: int, profundidade: int) -> bool:
	return (finalidade >= FINALIDADE_MINIMA and finalidade <= FINALIDADE_MAXIMA
		and regiao >= 0 and regiao <= REGIAO_MAXIMA
		and profundidade >= 0 and profundidade <= PROFUNDIDADE_MAXIMA)


## F2: estado inicial s0 do fluxo. A seed passa pela máscara u32 (fronteira).
## Quem chama valida a chave antes ([method chave_valida]).
static func derivar(seed_da_run: int, finalidade: int, regiao: int, profundidade: int) -> int:
	var h: int = fmix32((mascarar_u32(seed_da_run) + MISTURA_DOURADA) & MASCARA_U32)
	return mix(mix(mix(h, finalidade), regiao), profundidade)


## F3: real em [0, 1) a partir de u.
static func real_unitario(u: int) -> float:
	return float(u & MASCARA_U32) / DOIS_A_32


## F4: inteiro em [0, n) a partir de u. Quem chama valida 1 ≤ n ≤ 2²¹.
static func inteiro_limitado(u: int, n: int) -> int:
	return ((u & MASCARA_U32) * n) >> 32


## F5 inteiro, função pura de u: a + F4(b − a + 1). Quem chama valida a ≤ b
## e b − a + 1 ≤ 2²¹ ([method intervalo_inteiro_valido]).
static func inteiro_entre(u: int, a: int, b: int) -> int:
	return a + inteiro_limitado(u, b - a + 1)


## Validação do F5 inteiro sem calcular diferença que estoure int64.
static func intervalo_inteiro_valido(a: int, b: int) -> bool:
	if a > b:
		return false
	# b − a + 1 > 2²¹  ⟺  b ≥ a + 2²¹; a + 2²¹ só estoura quando b − a já é pequeno.
	if a <= 0x7FFFFFFFFFFFFFFF - N_MAXIMO and b >= a + N_MAXIMO:
		return false
	return true


## F5 real, função pura de u: a + (b − a)·r; se o arredondamento alcançar b, devolve a.
static func real_entre(u: int, a: float, b: float) -> float:
	var vr: float = a + (b - a) * real_unitario(u)
	if vr >= b:
		return a
	return vr


## Validação do F5 real: limites e diferença finitos, a ≤ b.
static func intervalo_real_valido(a: float, b: float) -> bool:
	return is_finite(a) and is_finite(b) and a <= b and is_finite(b - a)


## Valida os pesos inteiros do F6: lista não vazia, cada peso ≥ 0 e cabendo em
## 2³¹ − soma_atual, soma > 0. Devolve a soma W, ou −1 se inválido.
static func soma_de_pesos_inteiros(pesos: Array[int]) -> int:
	if pesos.is_empty():
		return -1
	var soma: int = 0
	for peso: int in pesos:
		if peso < 0 or peso > SOMA_INTEIRA_MAXIMA - soma:
			return -1
		soma += peso
	if soma == 0:
		return -1
	return soma


## Valida os pesos reais do F6: lista não vazia, pesos finitos ≥ 0, soma finita > 0.
## Devolve a soma W, ou −1.0 se inválido.
static func soma_de_pesos_reais(pesos: Array[float]) -> float:
	if pesos.is_empty():
		return -1.0
	var soma: float = 0.0
	for peso: float in pesos:
		if not is_finite(peso) or peso < 0.0:
			return -1.0
		soma += peso
	if not is_finite(soma) or soma <= 0.0:
		return -1.0
	return soma


## F6 inteiro (exato), função pura de u: menor i com u·W < C_i·2³²,
## comparado como (u·W) >> 32 < C_i (equivalente para C_i inteiro).
## Devolve −1 se os pesos forem inválidos.
static func escolha_ponderada_inteira(u: int, pesos: Array[int]) -> int:
	var soma: int = soma_de_pesos_inteiros(pesos)
	if soma < 0:
		return -1
	var alvo: int = ((u & MASCARA_U32) * soma) >> 32
	var acumulado: int = 0
	for indice: int in pesos.size():
		acumulado += pesos[indice]
		if alvo < acumulado:
			return indice
	return _ultimo_positivo_inteiro(pesos)


## F6 real, função pura de u: menor i com r·W < C_i. Se o arredondamento deixar
## x sem índice (x ≥ W), devolve o último índice de peso positivo (ADR-0005).
## Devolve −1 se os pesos forem inválidos.
static func escolha_ponderada_real(u: int, pesos: Array[float]) -> int:
	var soma: float = soma_de_pesos_reais(pesos)
	if soma < 0.0:
		return -1
	return escolha_ponderada_real_de_x(real_unitario(u) * soma, pesos)


## Núcleo do F6 real a partir de x já calculado; exposto para o vetor do caso
## de borda de arredondamento (x ≥ W).
static func escolha_ponderada_real_de_x(x: float, pesos: Array[float]) -> int:
	var acumulado: float = 0.0
	for indice: int in pesos.size():
		acumulado += pesos[indice]
		if x < acumulado:
			return indice
	for indice: int in range(pesos.size() - 1, -1, -1):
		if pesos[indice] > 0.0:
			return indice
	return -1


static func _ultimo_positivo_inteiro(pesos: Array[int]) -> int:
	for indice: int in range(pesos.size() - 1, -1, -1):
		if pesos[indice] > 0:
			return indice
	return -1
