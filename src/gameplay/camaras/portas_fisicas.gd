class_name PortasFisicas
extends RefCounted
## Estado, posição física e interação das portas na câmara
## (GDD camaras-e-ondas.md R13, R13-P; ADR-0015 §4.3–4.4; ADR-0006).
##
## Regras:
## - Nascem fechadas na montagem da câmara e abrem quando as Portas e recompensas entregam a lista.
## - Em fila no alto: [code]y = portas_y_px[/code] (177), espaçadas por [code]portas_espaco_px[/code] (450),
##   centradas em [code]x = camara_largura_px / 2[/code] (960):
##   - 1 porta: x = 960
##   - 2 portas: x = 735, 1185
##   - 3 portas: x = 510, 960, 1410
## - Alcance de interação: [code]dist <= porta_raio_px (69) + raio_jogador (27) + interagir_folga_px (15) = 111 px[/code].
## - A interação só vale em passo vivo (com hitstop 0 e fora de Transição), quando abertas e não escolhida.

const RAIO_JOGADOR_PADRAO: float = 27.0


## Uma porta física posicionada na arena.
class PortaFisica:
	extends RefCounted
	var indice: int
	var tipo: StringName
	var quantidade: int
	var posicao: Vector2
	var raio_px: float
	var aberta: bool = false

	func _init(p_indice: int, p_tipo: StringName, p_qtd: int, p_pos: Vector2, p_raio: float, p_aberta: bool) -> void:
		indice = p_indice
		tipo = p_tipo
		quantidade = p_qtd
		posicao = p_pos
		raio_px = p_raio
		aberta = p_aberta


var _tuning: RoomTuning
var _portas: Array[PortaFisica] = []
var _abertas: bool = false
var _escolhida: int = -1


func _init(tuning: RoomTuning) -> void:
	_tuning = tuning


## Reinicia as portas como fechadas para uma câmara nova.
func fechar_todas() -> void:
	_portas.clear()
	_abertas = false
	_escolhida = -1


## Abre [param tipos] (e [param quantidades] opcionais) nas posições centradas da R13.
func abrir(tipos: Array[StringName], quantidades: Array[int] = []) -> void:
	_portas.clear()
	_escolhida = -1
	if tipos.is_empty():
		_abertas = false
		return
	var posicoes: Array[Vector2] = calcular_posicoes(tipos.size(), _tuning)
	for i: int in tipos.size():
		var qtd: int = quantidades[i] if i < quantidades.size() else 0
		_portas.append(PortaFisica.new(i, tipos[i], qtd, posicoes[i], _tuning.porta_raio_px, true))
	_abertas = true


## Calcula as posições centradas em [code]x = L / 2[/code] a [code]y = portas_y_px[/code] (R13, AC-CO-18).
static func calcular_posicoes(n: int, tuning: RoomTuning) -> Array[Vector2]:
	var r: Array[Vector2] = []
	if n <= 0 or tuning == null:
		return r
	var centro_x: float = tuning.camara_largura_px * 0.5
	var espaco: float = tuning.portas_espaco_px
	var y: float = tuning.portas_y_px
	var x_inicial: float = centro_x - float(n - 1) * 0.5 * espaco
	for i: int in n:
		r.append(Vector2(x_inicial + float(i) * espaco, y))
	return r


## Distância máxima (inclusiva) entre centros para interagir com uma porta (R13: 69 + 27 + 15 = 111 px).
func alcance_interacao_px(raio_jogador: float = RAIO_JOGADOR_PADRAO) -> float:
	return _tuning.porta_raio_px + raio_jogador + _tuning.interagir_folga_px


## Verdadeiro se as portas estão abertas.
func estao_abertas() -> bool:
	return _abertas


## Lista das portas físicas atuais (cópia).
func listar() -> Array[PortaFisica]:
	return _portas.duplicate()


## Índice da porta ao alcance de [param pos_jogador] (a primeira na ordem esquerda→direita), ou -1.
func porta_ao_alcance(pos_jogador: Vector2, raio_jogador: float = RAIO_JOGADOR_PADRAO) -> int:
	if not _abertas or _escolhida >= 0:
		return -1
	var alcance: float = alcance_interacao_px(raio_jogador)
	for p: PortaFisica in _portas:
		if p.aberta and pos_jogador.distance_to(p.posicao) <= alcance + 1e-9:
			return p.indice
	return -1


## Tenta interagir a partir de [param pos_jogador]. Devolve o índice escolhido (0..n-1) ou -1.
## Ignora se fechadas, se já escolhida, ou se em hitstop/Transição.
func tentar_interagir(pos_jogador: Vector2, em_passo_vivo: bool = true,
		raio_jogador: float = RAIO_JOGADOR_PADRAO) -> int:
	if not em_passo_vivo or not _abertas or _escolhida >= 0:
		return -1
	var idx: int = porta_ao_alcance(pos_jogador, raio_jogador)
	if idx >= 0:
		_escolhida = idx
	return idx


## Índice da porta já escolhida (-1 se nenhuma).
func escolhida() -> int:
	return _escolhida
