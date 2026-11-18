class_name ComposicaoDeOndas
extends RefCounted
## Composição das ondas de uma câmara por orçamento e sorteio de elite
## (GDD camaras-e-ondas.md R6, R7, F1, F2; ADR-0005, ADR-0018).
##
## Regras:
## - F1 Orçamento: [code]orcamento_base + orcamento_por_prof * p + orcamento_por_regiao * r[/code].
## - F1 Número de ondas: [code]1[/code] se [code]p < ondas_limites[0][/code], [code]2[/code] se
##   [code]p < ondas_limites[1][/code], senão [code]3[/code].
## - Cada onda tenta até 20 sorteios no fluxo [code]ondas[/code] sobre os inimigos do pool da
##   região cujo custo cabe no orçamento restante (na ordem do manifesto/pool), descontando o
##   custo e parando quando nada cabe ou quando a onda atinge [code]max_inimigos_onda[/code] (9).

const MAX_TENTATIVAS_POR_ONDA: int = 20


## Entrada composta de um inimigo numa onda antes do spawn físico.
class EntradaDeOnda:
	extends RefCounted
	var inimigo_id: StringName
	var definicao: EnemyDef
	var custo: float
	var ordem: int
	var elite: bool = false

	func _init(p_id: StringName, p_def: EnemyDef, p_custo: float, p_ordem: int) -> void:
		inimigo_id = p_id
		definicao = p_def
		custo = p_custo
		ordem = p_ordem


## F1: orçamento de uma onda na profundidade [param p] e região [param indice_regiao].
static func orcamento_onda(rules: WaveRules, p: int, indice_regiao: int = 0) -> float:
	return rules.orcamento_base + rules.orcamento_por_prof * float(p) + rules.orcamento_por_regiao * float(indice_regiao)


## F1: quantidade de ondas na profundidade [param p].
static func numero_de_ondas(rules: WaveRules, p: int) -> int:
	if rules.ondas_limites.size() >= 2:
		if p < rules.ondas_limites[0]:
			return 1
		if p < rules.ondas_limites[1]:
			return 2
		return 3
	return 1


## Compõe todas as ondas de uma câmara de combate na montagem (R6).
## [param pool] está na ordem da [RegionDef].
static func compor_ondas(rules: WaveRules, pool: Array[EnemyDef], p: int, indice_regiao: int,
		fluxo_ondas: FluxoRng) -> Array[Array]:
	var ondas: Array[Array] = []
	if rules == null or pool.is_empty() or fluxo_ondas == null:
		return ondas
	var n_ondas: int = numero_de_ondas(rules, p)
	var orcamento: float = orcamento_onda(rules, p, indice_regiao)
	for _w: int in n_ondas:
		ondas.append(compor_uma_onda(rules, pool, orcamento, fluxo_ondas))
	return ondas


## Compõe uma única onda com [param orcamento] usando até 20 sorteios no [param fluxo_ondas].
static func compor_uma_onda(rules: WaveRules, pool: Array[EnemyDef], orcamento: float,
		fluxo_ondas: FluxoRng) -> Array[EntradaDeOnda]:
	var onda: Array[EntradaDeOnda] = []
	var restante: float = orcamento
	var teto: int = maxi(1, rules.max_inimigos_onda)
	for _tentativa: int in MAX_TENTATIVAS_POR_ONDA:
		if onda.size() >= teto:
			break
		var candidatos: Array[EnemyDef] = []
		for def: EnemyDef in pool:
			var c: float = _custo_inimigo(def)
			if c <= restante + 1e-9:
				candidatos.append(def)
		if candidatos.is_empty():
			break
		var idx: int = fluxo_ondas.inteiro(candidatos.size())
		var escolhido: EnemyDef = candidatos[idx]
		var custo: float = _custo_inimigo(escolhido)
		onda.append(EntradaDeOnda.new(escolhido.id, escolhido, custo, onda.size()))
		restante -= custo
	return onda


## Decide se cada inimigo da [param onda] é elite, chamando [param sorteador_elite]
## ([code]Callable(p: int, ja_ha_elite: bool) -> bool[/code]) na ordem da onda (R7, AC-CO-10).
static func aplicar_sorteio_de_elites(onda: Array[EntradaDeOnda], p: int, sorteador_elite: Callable) -> void:
	var ja_ha_elite: bool = false
	for entrada: EntradaDeOnda in onda:
		if sorteador_elite.is_valid():
			var eh_elite: bool = bool(sorteador_elite.call(p, ja_ha_elite))
			entrada.elite = eh_elite
			if eh_elite:
				ja_ha_elite = true


static func _custo_inimigo(def: EnemyDef) -> float:
	if def == null:
		return 1.0
	if def.has_meta(&"custo_onda_real"):
		return float(def.get_meta(&"custo_onda_real"))
	return maxf(0.1, float(def.custo_onda))
