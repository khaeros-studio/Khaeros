class_name ImportadorDeCanone
extends RefCounted
## Importador de preparo do cânone para recursos [code].tres[/code] do Godot
## (GDD de Conteúdo R1, R2, R6, R8, R11, Formulas F1–F6; ADR-0004; story 010 de
## conteudo e story 005 de assets-e-conteudo).
## Aplica exclusivamente as fórmulas F1–F6 de [Unidades], as constantes escondidas
## do cânone (`valor = value * constante` e `params`) e o arquivo
## [code]assets/data/canon/mapa_ids.csv[/code].
## Qualquer token canônico sem mapeamento em [code]mapa_ids.csv[/code] ou arena não
## uniforme interrompe a importação com erro explícito (AC-20, AC-30, AC-37, AC-39).
##
## Exemplo:
## [codeblock]
## var mapa := ImportadorDeCanone.carregar_mapa_ids()
## var r := ImportadorDeCanone.traduzir_id(mapa, "doutrina", "BLADE")
## assert(r["ok"] and r["id_godot"] == &"lamina")
## [/codeblock]

const CAMINHO_MAPA_IDS := "res://assets/data/canon/mapa_ids.csv"
const REGRA_IMPORTACAO := &"IMPORTACAO"

## Constantes escondidas no código do cânone para efeitos de bênçãos (GDD Edge Cases l. 896–908; AC-34, AC-41).
const CONSTANTES_EFEITOS: Dictionary = {
	&"corte_da_esquiva": {
		"constante": 10.0,
		"escala": true,
		"params": {&"sangramento": 1.0, &"alcance_extra_px": 9.0, &"empurrao": 360.0},
	},
	&"dano_vida_baixa_pct": {
		"constante": 1.0,
		"escala": true,
		"params": {&"limiar_vida": 0.5},
	},
	&"dano_enesimo_acerto": {
		"constante": 1.0,
		"escala": true,
		"params": {&"a_cada": 4.0},
	},
	&"dano_apos_esquiva": {
		"constante": 0.5,
		"escala": true,
		"params": {&"janela_s": 1.5},
	},
	&"selo_abala": {
		"constante": 1.0,
		"escala": false,
		"params": {&"duracao_s": 0.5},
	},
	&"explosao_ao_abater": {
		"constante": 12.0,
		"escala": true,
		"params": {&"raio_px": 150.0, &"empurrao": 720.0},
	},
	&"recusas_morte": {
		"constante": 1.0,
		"escala": false,
		"params": {&"vida_ao_voltar": 0.4, &"invuln_s": 2.0},
	},
	&"refletir_dano": {
		"constante": 3.0,
		"escala": true,
		"params": {},
	},
}


## Carrega [code]mapa_ids.csv[/code] num dicionário aninhado `mapa[tipo][id_canon] = StringName(id_godot)`.
static func carregar_mapa_ids(caminho: String = CAMINHO_MAPA_IDS) -> Dictionary:
	var mapa: Dictionary = {}
	if not FileAccess.file_exists(caminho):
		return mapa
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		return mapa
	var primeira := true
	while not f.eof_reached():
		var linha := f.get_csv_line()
		if linha.size() < 3:
			continue
		var tipo := linha[0].strip_edges()
		var id_canon := linha[1].strip_edges()
		var id_godot := linha[2].strip_edges()
		if primeira and tipo == "tipo" and id_canon == "id_canon":
			primeira = false
			continue
		primeira = false
		if tipo.is_empty() or id_canon.is_empty() or id_godot.is_empty():
			continue
		if not mapa.has(tipo):
			mapa[tipo] = {}
		(mapa[tipo] as Dictionary)[id_canon] = StringName(id_godot)
	return mapa


## Traduz `(tipo, id_canon)` usando [param mapa]. Falha com [Diagnostico] se não houver
## entrada em `mapa_ids.csv` — nunca repassa o token canônico cru (AC-20, AC-39).
static func traduzir_id(mapa: Dictionary, tipo: String, id_canon: String) -> Dictionary:
	if mapa.has(tipo):
		var sub: Dictionary = mapa[tipo]
		if sub.has(id_canon):
			return {
				"ok": true,
				"id_godot": sub[id_canon],
				"erro": null,
			}
	var d := Diagnostico.novo(
		REGRA_IMPORTACAO,
		tipo,
		id_canon,
		"token canônico '%s' do tipo '%s' sem mapeamento em mapa_ids.csv" % [id_canon, tipo]
	)
	d.arquivo = CAMINHO_MAPA_IDS
	return {
		"ok": false,
		"id_godot": &"",
		"erro": d,
	}


## Valida se a arena canônica tem escala uniforme com `1280 × 720` (AC-30, AC-37).
static func verificar_arena_canone(largura_canon: float, altura_canon: float) -> Diagnostico:
	if Unidades.escala_uniforme(largura_canon, altura_canon):
		return null
	return Diagnostico.novo(
		REGRA_IMPORTACAO,
		"arena",
		"%sx%s" % [largura_canon, altura_canon],
		"arena canônica %sx%s sem escala uniforme com 1280x720" % [largura_canon, altura_canon]
	)


## Converte um efeito canônico (`mod`, `value`) em [EffectDef] aplicando `mapa_ids.csv`
## e a constante escondida do cânone (`valor = value * constante` + `params`; AC-34, AC-41).
static func converter_efeito_canonico(
	mapa: Dictionary,
	mod_canon: String,
	valor_canon: float,
	escala_override: Variant = null,
	params_extras: Dictionary = {}
) -> Dictionary:
	var tr_tipo := traduzir_id(mapa, "efeito", mod_canon)
	if not bool(tr_tipo["ok"]):
		return {"ok": false, "efeito": null, "erro": tr_tipo["erro"]}
	var tipo_godot: StringName = tr_tipo["id_godot"]
	if not TabelaDeEfeitos.existe(tipo_godot):
		var d := Diagnostico.novo(
			REGRA_IMPORTACAO,
			"efeito.tipo",
			tipo_godot,
			"tipo de efeito '%s' ausente na TabelaDeEfeitos" % tipo_godot
		)
		return {"ok": false, "efeito": null, "erro": d}
	var info: Dictionary = CONSTANTES_EFEITOS.get(tipo_godot, {
		"constante": 1.0,
		"escala": valor_canon > 0.0 and tipo_godot != &"cargas_esquiva" and tipo_godot != &"trocas_oferta",
		"params": {},
	})
	var ef := EffectDef.new()
	ef.tipo = tipo_godot
	ef.valor = valor_canon * float(info["constante"])
	ef.escala_com_raridade = bool(escala_override) if escala_override != null else bool(info["escala"])
	var params_tipado: Dictionary[StringName, float] = {}
	var params_base: Dictionary = info["params"]
	for k: Variant in params_base:
		params_tipado[StringName(str(k))] = float(params_base[k])
	for k: Variant in params_extras:
		params_tipado[StringName(str(k))] = float(params_extras[k])
	ef.params = params_tipado
	return {"ok": true, "efeito": ef, "erro": null}


## Converte um registro canônico de tradição num [BoonDef].
## Os ids `trad_*` são mantidos iguais aos de `traditions.ts` sem passar pelo mapa (R2, AC-39);
## a doutrina canônica (`BLADE`, `RESONANCE`...) passa por `mapa_ids.csv`.
static func converter_tradicao(mapa: Dictionary, dados: Dictionary) -> Dictionary:
	var id_canon := String(dados.get("id", ""))
	if not id_canon.begins_with("trad_"):
		var d := Diagnostico.novo(REGRA_IMPORTACAO, "bencao.id", id_canon, "id de tradição inválido: %s" % id_canon)
		return {"ok": false, "definicao": null, "erro": d}
	var doutrina_canon := String(dados.get("doctrine", ""))
	var tr_dout := traduzir_id(mapa, "doutrina", doutrina_canon)
	if not bool(tr_dout["ok"]):
		return {"ok": false, "definicao": null, "erro": tr_dout["erro"]}
	var b := BoonDef.new()
	b.id = StringName(id_canon)
	b.doutrina = tr_dout["id_godot"]
	b.chave_nome = StringName(String(dados.get("chave_nome", id_canon.to_upper() + "_NAME")))
	b.chave_descricao = StringName(String(dados.get("chave_descricao", id_canon.to_upper() + "_DESC")))
	b.glifo = StringName(String(dados.get("glifo", "")))
	b.icone_ganho = String(dados.get("icone_ganho", ""))
	b.chave_preco = StringName(String(dados.get("chave_preco", "")))
	var efeitos_brutos: Array = dados.get("efeitos", [])
	for ef_dict: Dictionary in efeitos_brutos:
		var esc_ov: Variant = ef_dict.get("escala_com_raridade", null)
		var r_ef := converter_efeito_canonico(
			mapa,
			String(ef_dict.get("mod", "")),
			float(ef_dict.get("value", 0.0)),
			esc_ov,
			ef_dict.get("params", {})
		)
		if not bool(r_ef["ok"]):
			return {"ok": false, "definicao": null, "erro": r_ef["erro"]}
		b.efeitos.append(r_ef["efeito"] as EffectDef)
	return {"ok": true, "definicao": b, "erro": null}


## Converte um registro canônico de arma (`ARENA_WEAPONS`) num [WeaponDef] aplicando F1, F2, F4, F5, F6.
static func converter_arma(mapa: Dictionary, dados: Dictionary) -> Dictionary:
	var id_canon := String(dados.get("id", ""))
	var tr_id := traduzir_id(mapa, "arma", id_canon)
	if not bool(tr_id["ok"]):
		return {"ok": false, "definicao": null, "erro": tr_id["erro"]}
	var doutrina_canon := String(dados.get("doctrine", id_canon))
	var tr_dout := traduzir_id(mapa, "doutrina", doutrina_canon)
	if not bool(tr_dout["ok"]):
		return {"ok": false, "definicao": null, "erro": tr_dout["erro"]}
	var id_godot: StringName = tr_id["id_godot"]
	var prefixo := "WEAPON_%s" % String(id_godot).to_upper()
	var w := WeaponDef.new()
	w.id = id_godot
	w.doutrina = tr_dout["id_godot"]
	w.chave_nome = StringName(String(dados.get("chave_nome", prefixo + "_NAME")))
	w.vida_max = int(dados.get("maxHp", 100))
	w.velocidade = Unidades.velocidade_para_pxs(float(dados.get("moveSpeed", 4.3)))
	var r_atq := _converter_ataque(mapa, dados.get("attack", {}), prefixo + "_ATK")
	if not bool(r_atq["ok"]):
		return {"ok": false, "definicao": null, "erro": r_atq["erro"]}
	var r_esp := _converter_ataque(mapa, dados.get("special", {}), prefixo + "_ESP")
	if not bool(r_esp["ok"]):
		return {"ok": false, "definicao": null, "erro": r_esp["erro"]}
	w.ataque = r_atq["ataque"]
	w.especial = r_esp["ataque"]
	return {"ok": true, "definicao": w, "erro": null}


static func _converter_ataque(mapa: Dictionary, d: Dictionary, chave_padrao: String) -> Dictionary:
	var forma_canon := String(d.get("shape", ""))
	var tr_forma := traduzir_id(mapa, "forma_ataque", forma_canon)
	if not bool(tr_forma["ok"]):
		return {"ok": false, "ataque": null, "erro": tr_forma["erro"]}
	var a := AttackDef.new()
	a.chave_nome = StringName(String(d.get("chave_nome", chave_padrao)))
	a.forma = tr_forma["id_godot"]
	a.dano = float(d.get("damage", 0.0))
	a.recarga_s = Unidades.ticks_para_segundos(int(d.get("cooldownTicks", 16)))
	a.empurrao = Unidades.velocidade_para_pxs(float(d.get("knockback", 0.0)))
	var params_t: Dictionary[StringName, float] = {}
	match a.forma:
		&"arco":
			params_t[&"alcance_px"] = Unidades.unidade_para_px(float(d.get("range", 95.0)))
			params_t[&"meio_angulo_graus"] = Unidades.arredondar_casas(
				Unidades.arco_meio_angulo_graus(float(d.get("dot", 0.35))), 2
			)
		&"avanco":
			params_t[&"distancia_px"] = Unidades.unidade_para_px(float(d.get("distance", 220.0)))
			params_t[&"duracao_s"] = Unidades.ticks_para_segundos(int(d.get("durationTicks", 10)))
			params_t[&"raio_px"] = Unidades.unidade_para_px(float(d.get("radius", 46.0)))
		&"projetil":
			params_t[&"velocidade_pxs"] = Unidades.velocidade_para_pxs(float(d.get("projectileSpeed", 11.0)))
			params_t[&"raio_px"] = Unidades.unidade_para_px(float(d.get("radius", 10.0)))
			params_t[&"vida_s"] = Unidades.vida_do_projetil_s(int(d.get("rangeTicks", 50)))
			a.leque = PackedFloat64Array(d.get("spread", [0.0]))
			a.atravessa = bool(d.get("pierce", false))
		&"circulo":
			params_t[&"raio_px"] = Unidades.unidade_para_px(float(d.get("radius", 130.0)))
			params_t[&"deslocamento_px"] = Unidades.unidade_para_px(float(d.get("offset", 0.0)))
	a.params = params_t
	if d.has("combo"):
		a.multiplicadores_combo = PackedFloat64Array(d["combo"])
	var status_canon := String(d.get("status", ""))
	if not status_canon.is_empty():
		var tr_st := traduzir_id(mapa, "status", status_canon)
		if not bool(tr_st["ok"]):
			return {"ok": false, "ataque": null, "erro": tr_st["erro"]}
		a.status = tr_st["id_godot"]
	return {"ok": true, "ataque": a, "erro": null}


## Converte um registro canônico de inimigo (`ARENA_ENEMIES`) num [EnemyDef] aplicando F1, F2 e F4.
static func converter_inimigo(mapa: Dictionary, dados: Dictionary) -> Dictionary:
	var id_canon := String(dados.get("id", ""))
	var tr_id := traduzir_id(mapa, "inimigo", id_canon)
	if not bool(tr_id["ok"]):
		return {"ok": false, "definicao": null, "erro": tr_id["erro"]}
	var comp_canon := String(dados.get("behavior", ""))
	var tr_comp := traduzir_id(mapa, "comportamento", comp_canon)
	if not bool(tr_comp["ok"]):
		return {"ok": false, "definicao": null, "erro": tr_comp["erro"]}
	var id_godot: StringName = tr_id["id_godot"]
	var e := EnemyDef.new()
	e.id = id_godot
	e.chave_nome = StringName(String(dados.get("chave_nome", "ENEMY_%s_NAME" % String(id_godot).to_upper())))
	e.comportamento = tr_comp["id_godot"]
	e.vida = float(dados.get("hp", 30.0))
	e.velocidade = Unidades.velocidade_para_pxs(float(dados.get("speed", 1.7)))
	e.raio_px = Unidades.unidade_para_px(float(dados.get("radius", 16.0)))
	e.dano = float(dados.get("damage", 9.0))
	e.alcance_px = Unidades.unidade_para_px(float(dados.get("range", 30.0)))
	e.preparo_s = Unidades.ticks_para_segundos(int(dados.get("windupTicks", 26)))
	e.recarga_s = Unidades.ticks_para_segundos(int(dados.get("cooldownTicks", 60)))
	e.velocidade_projetil = Unidades.velocidade_para_pxs(float(dados.get("projectileSpeed", 0.0)))
	e.custo_onda = int(dados.get("cost", 1))
	return {"ok": true, "definicao": e, "erro": null}
