class_name V5NomesCanonicos
extends ValidadorDeRegra
## V5: ids, doutrinas e nomes PT-BR canônicos batem com o cânone após normalização
## Unicode NFC (GDD de Conteúdo R9, R9-P, R11; story 010 AC-13, AC-39, AC-40, AC-45, AC-60).
## Roda em CI / preparo sobre as definições carregadas e a tabela de localização.
##
## Exemplo:
## [codeblock]
## var v5 := V5NomesCanonicos.new(textos)
## var diags := v5.validar(itens)
## [/codeblock]

## Mapa canônico das 18 Tradições (`traditions.ts` / `FixtureBn.IDS`): id -> {doutrina, nome}.
const BENCAOS_CANONICAS: Dictionary = {
	&"trad_blade_traco_unico": {"doutrina": &"lamina", "nome": "O Traço Único"},
	&"trad_blade_lamina_pesada": {"doutrina": &"lamina", "nome": "A Lâmina Pesada"},
	&"trad_blade_corte_fantasma": {"doutrina": &"lamina", "nome": "O Corte Fantasma"},
	&"trad_resonance_fundo_poco": {"doutrina": &"ressonancia", "nome": "O Fundo do Poço"},
	&"trad_resonance_linha_contada": {"doutrina": &"ressonancia", "nome": "A Linha Contada"},
	&"trad_resonance_preco_nome": {"doutrina": &"ressonancia", "nome": "O Preço com Nome"},
	&"trad_guardian_muro_pedras": {"doutrina": &"guardiao", "nome": "O Muro de Pedras"},
	&"trad_guardian_voo_escudo": {"doutrina": &"guardiao", "nome": "O Voo do Escudo"},
	&"trad_guardian_armadura_vazia": {"doutrina": &"guardiao", "nome": "A Armadura Vazia"},
	&"trad_veil_penumbra": {"doutrina": &"veu", "nome": "A Penumbra"},
	&"trad_veil_sombra_viva": {"doutrina": &"veu", "nome": "A Sombra Viva"},
	&"trad_veil_fio_invisivel": {"doutrina": &"veu", "nome": "O Fio Invisível"},
	&"trad_transmutation_molde_vivo": {"doutrina": &"transmutacao", "nome": "O Molde Vivo"},
	&"trad_transmutation_forma_fixa": {"doutrina": &"transmutacao", "nome": "A Forma Fixa"},
	&"trad_transmutation_materia_residual": {"doutrina": &"transmutacao", "nome": "A Matéria Residual"},
	&"trad_pacts_primeiro_vinculo": {"doutrina": &"pactos", "nome": "O Primeiro Vínculo"},
	&"trad_pacts_os_que_ficam": {"doutrina": &"pactos", "nome": "Os Que Ficam"},
	&"trad_pacts_fardo_repartido": {"doutrina": &"pactos", "nome": "O Fardo Repartido"},
}

## Mapa canônico de armas (GDD armas-das-doutrinas.md R8; FabricaDeArmas.NOMES_CANONICOS).
const ARMAS_CANONICAS: Dictionary = {
	&"lamina": {
		"doutrina": &"lamina",
		"nome": "Lâmina do Juramento",
		"ataque": "Corte",
		"especial": "Investida",
	},
	&"ressonancia": {
		"doutrina": &"ressonancia",
		"nome": "Foco Ressonante",
		"ataque": "Pulso",
		"especial": "Onda de Ressonância",
	},
	&"pactos": {
		"doutrina": &"pactos",
		"nome": "Besta do Vínculo",
		"ataque": "Virote",
		"especial": "Chamado do Pacto",
	},
	&"guardiao": {
		"doutrina": &"guardiao",
		"nome": "Escudo-Bastião",
		"ataque": "Golpe de Escudo",
		"especial": "Muralha",
	},
	&"veu": {
		"doutrina": &"veu",
		"nome": "Adagas do Véu",
		"ataque": "Estocada",
		"especial": "Leque de Lâminas",
	},
	&"transmutacao": {
		"doutrina": &"transmutacao",
		"nome": "Cálice da Transmutação",
		"ataque": "Gota Corrosiva",
		"especial": "Transmutar",
	},
}

## Mapa canônico de inimigos: id -> nome PT-BR.
const INIMIGOS_CANONICOS: Dictionary = {
	&"eco_perdido": "Eco Perdido",
	&"anomalia_menor": "Anomalia Menor",
	&"fenda_errante": "Fenda Errante",
	&"anomalia_maior": "Anomalia Maior",
	&"soberano_do_limiar": "Soberano do Limiar",
}

## Mapa canônico de maldições (CurseDef): id -> nome PT-BR.
const MALDICOES_CANONICAS: Dictionary = {
	&"vulto_mudo": "Vulto Mudo",
	&"espreitador_da_fenda": "Espreitador da Fenda",
	&"baluarte_de_cinza": "Baluarte de Cinza",
	&"soberano_do_limiar": "Soberano do Limiar",
}

## Mapa canônico de regiões: id -> nome PT-BR.
const REGIOES_CANONICAS: Dictionary = {
	&"limiar": "Limiar da Beira",
	&"veio": "Veio Instável",
}

## Chave de categoria de maldições (R9-P, AC-45, AC-60).
const CHAVE_CATEGORIA_MALDICOES := "CURSE_CATEGORY_NAME"
const TERMO_CATEGORIA_CANONICO := "Maldições"
const TERMOS_PROIBIDOS_MALDICOES: PackedStringArray = ["Criaturas", "Laço dos Pactos"]

## Pares de decomposição NFD -> composição NFC para vogais e cedilha do português.
const _PARES_NFD_NFC: Array = [
	["a\u0301", "á"], ["a\u0300", "à"], ["a\u0302", "â"], ["a\u0303", "ã"],
	["e\u0301", "é"], ["e\u0302", "ê"],
	["i\u0301", "í"],
	["o\u0301", "ó"], ["o\u0302", "ô"], ["o\u0303", "õ"],
	["u\u0301", "ú"], ["u\u0308", "ü"],
	["c\u0327", "ç"],
	["A\u0301", "Á"], ["A\u0300", "À"], ["A\u0302", "Â"], ["A\u0303", "Ã"],
	["E\u0301", "É"], ["E\u0302", "Ê"],
	["I\u0301", "Í"],
	["O\u0301", "Ó"], ["O\u0302", "Ô"], ["O\u0303", "Õ"],
	["U\u0301", "Ú"], ["U\u0308", "Ü"],
	["C\u0327", "Ç"],
]

var _textos: TabelaDeTextos


func _init(textos: TabelaDeTextos) -> void:
	_textos = textos


## Normaliza sequências Unicode decompostas (NFD) para a forma composta canônica (NFC).
static func normalizar_nfc(texto: String) -> String:
	var out := texto
	for par: Array in _PARES_NFD_NFC:
		out = out.replace(String(par[0]), String(par[1]))
	return out


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	for item in itens:
		var def := item.definicao
		if def is BoonDef:
			_validar_bencao(item, def as BoonDef, out)
		elif def is WeaponDef:
			_validar_arma(item, def as WeaponDef, out)
		elif def is EnemyDef:
			_validar_inimigo(item, def as EnemyDef, out)
		elif def is CurseDef:
			_validar_maldicao(item, def as CurseDef, out)
		elif def is RegionDef:
			_validar_regiao(item, def as RegionDef, out)
	if _textos != null and _textos.tem(CHAVE_CATEGORIA_MALDICOES):
		var cat_txt := normalizar_nfc(_textos.texto(CHAVE_CATEGORIA_MALDICOES))
		if cat_txt != TERMO_CATEGORIA_CANONICO:
			var d := Diagnostico.novo(
				&"V5",
				CHAVE_CATEGORIA_MALDICOES,
				cat_txt,
				"%s: \"%s\" ≠ canônico \"%s\"" % [CHAVE_CATEGORIA_MALDICOES, cat_txt, TERMO_CATEGORIA_CANONICO]
			)
			d.tipo = &"curse"
			out.append(d)
	return out


func _validar_bencao(item: ItemDoCatalogo, b: BoonDef, out: Array[Diagnostico]) -> void:
	if not BENCAOS_CANONICAS.has(b.id):
		out.append(Diagnostico.de_item(
			item, &"V5", "id", b.id,
			"%s: id '%s' não pertence às 18 bênçãos canônicas" % [rotulo(item), b.id]
		))
		return
	var esp: Dictionary = BENCAOS_CANONICAS[b.id]
	var doutrina_esp: StringName = esp["doutrina"]
	var nome_esp: String = esp["nome"]
	if b.doutrina != doutrina_esp:
		out.append(Diagnostico.de_item(
			item, &"V5", "doutrina", b.doutrina,
			"%s: doutrina '%s' ≠ canônico '%s'" % [rotulo(item), b.doutrina, doutrina_esp]
		))
	_conferir_nome(item, "chave_nome", String(b.chave_nome), nome_esp, out)


func _validar_arma(item: ItemDoCatalogo, w: WeaponDef, out: Array[Diagnostico]) -> void:
	if not ARMAS_CANONICAS.has(w.id):
		out.append(Diagnostico.de_item(
			item, &"V5", "id", w.id,
			"%s: arma '%s' fora do cânone" % [rotulo(item), w.id]
		))
		return
	var esp: Dictionary = ARMAS_CANONICAS[w.id]
	if w.doutrina != esp["doutrina"]:
		out.append(Diagnostico.de_item(
			item, &"V5", "doutrina", w.doutrina,
			"%s: doutrina '%s' ≠ canônico '%s'" % [rotulo(item), w.doutrina, esp["doutrina"]]
		))
	_conferir_nome(item, "chave_nome", String(w.chave_nome), String(esp["nome"]), out)
	if w.ataque != null:
		_conferir_nome(item, "ataque.chave_nome", String(w.ataque.chave_nome), String(esp["ataque"]), out)
	if w.especial != null:
		_conferir_nome(item, "especial.chave_nome", String(w.especial.chave_nome), String(esp["especial"]), out)


func _validar_inimigo(item: ItemDoCatalogo, e: EnemyDef, out: Array[Diagnostico]) -> void:
	if not INIMIGOS_CANONICOS.has(e.id):
		out.append(Diagnostico.de_item(
			item, &"V5", "id", e.id,
			"%s: inimigo '%s' fora do cânone" % [rotulo(item), e.id]
		))
		return
	_conferir_nome(item, "chave_nome", String(e.chave_nome), String(INIMIGOS_CANONICOS[e.id]), out)


func _validar_maldicao(item: ItemDoCatalogo, c: CurseDef, out: Array[Diagnostico]) -> void:
	if not MALDICOES_CANONICAS.has(c.id):
		out.append(Diagnostico.de_item(
			item, &"V5", "id", c.id,
			"%s: maldição '%s' fora do cânone" % [rotulo(item), c.id]
		))
		return
	_conferir_nome(item, "chave_nome", String(c.chave_nome), String(MALDICOES_CANONICAS[c.id]), out)


func _validar_regiao(item: ItemDoCatalogo, r: RegionDef, out: Array[Diagnostico]) -> void:
	if not REGIOES_CANONICAS.has(r.id):
		out.append(Diagnostico.de_item(
			item, &"V5", "id", r.id,
			"%s: região '%s' fora do cânone" % [rotulo(item), r.id]
		))
		return
	_conferir_nome(item, "chave_nome", String(r.chave_nome), String(REGIOES_CANONICAS[r.id]), out)


func _conferir_nome(
	item: ItemDoCatalogo,
	campo: String,
	chave: String,
	esperado: String,
	out: Array[Diagnostico]
) -> void:
	if _textos == null or chave.is_empty() or not _textos.tem(chave):
		return
	var obtido_nfc := normalizar_nfc(_textos.texto(chave))
	var esperado_nfc := normalizar_nfc(esperado)
	if obtido_nfc != esperado_nfc:
		out.append(Diagnostico.de_item(
			item, &"V5", campo, obtido_nfc,
			"%s: nome \"%s\" ≠ canônico \"%s\"" % [rotulo(item), obtido_nfc, esperado_nfc]
		))
