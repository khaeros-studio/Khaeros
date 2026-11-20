class_name MapaMasmorra
extends RefCounted
## Gerador determinístico de masmorras com grafo DAG ramificado de 5 camadas (índices 0..6)
## por região da campanha de Khaeros.
##
## Gera até 20 salas ao longo de 4 regiões (5 salas percorridas por região: entrada, ramo 1,
## ramo 2, convergência e câmara do chefe) usando exclusivamente [RngAritmetica] e [FluxoRng].
## Módulo puro sem dependências de cena ou RNG nativo da engine.

const FINALIDADE_MAPA: int = 8

const MARGEM_SEGURANCA_PX: float = 180.0
const PORTA_Y_PX: float = 78.0
const PORTA_X_UNICA_FRAC: float = 0.5
const PORTA_X_ESQ_FRAC: float = 0.34
const PORTA_X_DIR_FRAC: float = 0.66
const SPAWN_OFFSET_FUNDO_PX: float = 220.0

const MARGEM_PAREDE_X_PX: float = 200.0
const MARGEM_PAREDE_TOPO_PX: float = 270.0
const MARGEM_PAREDE_FUNDO_PX: float = 210.0
const FOLGA_ENTRE_OBJETOS_PX: float = 92.0
const RAIO_PROP_BASE_PX: float = 44.0
const RAIO_INTERATIVO_PX: float = 46.0
const CHEFE_SPAWN_Y_PX: float = 360.0
const RAIO_ZONA_CHEFE_PX: float = 210.0
const TENTATIVAS_POSICAO: int = 36
const TOTAL_SALAS_REGIAO: int = 7

const COR_PORTAL_REGIAO: Color = Color("e3b23c")
const PROPS_ARQUITETURA: Array[String] = ["estatua_guardiao", "coluna_correntes"]

const PALETAS_TAG: Dictionary = {
	"BÊNÇÃO": [Color("e3b23c"), Color("f0c451"), Color("d9a22b")],
	"RELÍQUIA": [Color("c084fc"), Color("a855f7"), Color("d8b4fe")],
	"CURA": [Color("34d399"), Color("4ade80"), Color("2dd4bf")],
	"PACTO": [Color("e0259c"), Color("f43f5e"), Color("ec4899")],
	"ELITE": [Color("fb923c"), Color("f97316"), Color("fdba74")],
	"CHEFE": [Color("ef4444"), Color("dc2626"), Color("f87171")],
}

const MODELOS_SALAS: Array[Dictionary] = [
	{
		"indice": 0,
		"camada": 0,
		"ramo": 0,
		"tipo": "combate",
		"nome": "Átrio da Fenda",
		"largura": 2800.0,
		"altura": 1560.0,
		"recompensa_tag": "BÊNÇÃO",
		"proximas": [1, 2],
		"pilares_min": 2,
		"pilares_var": 3,
		"props_min": 4,
		"props_var": 2,
		"pacifica": false,
	},
	{
		"indice": 1,
		"camada": 1,
		"ramo": 0,
		"tipo": "emboscada",
		"nome": "Corredor de Emboscada",
		"largura": 2900.0,
		"altura": 1520.0,
		"recompensa_tag": "RELÍQUIA",
		"proximas": [3, 4],
		"pilares_min": 3,
		"pilares_var": 3,
		"props_min": 4,
		"props_var": 2,
		"pacifica": false,
	},
	{
		"indice": 2,
		"camada": 1,
		"ramo": 1,
		"tipo": "santuario_cura",
		"nome": "Santuário de Fluxo",
		"largura": 2600.0,
		"altura": 1440.0,
		"recompensa_tag": "CURA",
		"proximas": [3, 4],
		"pilares_min": 2,
		"pilares_var": 1,
		"props_min": 4,
		"props_var": 2,
		"pacifica": true,
	},
	{
		"indice": 3,
		"camada": 2,
		"ramo": 0,
		"tipo": "combate_denso",
		"nome": "Salão dos Ecos",
		"largura": 2900.0,
		"altura": 1560.0,
		"recompensa_tag": "RELÍQUIA",
		"proximas": [5],
		"pilares_min": 3,
		"pilares_var": 3,
		"props_min": 4,
		"props_var": 2,
		"pacifica": false,
	},
	{
		"indice": 4,
		"camada": 2,
		"ramo": 1,
		"tipo": "altar_pacto",
		"nome": "Altar do Pacto Sombrio",
		"largura": 2640.0,
		"altura": 1460.0,
		"recompensa_tag": "PACTO",
		"proximas": [5],
		"pilares_min": 2,
		"pilares_var": 1,
		"props_min": 4,
		"props_var": 2,
		"pacifica": true,
	},
	{
		"indice": 5,
		"camada": 3,
		"ramo": 0,
		"tipo": "elite_guarda",
		"nome": "Guarda da Fenda",
		"largura": 2860.0,
		"altura": 1560.0,
		"recompensa_tag": "ELITE",
		"proximas": [6],
		"pilares_min": 3,
		"pilares_var": 2,
		"props_min": 4,
		"props_var": 2,
		"pacifica": false,
	},
	{
		"indice": 6,
		"camada": 4,
		"ramo": 0,
		"tipo": "chefe",
		"nome": "Câmara do Chefe",
		"largura": 3000.0,
		"altura": 1620.0,
		"recompensa_tag": "CHEFE",
		"proximas": [],
		"pilares_min": 4,
		"pilares_var": 1,
		"props_min": 6,
		"props_var": 2,
		"pacifica": false,
	},
]

var _reg_id: String = ""
var _reg_index: int = 0
var _seed_val: int = 0
var _indice_atual: int = 0
var _salas: Array[Dictionary] = []


## Retorna a posição canônica de spawn do jogador para uma sala de dimensões [param largura] x [param altura].
static func ponto_spawn(largura: float, altura: float) -> Vector2:
	return Vector2(largura * 0.5, altura - SPAWN_OFFSET_FUNDO_PX)


## Retorna as posições das portas norte para [param qtd_portas] saídas (1 ou 2).
static func posicoes_portas_norte(largura: float, qtd_portas: int) -> Array[Vector2]:
	var posicoes: Array[Vector2] = []
	if qtd_portas >= 2:
		posicoes.append(Vector2(largura * PORTA_X_ESQ_FRAC, PORTA_Y_PX))
		posicoes.append(Vector2(largura * PORTA_X_DIR_FRAC, PORTA_Y_PX))
	else:
		posicoes.append(Vector2(largura * PORTA_X_UNICA_FRAC, PORTA_Y_PX))
	return posicoes


## Gera o grafo determinístico de 5 camadas (índices 0..6) para a região informada usando [RngAritmetica].
func gerar_regiao(reg_id: String, reg_index: int, seed_val: int) -> void:
	_reg_id = reg_id
	_reg_index = reg_index
	_seed_val = seed_val
	_indice_atual = 0
	_salas.clear()

	var fluxo_regiao: FluxoRng = _criar_fluxo(reg_id, reg_index, seed_val, 0)
	var ecos_ordenados: Array[String] = _sortear_ecos_regiao(reg_id, fluxo_regiao)

	for idx: int in range(MODELOS_SALAS.size()):
		var modelo: Dictionary = MODELOS_SALAS[idx]
		var fluxo_sala: FluxoRng = _criar_fluxo(reg_id, reg_index, seed_val, idx + 1)
		var sala: Dictionary = _construir_sala(idx, modelo, reg_id, ecos_ordenados, fluxo_sala)
		_salas.append(sala)


## Retorna uma cópia profunda da sala atual, ou {} se nenhuma região tiver sido gerada.
func sala_atual() -> Dictionary:
	if _salas.is_empty() or _indice_atual < 0 or _indice_atual >= _salas.size():
		return {}
	return _duplicar_sala(_salas[_indice_atual])


## Retorna 1 ou 2 portas de saída da sala atual, ou o portal regional na câmara do chefe limpa (regiões 0..2).
func portas_da_sala_atual() -> Array[Dictionary]:
	var portas: Array[Dictionary] = []
	if _salas.is_empty() or _indice_atual < 0 or _indice_atual >= _salas.size():
		return portas

	var atual: Dictionary = _salas[_indice_atual]
	var largura: float = float(atual["largura"])
	var proximas_arr: Array = atual["proximas"] as Array

	if proximas_arr.is_empty():
		var limpa: bool = bool(atual["limpa"])
		if _reg_index >= 0 and _reg_index < 3 and limpa:
			portas.append({
				"pos": Vector2(largura * PORTA_X_UNICA_FRAC, PORTA_Y_PX),
				"destino_idx": -1,
				"nome": "PRÓXIMA REGIÃO",
				"recompensa_tag": "REGIÃO",
				"cor": COR_PORTAL_REGIAO,
				"is_region_portal": true,
			})
		return portas

	var posicoes: Array[Vector2] = posicoes_portas_norte(largura, proximas_arr.size())
	var limite: int = mini(proximas_arr.size(), posicoes.size())
	for i: int in range(limite):
		var destino_idx: int = int(proximas_arr[i])
		if destino_idx < 0 or destino_idx >= _salas.size():
			continue
		var destino: Dictionary = _salas[destino_idx]
		var destino_cor: Color = destino["cor_tag"] as Color
		portas.append({
			"pos": posicoes[i],
			"destino_idx": destino_idx,
			"nome": String(destino["nome"]),
			"recompensa_tag": String(destino["recompensa_tag"]),
			"cor": destino_cor,
			"is_region_portal": false,
		})
	return portas


## Avança para [param destino_idx] se for uma saída válida da sala atual, marcando-a como visitada.
## Em destino inválido, mantém [member _indice_atual] inalterado e retorna {}.
func avancar_para(destino_idx: int) -> Dictionary:
	if _salas.is_empty() or _indice_atual < 0 or _indice_atual >= _salas.size():
		push_warning("MapaMasmorra: nenhuma região gerada antes de avancar_para(%d)." % destino_idx)
		return {}

	var atual: Dictionary = _salas[_indice_atual]
	if destino_idx < 0 or destino_idx >= _salas.size() or not _proximas_contem(atual, destino_idx):
		push_warning("MapaMasmorra: destino inválido %d a partir da sala %d." % [destino_idx, _indice_atual])
		return {}

	_indice_atual = destino_idx
	_salas[_indice_atual]["visitada"] = true
	return sala_atual()


## Marca a sala atual como limpa de forma idempotente.
func marcar_limpa() -> void:
	if _salas.is_empty() or _indice_atual < 0 or _indice_atual >= _salas.size():
		return
	_salas[_indice_atual]["limpa"] = true


## Retorna um retrato seguro (cópias profundas) de todas as salas da região para renderização no HUD.
func resumo_minimapa() -> Dictionary:
	var copia_salas: Array[Dictionary] = []
	for sala: Dictionary in _salas:
		copia_salas.append(_duplicar_sala(sala))

	var camada_atual: int = 0
	if _indice_atual >= 0 and _indice_atual < _salas.size():
		camada_atual = int(_salas[_indice_atual]["camada"])

	return {
		"reg_id": _reg_id,
		"reg_index": _reg_index,
		"indice_atual": _indice_atual,
		"camada_atual": camada_atual,
		"salas": copia_salas,
	}


static func _criar_fluxo(reg_id: String, reg_index: int, seed_val: int, profundidade: int) -> FluxoRng:
	var reg_clamped: int = clampi(reg_index, 0, RngAritmetica.REGIAO_MAXIMA)
	var prof_clamped: int = clampi(profundidade, 0, RngAritmetica.PROFUNDIDADE_MAXIMA)
	var estado: int = RngAritmetica.derivar(seed_val, FINALIDADE_MAPA, reg_clamped, prof_clamped)
	if reg_index != reg_clamped:
		estado = RngAritmetica.mix(estado, RngAritmetica.mascarar_u32(reg_index))
	if profundidade != prof_clamped:
		estado = RngAritmetica.mix(estado, RngAritmetica.mascarar_u32(profundidade))
	estado = RngAritmetica.mix(estado, _hash_reg_id(reg_id))
	return FluxoRng.new(estado, null, null)


static func _hash_reg_id(reg_id: String) -> int:
	var h: int = 0x517CC1B7
	var bytes: PackedByteArray = reg_id.to_utf8_buffer()
	for b: int in bytes:
		h = RngAritmetica.mix(h, b)
	return h


func _sortear_ecos_regiao(reg_id: String, fluxo_regiao: FluxoRng) -> Array[String]:
	var ecos_raw: Array[Dictionary] = CodexHistoria.ecos_por_regiao(reg_id)
	var ids: Array[String] = []
	for eco: Dictionary in ecos_raw:
		var eco_id: String = String(eco.get("id", ""))
		if not eco_id.is_empty():
			ids.append(eco_id)

	var prefixo: String = reg_id if not reg_id.is_empty() else "regiao"
	var idx_fb: int = 1
	while ids.size() < 3:
		var fallback_id: String = "eco_%s_%02d" % [prefixo, idx_fb]
		if not ids.has(fallback_id):
			ids.append(fallback_id)
		idx_fb += 1

	if ids.size() > 3:
		ids = ids.slice(0, 3)

	var embaralhado: Array = fluxo_regiao.embaralhar_copia(ids)
	var resultado: Array[String] = []
	for item_var: Variant in embaralhado:
		resultado.append(String(item_var))
	return resultado


func _construir_sala(idx: int, modelo: Dictionary, reg_id: String, ecos_ordenados: Array[String], fluxo: FluxoRng) -> Dictionary:
	var camada: int = int(modelo["camada"])
	var ramo: int = int(modelo["ramo"])
	var tipo: String = String(modelo["tipo"])
	var nome: String = String(modelo["nome"])
	var largura: float = float(modelo["largura"])
	var altura: float = float(modelo["altura"])
	var recompensa_tag: String = String(modelo["recompensa_tag"])
	var pacifica: bool = bool(modelo["pacifica"])

	var proximas_src: Array = modelo["proximas"] as Array
	var proximas: Array[int] = []
	for p_var: Variant in proximas_src:
		proximas.append(int(p_var))

	var cor_tag: Color = _sortear_cor_tag(recompensa_tag, fluxo)
	var spawn_pos: Vector2 = ponto_spawn(largura, altura)
	var qtd_portas_protegidas: int = maxi(1, proximas.size())
	var portas_pos: Array[Vector2] = posicoes_portas_norte(largura, qtd_portas_protegidas)

	var zonas_proibidas: Array[Dictionary] = [{"pos": spawn_pos, "raio_extra": 0.0}]
	for p_porta: Vector2 in portas_pos:
		zonas_proibidas.append({"pos": p_porta, "raio_extra": 0.0})
	if idx == 6:
		zonas_proibidas.append({
			"pos": Vector2(largura * 0.5, CHEFE_SPAWN_Y_PX),
			"raio_extra": RAIO_ZONA_CHEFE_PX - MARGEM_SEGURANCA_PX,
		})

	var ocupados: Array[Dictionary] = []
	var interativos: Array[Dictionary] = _gerar_interativos_sala(
		idx, reg_id, largura, altura, ecos_ordenados, fluxo, zonas_proibidas, ocupados
	)
	var pilares: Array[Dictionary] = _gerar_pilares_sala(
		idx, modelo, largura, altura, fluxo, zonas_proibidas, ocupados
	)
	var props: Array[Dictionary] = _gerar_props_sala(
		idx, modelo, largura, altura, fluxo, zonas_proibidas, ocupados
	)

	var id_prefixo: String = reg_id if not reg_id.is_empty() else "regiao"
	var id_sala: String = "%s_c%d_r%d_s%d" % [id_prefixo, camada, ramo, idx]

	return {
		"id": id_sala,
		"reg_id": reg_id,
		"camada": camada,
		"ramo": ramo,
		"tipo": tipo,
		"nome": nome,
		"recompensa_tag": recompensa_tag,
		"cor_tag": cor_tag,
		"largura": largura,
		"altura": altura,
		"pilares": pilares,
		"props": props,
		"interativos": interativos,
		"proximas": proximas,
		"visitada": idx == 0,
		"limpa": pacifica,
	}


func _sortear_cor_tag(recompensa_tag: String, fluxo: FluxoRng) -> Color:
	var paleta_raw: Variant = PALETAS_TAG.get(recompensa_tag, [Color("e3b23c")])
	if paleta_raw is Array:
		var paleta: Array = paleta_raw as Array
		if not paleta.is_empty():
			var idx_cor: int = fluxo.inteiro(paleta.size())
			var cor_base: Color = paleta[idx_cor] as Color
			var fator: float = fluxo.real_entre(-0.04, 0.04)
			if fator >= 0.0:
				return cor_base.lightened(fator)
			return cor_base.darkened(-fator)
	return Color("e3b23c")


func _gerar_interativos_sala(
	idx: int,
	reg_id: String,
	largura: float,
	altura: float,
	ecos_ordenados: Array[String],
	fluxo: FluxoRng,
	zonas_proibidas: Array[Dictionary],
	ocupados: Array[Dictionary]
) -> Array[Dictionary]:
	var interativos: Array[Dictionary] = []
	var lado_esq: bool = fluxo.inteiro(2) == 0
	var x_ala_a: float = largura * (0.24 if lado_esq else 0.76)
	var x_ala_b: float = largura * (0.76 if lado_esq else 0.24)
	var id_reg: String = reg_id if not reg_id.is_empty() else "regiao"

	match idx:
		0:
			var ancora0: Vector2 = Vector2(x_ala_a, altura * 0.46)
			var pos0: Vector2 = _posicionar_com_fallback(
				ancora0, 110.0, 95.0, RAIO_INTERATIVO_PX, largura, altura, fluxo, zonas_proibidas, ocupados
			)
			interativos.append(_criar_interativo(id_reg, idx, 0, "monolito_lore", pos0, ecos_ordenados[0]))
		1:
			var ancora1: Vector2 = Vector2(x_ala_a, altura * 0.40)
			var pos1: Vector2 = _posicionar_com_fallback(
				ancora1, 130.0, 110.0, RAIO_INTERATIVO_PX, largura, altura, fluxo, zonas_proibidas, ocupados
			)
			interativos.append(_criar_interativo(id_reg, idx, 0, "bau_reliquia", pos1, ""))
		2:
			var ancora_fonte2: Vector2 = Vector2(largura * 0.5, altura * 0.50)
			var pos_fonte2: Vector2 = _posicionar_com_fallback(
				ancora_fonte2, 85.0, 70.0, RAIO_INTERATIVO_PX, largura, altura, fluxo, zonas_proibidas, ocupados
			)
			interativos.append(_criar_interativo(id_reg, idx, 0, "fonte_cura", pos_fonte2, ""))

			var ancora_eco2: Vector2 = Vector2(x_ala_b, altura * 0.46)
			var pos_eco2: Vector2 = _posicionar_com_fallback(
				ancora_eco2, 100.0, 90.0, RAIO_INTERATIVO_PX, largura, altura, fluxo, zonas_proibidas, ocupados
			)
			interativos.append(_criar_interativo(id_reg, idx, 1, "monolito_lore", pos_eco2, ecos_ordenados[1]))
		3:
			var ancora3: Vector2 = Vector2(x_ala_b, altura * 0.40)
			var pos3: Vector2 = _posicionar_com_fallback(
				ancora3, 130.0, 110.0, RAIO_INTERATIVO_PX, largura, altura, fluxo, zonas_proibidas, ocupados
			)
			interativos.append(_criar_interativo(id_reg, idx, 0, "bau_reliquia", pos3, ""))
		4:
			var ancora_altar4: Vector2 = Vector2(largura * 0.5, altura * 0.48)
			var pos_altar4: Vector2 = _posicionar_com_fallback(
				ancora_altar4, 80.0, 65.0, RAIO_INTERATIVO_PX, largura, altura, fluxo, zonas_proibidas, ocupados
			)
			interativos.append(_criar_interativo(id_reg, idx, 0, "altar_pacto", pos_altar4, ""))

			var ancora_eco4: Vector2 = Vector2(x_ala_a, altura * 0.46)
			var pos_eco4: Vector2 = _posicionar_com_fallback(
				ancora_eco4, 100.0, 90.0, RAIO_INTERATIVO_PX, largura, altura, fluxo, zonas_proibidas, ocupados
			)
			interativos.append(_criar_interativo(id_reg, idx, 1, "monolito_lore", pos_eco4, ecos_ordenados[2]))
		5:
			var ancora5: Vector2 = Vector2(x_ala_a, altura * 0.52)
			var pos5: Vector2 = _posicionar_com_fallback(
				ancora5, 110.0, 95.0, RAIO_INTERATIVO_PX, largura, altura, fluxo, zonas_proibidas, ocupados
			)
			interativos.append(_criar_interativo(id_reg, idx, 0, "fonte_cura", pos5, ""))
		_:
			pass

	return interativos


static func _criar_interativo(
	id_reg: String,
	sala_idx: int,
	ordem: int,
	kind: String,
	pos: Vector2,
	eco_id: String
) -> Dictionary:
	return {
		"id": "%s_s%d_%s_%d" % [id_reg, sala_idx, kind, ordem],
		"kind": kind,
		"pos": pos,
		"usado": false,
		"eco_id": eco_id,
	}


func _gerar_pilares_sala(
	idx: int,
	modelo: Dictionary,
	largura: float,
	altura: float,
	fluxo: FluxoRng,
	zonas_proibidas: Array[Dictionary],
	ocupados: Array[Dictionary]
) -> Array[Dictionary]:
	var pilares: Array[Dictionary] = []
	var pilares_min: int = int(modelo["pilares_min"])
	var pilares_var: int = maxi(1, int(modelo["pilares_var"]))
	var alvo: int = pilares_min + fluxo.inteiro(pilares_var)

	var ancoras: Array[Vector2] = []
	if idx == 6:
		ancoras = [
			Vector2(largura * 0.25, altura * 0.36),
			Vector2(largura * 0.75, altura * 0.36),
			Vector2(largura * 0.25, altura * 0.68),
			Vector2(largura * 0.75, altura * 0.68),
		]
		for ancora: Vector2 in ancoras:
			var r_chefe: float = fluxo.real_entre(42.0, 50.0)
			var pos_chefe: Vector2 = _tentar_perto_ancora(
				ancora, 60.0, 50.0, r_chefe, largura, altura, fluxo, zonas_proibidas, ocupados
			)
			if pos_chefe != Vector2.INF:
				ocupados.append({"pos": pos_chefe, "r": r_chefe})
				pilares.append({"x": pos_chefe.x, "y": pos_chefe.y, "r": r_chefe})
		return pilares

	if idx == 2 or idx == 4:
		ancoras = [
			Vector2(largura * 0.22, altura * 0.62),
			Vector2(largura * 0.78, altura * 0.62),
		]
		for ancora_p: Vector2 in ancoras:
			var r_pac: float = fluxo.real_entre(38.0, 44.0)
			var pos_pac: Vector2 = _tentar_perto_ancora(
				ancora_p, 65.0, 55.0, r_pac, largura, altura, fluxo, zonas_proibidas, ocupados
			)
			if pos_pac != Vector2.INF:
				ocupados.append({"pos": pos_pac, "r": r_pac})
				pilares.append({"x": pos_pac.x, "y": pos_pac.y, "r": r_pac})
		return pilares

	var ancs_combate: Array[Vector2] = [
		Vector2(largura * 0.28, altura * 0.42),
		Vector2(largura * 0.72, altura * 0.42),
		Vector2(largura * 0.28, altura * 0.68),
		Vector2(largura * 0.72, altura * 0.68),
		Vector2(largura * 0.50, altura * 0.46),
	]
	var ancs_embaralhadas: Array = fluxo.embaralhar_copia(ancs_combate)
	for i: int in range(alvo):
		var r_pilar: float = fluxo.real_entre(40.0, 48.0)
		var pos_p: Vector2 = Vector2.INF
		if i < ancs_embaralhadas.size():
			var base_vec: Vector2 = ancs_embaralhadas[i] as Vector2
			pos_p = _tentar_perto_ancora(
				base_vec, 140.0, 95.0, r_pilar, largura, altura, fluxo, zonas_proibidas, ocupados
			)
		if pos_p == Vector2.INF:
			pos_p = _tentar_aleatorio_seguro(r_pilar, largura, altura, fluxo, zonas_proibidas, ocupados)
		if pos_p != Vector2.INF:
			ocupados.append({"pos": pos_p, "r": r_pilar})
			pilares.append({"x": pos_p.x, "y": pos_p.y, "r": r_pilar})
	return pilares


func _gerar_props_sala(
	idx: int,
	modelo: Dictionary,
	largura: float,
	altura: float,
	fluxo: FluxoRng,
	zonas_proibidas: Array[Dictionary],
	ocupados: Array[Dictionary]
) -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	var props_min: int = int(modelo["props_min"])
	var props_var: int = maxi(1, int(modelo["props_var"]))
	var alvo: int = props_min + fluxo.inteiro(props_var)

	var idx_tipo: int = fluxo.inteiro(PROPS_ARQUITETURA.size())
	var tipo_a: String = PROPS_ARQUITETURA[idx_tipo]
	var tipo_b: String = PROPS_ARQUITETURA[(idx_tipo + 1) % PROPS_ARQUITETURA.size()]

	if idx == 6:
		# Câmara do Chefe: props majestosos simétricos nas laterais esquerda e direita.
		var laterais: Array[Dictionary] = [
			{"ancora": Vector2(260.0, 390.0), "flip": false},
			{"ancora": Vector2(largura - 260.0, 390.0), "flip": true},
			{"ancora": Vector2(240.0, altura * 0.52), "flip": false},
			{"ancora": Vector2(largura - 240.0, altura * 0.52), "flip": true},
			{"ancora": Vector2(270.0, altura - 340.0), "flip": false},
			{"ancora": Vector2(largura - 270.0, altura - 340.0), "flip": true},
			{"ancora": Vector2(440.0, 310.0), "flip": false},
			{"ancora": Vector2(largura - 440.0, 310.0), "flip": true},
		]
		var pares_chefe: int = 3 + fluxo.inteiro(2)
		var total_chefe: int = mini(pares_chefe * 2, laterais.size())
		for i: int in range(total_chefe):
			var entrada: Dictionary = laterais[i]
			var ancora_lat: Vector2 = entrada["ancora"] as Vector2
			var flip_lat: bool = bool(entrada["flip"])
			var esc_chefe: float = fluxo.real_entre(1.22, 1.44)
			var r_chefe: float = RAIO_PROP_BASE_PX * esc_chefe
			var pos_lat: Vector2 = _tentar_perto_ancora(
				ancora_lat, 45.0, 45.0, r_chefe, largura, altura, fluxo, zonas_proibidas, ocupados
			)
			if pos_lat != Vector2.INF:
				var kind_chefe: String = tipo_a if (i % 2 == 0) else tipo_b
				ocupados.append({"pos": pos_lat, "r": r_chefe})
				props.append({
					"kind": kind_chefe,
					"pos": pos_lat,
					"scale": esc_chefe,
					"flip": flip_lat,
				})
		return props

	var ancoras_flanco: Array[Dictionary] = [
		{"ancora": Vector2(260.0, 340.0), "flip": false},
		{"ancora": Vector2(largura - 260.0, 340.0), "flip": true},
		{"ancora": Vector2(250.0, altura * 0.56), "flip": false},
		{"ancora": Vector2(largura - 250.0, altura * 0.56), "flip": true},
		{"ancora": Vector2(280.0, altura - 280.0), "flip": false},
		{"ancora": Vector2(largura - 280.0, altura - 280.0), "flip": true},
	]
	var flancos_ordem: Array = fluxo.embaralhar_copia(ancoras_flanco)
	for i: int in range(mini(alvo, flancos_ordem.size())):
		var item: Dictionary = flancos_ordem[i] as Dictionary
		var ancora_p: Vector2 = item["ancora"] as Vector2
		var flip_p: bool = bool(item["flip"])
		var esc: float = fluxo.real_entre(0.92, 1.18)
		var r_prop: float = RAIO_PROP_BASE_PX * esc
		var pos_p: Vector2 = _tentar_perto_ancora(
			ancora_p, 75.0, 75.0, r_prop, largura, altura, fluxo, zonas_proibidas, ocupados
		)
		if pos_p == Vector2.INF:
			pos_p = _tentar_aleatorio_seguro(r_prop, largura, altura, fluxo, zonas_proibidas, ocupados)
		if pos_p != Vector2.INF:
			var kind_prop: String = tipo_a if (i % 2 == 0) else tipo_b
			ocupados.append({"pos": pos_p, "r": r_prop})
			props.append({
				"kind": kind_prop,
				"pos": pos_p,
				"scale": esc,
				"flip": flip_p,
			})
	return props


func _posicionar_com_fallback(
	ancora: Vector2,
	jitter_x: float,
	jitter_y: float,
	r_obj: float,
	largura: float,
	altura: float,
	fluxo: FluxoRng,
	zonas_proibidas: Array[Dictionary],
	ocupados: Array[Dictionary]
) -> Vector2:
	var pos: Vector2 = _tentar_perto_ancora(
		ancora, jitter_x, jitter_y, r_obj, largura, altura, fluxo, zonas_proibidas, ocupados
	)
	if pos != Vector2.INF:
		ocupados.append({"pos": pos, "r": r_obj})
		return pos

	pos = _tentar_aleatorio_seguro(r_obj, largura, altura, fluxo, zonas_proibidas, ocupados)
	if pos != Vector2.INF:
		ocupados.append({"pos": pos, "r": r_obj})
		return pos

	var fallback_grid: Array[Vector2] = [
		Vector2(largura * 0.25, altura * 0.46),
		Vector2(largura * 0.75, altura * 0.46),
		Vector2(largura * 0.35, altura * 0.56),
		Vector2(largura * 0.65, altura * 0.56),
		Vector2(largura * 0.50, altura * 0.48),
		Vector2(largura * 0.20, altura * 0.36),
		Vector2(largura * 0.80, altura * 0.36),
		Vector2(largura * 0.22, altura * 0.70),
		Vector2(largura * 0.78, altura * 0.70),
		Vector2(largura * 0.42, altura * 0.42),
		Vector2(largura * 0.58, altura * 0.42),
	]
	for candidato: Vector2 in fallback_grid:
		if _posicao_segura(candidato, r_obj, largura, altura, zonas_proibidas, ocupados):
			ocupados.append({"pos": candidato, "r": r_obj})
			return candidato

	var pos_emergencia: Vector2 = Vector2(largura * 0.25, altura * 0.5)
	ocupados.append({"pos": pos_emergencia, "r": r_obj})
	return pos_emergencia


func _tentar_perto_ancora(
	ancora: Vector2,
	jitter_x: float,
	jitter_y: float,
	r_obj: float,
	largura: float,
	altura: float,
	fluxo: FluxoRng,
	zonas_proibidas: Array[Dictionary],
	ocupados: Array[Dictionary]
) -> Vector2:
	for _t: int in range(TENTATIVAS_POSICAO):
		var dx: float = fluxo.real_entre(-jitter_x, jitter_x)
		var dy: float = fluxo.real_entre(-jitter_y, jitter_y)
		var candidato: Vector2 = Vector2(
			clampf(ancora.x + dx, MARGEM_PAREDE_X_PX, largura - MARGEM_PAREDE_X_PX),
			clampf(ancora.y + dy, MARGEM_PAREDE_TOPO_PX, altura - MARGEM_PAREDE_FUNDO_PX)
		)
		if _posicao_segura(candidato, r_obj, largura, altura, zonas_proibidas, ocupados):
			return candidato
	if _posicao_segura(ancora, r_obj, largura, altura, zonas_proibidas, ocupados):
		return ancora
	return Vector2.INF


func _tentar_aleatorio_seguro(
	r_obj: float,
	largura: float,
	altura: float,
	fluxo: FluxoRng,
	zonas_proibidas: Array[Dictionary],
	ocupados: Array[Dictionary]
) -> Vector2:
	var x_min: float = MARGEM_PAREDE_X_PX
	var x_max: float = maxf(x_min + 1.0, largura - MARGEM_PAREDE_X_PX)
	var y_min: float = MARGEM_PAREDE_TOPO_PX
	var y_max: float = maxf(y_min + 1.0, altura - MARGEM_PAREDE_FUNDO_PX)
	for _t: int in range(TENTATIVAS_POSICAO):
		var candidato: Vector2 = Vector2(
			fluxo.real_entre(x_min, x_max),
			fluxo.real_entre(y_min, y_max)
		)
		if _posicao_segura(candidato, r_obj, largura, altura, zonas_proibidas, ocupados):
			return candidato
	return Vector2.INF


static func _posicao_segura(
	pos: Vector2,
	r_obj: float,
	largura: float,
	altura: float,
	zonas_proibidas: Array[Dictionary],
	ocupados: Array[Dictionary]
) -> bool:
	if pos.x < MARGEM_PAREDE_X_PX or pos.x > largura - MARGEM_PAREDE_X_PX:
		return false
	if pos.y < MARGEM_PAREDE_TOPO_PX or pos.y > altura - MARGEM_PAREDE_FUNDO_PX:
		return false

	for zona: Dictionary in zonas_proibidas:
		var z_pos: Vector2 = zona["pos"] as Vector2
		var z_extra: float = float(zona["raio_extra"])
		if pos.distance_to(z_pos) < MARGEM_SEGURANCA_PX + r_obj + z_extra:
			return false

	for oc: Dictionary in ocupados:
		var oc_pos: Vector2 = oc["pos"] as Vector2
		var oc_r: float = float(oc["r"])
		if pos.distance_to(oc_pos) < r_obj + oc_r + FOLGA_ENTRE_OBJETOS_PX:
			return false

	return true


static func _proximas_contem(sala: Dictionary, destino_idx: int) -> bool:
	var proximas: Array = sala["proximas"] as Array
	for p_var: Variant in proximas:
		if int(p_var) == destino_idx:
			return true
	return false


static func _duplicar_sala(sala: Dictionary) -> Dictionary:
	var pilares_copia: Array[Dictionary] = []
	var pilares_src: Array = sala["pilares"] as Array
	for p_var: Variant in pilares_src:
		var p: Dictionary = p_var as Dictionary
		pilares_copia.append(p.duplicate(true))

	var props_copia: Array[Dictionary] = []
	var props_src: Array = sala["props"] as Array
	for pr_var: Variant in props_src:
		var pr: Dictionary = pr_var as Dictionary
		props_copia.append(pr.duplicate(true))

	var interativos_copia: Array[Dictionary] = []
	var interativos_src: Array = sala["interativos"] as Array
	for it_var: Variant in interativos_src:
		var it: Dictionary = it_var as Dictionary
		interativos_copia.append(it.duplicate(true))

	var proximas_copia: Array[int] = []
	var proximas_src: Array = sala["proximas"] as Array
	for px_var: Variant in proximas_src:
		proximas_copia.append(int(px_var))

	return {
		"id": String(sala["id"]),
		"reg_id": String(sala["reg_id"]),
		"camada": int(sala["camada"]),
		"ramo": int(sala["ramo"]),
		"tipo": String(sala["tipo"]),
		"nome": String(sala["nome"]),
		"recompensa_tag": String(sala["recompensa_tag"]),
		"cor_tag": sala["cor_tag"] as Color,
		"largura": float(sala["largura"]),
		"altura": float(sala["altura"]),
		"pilares": pilares_copia,
		"props": props_copia,
		"interativos": interativos_copia,
		"proximas": proximas_copia,
		"visitada": bool(sala["visitada"]),
		"limpa": bool(sala["limpa"]),
	}
