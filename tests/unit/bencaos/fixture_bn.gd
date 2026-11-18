class_name FixtureBn
extends RefCounted
## Fixture BN (GDD bencaos-tradicoes.md, Acceptance Criteria): as 18 BoonDef na ordem
## canônica de TRADITION_SUBCHOICES (Khaeros traditions.ts) com os efeitos de
## BOON_EFFECTS mapeados pela TabelaDeEfeitos, RarityTable e BencaosTuning de fábrica.
## Provisória até os .tres de fábrica existirem (conteudo story-010 / assets-e-conteudo).

## Ids na ordem do manifesto (índice → id).
const IDS: Array[StringName] = [
	&"trad_blade_traco_unico", &"trad_blade_lamina_pesada", &"trad_blade_corte_fantasma",
	&"trad_resonance_fundo_poco", &"trad_resonance_linha_contada", &"trad_resonance_preco_nome",
	&"trad_guardian_muro_pedras", &"trad_guardian_voo_escudo", &"trad_guardian_armadura_vazia",
	&"trad_veil_penumbra", &"trad_veil_sombra_viva", &"trad_veil_fio_invisivel",
	&"trad_transmutation_molde_vivo", &"trad_transmutation_forma_fixa", &"trad_transmutation_materia_residual",
	&"trad_pacts_primeiro_vinculo", &"trad_pacts_os_que_ficam", &"trad_pacts_fardo_repartido",
]

## Efeito principal (tipo, valor, escala) por índice, de BOON_EFFECTS.
const EFEITOS: Array = [
	[&"dano_ataque_pct", 0.25, true], [&"dano_especial_pct", 0.4, true], [&"corte_da_esquiva", 1.0, true],
	[&"dano_vida_baixa_pct", 0.4, true], [&"dano_enesimo_acerto", 0.6, true], [&"dano_todo_pct", 0.2, true],
	[&"vida_max_plano", 25.0, true], [&"reducao_dano", 0.12, true], [&"escudo_sala", 15.0, true],
	[&"dano_apos_esquiva", 1.0, true], [&"golpe_sangramento", 1.0, true], [&"velocidade_pct", 0.12, true],
	[&"golpe_queimadura", 1.0, true], [&"dano_selo_pct", 0.6, true], [&"explosao_ao_abater", 1.0, true],
	[&"cura_ao_abater", 2.0, true], [&"recusas_morte", 1.0, false], [&"refletir_dano", 1.0, true],
]

const PESOS_FABRICA: PackedFloat64Array = [0.6, 0.3, 0.1]
const ESCALAS_FABRICA: PackedFloat64Array = [1.0, 1.5, 2.0]
const TAMANHO_OFERTA_FABRICA: int = 3


## As 18 BoonDef, na ordem do manifesto.
static func boons() -> Array[BoonDef]:
	var out: Array[BoonDef] = []
	for i: int in IDS.size():
		var b := BoonDef.new()
		b.id = IDS[i]
		b.chave_nome = StringName(String(IDS[i]).to_upper() + "_NAME")
		b.chave_descricao = StringName(String(IDS[i]).to_upper() + "_DESC")
		var e := EffectDef.new()
		e.tipo = EFEITOS[i][0]
		e.valor = EFEITOS[i][1]
		e.escala_com_raridade = EFEITOS[i][2]
		b.efeitos = [e] as Array[EffectDef]
		out.append(b)
	return out


## Os primeiros [param n] da fixture (pool injetado menor).
static func boons_ate(n: int) -> Array[BoonDef]:
	return boons().slice(0, n)


## RarityTable de fábrica (0,6/0,3/0,1; 1/1,5/2).
static func tabela() -> RarityTable:
	var t := RarityTable.new()
	t.id = &"rarity_table"
	t.pesos = PESOS_FABRICA
	t.escalas = ESCALAS_FABRICA
	return t


## BencaosTuning de fábrica (3, 0, 0).
static func tuning(bonus: float = 0.0) -> BencaosTuning:
	var t := BencaosTuning.new()
	t.id = &"bencaos_tuning"
	t.tamanho_oferta = TAMANHO_OFERTA_FABRICA
	t.trocas_iniciais = 0
	t.raridade_bonus = bonus
	return t


## Itens de catálogo para os validadores (tuning e tabela).
static func itens(tuning_bn: BencaosTuning, tabela_r: RarityTable) -> Array[ItemDoCatalogo]:
	var out: Array[ItemDoCatalogo] = []
	out.append(ItemDoCatalogo.new(&"tuning", "res://teste/tuning/bencaos_tuning.tres", 0, tuning_bn))
	out.append(ItemDoCatalogo.new(&"rarity_table", "res://teste/rarity_table/rarity_table.tres", 1, tabela_r))
	return out
