class_name LayoutDaCamara
extends RefCounted
## Geração determinística de obstáculos circulares e geometria da câmara
## (GDD camaras-e-ondas.md R2, R5, R12, R14-P, F4; ADR-0005, ADR-0008).
##
## Regras:
## - Câmara de combate: sorteia [code]n = obstaculos_min + fluxo.inteiro(obstaculos_var)[/code] (2 a 4).
##   Para cada uma das [code]n[/code] pedras tentadas, consome **sempre** [code]obstaculo_tentativas[/code] (10)
##   candidatos do fluxo [code]layout[/code] (3 números por candidato: raio, x, y → 30 números por pedra).
##   Aceita o 1º candidato que respeita [code]|c − c_j| >= r + r_j + folga_obstaculo_px[/code] contra todas
##   as pedras já aceitas; se nenhum servir, omite a pedra.
## - Santuário: layout fixo, 1 pedra de raio 63 px em (960; 495), 0 números consumidos.
## - Chefe: layout fixo, 4 pedras de raio 51 px em (390; 300), (1530; 300), (390; 750), (1530; 750),
##   0 números consumidos.

const X_MIN_PADRAO: float = 270.0
const X_MAX_PADRAO: float = 1650.0
const Y_MIN_PADRAO: float = 255.0
const Y_MAX_PADRAO: float = 765.0
const PASSO_RAIO_PX: float = 1.5

const PEDRA_SANTUARIO_CENTRO: Vector2 = Vector2(960.0, 495.0)
const PEDRA_SANTUARIO_RAIO: float = 63.0

const PEDRAS_CHEFE_CENTROS: Array[Vector2] = [
	Vector2(390.0, 300.0),
	Vector2(1530.0, 300.0),
	Vector2(390.0, 750.0),
	Vector2(1530.0, 750.0),
]
const PEDRA_CHEFE_RAIO: float = 51.0


## Retângulo jogável da câmara inteira com origem em (0, 0) (R2, AC-CO-03).
static func retangulo_jogavel(tuning: RoomTuning) -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(tuning.camara_largura_px, tuning.camara_altura_px))


## Ponto de entrada do jogador na câmara (R4: (960, 930) no MVP).
static func ponto_de_entrada(tuning: RoomTuning) -> Vector2:
	if tuning.entrada_px.size() >= 2:
		return Vector2(tuning.entrada_px[0], tuning.entrada_px[1])
	return Vector2(960.0, 930.0)


## Ponto de entrada da Maldição em campo atrás do jogador (R4-P 1b, F6, AC-CO-35).
static func ponto_entrada_maldicao(tuning: RoomTuning, distancia_seguir_px: float, raio_especie: float) -> Vector2:
	var entrada: Vector2 = ponto_de_entrada(tuning)
	var y: float = minf(entrada.y + distancia_seguir_px, tuning.camara_altura_px - raio_especie)
	return Vector2(entrada.x, y)


## Gera a lista de obstáculos de uma câmara pelo seu [param tipo_camara].
## Só câmaras de [code]combate[/code] consomem [param fluxo_layout].
static func gerar_obstaculos(tipo_camara: StringName, tuning: RoomTuning, fluxo_layout: FluxoRng) -> Array[ObstaculoCircular]:
	match tipo_camara:
		ProfundidadeCamara.TIPO_SANTUARIO:
			return obstaculos_santuario()
		ProfundidadeCamara.TIPO_CHEFE:
			return obstaculos_chefe()
		_:
			return sortear_obstaculos_combate(tuning, fluxo_layout)


## Layout fixo do Santuário Esquecido (R12, AC-CO-17).
static func obstaculos_santuario() -> Array[ObstaculoCircular]:
	var r: Array[ObstaculoCircular] = [ObstaculoCircular.new(PEDRA_SANTUARIO_CENTRO, PEDRA_SANTUARIO_RAIO)]
	return r


## Layout fixo da câmara do Chefe (R14-P, AC-CO-29).
static func obstaculos_chefe() -> Array[ObstaculoCircular]:
	var r: Array[ObstaculoCircular] = []
	for c: Vector2 in PEDRAS_CHEFE_CENTROS:
		r.append(ObstaculoCircular.new(c, PEDRA_CHEFE_RAIO))
	return r


## Sorteia de [code]obstaculos_min[/code] a [code]obstaculos_min + obstaculos_var - 1[/code] pedras
## consumindo sempre [code]obstaculo_tentativas[/code] candidatos (3 números cada) por pedra tentada (R5, F4).
static func sortear_obstaculos_combate(tuning: RoomTuning, fluxo_layout: FluxoRng) -> Array[ObstaculoCircular]:
	var pedras: Array[ObstaculoCircular] = []
	if fluxo_layout == null or tuning == null:
		return pedras
	var var_n: int = maxi(1, tuning.obstaculos_var)
	var n_pedras: int = tuning.obstaculos_min + fluxo_layout.inteiro(var_n)
	var tentativas: int = maxi(1, tuning.obstaculo_tentativas)
	var passos_raio: int = maxi(1, tuning.obstaculo_passos)
	for _i: int in n_pedras:
		var escolhido: ObstaculoCircular = null
		for _t: int in tentativas:
			var passo_r: int = fluxo_layout.inteiro(passos_raio)
			var raio: float = tuning.obstaculo_raio_min_px + PASSO_RAIO_PX * float(passo_r)
			var x: float = fluxo_layout.real_entre(X_MIN_PADRAO, X_MAX_PADRAO)
			var y: float = fluxo_layout.real_entre(Y_MIN_PADRAO, Y_MAX_PADRAO)
			if escolhido == null and _candidato_valido(Vector2(x, y), raio, pedras, tuning.folga_obstaculo_px):
				escolhido = ObstaculoCircular.new(Vector2(x, y), raio)
		if escolhido != null:
			pedras.append(escolhido)
	return pedras


## Constrói a [GeometriaDeMovimento] da câmara a partir do [param tuning] e [param obstaculos].
static func construir_geometria(tuning: RoomTuning, obstaculos: Array[ObstaculoCircular]) -> GeometriaDeMovimento:
	return GeometriaDeMovimento.new(retangulo_jogavel(tuning), obstaculos)


static func _candidato_valido(centro: Vector2, raio: float, existentes: Array[ObstaculoCircular], folga: float) -> bool:
	for p: ObstaculoCircular in existentes:
		var dist_min: float = raio + p.raio + folga
		if centro.distance_to(p.centro) < dist_min - 1e-9:
			return false
	return true
