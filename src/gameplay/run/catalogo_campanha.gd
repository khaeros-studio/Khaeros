class_name CatalogoCampanha
extends RefCounted
## Catálogo da campanha estendida (4 regiões jogáveis, 4 chefes e pool de 15 bênçãos).
##
## Fornece dados imutáveis (cópias novas a cada chamada) para a progressão de regiões,
## paletas visuais, ondas de combate, parâmetros de chefes e sorteio determinístico
## de ofertas de bênçãos usando [RngAritmetica] e [FluxoRng].

const FINALIDADE_OFERTA_BENCAO: int = 4
const TAMANHO_OFERTA: int = 3


## Retorna as 4 regiões jogáveis da campanha em ordem de progressão:
## 0. limiar ("O Limiar da Beira")
## 1. veio_instavel ("Veio Instável")
## 2. fosso_das_cinzas ("Fosso das Cinzas")
## 3. santuario_partido ("Santuário Partido")
static func regioes() -> Array[Dictionary]:
	var lista: Array[Dictionary] = [
		{
			"id": "limiar",
			"nome": "O Limiar da Beira",
			"bg": Color("0e101a"),
			"floor": Color("1d212b"),
			"accent": Color("e3b23c"),
			"border": Color("383b46"),
			"motif": "limiar",
			"paleta": {
				"bg": Color("0e101a"),
				"floor": Color("1d212b"),
				"accent": Color("e3b23c"),
				"border": Color("383b46"),
				"motif": "limiar",
			},
			"ondas": [
				[
					{"id": "eco_perdido", "x": 750.0, "y": 250.0},
					{"id": "eco_perdido", "x": 1650.0, "y": 250.0},
					{"id": "anomalia_menor", "x": 375.0, "y": 375.0},
				],
				[
					{"id": "eco_perdido", "x": 625.0, "y": 225.0},
					{"id": "eco_perdido", "x": 1200.0, "y": 200.0, "elite": true},
					{"id": "eco_perdido", "x": 1775.0, "y": 225.0},
					{"id": "anomalia_menor", "x": 312.5, "y": 500.0},
					{"id": "anomalia_menor", "x": 2087.5, "y": 500.0},
				],
				[
					{"id": "eco_perdido", "x": 500.0, "y": 375.0},
					{"id": "eco_perdido", "x": 1200.0, "y": 200.0, "elite": true},
					{"id": "eco_perdido", "x": 1900.0, "y": 375.0},
					{"id": "anomalia_menor", "x": 875.0, "y": 200.0},
					{"id": "anomalia_menor", "x": 1525.0, "y": 200.0},
				],
			],
			"chefe": {
				"id": "soberano_do_limiar",
				"nome": "Soberano do Limiar",
				"vida": 700.0,
				"velocidade": 130.0,
				"raio": 48.0,
				"dano": 18.0,
				"boss_style": "soberano",
				"fragmentos": 24,
			},
		},
		{
			"id": "veio_instavel",
			"nome": "Veio Instável",
			"bg": Color("140b16"),
			"floor": Color("241728"),
			"accent": Color("e0259c"),
			"border": Color("572c5c"),
			"motif": "veio",
			"paleta": {
				"bg": Color("140b16"),
				"floor": Color("241728"),
				"accent": Color("e0259c"),
				"border": Color("572c5c"),
				"motif": "veio",
			},
			"ondas": [
				[
					{"id": "eco_perdido", "x": 600.0, "y": 240.0},
					{"id": "eco_perdido", "x": 1200.0, "y": 210.0, "elite": true},
					{"id": "eco_perdido", "x": 1800.0, "y": 240.0},
					{"id": "anomalia_menor", "x": 360.0, "y": 420.0},
					{"id": "anomalia_menor", "x": 2040.0, "y": 420.0},
				],
				[
					{"id": "eco_perdido", "x": 520.0, "y": 260.0, "elite": true},
					{"id": "eco_perdido", "x": 1880.0, "y": 260.0, "elite": true},
					{"id": "eco_perdido", "x": 1200.0, "y": 200.0},
					{"id": "anomalia_menor", "x": 420.0, "y": 540.0},
					{"id": "anomalia_menor", "x": 1200.0, "y": 320.0},
					{"id": "anomalia_menor", "x": 1980.0, "y": 540.0},
				],
				[
					{"id": "eco_perdido", "x": 480.0, "y": 360.0, "elite": true},
					{"id": "eco_perdido", "x": 1200.0, "y": 200.0, "elite": true},
					{"id": "eco_perdido", "x": 1920.0, "y": 360.0},
					{"id": "anomalia_menor", "x": 780.0, "y": 210.0, "elite": true},
					{"id": "anomalia_menor", "x": 1620.0, "y": 210.0},
					{"id": "anomalia_menor", "x": 2080.0, "y": 520.0},
				],
			],
			"chefe": {
				"id": "guardiao_do_rito",
				"nome": "Guardião do Rito",
				"vida": 950.0,
				"velocidade": 135.0,
				"raio": 50.0,
				"dano": 20.0,
				"boss_style": "leque",
				"fragmentos": 32,
			},
		},
		{
			"id": "fosso_das_cinzas",
			"nome": "Fosso das Cinzas",
			"bg": Color("141010"),
			"floor": Color("231d1c"),
			"accent": Color("e07b39"),
			"border": Color("4d3a34"),
			"motif": "cinzas",
			"paleta": {
				"bg": Color("141010"),
				"floor": Color("231d1c"),
				"accent": Color("e07b39"),
				"border": Color("4d3a34"),
				"motif": "cinzas",
			},
			"ondas": [
				[
					{"id": "eco_perdido", "x": 540.0, "y": 240.0, "elite": true},
					{"id": "eco_perdido", "x": 1200.0, "y": 210.0},
					{"id": "eco_perdido", "x": 1860.0, "y": 240.0, "elite": true},
					{"id": "anomalia_menor", "x": 340.0, "y": 460.0},
					{"id": "anomalia_menor", "x": 960.0, "y": 220.0},
					{"id": "anomalia_menor", "x": 2060.0, "y": 460.0},
				],
				[
					{"id": "eco_perdido", "x": 440.0, "y": 300.0, "elite": true},
					{"id": "eco_perdido", "x": 1200.0, "y": 190.0, "elite": true},
					{"id": "eco_perdido", "x": 1960.0, "y": 300.0, "elite": true},
					{"id": "eco_perdido", "x": 820.0, "y": 360.0},
					{"id": "anomalia_menor", "x": 320.0, "y": 580.0},
					{"id": "anomalia_menor", "x": 1580.0, "y": 240.0, "elite": true},
					{"id": "anomalia_menor", "x": 2080.0, "y": 580.0},
				],
				[
					{"id": "eco_perdido", "x": 460.0, "y": 380.0, "elite": true},
					{"id": "eco_perdido", "x": 960.0, "y": 200.0, "elite": true},
					{"id": "eco_perdido", "x": 1440.0, "y": 200.0, "elite": true},
					{"id": "eco_perdido", "x": 1940.0, "y": 380.0},
					{"id": "anomalia_menor", "x": 340.0, "y": 260.0, "elite": true},
					{"id": "anomalia_menor", "x": 1200.0, "y": 300.0},
					{"id": "anomalia_menor", "x": 2060.0, "y": 260.0, "elite": true},
				],
			],
			"chefe": {
				"id": "colosso_de_cinza",
				"nome": "Colosso de Cinza",
				"vida": 1150.0,
				"velocidade": 120.0,
				"raio": 58.0,
				"dano": 24.0,
				"boss_style": "colosso",
				"fragmentos": 38,
			},
		},
		{
			"id": "santuario_partido",
			"nome": "Santuário Partido",
			"bg": Color("0a0d1c"),
			"floor": Color("141a30"),
			"accent": Color("7dd3fc"),
			"border": Color("3b4c78"),
			"motif": "santuario",
			"paleta": {
				"bg": Color("0a0d1c"),
				"floor": Color("141a30"),
				"accent": Color("7dd3fc"),
				"border": Color("3b4c78"),
				"motif": "santuario",
			},
			"ondas": [
				[
					{"id": "eco_perdido", "x": 480.0, "y": 240.0, "elite": true},
					{"id": "eco_perdido", "x": 1200.0, "y": 200.0, "elite": true},
					{"id": "eco_perdido", "x": 1920.0, "y": 240.0, "elite": true},
					{"id": "anomalia_menor", "x": 340.0, "y": 500.0, "elite": true},
					{"id": "anomalia_menor", "x": 900.0, "y": 240.0},
					{"id": "anomalia_menor", "x": 1500.0, "y": 240.0},
					{"id": "anomalia_menor", "x": 2060.0, "y": 500.0, "elite": true},
				],
				[
					{"id": "eco_perdido", "x": 420.0, "y": 320.0, "elite": true},
					{"id": "eco_perdido", "x": 860.0, "y": 210.0, "elite": true},
					{"id": "eco_perdido", "x": 1540.0, "y": 210.0, "elite": true},
					{"id": "eco_perdido", "x": 1980.0, "y": 320.0, "elite": true},
					{"id": "anomalia_menor", "x": 320.0, "y": 600.0, "elite": true},
					{"id": "anomalia_menor", "x": 1200.0, "y": 260.0, "elite": true},
					{"id": "anomalia_menor", "x": 2080.0, "y": 600.0, "elite": true},
				],
				[
					{"id": "eco_perdido", "x": 420.0, "y": 380.0, "elite": true},
					{"id": "eco_perdido", "x": 920.0, "y": 200.0, "elite": true},
					{"id": "eco_perdido", "x": 1480.0, "y": 200.0, "elite": true},
					{"id": "eco_perdido", "x": 1980.0, "y": 380.0, "elite": true},
					{"id": "anomalia_menor", "x": 320.0, "y": 240.0, "elite": true},
					{"id": "anomalia_menor", "x": 760.0, "y": 340.0},
					{"id": "anomalia_menor", "x": 1640.0, "y": 340.0},
					{"id": "anomalia_menor", "x": 2080.0, "y": 240.0, "elite": true},
				],
			],
			"chefe": {
				"id": "arconte_da_fenda",
				"nome": "Arconte da Fenda",
				"vida": 1400.0,
				"velocidade": 148.0,
				"raio": 52.0,
				"dano": 26.0,
				"boss_style": "arconte",
				"fragmentos": 48,
			},
		},
	]
	return lista


## Retorna o pool de 15 bênçãos jogáveis variadas cobrindo dano, mobilidade,
## sobrevivência, esquiva, cadência, alcance, vampirismo, empurrão, especial,
## escudo e crítico.
static func bencaos_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = [
		{
			"id": "fio_cortante",
			"nome": "Fio Cortante",
			"texto": "+18% de dano em todos os golpes.",
			"raridade": "comum",
			"efeito": "dano_pct",
			"valor": 0.18,
		},
		{
			"id": "furia_soberana",
			"nome": "Fúria Soberana",
			"texto": "+45% de dano em todos os golpes.",
			"raridade": "epica",
			"efeito": "dano_pct",
			"valor": 0.45,
		},
		{
			"id": "passos_leves",
			"nome": "Passos Leves",
			"texto": "+14% de velocidade de movimento.",
			"raridade": "comum",
			"efeito": "velocidade_pct",
			"valor": 0.14,
		},
		{
			"id": "vigor_renovado",
			"nome": "Vigor Renovado",
			"texto": "+25 Vida Máxima e recupera 30 de Vida.",
			"raridade": "comum",
			"efeito": "vida_max_cura",
			"valor": 25.0,
			"cura": 30.0,
		},
		{
			"id": "coracao_inabalavel",
			"nome": "Coração Inabalável",
			"texto": "+45 Vida Máxima e cura total.",
			"raridade": "epica",
			"efeito": "vida_max_cura",
			"valor": 45.0,
			"cura_total": true,
		},
		{
			"id": "passo_duplo",
			"nome": "Passo Duplo",
			"texto": "+1 carga de esquiva consecutiva.",
			"raridade": "rara",
			"efeito": "esquiva_carga",
			"valor": 1.0,
		},
		{
			"id": "reflexo_fugaz",
			"nome": "Reflexo Fugaz",
			"texto": "-25% no tempo de recarga da esquiva.",
			"raridade": "comum",
			"efeito": "esquiva_recarga",
			"valor": 0.25,
		},
		{
			"id": "cadencia_agil",
			"nome": "Cadência Ágil",
			"texto": "-18% na recarga dos ataques.",
			"raridade": "comum",
			"efeito": "ataque_rapido",
			"valor": 0.18,
		},
		{
			"id": "fluxo_cortante",
			"nome": "Fluxo Cortante",
			"texto": "-28% na recarga dos ataques.",
			"raridade": "rara",
			"efeito": "ataque_rapido",
			"valor": 0.28,
		},
		{
			"id": "arco_ampliado",
			"nome": "Arco Ampliado",
			"texto": "+22% de alcance e área dos golpes.",
			"raridade": "comum",
			"efeito": "alcance_pct",
			"valor": 0.22,
		},
		{
			"id": "sede_carmesim",
			"nome": "Sede Carmesim",
			"texto": "Recupera +6 de Vida ao abater inimigos.",
			"raridade": "rara",
			"efeito": "vampirismo",
			"valor": 6.0,
		},
		{
			"id": "impacto_brutal",
			"nome": "Impacto Brutal",
			"texto": "+35% de empurrão nos golpes.",
			"raridade": "comum",
			"efeito": "empurrao_pct",
			"valor": 0.35,
		},
		{
			"id": "eco_devastador",
			"nome": "Eco Devastador",
			"texto": "+35% de dano no ataque Especial.",
			"raridade": "rara",
			"efeito": "especial_dano",
			"valor": 0.35,
		},
		{
			"id": "egide_da_camara",
			"nome": "Égide da Câmara",
			"texto": "+25 de escudo temporário ao entrar em cada câmara.",
			"raridade": "rara",
			"efeito": "escudo_camara",
			"valor": 25.0,
		},
		{
			"id": "golpe_certeiro",
			"nome": "Golpe Certeiro",
			"texto": "+20% de chance de golpe crítico (1.8x de dano).",
			"raridade": "epica",
			"efeito": "critico_chance",
			"valor": 0.20,
			"multiplicador": 1.8,
		},
	]
	return pool


## Sorteia deterministicamente 3 bênçãos distintas do pool usando [RngAritmetica] e [FluxoRng].
## Exclui bênçãos cujo id esteja em [param ja_tomadas]; se restarem menos de 3 disponíveis,
## completa com itens restantes do pool mantendo as 3 cartas distintas entre si.
static func sortear_oferta(seed_valor: int, indice_oferta: int, ja_tomadas: Array[StringName]) -> Array[Dictionary]:
	var pool: Array[Dictionary] = bencaos_pool()
	var disponiveis: Array[Dictionary] = []
	var ids_disponiveis: Dictionary = {}

	for item: Dictionary in pool:
		var item_id: StringName = StringName(String(item["id"]))
		if not ja_tomadas.has(item_id):
			disponiveis.append(item)
			ids_disponiveis[item_id] = true

	if disponiveis.size() < TAMANHO_OFERTA:
		for item: Dictionary in pool:
			var item_id: StringName = StringName(String(item["id"]))
			if not ids_disponiveis.has(item_id):
				disponiveis.append(item)
				ids_disponiveis[item_id] = true
			if disponiveis.size() >= TAMANHO_OFERTA:
				break

	var profundidade: int = clampi(indice_oferta, 0, RngAritmetica.PROFUNDIDADE_MAXIMA)
	var estado_inicial: int = RngAritmetica.derivar(
		seed_valor,
		FINALIDADE_OFERTA_BENCAO,
		0,
		profundidade
	)
	if indice_oferta < 0 or indice_oferta > RngAritmetica.PROFUNDIDADE_MAXIMA:
		estado_inicial = RngAritmetica.mix(estado_inicial, RngAritmetica.mascarar_u32(indice_oferta))

	var fluxo: FluxoRng = FluxoRng.new(estado_inicial, null, null)
	var indices: Array[int] = fluxo.k_distintos(disponiveis.size(), TAMANHO_OFERTA)
	var oferta: Array[Dictionary] = []
	for idx: int in indices:
		var carta: Dictionary = disponiveis[idx]
		oferta.append(carta.duplicate(true))
	return oferta
