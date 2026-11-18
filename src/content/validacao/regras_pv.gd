class_name RegrasPv
extends ValidadorDoDono
## PV1–PV8 (Portas e recompensas; GDD portas-e-recompensas.md §Validação da RewardTable
## e GDD de Conteúdo R9): PV1/PV2/PV7 (erros), PV3/PV4/PV6 (avisos), PV5 e PV8 (avisos
## na 2ª passada).
##
## Exemplo:
## [codeblock]
## var diags := RegrasPv.new().validar(itens)
## [/codeblock]

const PRIMEIRAS_VALIDAS: Array[StringName] = [&"bencao", &"fragmentos", &"cura"]
const SANTUARIO_CURA_PADRAO: float = 0.4


func prefixo() -> StringName:
	return &"PV"


func precisa_da_segunda_passada() -> bool:
	return true


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var santuario_cura := SANTUARIO_CURA_PADRAO
	var item_room := primeiro_da_classe(itens, "RoomTuning")
	if item_room != null:
		var rt_room := item_room.definicao as RoomTuning
		if rt_room.santuario_cura > 0.0:
			santuario_cura = rt_room.santuario_cura
	for item in itens_do_tipo(itens, &"reward_table"):
		var r := item.definicao as RewardTable
		if r == null:
			continue
		if r.chance_tres_portas < 0.0 or r.chance_tres_portas > 1.0 or r.cura_porta < 0.0 or r.cura_porta > 1.0 or r.fragmentos_porta_base < 0 or r.fragmentos_porta_passo < 1:
			out.append(Diagnostico.de_item(item, &"PV1", "reward_table", r.chance_tres_portas,
				"RewardTable: chance_tres_portas, cura_porta, fragmentos_porta_base ou fragmentos_porta_passo inválidos"))
		if not PRIMEIRAS_VALIDAS.has(r.primeira_recompensa):
			out.append(Diagnostico.de_item(item, &"PV2", "primeira_recompensa", r.primeira_recompensa,
				"RewardTable: primeira_recompensa %s fora de %s" % [r.primeira_recompensa, PRIMEIRAS_VALIDAS]))
		var peso_prov := float(r.pesos_portas.get(&"provacao", 0.0))
		if peso_prov > 0.0:
			out.append(Diagnostico.de_item(item, &"PV7", "pesos_portas.provacao", peso_prov,
				"RewardTable: peso de provacao > 0 no MVP"))
		var positivos := 0
		for k: StringName in r.pesos_portas:
			if float(r.pesos_portas[k]) > 0.0:
				positivos += 1
		if positivos < 3 and r.chance_tres_portas > 0.0:
			out.append(Diagnostico.de_item(item, &"PV3", "pesos_portas", r.pesos_portas,
				"RewardTable: menos de 3 tipos com peso > 0 e chance_tres_portas > 0", Diagnostico.Nivel.AVISO))
		if r.cura_porta >= santuario_cura:
			out.append(Diagnostico.de_item(item, &"PV4", "cura_porta", r.cura_porta,
				"RewardTable: cura_porta >= santuario_cura", Diagnostico.Nivel.AVISO))
		if r.chance_tres_portas > 0.6 or r.fragmentos_porta_base < 1 or r.fragmentos_porta_base > 4 or r.fragmentos_porta_passo < 2 or r.fragmentos_porta_passo > 5 or r.cura_porta < 0.15 or r.cura_porta > 0.39:
			out.append(Diagnostico.de_item(item, &"PV6", "reward_table", null,
				"RewardTable: campo fora da faixa de design", Diagnostico.Nivel.AVISO))
	return out


func validar_segunda_passada(itens: Array[ItemDoCatalogo], _catalogo: Catalogo) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var item_rt := primeiro_da_classe(itens, "RunTuning")
	var bencaos := itens_do_tipo(itens, &"boon")
	if bencaos.is_empty():
		return out
	for item_reg in itens_do_tipo(itens, &"region"):
		var reg := item_reg.definicao as RegionDef
		if reg == null:
			continue
		var n_jogaveis := reg.camaras.size()
		if item_rt != null:
			var rt := item_rt.definicao as RunTuning
			if rt.camaras_jogaveis.has(reg.id):
				n_jogaveis = int(rt.camaras_jogaveis[reg.id])
		var k_livres := 0
		for idx in range(0, mini(n_jogaveis, reg.camaras.size()) - 1):
			var prox := reg.camaras[idx + 1]
			if prox == &"combate":
				k_livres += 1
		if 1 + k_livres > bencaos.size():
			out.append(Diagnostico.de_item(item_reg, &"PV8", "camaras", 1 + k_livres,
				"RegionDef: %d escolhas de bênção possíveis > %d bênçãos no pool" % [1 + k_livres, bencaos.size()],
				Diagnostico.Nivel.AVISO))
	return out
