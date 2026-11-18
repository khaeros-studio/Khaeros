class_name FormulasDePortas
extends RefCounted
## Fórmulas F1, F1-P, F3, F3-P e F4 de Portas e recompensas
## (GDD portas-e-recompensas.md §Formulas; ADR-0009, ADR-0015).


## F1: Fragmentos concedidos ao limpar uma câmara de profundidade [param p] com porta de Fragmentos:
## [code]fragmentos_porta_base + floor(p / fragmentos_porta_passo)[/code] (p 0..2 → 2; p 3..4 → 3; p 6 → 4).
static func fragmentos_por_porta(tabela: RewardTable, p: int) -> int:
	if tabela == null:
		return 2
	var passo: int = maxi(1, tabela.fragmentos_porta_passo)
	@warning_ignore("integer_division")
	var bonus: int = maxi(0, p) / passo
	return tabela.fragmentos_porta_base + bonus


## F4: Cura nominal de uma porta de cura: [code]round(vida_max * cura_porta)[/code], arredondando x,5 longe do zero.
static func cura_nominal_porta(tabela: RewardTable, vida_max: int) -> int:
	if tabela == null:
		return 0
	return Unidades.arredondar_meio_longe_do_zero(float(vida_max) * tabela.cura_porta)


## F4: Nova Vida após aplicar a cura da porta: [code]min(vida_max, vida_atual + cura_nominal)[/code].
static func aplicar_cura_porta(tabela: RewardTable, vida_atual: int, vida_max: int) -> int:
	var cura: int = cura_nominal_porta(tabela, vida_max)
	return mini(vida_max, vida_atual + cura)


## F1-P: Máximo de Fragmentos obtidos por portas no Limiar (p ∈ {1, 2, 3, 4} → 2 + 2 + 3 + 3 = 10).
static func max_fragmentos_portas_limiar(tabela: RewardTable) -> int:
	var soma: int = 0
	for p: int in [1, 2, 3, 4]:
		soma += fragmentos_por_porta(tabela, p)
	return soma


## F3 / F3-P: Esperança matemática de bênçãos numa run com [param k_escolhas_livres] (4 no Limiar com chefe)
## quando o jogador sempre escolhe bênção quando aparece.
static func esperanca_bencaos_run(tabela: RewardTable, k_escolhas_livres: int = 4) -> float:
	var p_b: float = ValidacaoRewardTable.prob_bencao_na_escolha(tabela)
	return 1.0 + float(k_escolhas_livres) * p_b
