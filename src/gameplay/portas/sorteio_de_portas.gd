class_name SorteioDePortas
extends RefCounted
## Sorteio determinístico das portas livres sem repetição pelo fluxo [code]portas[/code]
## (GDD portas-e-recompensas.md R6, R7, F2; ADR-0005).
##
## Regras:
## - Consome **sempre 4 reais** ([code]u0, u1, u2, u3[/code]) do [param fluxo_portas] por escolha livre:
##   - [code]u0[/code]: [code]n = 3[/code] se [code]u0 < chance_tres_portas[/code], senão [code]2[/code]
##     (limitado ao nº de tipos com peso > 0);
##   - [code]u1[/code]: 1º tipo ponderado pelos pesos na ordem canônica ([code]bencao[/code], [code]fragmentos[/code], [code]cura[/code]);
##   - [code]u2[/code]: 2º tipo ponderado entre os tipos restantes com peso > 0;
##   - [code]u3[/code]: consumido e descartado (o 3º tipo é o único que sobra), mantendo consumo fixo de 4 reais.
## - Portas forçadas ([code]santuario[/code], [code]chefe[/code], [code]ultima[/code]) não chamam este sorteio
##   e consomem **0 reais**.

const ORDEM_TIPOS: Array[StringName] = [&"bencao", &"fragmentos", &"cura", &"provacao"]


## Sorteia os tipos de portas livres consumindo exatamente 4 reais de [param fluxo_portas].
## Se [param b_restantes] == 0 (pool de bênçãos esgotado), o peso de [code]bencao[/code] pode ser mantido
## ou zerado conforme configuração; por padrão na R7 do GDD os pesos vêm da [RewardTable].
static func sortear(tabela: RewardTable, fluxo_portas: FluxoRng) -> Array[StringName]:
	var resultado: Array[StringName] = []
	if tabela == null or fluxo_portas == null:
		return resultado
	var u0: float = fluxo_portas.real_unitario()
	var u1: float = fluxo_portas.real_unitario()
	var u2: float = fluxo_portas.real_unitario()
	var _u3: float = fluxo_portas.real_unitario()
	return sortear_com_reais(tabela, u0, u1, u2, _u3)


## Executa a F2 pura sobre os 4 reais [param u0]..[param _u3] já lidos.
static func sortear_com_reais(tabela: RewardTable, u0: float, u1: float, u2: float, _u3: float = 0.0) -> Array[StringName]:
	var disponiveis: Array[StringName] = []
	var pesos: Array[float] = []
	for t: StringName in ORDEM_TIPOS:
		var p: float = float(tabela.pesos_portas.get(t, 0.0))
		if p > 0.0:
			disponiveis.append(t)
			pesos.append(p)
	var resultado: Array[StringName] = []
	if disponiveis.is_empty():
		return resultado
	var n_desejado: int = 3 if u0 < tabela.chance_tres_portas else 2
	var n_final: int = mini(n_desejado, disponiveis.size())

	# 1º tipo com u1
	var idx1: int = _escolher_por_real(pesos, u1)
	resultado.append(disponiveis[idx1])
	disponiveis.remove_at(idx1)
	pesos.remove_at(idx1)

	if n_final >= 2 and not disponiveis.is_empty():
		var idx2: int = _escolher_por_real(pesos, u2)
		resultado.append(disponiveis[idx2])
		disponiveis.remove_at(idx2)
		pesos.remove_at(idx2)

	if n_final >= 3 and not disponiveis.is_empty():
		resultado.append(disponiveis[0])

	return resultado


static func _escolher_por_real(pesos: Array[float], u: float) -> int:
	var soma: float = 0.0
	for p: float in pesos:
		soma += p
	if soma <= 0.0:
		return 0
	var alvo: float = clampf(u, 0.0, 1.0 - 1e-12) * soma
	var acum: float = 0.0
	for i: int in pesos.size():
		acum += pesos[i]
		if alvo < acum - 1e-12:
			return i
	return pesos.size() - 1
