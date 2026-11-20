class_name ArvoreDosReinos
extends RefCounted
## Árvore dos 9 Reinos Jogáveis de Khaeros em escalada roguelike crescente.
##
## Unifica as 4 regiões canônicas de [CatalogoCampanha] e os 5 reinos avançados de
## [CatalogoMapasBosses] em um grafo DAG de 9 nós (índices 0..8, Tiers 1..3),
## preservando imutabilidade por cópia profunda e 100% de determinismo (zero RNG).

const TOTAL_REINOS: int = 9
const CAMERA_ZOOM_ORIGINAL: float = 1.12
const LARGURA_ARENA_REF: float = 2400.0
const ALTURA_ARENA_REF: float = 1350.0


## Retorna cópias profundas e independentes dos 9 reinos jogáveis em ordem de escalada (0..8).
static func reinos() -> Array[Dictionary]:
	return _construir_reinos()


## Retorna cópia profunda do reino de índice [param idx] (0..8), ou {} se inválido.
static func obter_reino(idx: int) -> Dictionary:
	if idx < 0 or idx >= TOTAL_REINOS:
		return {}
	var lista: Array[Dictionary] = _construir_reinos()
	if idx >= lista.size():
		return {}
	return lista[idx]


## Retorna cópia profunda do reino cujo identificador é [param reg_id], ou {} se não existir.
static func obter_por_id(reg_id: String) -> Dictionary:
	if reg_id.is_empty():
		return {}
	var lista: Array[Dictionary] = _construir_reinos()
	for reino: Dictionary in lista:
		var id_atual: String = String(reino.get("id", ""))
		if id_atual == reg_id:
			return reino
	return {}


## Retorna o número total de reinos jogáveis na Árvore (9).
static func total_reinos() -> int:
	return TOTAL_REINOS


static func _construir_reinos() -> Array[Dictionary]:
	var originais_por_id: Dictionary = _mapear_originais_por_id()

	var lista: Array[Dictionary] = [
		_montar_reino_original(
			0,
			originais_por_id,
			"limiar",
			"As Lajes do Primeiro Juramento",
			"D",
			1,
			1,
			1.0,
			1.0,
			Vector2(0.50, 0.86),
			[1, 2],
			"queda_soberano",
			["Elo de Ouro Partido", "Selo do Juramento Subjugado"]
		),
		_montar_reino_avancado(
			1,
			"colina_raizes_profundas",
			"Colina das Raízes Profundas",
			"Clareira do Sensor Vivo",
			"C+",
			21,
			1,
			1.35,
			1.15,
			Vector2(0.24, 0.72),
			[3],
			"coroa_de_espinhos",
			"Pise apenas nas lajes antigas — cada raiz viva escuta o peso dos seus passos.",
			"devorador",
			28,
			_ondas_colina_raizes()
		),
		_montar_reino_original(
			2,
			originais_por_id,
			"veio_instavel",
			"Fissuras da Ressonância",
			"B",
			30,
			1,
			1.65,
			1.25,
			Vector2(0.76, 0.72),
			[3],
			"ecos_do_veio",
			["Assinatura de Bronze Ritual", "Contrato Sem Cláusula de Saída"]
		),
		_montar_reino_original(
			3,
			originais_por_id,
			"fosso_das_cinzas",
			"A Fornalha Silenciosa",
			"A",
			38,
			2,
			2.00,
			1.35,
			Vector2(0.50, 0.56),
			[4, 5],
			"forja_silenciada",
			["Núcleo de Cinza Primordial", "Martelo Rachado do Mestre Ferreiro"]
		),
		_montar_reino_avancado(
			4,
			"costa_abissal",
			"Costa Abissal",
			"Cais da Água Negra",
			"A+",
			48,
			2,
			2.40,
			1.48,
			Vector2(0.22, 0.42),
			[6],
			"mare_morta",
			"A maré negra sobe sobre o cais partido; os faróis marcam o último abrigo.",
			"leviata",
			40,
			_ondas_costa_abissal()
		),
		_montar_reino_avancado(
			5,
			"escarpas_copa_quebrada",
			"Escarpas da Copa Quebrada",
			"Platôs dos Seis Olhos",
			"A+",
			53,
			2,
			2.80,
			1.60,
			Vector2(0.78, 0.42),
			[6],
			"vigia_escarpa",
			"Entre platôs suspensos e abismos abertos, seis olhos medem cada salto.",
			"vigia",
			44,
			_ondas_escarpas_copa()
		),
		_montar_reino_original(
			6,
			originais_por_id,
			"santuario_partido",
			"Observatório Estrelado",
			"S-",
			64,
			3,
			3.30,
			1.75,
			Vector2(0.50, 0.30),
			[7],
			"santuario_partido",
			["Coração de Fenda Selado", "Lascas da Cúpula de Cristal Azul-Gelo"]
		),
		_montar_reino_avancado(
			7,
			"fendas_cinzentas",
			"Fendas Cinzentas",
			"Fosso-Prisão Imperial",
			"S",
			74,
			3,
			3.90,
			1.92,
			Vector2(0.32, 0.17),
			[8],
			"tirano_quebrado",
			"Grilhões partidos rangem no basalto; use os monólitos antes que o cerco se feche.",
			"tirano",
			56,
			_ondas_fendas_cinzentas()
		),
		_montar_reino_avancado(
			8,
			"terras_baldias_subterraneas",
			"Terras Baldias Subterrâneas",
			"Abismo dos Selos Antigos",
			"Cataclísmico",
			90,
			3,
			4.80,
			2.15,
			Vector2(0.50, 0.08),
			[],
			"pesadelo_selado",
			"Sob os selos quebrados do abismo, a luz sagrada é a última linha contra o vazio.",
			"pesadelo",
			75,
			_ondas_terras_baldias()
		),
	]
	return lista


static func _mapear_originais_por_id() -> Dictionary:
	var mapa: Dictionary = {}
	var originais: Array[Dictionary] = CatalogoCampanha.regioes()
	for reg: Dictionary in originais:
		var reg_id: String = String(reg.get("id", ""))
		if not reg_id.is_empty():
			mapa[reg_id] = reg
	return mapa


static func _montar_reino_original(
	indice: int,
	originais_por_id: Dictionary,
	reg_id: String,
	subtitulo: String,
	rank: String,
	nivel: int,
	tier: int,
	hp_mult: float,
	dmg_mult: float,
	tree_pos: Vector2,
	conexoes_raw: Array,
	quest_id: String,
	espolios_raw: Array
) -> Dictionary:
	var base_raw: Variant = originais_por_id.get(reg_id, {})
	var base: Dictionary = base_raw as Dictionary if base_raw is Dictionary else {}

	var paleta_raw: Variant = base.get("paleta", {})
	var paleta_src: Dictionary = paleta_raw as Dictionary if paleta_raw is Dictionary else {}
	var paleta: Dictionary = paleta_src.duplicate(true)

	var pilares: Array[Dictionary] = _copiar_pilares(base.get("pilares", []))
	var ondas: Array = _copiar_ondas(base.get("ondas", []))
	var espolios_copia_chefe: Array[String] = _copiar_strings(espolios_raw)
	var espolios_copia_reino: Array[String] = _copiar_strings(espolios_raw)
	var conexoes: Array[int] = _copiar_ints(conexoes_raw)

	var chefe_raw: Variant = base.get("chefe", {})
	var chefe_src: Dictionary = chefe_raw as Dictionary if chefe_raw is Dictionary else {}
	var chefe: Dictionary = {
		"id": String(chefe_src.get("id", "")),
		"nome": String(chefe_src.get("nome", "")),
		"vida": float(chefe_src.get("vida", 0.0)),
		"velocidade": float(chefe_src.get("velocidade", 0.0)),
		"raio": float(chefe_src.get("raio", 48.0)),
		"dano": float(chefe_src.get("dano", 0.0)),
		"boss_style": String(chefe_src.get("boss_style", "")),
		"fragmentos": int(chefe_src.get("fragmentos", 0)),
		"espolios": espolios_copia_chefe,
	}

	return {
		"indice": indice,
		"id": reg_id,
		"nome": String(base.get("nome", reg_id)),
		"subtitulo": subtitulo,
		"rank": rank,
		"nivel": nivel,
		"tier": tier,
		"hp_mult": hp_mult,
		"dmg_mult": dmg_mult,
		"camera_zoom": CAMERA_ZOOM_ORIGINAL,
		"bg": _cor_de(base, "bg", Color.BLACK),
		"floor": _cor_de(base, "floor", Color.BLACK),
		"accent": _cor_de(base, "accent", Color.WHITE),
		"border": _cor_de(base, "border", Color.GRAY),
		"motif": String(base.get("motif", reg_id)),
		"paleta": paleta,
		"fala_entrada": String(base.get("fala_entrada", "")),
		"pilares": pilares,
		"ondas": ondas,
		"chefe": chefe,
		"tree_pos": tree_pos,
		"conexoes": conexoes,
		"quest_id": quest_id,
		"espolios": espolios_copia_reino,
	}


static func _montar_reino_avancado(
	indice: int,
	reg_id: String,
	nome: String,
	subtitulo: String,
	rank: String,
	nivel: int,
	tier: int,
	hp_mult: float,
	dmg_mult: float,
	tree_pos: Vector2,
	conexoes_raw: Array,
	quest_id: String,
	fala_entrada: String,
	boss_style: String,
	fragmentos: int,
	ondas: Array
) -> Dictionary:
	var mapa: Dictionary = CatalogoMapasBosses.obter_mapa(reg_id)

	var paleta_raw: Variant = mapa.get("paleta", {})
	var paleta_src: Dictionary = paleta_raw as Dictionary if paleta_raw is Dictionary else {}
	var paleta: Dictionary = paleta_src.duplicate(true)

	var arena_raw: Variant = mapa.get("arena", {})
	var arena: Dictionary = arena_raw as Dictionary if arena_raw is Dictionary else {}
	var largura_arena: float = maxf(1.0, float(arena.get("largura", LARGURA_ARENA_REF)))
	var altura_arena: float = maxf(1.0, float(arena.get("altura", ALTURA_ARENA_REF)))

	var pilares: Array[Dictionary] = _converter_obstaculos_em_pilares(
		mapa.get("obstaculos", []),
		largura_arena,
		altura_arena
	)

	var boss_raw: Variant = mapa.get("boss", {})
	var boss_src: Dictionary = boss_raw as Dictionary if boss_raw is Dictionary else {}
	var espolios_boss: Array[String] = _extrair_nomes_espolios(boss_src.get("espolios", []))
	var conexoes: Array[int] = _copiar_ints(conexoes_raw)

	var chefe: Dictionary = {
		"id": String(boss_src.get("id", "")),
		"nome": String(boss_src.get("nome", "")),
		"vida": float(boss_src.get("vida", 0.0)),
		"velocidade": float(boss_src.get("velocidade", 0.0)),
		"raio": float(boss_src.get("raio_px", 60.0)),
		"dano": float(boss_src.get("dano", 0.0)),
		"boss_style": boss_style,
		"fragmentos": fragmentos,
		"espolios": _copiar_strings(espolios_boss),
	}

	return {
		"indice": indice,
		"id": reg_id,
		"nome": nome,
		"subtitulo": subtitulo,
		"rank": rank,
		"nivel": nivel,
		"tier": tier,
		"hp_mult": hp_mult,
		"dmg_mult": dmg_mult,
		"camera_zoom": float(mapa.get("camera_zoom", 1.0)),
		"bg": _cor_de(paleta, "bg", Color.BLACK),
		"floor": _cor_de(paleta, "floor", Color.BLACK),
		"accent": _cor_de(paleta, "accent", Color.WHITE),
		"border": _cor_de(paleta, "border", Color.GRAY),
		"motif": String(paleta.get("motif", reg_id)),
		"paleta": paleta,
		"fala_entrada": fala_entrada,
		"pilares": pilares,
		"ondas": _copiar_ondas(ondas),
		"chefe": chefe,
		"tree_pos": tree_pos,
		"conexoes": conexoes,
		"quest_id": quest_id,
		"espolios": _copiar_strings(espolios_boss),
	}


static func _converter_obstaculos_em_pilares(
	obstaculos_raw: Variant,
	largura_arena: float,
	altura_arena: float
) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	if not (obstaculos_raw is Array):
		return resultado
	var escala_x: float = LARGURA_ARENA_REF / largura_arena
	var escala_y: float = ALTURA_ARENA_REF / altura_arena
	var obstaculos: Array = obstaculos_raw as Array
	for item_var: Variant in obstaculos:
		if not (item_var is Dictionary):
			continue
		var item: Dictionary = item_var as Dictionary
		var pos_raw: Variant = item.get("pos", Vector2.ZERO)
		var pos: Vector2 = pos_raw as Vector2 if pos_raw is Vector2 else Vector2.ZERO
		var raio: float = float(item.get("raio", 46.0))
		resultado.append({
			"x": roundf(pos.x * escala_x),
			"y": roundf(pos.y * escala_y),
			"r": raio,
		})
	return resultado


static func _extrair_nomes_espolios(espolios_raw: Variant) -> Array[String]:
	var nomes: Array[String] = []
	if not (espolios_raw is Array):
		return nomes
	var lista: Array = espolios_raw as Array
	for item_var: Variant in lista:
		if item_var is Dictionary:
			var item: Dictionary = item_var as Dictionary
			var nome: String = String(item.get("nome", ""))
			if not nome.is_empty():
				nomes.append(nome)
		elif item_var is String:
			var nome_str: String = String(item_var)
			if not nome_str.is_empty():
				nomes.append(nome_str)
	return nomes


static func _copiar_pilares(pilares_raw: Variant) -> Array[Dictionary]:
	var copia: Array[Dictionary] = []
	if not (pilares_raw is Array):
		return copia
	var lista: Array = pilares_raw as Array
	for item_var: Variant in lista:
		if item_var is Dictionary:
			var item: Dictionary = item_var as Dictionary
			copia.append({
				"x": float(item.get("x", 0.0)),
				"y": float(item.get("y", 0.0)),
				"r": float(item.get("r", 44.0)),
			})
	return copia


static func _copiar_ondas(ondas_raw: Variant) -> Array:
	var copia: Array = []
	if not (ondas_raw is Array):
		return copia
	var lista_ondas: Array = ondas_raw as Array
	for onda_var: Variant in lista_ondas:
		if not (onda_var is Array):
			continue
		var onda_src: Array = onda_var as Array
		var onda_dst: Array = []
		for spawn_var: Variant in onda_src:
			if spawn_var is Dictionary:
				onda_dst.append((spawn_var as Dictionary).duplicate(true))
		copia.append(onda_dst)
	return copia


static func _copiar_ints(origem: Array) -> Array[int]:
	var copia: Array[int] = []
	for valor_var: Variant in origem:
		copia.append(int(valor_var))
	return copia


static func _copiar_strings(origem: Array) -> Array[String]:
	var copia: Array[String] = []
	for valor_var: Variant in origem:
		copia.append(String(valor_var))
	return copia


static func _cor_de(origem: Dictionary, chave: String, padrao: Color) -> Color:
	var val_raw: Variant = origem.get(chave, padrao)
	if val_raw is Color:
		return val_raw as Color
	return padrao


static func _ondas_colina_raizes() -> Array:
	return [
		[
			{"id": "eco_perdido", "x": 640.0, "y": 240.0},
			{"id": "vulto_mudo", "x": 1200.0, "y": 210.0},
			{"id": "eco_perdido", "x": 1760.0, "y": 240.0},
			{"id": "espreitador_da_fenda", "x": 420.0, "y": 420.0},
			{"id": "anomalia_menor", "x": 1980.0, "y": 420.0},
		],
		[
			{"id": "vulto_mudo", "x": 580.0, "y": 230.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 1820.0, "y": 230.0},
			{"id": "eco_perdido", "x": 1200.0, "y": 210.0},
			{"id": "anomalia_menor", "x": 360.0, "y": 500.0},
			{"id": "anomalia_menor", "x": 2040.0, "y": 500.0},
		],
		[
			{"id": "espreitador_da_fenda", "x": 640.0, "y": 220.0, "elite": true},
			{"id": "vulto_mudo", "x": 1760.0, "y": 220.0, "elite": true},
			{"id": "eco_perdido", "x": 460.0, "y": 380.0},
			{"id": "eco_perdido", "x": 1940.0, "y": 380.0},
			{"id": "anomalia_menor", "x": 1200.0, "y": 280.0},
			{"id": "fenda_errante", "x": 1200.0, "y": 200.0},
		],
	]


static func _ondas_costa_abissal() -> Array:
	return [
		[
			{"id": "baluarte_de_cinza", "x": 1200.0, "y": 210.0},
			{"id": "vulto_mudo", "x": 500.0, "y": 240.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 1900.0, "y": 240.0, "elite": true},
			{"id": "fenda_errante", "x": 860.0, "y": 220.0, "elite": true},
			{"id": "anomalia_menor", "x": 360.0, "y": 520.0},
			{"id": "eco_perdido", "x": 2040.0, "y": 520.0},
		],
		[
			{"id": "baluarte_de_cinza", "x": 1200.0, "y": 200.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 460.0, "y": 260.0, "elite": true},
			{"id": "vulto_mudo", "x": 1940.0, "y": 260.0, "elite": true},
			{"id": "fenda_errante", "x": 760.0, "y": 220.0, "elite": true},
			{"id": "fenda_errante", "x": 1640.0, "y": 220.0},
			{"id": "anomalia_menor", "x": 340.0, "y": 540.0},
			{"id": "eco_perdido", "x": 2060.0, "y": 540.0},
		],
		[
			{"id": "baluarte_de_cinza", "x": 880.0, "y": 210.0, "elite": true},
			{"id": "baluarte_de_cinza", "x": 1520.0, "y": 210.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 420.0, "y": 320.0, "elite": true},
			{"id": "vulto_mudo", "x": 1980.0, "y": 320.0, "elite": true},
			{"id": "fenda_errante", "x": 340.0, "y": 220.0, "elite": true},
			{"id": "fenda_errante", "x": 2060.0, "y": 220.0, "elite": true},
			{"id": "anomalia_menor", "x": 1200.0, "y": 300.0},
			{"id": "eco_perdido", "x": 1200.0, "y": 420.0},
		],
	]


static func _ondas_escarpas_copa() -> Array:
	return [
		[
			{"id": "baluarte_de_cinza", "x": 1200.0, "y": 210.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 480.0, "y": 240.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 1920.0, "y": 240.0, "elite": true},
			{"id": "fenda_errante", "x": 840.0, "y": 210.0, "elite": true},
			{"id": "vulto_mudo", "x": 360.0, "y": 480.0},
			{"id": "fenda_errante", "x": 1560.0, "y": 210.0},
			{"id": "anomalia_menor", "x": 2040.0, "y": 480.0},
		],
		[
			{"id": "baluarte_de_cinza", "x": 860.0, "y": 210.0, "elite": true},
			{"id": "baluarte_de_cinza", "x": 1540.0, "y": 210.0},
			{"id": "espreitador_da_fenda", "x": 440.0, "y": 290.0, "elite": true},
			{"id": "vulto_mudo", "x": 1960.0, "y": 290.0, "elite": true},
			{"id": "fenda_errante", "x": 340.0, "y": 540.0, "elite": true},
			{"id": "fenda_errante", "x": 2060.0, "y": 540.0, "elite": true},
			{"id": "anomalia_menor", "x": 1200.0, "y": 280.0},
		],
		[
			{"id": "baluarte_de_cinza", "x": 900.0, "y": 200.0, "elite": true},
			{"id": "baluarte_de_cinza", "x": 1500.0, "y": 200.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 440.0, "y": 330.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 1960.0, "y": 330.0, "elite": true},
			{"id": "vulto_mudo", "x": 740.0, "y": 260.0, "elite": true},
			{"id": "fenda_errante", "x": 340.0, "y": 220.0, "elite": true},
			{"id": "fenda_errante", "x": 2060.0, "y": 220.0, "elite": true},
			{"id": "anomalia_menor", "x": 1660.0, "y": 260.0},
		],
	]


static func _ondas_fendas_cinzentas() -> Array:
	return [
		[
			{"id": "baluarte_de_cinza", "x": 860.0, "y": 210.0, "elite": true},
			{"id": "baluarte_de_cinza", "x": 1540.0, "y": 210.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 440.0, "y": 270.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 1960.0, "y": 270.0, "elite": true},
			{"id": "fenda_errante", "x": 340.0, "y": 520.0, "elite": true},
			{"id": "fenda_errante", "x": 2060.0, "y": 520.0, "elite": true},
			{"id": "vulto_mudo", "x": 1200.0, "y": 260.0},
			{"id": "anomalia_menor", "x": 1200.0, "y": 360.0},
		],
		[
			{"id": "baluarte_de_cinza", "x": 860.0, "y": 210.0, "elite": true},
			{"id": "baluarte_de_cinza", "x": 1540.0, "y": 210.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 420.0, "y": 320.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 1980.0, "y": 320.0, "elite": true},
			{"id": "vulto_mudo", "x": 740.0, "y": 270.0, "elite": true},
			{"id": "vulto_mudo", "x": 1660.0, "y": 270.0, "elite": true},
			{"id": "fenda_errante", "x": 340.0, "y": 220.0, "elite": true},
			{"id": "fenda_errante", "x": 2060.0, "y": 220.0, "elite": true},
		],
		[
			{"id": "baluarte_de_cinza", "x": 800.0, "y": 200.0, "elite": true},
			{"id": "baluarte_de_cinza", "x": 1200.0, "y": 200.0, "elite": true},
			{"id": "baluarte_de_cinza", "x": 1600.0, "y": 200.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 420.0, "y": 340.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 1980.0, "y": 340.0, "elite": true},
			{"id": "vulto_mudo", "x": 640.0, "y": 460.0, "elite": true},
			{"id": "vulto_mudo", "x": 1760.0, "y": 460.0, "elite": true},
			{"id": "fenda_errante", "x": 340.0, "y": 220.0, "elite": true},
			{"id": "fenda_errante", "x": 2060.0, "y": 220.0, "elite": true},
		],
	]


static func _ondas_terras_baldias() -> Array:
	return [
		[
			{"id": "baluarte_de_cinza", "x": 860.0, "y": 210.0, "elite": true},
			{"id": "baluarte_de_cinza", "x": 1540.0, "y": 210.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 420.0, "y": 300.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 1980.0, "y": 300.0, "elite": true},
			{"id": "vulto_mudo", "x": 740.0, "y": 260.0, "elite": true},
			{"id": "vulto_mudo", "x": 1660.0, "y": 260.0, "elite": true},
			{"id": "fenda_errante", "x": 340.0, "y": 540.0, "elite": true},
			{"id": "fenda_errante", "x": 2060.0, "y": 540.0, "elite": true},
		],
		[
			{"id": "baluarte_de_cinza", "x": 800.0, "y": 200.0, "elite": true},
			{"id": "baluarte_de_cinza", "x": 1200.0, "y": 200.0, "elite": true},
			{"id": "baluarte_de_cinza", "x": 1600.0, "y": 200.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 420.0, "y": 320.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 1980.0, "y": 320.0, "elite": true},
			{"id": "fenda_errante", "x": 340.0, "y": 220.0, "elite": true},
			{"id": "fenda_errante", "x": 2060.0, "y": 220.0, "elite": true},
			{"id": "vulto_mudo", "x": 640.0, "y": 460.0, "elite": true},
			{"id": "anomalia_menor", "x": 1760.0, "y": 460.0, "elite": true},
		],
		[
			{"id": "baluarte_de_cinza", "x": 760.0, "y": 200.0, "elite": true},
			{"id": "baluarte_de_cinza", "x": 1200.0, "y": 200.0, "elite": true},
			{"id": "baluarte_de_cinza", "x": 1640.0, "y": 200.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 400.0, "y": 310.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 1200.0, "y": 310.0, "elite": true},
			{"id": "espreitador_da_fenda", "x": 2000.0, "y": 310.0, "elite": true},
			{"id": "fenda_errante", "x": 340.0, "y": 210.0, "elite": true},
			{"id": "fenda_errante", "x": 2060.0, "y": 210.0, "elite": true},
			{"id": "vulto_mudo", "x": 620.0, "y": 490.0, "elite": true},
			{"id": "anomalia_menor", "x": 1780.0, "y": 490.0, "elite": true},
		],
	]
