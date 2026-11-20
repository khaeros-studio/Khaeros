class_name CatalogoMapasBosses
extends RefCounted
## Catálogo imutável dos 5 mapas avançados e 5 chefes de Khaeros em ordem de progressão.
##
## Fornece definições de arena, paleta visual, ficha completa de chefe (atributos,
## habilidades, fraquezas e espólios canônicos), zonas seguras, perigos dinâmicos,
## obstáculos táticos, interativos, props de narrativa ambiental, mecânicas de passo
## e manifestos de assets necessários. Todas as consultas retornam cópias profundas
## via [method Dictionary.duplicate] com [code]true[/code] para preservar imutabilidade.

const MARGEM_BORDA_PADRAO_PX: float = 80.0
const CHAVES_ASSETS_CONSOLIDADAS: Array[String] = [
	"arena_bg",
	"tiles",
	"props",
	"vfx",
	"indicadores_perigo",
	"boss_atlases",
]


## Retorna cópias profundas dos 5 mapas e chefes na ordem exata de progressão:
## 0. colina_raizes_profundas (Rank C+, Nível 21)
## 1. costa_abissal (Rank A+, Nível 48)
## 2. escarpas_copa_quebrada (Rank A+, Nível 53)
## 3. fendas_cinzentas (Rank S, Nível 74)
## 4. terras_baldias_subterraneas (Rank Cataclísmico, Nível 90)
static func mapas() -> Array[Dictionary]:
	var definicoes: Array[Dictionary] = _definicoes_mapas()
	var resultado: Array[Dictionary] = []
	for mapa: Dictionary in definicoes:
		resultado.append(mapa.duplicate(true))
	return resultado


## Retorna uma cópia profunda do mapa correspondente a [param id_mapa], ou {} se não existir.
static func obter_mapa(id_mapa: String) -> Dictionary:
	if id_mapa.is_empty():
		return {}
	var definicoes: Array[Dictionary] = _definicoes_mapas()
	for mapa: Dictionary in definicoes:
		var id_atual: String = String(mapa.get("id", ""))
		if id_atual == id_mapa:
			return mapa.duplicate(true)
	return {}


## Retorna uma cópia profunda do mapa cujo chefe possui [param id_boss], ou {} se não existir.
static func obter_por_boss(id_boss: String) -> Dictionary:
	if id_boss.is_empty():
		return {}
	var definicoes: Array[Dictionary] = _definicoes_mapas()
	for mapa: Dictionary in definicoes:
		var boss_raw: Variant = mapa.get("boss", {})
		var boss: Dictionary = boss_raw as Dictionary if boss_raw is Dictionary else {}
		var boss_id: String = String(boss.get("id", ""))
		if boss_id == id_boss:
			return mapa.duplicate(true)
	return {}


## Retorna os IDs dos 5 mapas na ordem canônica de progressão.
static func ids_mapas() -> Array[String]:
	var definicoes: Array[Dictionary] = _definicoes_mapas()
	var ids: Array[String] = []
	for mapa: Dictionary in definicoes:
		ids.append(String(mapa.get("id", "")))
	return ids


## Consolida listas únicas de todos os assets necessários entre os 5 mapas:
## arena_bg, tiles, props, vfx, indicadores_perigo e boss_atlases.
static func resumo_assets_totais() -> Dictionary:
	var arena_bgs: Array[String] = []
	var tiles: Array[String] = []
	var props: Array[String] = []
	var vfx: Array[String] = []
	var indicadores_perigo: Array[String] = []
	var boss_atlases: Array[String] = []

	var vistos_arena_bg: Dictionary = {}
	var vistos_tiles: Dictionary = {}
	var vistos_props: Dictionary = {}
	var vistos_vfx: Dictionary = {}
	var vistos_indicadores: Dictionary = {}
	var vistos_boss_atlases: Dictionary = {}

	var definicoes: Array[Dictionary] = _definicoes_mapas()
	for mapa: Dictionary in definicoes:
		var assets_raw: Variant = mapa.get("assets_necessarios", {})
		var assets: Dictionary = assets_raw as Dictionary if assets_raw is Dictionary else {}
		_coletar_assets_chave(arena_bgs, vistos_arena_bg, assets.get("arena_bg", null))
		_coletar_assets_chave(tiles, vistos_tiles, assets.get("tiles", null))
		_coletar_assets_chave(props, vistos_props, assets.get("props", null))
		_coletar_assets_chave(vfx, vistos_vfx, assets.get("vfx", null))
		_coletar_assets_chave(indicadores_perigo, vistos_indicadores, assets.get("indicadores_perigo", null))
		_coletar_assets_chave(boss_atlases, vistos_boss_atlases, assets.get("boss_atlases", null))

	var consolidado: Dictionary = {
		"arena_bg": arena_bgs,
		"tiles": tiles,
		"props": props,
		"vfx": vfx,
		"indicadores_perigo": indicadores_perigo,
		"boss_atlases": boss_atlases,
	}
	return consolidado


static func _coletar_assets_chave(destino: Array[String], vistos: Dictionary, entrada: Variant) -> void:
	if entrada is String:
		_adicionar_asset_unico(destino, vistos, String(entrada))
	elif entrada is Array:
		var entrada_arr: Array = entrada as Array
		for item_var: Variant in entrada_arr:
			_adicionar_asset_unico(destino, vistos, String(item_var))


static func _adicionar_asset_unico(destino: Array[String], vistos: Dictionary, caminho: String) -> void:
	if caminho.is_empty():
		return
	if not vistos.has(caminho):
		vistos[caminho] = true
		destino.append(caminho)


static func _definicoes_mapas() -> Array[Dictionary]:
	var lista: Array[Dictionary] = [
		_mapa_01_colina_raizes_profundas(),
		_mapa_02_costa_abissal(),
		_mapa_03_escarpas_copa_quebrada(),
		_mapa_04_fendas_cinzentas(),
		_mapa_05_terras_baldias_subterraneas(),
	]
	return lista


static func _mapa_01_colina_raizes_profundas() -> Dictionary:
	return {
		"id": "colina_raizes_profundas",
		"nome": "Colina das Raízes Profundas",
		"subtitulo": "Clareira Ancestral da Coroa Vegetal",
		"bioma": "floresta_antiga_corrompida",
		"rank": "C+",
		"nivel_recomendado": 21,
		"escala_metros": 8.0,
		"camera_zoom": 1.08,
		"paleta": {
			"bg": Color("0c120e"),
			"floor": Color("1a241c"),
			"accent": Color("a3c962"),
			"border": Color("334436"),
			"perigo": Color("e0259c"),
			"seguro": Color("6ee7b7"),
			"nevoa": Color("1f2e24"),
			"motif": "colina_raizes",
		},
		"arena": {
			"forma": "circular",
			"largura": 2800.0,
			"altura": 1760.0,
			"margem_borda_px": MARGEM_BORDA_PADRAO_PX,
			"raio_arena": 760.0,
			"centro": Vector2(1400.0, 880.0),
			"spawn_jogador": Vector2(1400.0, 1500.0),
			"spawn_boss": Vector2(1400.0, 880.0),
		},
		"boss": {
			"id": "devorador_coroa_espinhos",
			"nome": "Devorador da Coroa de Espinhos",
			"arquetipo": "Controlador Estático",
			"rank": "C+",
			"nivel": 21,
			"vida": 1250.0,
			"velocidade": 0.0,
			"raio_px": 88.0,
			"dano": 19.0,
			"escala_sprite": 1.45,
			"estatico": true,
			"fases": 2,
			"limiar_fase2_frac": 0.50,
			"atlas_id": "chefe_devorador_coroa",
			"descricao": (
				"Entidade vegetal parasitária ancorada no centro da clareira, cercada por uma "
				+ "coroa de espinhos retorcidos que sente passos sobre o solo vivo."
			),
			"tatica": (
				"Permaneça sobre as lajes de pedra antiga para anular o Sensor de Raízes, "
				+ "ative as runas de vento contra os bolsões de esporos e puna entre os ataques de chicote."
			),
			"habilidades": [
				{
					"id": "sensor_de_raizes",
					"nome": "Sensor de Raízes",
					"tipo": "passiva",
					"forma_telegrafo": "circulo",
					"dano_mult": 0.0,
					"alcance_px": 680.0,
					"preparo_s": 0.0,
					"recarga_s": 0.0,
					"descricao": "Detecta vibrações de passos fora das lajes antigas e marca o alvo para ataques subterrâneos.",
				},
				{
					"id": "miragem_de_esporos",
					"nome": "Miragem de Esporos",
					"tipo": "ilusao",
					"forma_telegrafo": "circulo",
					"dano_mult": 0.85,
					"alcance_px": 240.0,
					"preparo_s": 0.75,
					"recarga_s": 2.20,
					"descricao": "Projeta silhuetas ilusórias entre os bolsões de esporos enquanto libera nuvens tóxicas.",
				},
				{
					"id": "chicote_agulhas_aperto_devorador",
					"nome": "Chicote de Agulhas & Aperto Devorador",
					"tipo": "area",
					"forma_telegrafo": "setor",
					"dano_mult": 1.15,
					"alcance_px": 380.0,
					"preparo_s": 0.65,
					"recarga_s": 1.80,
					"descricao": "Varre um setor amplo com vinhas farpadas e fecha mandíbulas de raiz sobre alvos rastreados.",
				},
				{
					"id": "fissura_da_coroa",
					"nome": "Fissura da Coroa",
					"tipo": "area",
					"forma_telegrafo": "linha",
					"dano_mult": 1.40,
					"alcance_px": 640.0,
					"preparo_s": 0.90,
					"recarga_s": 3.00,
					"descricao": "Parte a coroa central e projeta fissuras radiais de espinhos em múltiplos eixos.",
				},
			],
			"fraquezas": ["Lajes de Pedra Antiga", "Runas de Vento", "Cortes em Área"],
			"imunidades": ["empurrao", "deslocamento_forcado"],
			"espolios": [
				{
					"id": "nucleo_espinho",
					"nome": "Núcleo de Espinho",
					"raridade": "rara",
					"tipo": "nucleo",
					"quantidade": 1,
					"descricao": "Cerne pulsante de espinho ancestral saturado de Fluxo vegetal.",
				},
				{
					"id": "casca_espinhosa",
					"nome": "Casca Espinhosa",
					"raridade": "comum",
					"tipo": "material",
					"quantidade": 1,
					"descricao": "Placa fibrosa de armadura vegetal usada em reforja defensiva.",
				},
			],
		},
		"zonas_seguras": [
			{
				"id": "laje_pedra_antiga_sul",
				"tipo": "laje_pedra_antiga",
				"nome": "Laje de Pedra Antiga Sul",
				"pos": Vector2(1400.0, 1420.0),
				"raio": 110.0,
				"efeito": "anula_sensor_raizes",
			},
			{
				"id": "laje_pedra_antiga_oeste",
				"tipo": "laje_pedra_antiga",
				"nome": "Laje de Pedra Antiga Oeste",
				"pos": Vector2(860.0, 980.0),
				"raio": 105.0,
				"efeito": "anula_sensor_raizes",
			},
			{
				"id": "laje_pedra_antiga_leste",
				"tipo": "laje_pedra_antiga",
				"nome": "Laje de Pedra Antiga Leste",
				"pos": Vector2(1940.0, 980.0),
				"raio": 105.0,
				"efeito": "anula_sensor_raizes",
			},
			{
				"id": "laje_pedra_antiga_noroeste",
				"tipo": "laje_pedra_antiga",
				"nome": "Laje de Pedra Antiga Noroeste",
				"pos": Vector2(1020.0, 520.0),
				"raio": 100.0,
				"efeito": "anula_sensor_raizes",
			},
			{
				"id": "laje_pedra_antiga_nordeste",
				"tipo": "laje_pedra_antiga",
				"nome": "Laje de Pedra Antiga Nordeste",
				"pos": Vector2(1780.0, 520.0),
				"raio": 100.0,
				"efeito": "anula_sensor_raizes",
			},
		],
		"perigos_dinamicos": [
			{
				"id": "solo_raizes_sensor_central",
				"tipo": "solo_raizes_sensor",
				"nome": "Solo Vivo de Raízes Sensoras",
				"pos": Vector2(1400.0, 880.0),
				"raio": 680.0,
				"dano_por_tick": 0.0,
				"efeito": "ativa_rastreamento_subterraneo",
			},
			{
				"id": "bolsao_esporos_so",
				"tipo": "bolsao_esporos",
				"nome": "Bolsão de Esporos Sudoeste",
				"pos": Vector2(1040.0, 1220.0),
				"raio": 95.0,
				"dano_por_tick": 8.0,
				"efeito": "envenenamento_e_miragem",
			},
			{
				"id": "bolsao_esporos_se",
				"tipo": "bolsao_esporos",
				"nome": "Bolsão de Esporos Sudeste",
				"pos": Vector2(1760.0, 1220.0),
				"raio": 95.0,
				"dano_por_tick": 8.0,
				"efeito": "envenenamento_e_miragem",
			},
			{
				"id": "bolsao_esporos_no",
				"tipo": "bolsao_esporos",
				"nome": "Bolsão de Esporos Noroeste",
				"pos": Vector2(960.0, 720.0),
				"raio": 95.0,
				"dano_por_tick": 8.0,
				"efeito": "envenenamento_e_miragem",
			},
			{
				"id": "bolsao_esporos_ne",
				"tipo": "bolsao_esporos",
				"nome": "Bolsão de Esporos Nordeste",
				"pos": Vector2(1840.0, 720.0),
				"raio": 95.0,
				"dano_por_tick": 8.0,
				"efeito": "envenenamento_e_miragem",
			},
		],
		"obstaculos": [
			{
				"id": "raiz_borda_noroeste",
				"tipo": "raiz_espinhosa_borda",
				"nome": "Muralha de Raízes Noroeste",
				"pos": Vector2(760.0, 420.0),
				"raio": 56.0,
				"destrutivel": false,
			},
			{
				"id": "raiz_borda_nordeste",
				"tipo": "raiz_espinhosa_borda",
				"nome": "Muralha de Raízes Nordeste",
				"pos": Vector2(2040.0, 420.0),
				"raio": 56.0,
				"destrutivel": false,
			},
			{
				"id": "casca_borda_sudoeste",
				"tipo": "casca_petrificada_borda",
				"nome": "Casca Petrificada Sudoeste",
				"pos": Vector2(740.0, 1340.0),
				"raio": 54.0,
				"destrutivel": false,
			},
			{
				"id": "casca_borda_sudeste",
				"tipo": "casca_petrificada_borda",
				"nome": "Casca Petrificada Sudeste",
				"pos": Vector2(2060.0, 1340.0),
				"raio": 54.0,
				"destrutivel": false,
			},
		],
		"interativos": [
			{
				"id": "dissipador_vento_oeste",
				"tipo": "dissipador_vento",
				"nome": "Dissipador de Vento Oeste",
				"pos": Vector2(690.0, 880.0),
				"raio": 46.0,
				"acao": "dispersar_esporos_e_miragens",
				"recarga_passos": 480,
				"usado": false,
			},
			{
				"id": "runa_vento_leste",
				"tipo": "runa_vento",
				"nome": "Runa de Vento Leste",
				"pos": Vector2(2110.0, 880.0),
				"raio": 46.0,
				"acao": "dispersar_esporos_e_miragens",
				"recarga_passos": 480,
				"usado": false,
			},
			{
				"id": "runa_vento_norte",
				"tipo": "runa_vento",
				"nome": "Runa de Vento Norte",
				"pos": Vector2(1400.0, 280.0),
				"raio": 46.0,
				"acao": "revelar_alvo_real_e_limpar_esporos",
				"recarga_passos": 540,
				"usado": false,
			},
		],
		"props_storytelling": [
			{
				"id": "marco_pedra_sulcos_01",
				"tipo": "marco_pedra_sem_texto",
				"nome": "Marco de Pedra com Sulcos Gastos",
				"pos": Vector2(620.0, 640.0),
				"descricao": "Pedra lascada sem texto ou heráldica marcada por ferramentas antigas antes das raízes tomarem a clareira.",
			},
			{
				"id": "toco_podre_espinhos_01",
				"tipo": "toco_podre",
				"nome": "Toco Retorcido por Raízes Secas",
				"pos": Vector2(2180.0, 1180.0),
				"descricao": "Tronco oco calcificado na beira da clareira, perfurado por raízes enegrecidas.",
			},
		],
		"mecanicas_ambientais": [
			{
				"id": "rastreamento_por_vibracao",
				"nome": "Sensor Contínuo de Raízes",
				"intervalo_passos": 0,
				"descricao": "Caminhar fora das lajes de pedra antiga ativa o rastreamento do boss.",
			},
			{
				"id": "pulso_esporos_periodico",
				"nome": "Pulso Periódico de Esporos",
				"intervalo_passos": 360,
				"descricao": "Os quatro bolsões liberam névoa tóxica e miragens se não forem dissipados pelo vento.",
			},
		],
		"assets_necessarios": {
			"arena_bg": "res://assets/art/environment/colina_raizes_profundas/arena_bg.png",
			"tiles": [
				"res://assets/art/environment/colina_raizes_profundas/chao_solo_raizes_01.png",
				"res://assets/art/environment/colina_raizes_profundas/laje_pedra_antiga_01.png",
			],
			"props": [
				"res://assets/art/environment/colina_raizes_profundas/raiz_borda_01.png",
				"res://assets/art/environment/colina_raizes_profundas/casca_espinhosa_01.png",
				"res://assets/art/environment/colina_raizes_profundas/runa_vento_01.png",
			],
			"vfx": [
				"res://assets/art/vfx/esporos_toxicos_v01.png",
				"res://assets/art/vfx/rajada_vento_v01.png",
			],
			"indicadores_perigo": [
				"res://assets/art/vfx/indicador_sensor_raizes_v01.png",
				"res://assets/art/vfx/indicador_fissura_coroa_v01.png",
			],
			"boss_atlases": [
				"res://assets/art/runtime/chefe_devorador_coroa/chefe_devorador_coroa_frames_v01.tres",
			],
		},
	}


static func _mapa_02_costa_abissal() -> Dictionary:
	return {
		"id": "costa_abissal",
		"nome": "Costa Abissal (Cais da Água Negra)",
		"subtitulo": "Cais Quebrado sob a Maré Negra",
		"bioma": "costa_abissal",
		"rank": "A+",
		"nivel_recomendado": 48,
		"escala_metros": 32.0,
		"camera_zoom": 0.92,
		"paleta": {
			"bg": Color("070c14"),
			"floor": Color("121d2b"),
			"accent": Color("38bdf8"),
			"border": Color("28425a"),
			"perigo": Color("e0259c"),
			"seguro": Color("e3b23c"),
			"nevoa": Color("15283a"),
			"motif": "costa_abissal",
		},
		"arena": {
			"forma": "costeira",
			"largura": 3400.0,
			"altura": 1920.0,
			"margem_borda_px": MARGEM_BORDA_PADRAO_PX,
			"centro": Vector2(1700.0, 960.0),
			"spawn_jogador": Vector2(1700.0, 1620.0),
			"spawn_boss": Vector2(1700.0, 460.0),
		},
		"boss": {
			"id": "leviata_mare_morta",
			"nome": "Leviatã da Maré Morta",
			"arquetipo": "Colosso Aquático",
			"rank": "A+",
			"nivel": 48,
			"vida": 2400.0,
			"velocidade": 165.0,
			"raio_px": 108.0,
			"dano": 28.0,
			"escala_sprite": 2.15,
			"estatico": false,
			"fases": 2,
			"limiar_fase2_frac": 0.50,
			"atlas_id": "chefe_leviata_mare",
			"descricao": (
				"Colosso serpentino blindado por cracas abissais que controla os ciclos de maré "
				+ "e esmaga embarcações inteiras contra o cais submerso."
			),
			"tatica": (
				"Use os píeres elevados e recifes na maré alta e atraia a Investida Quebra-Maré "
				+ "contra os três quebra-mares de farol para atordoar o colosso."
			),
			"habilidades": [
				{
					"id": "instinto_da_tempestade",
					"nome": "Instinto da Tempestade",
					"tipo": "passiva",
					"forma_telegrafo": "nenhum",
					"dano_mult": 0.0,
					"alcance_px": 900.0,
					"preparo_s": 0.0,
					"recarga_s": 0.0,
					"descricao": "Acelera o deslocamento do Leviatã em água profunda e intensifica ondas durante a maré alta.",
				},
				{
					"id": "investida_quebra_mare",
					"nome": "Investida Quebra-Maré",
					"tipo": "investida",
					"forma_telegrafo": "retangulo",
					"dano_mult": 1.25,
					"alcance_px": 780.0,
					"preparo_s": 0.70,
					"recarga_s": 2.10,
					"descricao": "Avança como aríete ao longo do eixo travado; colidir com quebra-mares de farol interrompe o golpe.",
				},
				{
					"id": "ruptura_de_pressao",
					"nome": "Ruptura de Pressão",
					"tipo": "area",
					"forma_telegrafo": "anel",
					"dano_mult": 1.10,
					"alcance_px": 320.0,
					"preparo_s": 0.75,
					"recarga_s": 2.40,
					"descricao": "Comprime a água ao redor e libera anel de choque que arremessa alvos para fora dos píeres.",
				},
				{
					"id": "rugido_abissal_espiral",
					"nome": "Rugido Abissal & Espiral das Profundezas",
					"tipo": "area",
					"forma_telegrafo": "circulo",
					"dano_mult": 1.35,
					"alcance_px": 460.0,
					"preparo_s": 0.95,
					"recarga_s": 3.20,
					"descricao": "Convoca redemoinhos em espiral por toda a costa e dispara jatos radiais de pressão negra.",
				},
			],
			"fraquezas": ["Quebra-Mares de Farol", "Terreno Elevado", "Impactos Ressonantes"],
			"imunidades": ["lentidao_agua", "cambaleio_leve"],
			"espolios": [
				{
					"id": "nucleo_abissal",
					"nome": "Núcleo Abissal",
					"raridade": "epica",
					"tipo": "nucleo",
					"quantidade": 1,
					"descricao": "Orbe denso de pressão oceânica condensada das profundezas da Costa Abissal.",
				},
				{
					"id": "escama_ruina",
					"nome": "Escama de Ruína",
					"raridade": "rara",
					"tipo": "material",
					"quantidade": 1,
					"descricao": "Escama calcificada capaz de suportar impactos extremos de maré alta.",
				},
			],
		},
		"zonas_seguras": [
			{
				"id": "pier_elevado_sul",
				"tipo": "pier_elevado",
				"nome": "Píer Elevado do Desembarque",
				"pos": Vector2(1700.0, 1520.0),
				"raio": 160.0,
				"elevacao": 1,
				"efeito": "protege_da_mare_alta",
			},
			{
				"id": "pier_elevado_oeste",
				"tipo": "pier_elevado",
				"nome": "Píer Elevado Oeste",
				"pos": Vector2(760.0, 1180.0),
				"raio": 145.0,
				"elevacao": 1,
				"efeito": "protege_da_mare_alta",
			},
			{
				"id": "pier_elevado_leste",
				"tipo": "pier_elevado",
				"nome": "Píer Elevado Leste",
				"pos": Vector2(2640.0, 1180.0),
				"raio": 145.0,
				"elevacao": 1,
				"efeito": "protege_da_mare_alta",
			},
			{
				"id": "recife_alto_noroeste",
				"tipo": "recife_alto",
				"nome": "Recife Alto Noroeste",
				"pos": Vector2(980.0, 620.0),
				"raio": 120.0,
				"elevacao": 1,
				"efeito": "protege_da_mare_alta",
			},
			{
				"id": "recife_alto_nordeste",
				"tipo": "recife_alto",
				"nome": "Recife Alto Nordeste",
				"pos": Vector2(2420.0, 620.0),
				"raio": 120.0,
				"elevacao": 1,
				"efeito": "protege_da_mare_alta",
			},
		],
		"perigos_dinamicos": [
			{
				"id": "agua_profunda_norte",
				"tipo": "agua_profunda",
				"nome": "Canal de Água Profunda Norte",
				"pos": Vector2(1700.0, 320.0),
				"raio": 180.0,
				"dano_por_tick": 14.0,
				"efeito": "lentidao_severa_e_afogamento",
			},
			{
				"id": "agua_profunda_oeste",
				"tipo": "agua_profunda",
				"nome": "Fosso Aquático Oeste",
				"pos": Vector2(440.0, 760.0),
				"raio": 180.0,
				"dano_por_tick": 14.0,
				"efeito": "lentidao_severa_e_afogamento",
			},
			{
				"id": "agua_profunda_leste",
				"tipo": "agua_profunda",
				"nome": "Fosso Aquático Leste",
				"pos": Vector2(2960.0, 760.0),
				"raio": 180.0,
				"dano_por_tick": 14.0,
				"efeito": "lentidao_severa_e_afogamento",
			},
			{
				"id": "mare_alta_tempestade_central",
				"tipo": "ciclo_mare_alta",
				"nome": "Zona de Inundação da Maré Alta",
				"pos": Vector2(1700.0, 960.0),
				"raio": 260.0,
				"dano_por_tick": 10.0,
				"efeito": "inunda_trechos_baixos_na_tempestade",
			},
		],
		"obstaculos": [
			{
				"id": "quebra_mares_farol_oeste",
				"tipo": "quebra_mares_farol",
				"nome": "Quebra-Mares do Farol Oeste",
				"pos": Vector2(1020.0, 1020.0),
				"raio": 64.0,
				"destrutivel": false,
				"efeito_impacto_boss": "interrompe_investida_quebra_mare",
			},
			{
				"id": "quebra_mares_farol_leste",
				"tipo": "quebra_mares_farol",
				"nome": "Quebra-Mares do Farol Leste",
				"pos": Vector2(2380.0, 1020.0),
				"raio": 64.0,
				"destrutivel": false,
				"efeito_impacto_boss": "interrompe_investida_quebra_mare",
			},
			{
				"id": "quebra_mares_farol_central",
				"tipo": "quebra_mares_farol",
				"nome": "Quebra-Mares do Farol Central",
				"pos": Vector2(1700.0, 860.0),
				"raio": 68.0,
				"destrutivel": false,
				"efeito_impacto_boss": "interrompe_investida_quebra_mare",
			},
		],
		"interativos": [
			{
				"id": "sinalizador_farol_oeste",
				"tipo": "baliza_farol",
				"nome": "Baliza de Farol Oeste",
				"pos": Vector2(560.0, 1460.0),
				"raio": 46.0,
				"acao": "iluminar_recifes_e_reduzir_nevoa",
				"recarga_passos": 540,
				"usado": false,
			},
			{
				"id": "sinalizador_farol_leste",
				"tipo": "baliza_farol",
				"nome": "Baliza de Farol Leste",
				"pos": Vector2(2840.0, 1460.0),
				"raio": 46.0,
				"acao": "iluminar_recifes_e_reduzir_nevoa",
				"recarga_passos": 540,
				"usado": false,
			},
		],
		"props_storytelling": [
			{
				"id": "navio_partido_oeste",
				"tipo": "navio_partido",
				"nome": "Casco Partido de Embarcação Antiga",
				"pos": Vector2(460.0, 1180.0),
				"descricao": "Restos de um casco partido ao meio pela maré negra, sem inscrições ou bandeiras legíveis.",
			},
			{
				"id": "ancora_colossal_leste",
				"tipo": "ancora_colossal",
				"nome": "Âncora Colossal Enferrujada",
				"pos": Vector2(2920.0, 1180.0),
				"descricao": "Âncora titânica arrastada do fundo abissal durante a última tormenta.",
			},
		],
		"mecanicas_ambientais": [
			{
				"id": "ciclo_mare_alta_tempestade",
				"nome": "Ciclo de Maré Alta e Tempestade",
				"intervalo_passos": 600,
				"descricao": "Alterna entre maré baixa e maré alta, submergindo o cais fora dos píeres e recifes.",
			},
			{
				"id": "correnteza_agua_profunda",
				"nome": "Correnteza para Água Profunda",
				"intervalo_passos": 420,
				"descricao": "Ondas laterais empurram combatentes em direção às bordas submersas.",
			},
		],
		"assets_necessarios": {
			"arena_bg": "res://assets/art/environment/costa_abissal/arena_bg.png",
			"tiles": [
				"res://assets/art/environment/costa_abissal/cais_madeira_molhada_01.png",
				"res://assets/art/environment/costa_abissal/agua_negra_tile_01.png",
				"res://assets/art/environment/costa_abissal/recife_elevado_01.png",
			],
			"props": [
				"res://assets/art/environment/costa_abissal/quebra_mares_farol_01.png",
				"res://assets/art/environment/costa_abissal/navio_partido_01.png",
				"res://assets/art/environment/costa_abissal/ancora_colossal_01.png",
			],
			"vfx": [
				"res://assets/art/vfx/espiral_profundezas_v01.png",
				"res://assets/art/vfx/onda_mare_alta_v01.png",
			],
			"indicadores_perigo": [
				"res://assets/art/vfx/indicador_investida_mare_v01.png",
				"res://assets/art/vfx/indicador_ruptura_pressao_v01.png",
			],
			"boss_atlases": [
				"res://assets/art/runtime/chefe_leviata_mare/chefe_leviata_mare_frames_v01.tres",
			],
		},
	}


static func _mapa_03_escarpas_copa_quebrada() -> Dictionary:
	return {
		"id": "escarpas_copa_quebrada",
		"nome": "Escarpas da Copa Quebrada",
		"subtitulo": "Platôs Suspensos da Espinha Partida",
		"bioma": "escarpas_rochosas",
		"rank": "A+",
		"nivel_recomendado": 53,
		"escala_metros": 20.0,
		"camera_zoom": 0.94,
		"paleta": {
			"bg": Color("0e0f14"),
			"floor": Color("22242d"),
			"accent": Color("f59e0b"),
			"border": Color("4a4d5c"),
			"perigo": Color("e0259c"),
			"seguro": Color("e3b23c"),
			"nevoa": Color("272a36"),
			"motif": "escarpas_copa",
		},
		"arena": {
			"forma": "verticalizada",
			"largura": 3200.0,
			"altura": 1880.0,
			"margem_borda_px": MARGEM_BORDA_PADRAO_PX,
			"centro": Vector2(1600.0, 940.0),
			"spawn_jogador": Vector2(1600.0, 1580.0),
			"spawn_boss": Vector2(1600.0, 420.0),
		},
		"boss": {
			"id": "vigia_coroa_partida",
			"nome": "Vigia da Coroa Partida",
			"arquetipo": "Bruto de Escarpa / Controlador Multi-Membros",
			"rank": "A+",
			"nivel": 53,
			"vida": 2850.0,
			"velocidade": 122.0,
			"raio_px": 102.0,
			"dano": 32.0,
			"escala_sprite": 2.05,
			"estatico": false,
			"fases": 2,
			"limiar_fase2_frac": 0.50,
			"atlas_id": "chefe_vigia_coroa",
			"descricao": (
				"Guardião ciclópico de escarpa munido de múltiplos braços articulados e "
				+ "olho prismático que vigia todos os ângulos entre os platôs."
			),
			"tatica": (
				"Alterne entre os três platôs elevados pelas duas pontes para quebrar o ângulo da Visão Hexagonal, "
				+ "use coberturas destrutíveis contra o agarrão e evite as beiradas durante as ondas sísmicas."
			),
			"habilidades": [
				{
					"id": "visao_hexagonal",
					"nome": "Visão Hexagonal",
					"tipo": "passiva",
					"forma_telegrafo": "setor",
					"dano_mult": 0.90,
					"alcance_px": 540.0,
					"preparo_s": 0.55,
					"recarga_s": 1.60,
					"descricao": "Dispara feixes de rastreamento em seis ângulos sempre que o jogador permanece na mesma elevação.",
				},
				{
					"id": "descida_titanica",
					"nome": "Descida Titânica",
					"tipo": "area",
					"forma_telegrafo": "circulo",
					"dano_mult": 1.30,
					"alcance_px": 310.0,
					"preparo_s": 0.85,
					"recarga_s": 2.50,
					"descricao": "Salta entre desníveis e esmaga o platô alvo, gerando ondas sísmicas expansivas.",
				},
				{
					"id": "sobrecarga_de_agarrao",
					"nome": "Sobrecarga de Agarrão",
					"tipo": "controle",
					"forma_telegrafo": "retangulo",
					"dano_mult": 1.20,
					"alcance_px": 460.0,
					"preparo_s": 0.65,
					"recarga_s": 2.20,
					"descricao": "Estende braços múltiplos para capturar o alvo e arremessá-lo na direção da beirada.",
				},
				{
					"id": "renascimento_da_coroa",
					"nome": "Renascimento da Coroa",
					"tipo": "furia",
					"forma_telegrafo": "anel",
					"dano_mult": 1.35,
					"alcance_px": 360.0,
					"preparo_s": 0.90,
					"recarga_s": 3.20,
					"descricao": "Reconstitui membros perdidos abaixo de 50% de Vida e libera anel de fragmentos de pedra.",
				},
			],
			"fraquezas": ["Mudança de Elevação", "Coberturas Destrutíveis", "Quebra de Membros"],
			"imunidades": ["cambaleio_leve", "empurrao_frontal"],
			"espolios": [
				{
					"id": "nucleo_coroa",
					"nome": "Núcleo da Coroa",
					"raridade": "epica",
					"tipo": "nucleo",
					"quantidade": 1,
					"descricao": "Núcleo geométrico que sincroniza os múltiplos membros do Vigia da Escarpa.",
				},
				{
					"id": "placa_coroa_regenerada",
					"nome": "Placa de Coroa Regenerada",
					"raridade": "rara",
					"tipo": "material",
					"quantidade": 1,
					"descricao": "Segmento pétreo capaz de regenerar microfissuras sob tensão.",
				},
			],
		},
		"zonas_seguras": [
			{
				"id": "plato_elevado_sul",
				"tipo": "plato_elevado",
				"nome": "Platô Elevado Sul",
				"pos": Vector2(1600.0, 1480.0),
				"raio": 165.0,
				"elevacao": 2,
				"efeito": "vantagem_altura_e_protecao_borda",
			},
			{
				"id": "plato_elevado_oeste",
				"tipo": "plato_elevado",
				"nome": "Platô Elevado Oeste",
				"pos": Vector2(720.0, 920.0),
				"raio": 165.0,
				"elevacao": 2,
				"efeito": "vantagem_altura_e_protecao_borda",
			},
			{
				"id": "plato_elevado_leste",
				"tipo": "plato_elevado",
				"nome": "Platô Elevado Leste",
				"pos": Vector2(2480.0, 920.0),
				"raio": 165.0,
				"elevacao": 2,
				"efeito": "vantagem_altura_e_protecao_borda",
			},
			{
				"id": "ponte_escarpa_oeste",
				"tipo": "ponte_escarpa",
				"nome": "Ponte Suspensa Oeste",
				"pos": Vector2(1140.0, 1140.0),
				"raio": 120.0,
				"elevacao": 1,
				"efeito": "travessia_segura_entre_platos",
			},
			{
				"id": "ponte_escarpa_leste",
				"tipo": "ponte_escarpa",
				"nome": "Ponte Suspensa Leste",
				"pos": Vector2(2060.0, 1140.0),
				"raio": 120.0,
				"elevacao": 1,
				"efeito": "travessia_segura_entre_platos",
			},
		],
		"perigos_dinamicos": [
			{
				"id": "beirada_penhasco_oeste",
				"tipo": "beirada_penhasco",
				"nome": "Beirada do Penhasco Oeste",
				"pos": Vector2(240.0, 940.0),
				"raio": 120.0,
				"knockback_letal": true,
				"dano_por_tick": 50.0,
				"efeito": "queda_letal_por_empurrao",
			},
			{
				"id": "beirada_penhasco_leste",
				"tipo": "beirada_penhasco",
				"nome": "Beirada do Penhasco Leste",
				"pos": Vector2(2960.0, 940.0),
				"raio": 120.0,
				"knockback_letal": true,
				"dano_por_tick": 50.0,
				"efeito": "queda_letal_por_empurrao",
			},
			{
				"id": "beirada_penhasco_norte",
				"tipo": "beirada_penhasco",
				"nome": "Beirada do Penhasco Norte",
				"pos": Vector2(1600.0, 190.0),
				"raio": 95.0,
				"knockback_letal": true,
				"dano_por_tick": 50.0,
				"efeito": "queda_letal_por_empurrao",
			},
			{
				"id": "onda_sismica_escarpa",
				"tipo": "onda_sismica",
				"nome": "Fissura de Ondas Sísmicas Central",
				"pos": Vector2(1600.0, 820.0),
				"raio": 230.0,
				"knockback_letal": false,
				"dano_por_tick": 16.0,
				"efeito": "empurrao_radial_e_abalo",
			},
		],
		"obstaculos": [
			{
				"id": "cobertura_destrutivel_so",
				"tipo": "cobertura_rocha_destrutivel",
				"nome": "Bloqueio Rochoso Sudoeste",
				"pos": Vector2(1180.0, 1340.0),
				"raio": 46.0,
				"destrutivel": true,
				"hp": 120.0,
			},
			{
				"id": "cobertura_destrutivel_se",
				"tipo": "cobertura_rocha_destrutivel",
				"nome": "Bloqueio Rochoso Sudeste",
				"pos": Vector2(2020.0, 1340.0),
				"raio": 46.0,
				"destrutivel": true,
				"hp": 120.0,
			},
			{
				"id": "cobertura_destrutivel_no",
				"tipo": "cobertura_rocha_destrutivel",
				"nome": "Bloqueio Rochoso Noroeste",
				"pos": Vector2(1040.0, 680.0),
				"raio": 46.0,
				"destrutivel": true,
				"hp": 120.0,
			},
			{
				"id": "cobertura_destrutivel_ne",
				"tipo": "cobertura_rocha_destrutivel",
				"nome": "Bloqueio Rochoso Nordeste",
				"pos": Vector2(2160.0, 680.0),
				"raio": 46.0,
				"destrutivel": true,
				"hp": 120.0,
			},
		],
		"interativos": [
			{
				"id": "ancora_escalada_oeste",
				"tipo": "ancora_escalada",
				"nome": "Âncora de Escalada Oeste",
				"pos": Vector2(880.0, 1340.0),
				"raio": 44.0,
				"acao": "reposicionar_para_plato_oeste",
				"recarga_passos": 360,
				"usado": false,
			},
			{
				"id": "ancora_escalada_leste",
				"tipo": "ancora_escalada",
				"nome": "Âncora de Escalada Leste",
				"pos": Vector2(2320.0, 1340.0),
				"raio": 44.0,
				"acao": "reposicionar_para_plato_leste",
				"recarga_passos": 360,
				"usado": false,
			},
		],
		"props_storytelling": [
			{
				"id": "coroa_pedra_partida_prop",
				"tipo": "monumento_partido",
				"nome": "Coroa de Pedra Partida da Vigília",
				"pos": Vector2(560.0, 560.0),
				"descricao": "Fragmento de rocha talhada sem inscrições partido ao meio na borda do desfiladeiro.",
			},
			{
				"id": "tronco_petrificado_escarpa",
				"tipo": "tronco_petrificado",
				"nome": "Tronco Petrificado Tombado",
				"pos": Vector2(2640.0, 560.0),
				"descricao": "Resto de copa antiga calcificada pela Beira, sem marcas de corte humano.",
			},
		],
		"mecanicas_ambientais": [
			{
				"id": "ondas_sismicas_periodicas",
				"nome": "Ondas Sísmicas de Escarpa",
				"intervalo_passos": 480,
				"descricao": "Tremores periódicos empurram combatentes fora dos platôs na direção dos penhascos.",
			},
			{
				"id": "knockback_letal_beirada",
				"nome": "Knockback Letal de Beirada",
				"intervalo_passos": 0,
				"descricao": "Ultrapassar as beiradas de penhasco por empurrão aplica penalidade severa de queda.",
			},
		],
		"assets_necessarios": {
			"arena_bg": "res://assets/art/environment/escarpas_copa_quebrada/arena_bg.png",
			"tiles": [
				"res://assets/art/environment/escarpas_copa_quebrada/plato_rocha_01.png",
				"res://assets/art/environment/escarpas_copa_quebrada/ponte_suspensa_01.png",
			],
			"props": [
				"res://assets/art/environment/escarpas_copa_quebrada/cobertura_destrutivel_01.png",
				"res://assets/art/environment/escarpas_copa_quebrada/ancora_escalada_01.png",
			],
			"vfx": [
				"res://assets/art/vfx/onda_sismica_escarpa_v01.png",
				"res://assets/art/vfx/destrocos_cobertura_v01.png",
			],
			"indicadores_perigo": [
				"res://assets/art/vfx/indicador_beirada_penhasco_v01.png",
				"res://assets/art/vfx/indicador_visao_hexagonal_v01.png",
			],
			"boss_atlases": [
				"res://assets/art/runtime/chefe_vigia_coroa/chefe_vigia_coroa_frames_v01.tres",
			],
		},
	}


static func _mapa_04_fendas_cinzentas() -> Dictionary:
	return {
		"id": "fendas_cinzentas",
		"nome": "Fendas Cinzentas (Fosso-Prisão Antigo)",
		"subtitulo": "Muralhas Quebradas da Prisão de Basalto",
		"bioma": "prisao_cinzenta",
		"rank": "S",
		"nivel_recomendado": 74,
		"escala_metros": 25.0,
		"camera_zoom": 0.90,
		"paleta": {
			"bg": Color("0c0c10"),
			"floor": Color("1f2026"),
			"accent": Color("ef4444"),
			"border": Color("4b4d57"),
			"perigo": Color("e0259c"),
			"seguro": Color("94a3b8"),
			"nevoa": Color("23242c"),
			"motif": "fendas_cinzentas",
		},
		"arena": {
			"forma": "retangular",
			"largura": 3500.0,
			"altura": 1840.0,
			"margem_borda_px": MARGEM_BORDA_PADRAO_PX,
			"centro": Vector2(1750.0, 920.0),
			"spawn_jogador": Vector2(1750.0, 1560.0),
			"spawn_boss": Vector2(1750.0, 420.0),
		},
		"boss": {
			"id": "tirano_quebra_grilhoes",
			"nome": "Tirano Quebra-Grilhões",
			"arquetipo": "Bruto de Cerco / Juggernaut Imparável",
			"rank": "S",
			"nivel": 74,
			"vida": 3900.0,
			"velocidade": 158.0,
			"raio_px": 112.0,
			"dano": 38.0,
			"escala_sprite": 2.25,
			"estatico": false,
			"fases": 2,
			"limiar_fase2_frac": 0.50,
			"atlas_id": "chefe_tirano_grilhoes",
			"descricao": (
				"Juggernaut colossal que despedaçou seus próprios grilhões de contenção e "
				+ "esmaga o fosso-prisão com investidas capazes de fender o basalto."
			),
			"tatica": (
				"Use os corredores laterais de flanqueio para escapar do terreno de correntes partidas e "
				+ "direcione a Investida de Compressão contra os quatro monólitos de contenção para atordoá-lo."
			),
			"habilidades": [
				{
					"id": "investida_de_compressao",
					"nome": "Investida de Compressão",
					"tipo": "investida",
					"forma_telegrafo": "retangulo",
					"dano_mult": 1.35,
					"alcance_px": 840.0,
					"preparo_s": 0.65,
					"recarga_s": 2.00,
					"descricao": "Arrancada imparável em linha reta; colidir contra um monólito de contenção interrompe e atordoa o Tirano.",
				},
				{
					"id": "rasgo_do_tirano",
					"nome": "Rasgo do Tirano",
					"tipo": "corpo_a_corpo",
					"forma_telegrafo": "setor",
					"dano_mult": 1.20,
					"alcance_px": 270.0,
					"preparo_s": 0.55,
					"recarga_s": 1.70,
					"descricao": "Golpe duplo com a garra fendedora que abre fendas no chão ao longo do arco.",
				},
				{
					"id": "pressao_soberana",
					"nome": "Pressão Soberana",
					"tipo": "area",
					"forma_telegrafo": "circulo",
					"dano_mult": 1.30,
					"alcance_px": 340.0,
					"preparo_s": 0.80,
					"recarga_s": 2.60,
					"descricao": "Impacto gravitacional com os punhos acorrentados que esmaga o centro da prisão.",
				},
				{
					"id": "frenesi_quebra_grilhoes",
					"nome": "Frenesi Quebra-Grilhões",
					"tipo": "furia",
					"forma_telegrafo": "anel",
					"dano_mult": 1.50,
					"alcance_px": 420.0,
					"preparo_s": 0.90,
					"recarga_s": 3.10,
					"descricao": "Rompe os últimos elos de ferro em Fúria e encadeia três avanços de cerco consecutivos.",
				},
			],
			"fraquezas": ["Monólitos de Contenção", "Corredores de Flanqueio", "Atordoamento por Colisão"],
			"imunidades": ["empurrao", "imobilizacao", "quebrou_comum"],
			"espolios": [
				{
					"id": "nucleo_tirano",
					"nome": "Núcleo do Tirano",
					"raridade": "lendaria",
					"tipo": "nucleo",
					"quantidade": 1,
					"descricao": "Coração ferro-cinza forjado sob séculos de aprisionamento e fúria contida.",
				},
				{
					"id": "garra_fendedora",
					"nome": "Garra Fendedora",
					"raridade": "epica",
					"tipo": "material",
					"quantidade": 1,
					"descricao": "Lâmina natural capaz de partir grilhões rúnicos e armaduras de cerco.",
				},
			],
		},
		"zonas_seguras": [
			{
				"id": "corredor_flanqueio_oeste",
				"tipo": "corredor_flanqueio",
				"nome": "Corredor de Flanqueio Oeste",
				"pos": Vector2(440.0, 920.0),
				"raio": 160.0,
				"efeito": "rota_livre_sem_correntes",
			},
			{
				"id": "corredor_flanqueio_leste",
				"tipo": "corredor_flanqueio",
				"nome": "Corredor de Flanqueio Leste",
				"pos": Vector2(3060.0, 920.0),
				"raio": 160.0,
				"efeito": "rota_livre_sem_correntes",
			},
			{
				"id": "alcova_flanqueio_sul",
				"tipo": "corredor_flanqueio",
				"nome": "Alcova Tática da Entrada",
				"pos": Vector2(1750.0, 1520.0),
				"raio": 140.0,
				"efeito": "rota_livre_sem_correntes",
			},
		],
		"perigos_dinamicos": [
			{
				"id": "correntes_partidas_centro",
				"tipo": "correntes_partidas",
				"nome": "Campo de Correntes Partidas Central",
				"pos": Vector2(1750.0, 940.0),
				"raio": 185.0,
				"terreno_dificil": true,
				"fator_lentidao": 0.70,
				"dano_por_tick": 12.0,
				"efeito": "reduz_velocidade_e_corta_passo",
			},
			{
				"id": "correntes_partidas_oeste",
				"tipo": "correntes_partidas",
				"nome": "Campo de Correntes Partidas Oeste",
				"pos": Vector2(1040.0, 740.0),
				"raio": 155.0,
				"terreno_dificil": true,
				"fator_lentidao": 0.70,
				"dano_por_tick": 12.0,
				"efeito": "reduz_velocidade_e_corta_passo",
			},
			{
				"id": "correntes_partidas_leste",
				"tipo": "correntes_partidas",
				"nome": "Campo de Correntes Partidas Leste",
				"pos": Vector2(2460.0, 740.0),
				"raio": 155.0,
				"terreno_dificil": true,
				"fator_lentidao": 0.70,
				"dano_por_tick": 12.0,
				"efeito": "reduz_velocidade_e_corta_passo",
			},
		],
		"obstaculos": [
			{
				"id": "monolito_contencao_so",
				"tipo": "monolito_contencao",
				"nome": "Monólito de Contenção Sudoeste",
				"pos": Vector2(1140.0, 1220.0),
				"raio": 58.0,
				"destrutivel": false,
				"efeito_impacto_boss": "interrompe_investida_e_atordoa",
			},
			{
				"id": "monolito_contencao_se",
				"tipo": "monolito_contencao",
				"nome": "Monólito de Contenção Sudeste",
				"pos": Vector2(2360.0, 1220.0),
				"raio": 58.0,
				"destrutivel": false,
				"efeito_impacto_boss": "interrompe_investida_e_atordoa",
			},
			{
				"id": "monolito_contencao_no",
				"tipo": "monolito_contencao",
				"nome": "Monólito de Contenção Noroeste",
				"pos": Vector2(1140.0, 620.0),
				"raio": 58.0,
				"destrutivel": false,
				"efeito_impacto_boss": "interrompe_investida_e_atordoa",
			},
			{
				"id": "monolito_contencao_ne",
				"tipo": "monolito_contencao",
				"nome": "Monólito de Contenção Nordeste",
				"pos": Vector2(2360.0, 620.0),
				"raio": 58.0,
				"destrutivel": false,
				"efeito_impacto_boss": "interrompe_investida_e_atordoa",
			},
		],
		"interativos": [
			{
				"id": "alavanca_contencao_oeste",
				"tipo": "mecanismo_contencao",
				"nome": "Alavanca de Contenção Oeste",
				"pos": Vector2(620.0, 1340.0),
				"raio": 46.0,
				"acao": "reforcar_monolitos_de_contencao",
				"recarga_passos": 600,
				"usado": false,
			},
			{
				"id": "alavanca_contencao_leste",
				"tipo": "mecanismo_contencao",
				"nome": "Alavanca de Contenção Leste",
				"pos": Vector2(2880.0, 1340.0),
				"raio": 46.0,
				"acao": "reforcar_monolitos_de_contencao",
				"recarga_passos": 600,
				"usado": false,
			},
		],
		"props_storytelling": [
			{
				"id": "grilhoes_gigantes_partidos",
				"tipo": "grilhoes_partidos",
				"nome": "Grilhões Gigantes Partidos",
				"pos": Vector2(1750.0, 260.0),
				"descricao": "Elos monumentais arrancados de argolas de basalto de dentro para fora.",
			},
			{
				"id": "sulcos_investida_basalto",
				"tipo": "sulcos_investida",
				"nome": "Sulcos Profundos de Investida",
				"pos": Vector2(460.0, 420.0),
				"descricao": "Rastros fundos escavados nas lajes cinzentas por incontáveis investidas antigas.",
			},
		],
		"mecanicas_ambientais": [
			{
				"id": "terreno_dificil_correntes",
				"nome": "Terreno Difícil de Correntes Partidas",
				"intervalo_passos": 0,
				"descricao": "Atravessar correntes partidas reduz a velocidade de deslocamento fora dos corredores laterais.",
			},
			{
				"id": "ressonancia_monolito_atordoamento",
				"nome": "Choque contra Monólito de Contenção",
				"intervalo_passos": 300,
				"descricao": "Impactos do boss contra os monólitos liberam pulso de contenção e janela de atordoamento.",
			},
		],
		"assets_necessarios": {
			"arena_bg": "res://assets/art/environment/fendas_cinzentas/arena_bg.png",
			"tiles": [
				"res://assets/art/environment/fendas_cinzentas/piso_prisao_basalto_01.png",
				"res://assets/art/environment/fendas_cinzentas/corredor_flanqueio_01.png",
			],
			"props": [
				"res://assets/art/environment/fendas_cinzentas/monolito_contencao_01.png",
				"res://assets/art/environment/fendas_cinzentas/correntes_partidas_01.png",
				"res://assets/art/environment/fendas_cinzentas/grilhoes_gigantes_01.png",
			],
			"vfx": [
				"res://assets/art/vfx/impacto_compressao_v01.png",
				"res://assets/art/vfx/estilhacos_correntes_v01.png",
			],
			"indicadores_perigo": [
				"res://assets/art/vfx/indicador_investida_tirano_v01.png",
				"res://assets/art/vfx/indicador_pressao_soberana_v01.png",
			],
			"boss_atlases": [
				"res://assets/art/runtime/chefe_tirano_grilhoes/chefe_tirano_grilhoes_frames_v01.tres",
			],
		},
	}


static func _mapa_05_terras_baldias_subterraneas() -> Dictionary:
	return {
		"id": "terras_baldias_subterraneas",
		"nome": "Terras Baldias Subterrâneas (Abismo dos Selos)",
		"subtitulo": "Câmara Primordial do Selo Rompido",
		"bioma": "abismo_subterraneo",
		"rank": "Cataclísmico",
		"nivel_recomendado": 90,
		"escala_metros": 50.0,
		"camera_zoom": 0.82,
		"paleta": {
			"bg": Color("07060c"),
			"floor": Color("151322"),
			"accent": Color("e0259c"),
			"border": Color("3b2d54"),
			"perigo": Color("e0259c"),
			"seguro": Color("fde047"),
			"nevoa": Color("120e1f"),
			"motif": "abismo_selos",
		},
		"arena": {
			"forma": "caverna",
			"largura": 3800.0,
			"altura": 2100.0,
			"margem_borda_px": MARGEM_BORDA_PADRAO_PX,
			"centro": Vector2(1900.0, 1050.0),
			"spawn_jogador": Vector2(1900.0, 1780.0),
			"spawn_boss": Vector2(1900.0, 520.0),
		},
		"boss": {
			"id": "pesadelo_fendas_subterraneas",
			"nome": "Pesadelo das Fendas Subterrâneas",
			"arquetipo": "Entidade Abissal / Devorador Subterrâneo",
			"rank": "Cataclísmico",
			"nivel": 90,
			"vida": 6200.0,
			"velocidade": 175.0,
			"raio_px": 136.0,
			"dano": 46.0,
			"escala_sprite": 2.85,
			"estatico": false,
			"fases": 3,
			"limiar_fase2_frac": 0.66,
			"limiar_fase3_frac": 0.33,
			"atlas_id": "chefe_pesadelo_abismo",
			"descricao": (
				"Entidade abissal cataclísmica que escava sob o solo arenoso primordial para regenerar "
				+ "carne e rasgar a caverna com tentáculos e o Olhar do Abismo."
			),
			"tatica": (
				"Use os Selos Antigos para forçar o Pesadelo à superfície e cortar sua regeneração, "
				+ "ative os Cristais Harmônicos para desorientá-lo e combata sob as Fendas de Luz Sagrada."
			),
			"habilidades": [
				{
					"id": "escavacao_abissal_regeneracao",
					"nome": "Escavação Abissal & Regeneração Abissal",
					"tipo": "passiva",
					"forma_telegrafo": "circulo",
					"dano_mult": 1.10,
					"alcance_px": 260.0,
					"preparo_s": 0.80,
					"recarga_s": 2.80,
					"descricao": "Submerge no solo arenoso para recuperar Vida continuamente até ser contido por Selos Antigos.",
				},
				{
					"id": "tentaculos_do_vazio",
					"nome": "Tentáculos do Vazio",
					"tipo": "invocacao",
					"forma_telegrafo": "circulo",
					"dano_mult": 1.25,
					"alcance_px": 220.0,
					"preparo_s": 0.70,
					"recarga_s": 2.30,
					"descricao": "Emerge apêndices sombrios ao redor das plataformas de rocha matriz para cercar o Iniciado.",
				},
				{
					"id": "olhar_do_abismo",
					"nome": "Olhar do Abismo",
					"tipo": "area",
					"forma_telegrafo": "setor",
					"dano_mult": 1.40,
					"alcance_px": 720.0,
					"preparo_s": 0.85,
					"recarga_s": 2.70,
					"descricao": "Projeta cone cataclísmico de escuridão que petrifica fora das fendas de Luz Sagrada.",
				},
				{
					"id": "devoracao_total",
					"nome": "Devoração Total",
					"tipo": "furia",
					"forma_telegrafo": "anel",
					"dano_mult": 1.65,
					"alcance_px": 540.0,
					"preparo_s": 1.05,
					"recarga_s": 3.60,
					"descricao": "Abre uma voragem central que suga a caverna inteira antes de detonar em ondas abissais.",
				},
			],
			"fraquezas": ["Luz Sagrada", "Vibrações Harmônicas", "Selos Antigos"],
			"imunidades": ["empurrao", "sangramento_subterraneo", "escuridao"],
			"espolios": [
				{
					"id": "nucleo_abismo",
					"nome": "Núcleo do Abismo",
					"raridade": "cataclismica",
					"tipo": "nucleo",
					"quantidade": 1,
					"descricao": "Fragmento vivo da fenda primordial onde o próprio abismo pulsa.",
				},
			],
		},
		"zonas_seguras": [
			{
				"id": "rocha_matriz_runica_sul",
				"tipo": "rocha_matriz_runica",
				"nome": "Plataforma de Rocha Matriz Rúnica Sul",
				"pos": Vector2(1900.0, 1660.0),
				"raio": 155.0,
				"impede_escavacao": true,
				"efeito": "solo_solido_anti_escavacao",
			},
			{
				"id": "rocha_matriz_runica_oeste",
				"tipo": "rocha_matriz_runica",
				"nome": "Plataforma de Rocha Matriz Rúnica Oeste",
				"pos": Vector2(780.0, 1080.0),
				"raio": 145.0,
				"impede_escavacao": true,
				"efeito": "solo_solido_anti_escavacao",
			},
			{
				"id": "rocha_matriz_runica_leste",
				"tipo": "rocha_matriz_runica",
				"nome": "Plataforma de Rocha Matriz Rúnica Leste",
				"pos": Vector2(3020.0, 1080.0),
				"raio": 145.0,
				"impede_escavacao": true,
				"efeito": "solo_solido_anti_escavacao",
			},
			{
				"id": "fenda_luz_sagrada_oeste",
				"tipo": "fenda_luz_sagrada",
				"nome": "Fenda de Luz Sagrada Oeste",
				"pos": Vector2(1180.0, 1340.0),
				"raio": 110.0,
				"fraqueza_ativada": "Luz Sagrada",
				"efeito": "purifica_escuridao_e_amplifica_dano_sagrado",
			},
			{
				"id": "fenda_luz_sagrada_leste",
				"tipo": "fenda_luz_sagrada",
				"nome": "Fenda de Luz Sagrada Leste",
				"pos": Vector2(2620.0, 1340.0),
				"raio": 110.0,
				"fraqueza_ativada": "Luz Sagrada",
				"efeito": "purifica_escuridao_e_amplifica_dano_sagrado",
			},
			{
				"id": "fenda_luz_sagrada_central",
				"tipo": "fenda_luz_sagrada",
				"nome": "Fenda de Luz Sagrada Central",
				"pos": Vector2(1900.0, 820.0),
				"raio": 110.0,
				"fraqueza_ativada": "Luz Sagrada",
				"efeito": "purifica_escuridao_e_amplifica_dano_sagrado",
			},
		],
		"perigos_dinamicos": [
			{
				"id": "solo_arenoso_norte",
				"tipo": "solo_arenoso_escavacao",
				"nome": "Solo Arenoso de Escavação Norte",
				"pos": Vector2(1900.0, 560.0),
				"raio": 260.0,
				"permite_regeneracao_abissal": true,
				"dano_por_tick": 18.0,
				"efeito": "permite_escavacao_e_regeneracao_abissal",
			},
			{
				"id": "solo_arenoso_oeste",
				"tipo": "solo_arenoso_escavacao",
				"nome": "Solo Arenoso de Escavação Oeste",
				"pos": Vector2(1260.0, 960.0),
				"raio": 200.0,
				"permite_regeneracao_abissal": true,
				"dano_por_tick": 18.0,
				"efeito": "permite_escavacao_e_regeneracao_abissal",
			},
			{
				"id": "solo_arenoso_leste",
				"tipo": "solo_arenoso_escavacao",
				"nome": "Solo Arenoso de Escavação Leste",
				"pos": Vector2(2540.0, 960.0),
				"raio": 200.0,
				"permite_regeneracao_abissal": true,
				"dano_por_tick": 18.0,
				"efeito": "permite_escavacao_e_regeneracao_abissal",
			},
			{
				"id": "tremor_tectonico_centro",
				"tipo": "tremor_tectonico",
				"nome": "Zona de Tremor Tectônico",
				"pos": Vector2(1900.0, 1180.0),
				"raio": 220.0,
				"permite_regeneracao_abissal": false,
				"dano_por_tick": 22.0,
				"efeito": "desmoronamento_e_instabilidade",
			},
		],
		"obstaculos": [
			{
				"id": "estalagmite_matriz_so",
				"tipo": "rocha_matriz_pilastra",
				"nome": "Pilastra de Rocha Matriz Sudoeste",
				"pos": Vector2(1380.0, 1480.0),
				"raio": 54.0,
				"destrutivel": false,
			},
			{
				"id": "estalagmite_matriz_se",
				"tipo": "rocha_matriz_pilastra",
				"nome": "Pilastra de Rocha Matriz Sudeste",
				"pos": Vector2(2420.0, 1480.0),
				"raio": 54.0,
				"destrutivel": false,
			},
			{
				"id": "estalagmite_matriz_no",
				"tipo": "rocha_matriz_pilastra",
				"nome": "Pilastra de Rocha Matriz Noroeste",
				"pos": Vector2(1380.0, 680.0),
				"raio": 54.0,
				"destrutivel": false,
			},
			{
				"id": "estalagmite_matriz_ne",
				"tipo": "rocha_matriz_pilastra",
				"nome": "Pilastra de Rocha Matriz Nordeste",
				"pos": Vector2(2420.0, 680.0),
				"raio": 54.0,
				"destrutivel": false,
			},
		],
		"interativos": [
			{
				"id": "selo_runico_antigo_so",
				"tipo": "selo_runico_antigo",
				"nome": "Selo Rúnico Antigo Sudoeste",
				"pos": Vector2(1020.0, 1520.0),
				"raio": 48.0,
				"acao": "conter_na_superficie_e_cortar_regeneracao",
				"fraqueza_ativada": "Selos Antigos",
				"recarga_passos": 600,
				"usado": false,
			},
			{
				"id": "selo_runico_antigo_se",
				"tipo": "selo_runico_antigo",
				"nome": "Selo Rúnico Antigo Sudeste",
				"pos": Vector2(2780.0, 1520.0),
				"raio": 48.0,
				"acao": "conter_na_superficie_e_cortar_regeneracao",
				"fraqueza_ativada": "Selos Antigos",
				"recarga_passos": 600,
				"usado": false,
			},
			{
				"id": "selo_runico_antigo_no",
				"tipo": "selo_runico_antigo",
				"nome": "Selo Rúnico Antigo Noroeste",
				"pos": Vector2(1020.0, 620.0),
				"raio": 48.0,
				"acao": "conter_na_superficie_e_cortar_regeneracao",
				"fraqueza_ativada": "Selos Antigos",
				"recarga_passos": 600,
				"usado": false,
			},
			{
				"id": "selo_runico_antigo_ne",
				"tipo": "selo_runico_antigo",
				"nome": "Selo Rúnico Antigo Nordeste",
				"pos": Vector2(2780.0, 620.0),
				"raio": 48.0,
				"acao": "conter_na_superficie_e_cortar_regeneracao",
				"fraqueza_ativada": "Selos Antigos",
				"recarga_passos": 600,
				"usado": false,
			},
			{
				"id": "cristal_harmonico_oeste",
				"tipo": "cristal_harmonico",
				"nome": "Cristal Harmônico Oeste",
				"pos": Vector2(620.0, 1080.0),
				"raio": 44.0,
				"acao": "emitir_vibracao_harmonica_desorientar",
				"fraqueza_ativada": "Vibrações Harmônicas",
				"recarga_passos": 540,
				"usado": false,
			},
			{
				"id": "cristal_harmonico_leste",
				"tipo": "cristal_harmonico",
				"nome": "Cristal Harmônico Leste",
				"pos": Vector2(3180.0, 1080.0),
				"raio": 44.0,
				"acao": "emitir_vibracao_harmonica_desorientar",
				"fraqueza_ativada": "Vibrações Harmônicas",
				"recarga_passos": 540,
				"usado": false,
			},
			{
				"id": "cristal_harmonico_norte",
				"tipo": "cristal_harmonico",
				"nome": "Cristal Harmônico Norte",
				"pos": Vector2(1900.0, 320.0),
				"raio": 44.0,
				"acao": "emitir_vibracao_harmonica_desorientar",
				"fraqueza_ativada": "Vibrações Harmônicas",
				"recarga_passos": 540,
				"usado": false,
			},
		],
		"props_storytelling": [
			{
				"id": "obelisco_selo_rompido_oeste",
				"tipo": "obelisco_selo_rompido",
				"nome": "Obelisco do Primeiro Selo Rompido",
				"pos": Vector2(520.0, 520.0),
				"descricao": "Monólito de contenção geológica anterior à Universidade partido pelo abismo.",
			},
			{
				"id": "formacao_cristalina_ressonante",
				"tipo": "diapasao_natural",
				"nome": "Formação Cristalina Ressonante",
				"pos": Vector2(3280.0, 520.0),
				"descricao": "Diapasão mineral natural cravado na caverna que vibra em frequência harmônica pura.",
			},
		],
		"mecanicas_ambientais": [
			{
				"id": "escavacao_solo_arenoso",
				"nome": "Escavação e Regeneração Abissal",
				"intervalo_passos": 180,
				"descricao": "Enquanto submerso em solo arenoso sem selo ativo, o boss regenera Vida periodicamente.",
			},
			{
				"id": "tremor_tectonico_periodico",
				"nome": "Tremor Tectônico Subterrâneo",
				"intervalo_passos": 540,
				"descricao": "Abalos sísmicos periódicos deslocam detritos fora das plataformas de rocha matriz.",
			},
			{
				"id": "ressonancia_luz_sagrada_contencao",
				"nome": "Zona de Luz Sagrada",
				"intervalo_passos": 0,
				"descricao": "Fendas de Luz Sagrada dissipam escuridão do Olhar do Abismo de forma contínua.",
			},
		],
		"assets_necessarios": {
			"arena_bg": "res://assets/art/environment/terras_baldias_subterraneas/arena_bg.png",
			"tiles": [
				"res://assets/art/environment/terras_baldias_subterraneas/rocha_matriz_runica_01.png",
				"res://assets/art/environment/terras_baldias_subterraneas/solo_arenoso_abissal_01.png",
			],
			"props": [
				"res://assets/art/environment/terras_baldias_subterraneas/selo_runico_antigo_01.png",
				"res://assets/art/environment/terras_baldias_subterraneas/cristal_harmonico_01.png",
				"res://assets/art/environment/terras_baldias_subterraneas/obelisco_selo_rompido_01.png",
			],
			"vfx": [
				"res://assets/art/vfx/luz_sagrada_fenda_v01.png",
				"res://assets/art/vfx/tentaculos_vazio_v01.png",
				"res://assets/art/vfx/vibracao_harmonica_v01.png",
			],
			"indicadores_perigo": [
				"res://assets/art/vfx/indicador_escavacao_abissal_v01.png",
				"res://assets/art/vfx/indicador_devoracao_total_v01.png",
			],
			"boss_atlases": [
				"res://assets/art/runtime/chefe_pesadelo_abismo/chefe_pesadelo_abismo_frames_v01.tres",
			],
		},
	}
