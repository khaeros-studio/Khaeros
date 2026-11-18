class_name ValidadorVinculo
extends RefCounted
## Validação VP1–VP9 do [VinculoTuning] e de [code]CurseDef.memorias[/code]
## (GDD vinculo-e-pactos.md §Validações, F4, F5; ADR-0004).
## Envolve [RegrasVp] nas duas passadas e provê cálculo de memórias reveladas (F5).

const ORDEM_RARIDADES: Array[StringName] = [&"comum", &"refinado", &"raro", &"epico", &"primordial"]


## Executa 1ª e 2ª passadas das regras VP1–VP9 sobre [param itens].
static func validar_tudo(itens: Array[ItemDoCatalogo], catalogo: Catalogo = null) -> Array[Diagnostico]:
	var vp := RegrasVp.new()
	var out: Array[Diagnostico] = vp.validar(itens)
	out.append_array(vp.validar_segunda_passada(itens, catalogo))
	return out


## F5: Quantidade de memórias reveladas de uma espécie (GDD vinculo-e-pactos.md F5).
## [code]reveladas = min(n_mem, max(encontros_vistos, pactuada ? 1 : 0) + (nivel >= nivel_max ? 1 : 0))[/code].
static func memorias_reveladas(raridade: StringName, encontros_vistos: int, pactuada: bool,
		nivel: int, tuning: VinculoTuning = null) -> int:
	var n_mem: int = total_memorias_por_raridade(raridade, tuning)
	var nivel_max: int = tuning.nivel_max if (tuning != null and tuning.nivel_max > 0) else 5
	var base: int = maxi(encontros_vistos, 1 if pactuada else 0)
	var extra_topo: int = 1 if nivel >= nivel_max else 0
	return mini(n_mem, base + extra_topo)


## Quantidade total de memórias esperada para [param raridade] (Comum 1, Refinado 2, Raro 3, Épico 4, Primordial 4).
static func total_memorias_por_raridade(raridade: StringName, tuning: VinculoTuning = null) -> int:
	var idx: int = ORDEM_RARIDADES.find(raridade)
	if idx < 0:
		return 1
	if tuning != null and idx < tuning.memorias_por_raridade.size():
		return int(tuning.memorias_por_raridade[idx])
	const PADRAO: Array[int] = [1, 2, 3, 4, 4]
	return PADRAO[idx]
