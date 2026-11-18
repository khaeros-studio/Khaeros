class_name SorteioDoEncontro
extends RefCounted
## Sorteio determinístico do encontro de pacto na criação da run de Pactos pelo fluxo [code]pactos[/code] (9)
## (GDD vinculo-e-pactos.md V5, V6, F1; ADR-0005, ADR-0015).
##
## Regras (F1):
## - Só ocorre em runs com Doutrina [code]pactos[/code]; nas outras Doutrinas não toca o fluxo.
## - Consome **sempre 4 reais** ([code]u0, u1, u2, u3[/code]) do fluxo [code](pactos, regiao, 0)[/code],
##   mesmo quando alguma garantia (G1, G2, G3) está ativa (AC-VP-03, AC-VP-04).
## - Garantias:
##   - [code]G1 = not perfil.primeiro_encontro_visto[/code] → força encontro no 1º índice de
##     [code]indices_encontro[/code] (1) com a espécie regular não pactuada de menor raridade
##     (empate: ordem do manifesto → [code]espreitador_da_fenda[/code]);
##   - [code]G2 = not perfil.encontro_pendente.is_empty()[/code] → força a espécie pendente (prioridade G2 > G1 para a espécie);
##   - [code]G3 = perfil.runs_pactos_sem_encontro >= tuning.pity_runs[/code] (2) → força [code]ocorre = true[/code].
## - Sem garantia: [code]ocorre = (u0 < tuning.chance_encontro)[/code] (0,6).
## - Índice da câmara: [code]G1 ? indices_encontro[0] : indices_encontro[floor(u1 * n_idx)][/code].
## - Espécie:
##   - [code]G2[/code] → [code]encontro_pendente[0][/code];
##   - senão [code]G1[/code] → menor raridade em [code]NP[/code];
##   - senão se [code]NP != vazio e (u2 < chance_nao_pactuada ou P == vazio)[/code] → escolha ponderada em [code]NP[/code] com [code]u3[/code];
##   - senão → escolha ponderada em [code]P[/code] com [code]u3[/code].

const ORDEM_RARIDADES_REGULARES: Array[StringName] = [&"comum", &"refinado", &"raro", &"epico"]


## Resultado imutável do sorteio F1 de uma run.
class ResultadoDoSorteio:
	extends RefCounted
	var ocorre: bool = false
	var indice_camara: int = -1
	var especie_id: StringName = &""
	var reais_consumidos: Array[float] = []


## Executa o sorteio F1 consumindo sempre 4 reais de [param fluxo_pactos].
static func sortear(perfil: PerfilVinculo, tuning: VinculoTuning, fluxo_pactos: FluxoRng) -> ResultadoDoSorteio:
	if fluxo_pactos == null:
		return ResultadoDoSorteio.new()
	var u0: float = fluxo_pactos.real_unitario()
	var u1: float = fluxo_pactos.real_unitario()
	var u2: float = fluxo_pactos.real_unitario()
	var u3: float = fluxo_pactos.real_unitario()
	var res: ResultadoDoSorteio = sortear_com_reais(perfil, tuning, u0, u1, u2, u3)
	res.reais_consumidos = [u0, u1, u2, u3]
	return res


## Executa a fórmula F1 pura sobre os 4 reais [param u0]..[param u3] já extraídos.
static func sortear_com_reais(perfil: PerfilVinculo, tuning: VinculoTuning,
		u0: float, u1: float, u2: float, u3: float) -> ResultadoDoSorteio:
	var res := ResultadoDoSorteio.new()
	if perfil == null or tuning == null:
		return res
	var indices: PackedInt64Array = tuning.indices_encontro if not tuning.indices_encontro.is_empty() else PackedInt64Array([1, 2])
	var g1: bool = not perfil.primeiro_encontro_visto
	var g2: bool = not perfil.encontro_pendente.is_empty()
	var g3: bool = perfil.runs_pactos_sem_encontro >= maxi(1, tuning.pity_runs)

	res.ocorre = g1 or g2 or g3 or (u0 < tuning.chance_encontro)
	if not res.ocorre:
		return res

	# Índice da câmara
	if g1:
		res.indice_camara = int(indices[0])
	else:
		var n_idx: int = indices.size()
		var k: int = clampi(int(floor(clampf(u1, 0.0, 1.0 - 1e-12) * float(n_idx))), 0, n_idx - 1)
		res.indice_camara = int(indices[k])

	# Grupos NP (regulares não pactuadas) e P (regulares pactuadas) na ordem do manifesto
	var np: Array[StringName] = perfil.especies_regulares_nao_pactuadas()
	var p_grupo: Array[StringName] = perfil.especies_regulares_pactuadas()

	# Escolha da espécie (prioridade G2 > G1 > sorteio u2/u3)
	if g2:
		res.especie_id = StringName(perfil.encontro_pendente[0])
	elif g1 and not np.is_empty():
		res.especie_id = _menor_raridade(np, perfil)
	elif not np.is_empty() and (u2 < tuning.chance_nao_pactuada or p_grupo.is_empty()):
		res.especie_id = _escolha_ponderada(np, perfil, tuning, u3)
	elif not p_grupo.is_empty():
		res.especie_id = _escolha_ponderada(p_grupo, perfil, tuning, u3)
	elif not np.is_empty():
		res.especie_id = np[0]

	return res


static func _menor_raridade(grupo: Array[StringName], perfil: PerfilVinculo) -> StringName:
	var melhor_id: StringName = grupo[0]
	var melhor_rank: int = 999
	for id: StringName in grupo:
		var def: CurseDef = perfil.definicao_de(id)
		var rar: StringName = def.raridade if def != null else &"comum"
		var rank: int = ORDEM_RARIDADES_REGULARES.find(rar)
		if rank < 0:
			rank = 999
		if rank < melhor_rank:
			melhor_rank = rank
			melhor_id = id
	return melhor_id


static func _escolha_ponderada(grupo: Array[StringName], perfil: PerfilVinculo,
		tuning: VinculoTuning, u: float) -> StringName:
	if grupo.is_empty():
		return &""
	var pesos: Array[float] = []
	var soma: float = 0.0
	for id: StringName in grupo:
		var def: CurseDef = perfil.definicao_de(id)
		var rar: StringName = def.raridade if def != null else &"comum"
		var w: float = _peso_da_raridade(rar, tuning)
		pesos.append(w)
		soma += w
	if soma <= 0.0:
		return grupo[0]
	var alvo: float = clampf(u, 0.0, 1.0 - 1e-12) * soma
	var acum: float = 0.0
	for i: int in grupo.size():
		acum += pesos[i]
		if alvo < acum - 1e-12:
			return grupo[i]
	return grupo[grupo.size() - 1]


static func _peso_da_raridade(raridade: StringName, tuning: VinculoTuning) -> float:
	var idx: int = ORDEM_RARIDADES_REGULARES.find(raridade)
	if idx >= 0 and tuning != null and idx < tuning.peso_raridade.size():
		return maxf(0.0, float(tuning.peso_raridade[idx]))
	const PADRAO: Array[float] = [3.0, 2.0, 1.0, 1.0]
	if idx >= 0 and idx < PADRAO.size():
		return PADRAO[idx]
	return 1.0
