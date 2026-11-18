class_name RegrasBn
extends ValidadorDoDono
## BN1–BN2 (Bênçãos, erros; GDD bencaos-tradicoes.md "Tuning Knobs" > Validação;
## ADR-0004): BN1 [code]tamanho_oferta[/code] ≠ 3 no MVP (4–5 reservado) ou fora de
## 1–5, ou [code]trocas_iniciais[/code] negativa; BN2 [RarityTable] com pesos que não
## somam > 0 ou escalas não crescentes (ou listas de tamanhos diferentes).
## Entra no mesmo relatório do catálogo via [method ValidadorDeCatalogo.acrescentar].
##
## Exemplo:
## [codeblock]
## var diags := RegrasBn.new().validar(itens)
## [/codeblock]

## Faixa do knob (GDD Tuning Knobs) e o único valor aceito no MVP (R3/R4 fixam 3 reais).
## São regras de validação, não valores de gameplay.
const TAMANHO_OFERTA_MIN: int = 1
const TAMANHO_OFERTA_MAX: int = 5
const TAMANHO_OFERTA_MVP: int = 3


func prefixo() -> StringName:
	return &"BN"


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var item_t := primeiro_da_classe(itens, "BencaosTuning")
	if item_t != null:
		var t := item_t.definicao as BencaosTuning
		if t.tamanho_oferta < TAMANHO_OFERTA_MIN or t.tamanho_oferta > TAMANHO_OFERTA_MAX:
			out.append(Diagnostico.de_item(item_t, &"BN1", "tamanho_oferta", t.tamanho_oferta,
				"BencaosTuning: tamanho_oferta %d fora de %d–%d" % [t.tamanho_oferta, TAMANHO_OFERTA_MIN, TAMANHO_OFERTA_MAX]))
		elif t.tamanho_oferta != TAMANHO_OFERTA_MVP:
			out.append(Diagnostico.de_item(item_t, &"BN1", "tamanho_oferta", t.tamanho_oferta,
				"BencaosTuning: tamanho_oferta %d reservado (MVP exige %d)" % [t.tamanho_oferta, TAMANHO_OFERTA_MVP]))
		if t.trocas_iniciais < 0 or t.trocas_iniciais > 5:
			out.append(Diagnostico.de_item(item_t, &"BN1", "trocas_iniciais", t.trocas_iniciais,
				"BencaosTuning: trocas_iniciais %d fora de 0–5" % t.trocas_iniciais))
		if t.raridade_bonus < 0.0 - 1e-9 or t.raridade_bonus > 1.0 + 1e-9:
			out.append(Diagnostico.de_item(item_t, &"BN1", "raridade_bonus", t.raridade_bonus,
				"BencaosTuning: raridade_bonus %s fora de 0–1" % str(t.raridade_bonus)))
	for item_r in itens_do_tipo(itens, &"rarity_table"):
		var r := item_r.definicao as RarityTable
		var soma: float = 0.0
		for p: float in r.pesos:
			soma += p
		if not (soma > 0.0):
			out.append(Diagnostico.de_item(item_r, &"BN2", "pesos", r.pesos, "RarityTable: pesos não somam > 0"))
		if r.escalas.size() != r.pesos.size():
			out.append(Diagnostico.de_item(item_r, &"BN2", "escalas", r.escalas,
				"RarityTable: %d escalas para %d pesos" % [r.escalas.size(), r.pesos.size()]))
		for i: int in range(1, r.escalas.size()):
			if not (r.escalas[i] > r.escalas[i - 1]):
				out.append(Diagnostico.de_item(item_r, &"BN2", "escalas", r.escalas, "RarityTable: escalas não crescentes"))
				break
	return out
