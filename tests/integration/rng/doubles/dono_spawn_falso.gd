## Dublê: dono de `spawn` (Câmaras) com K candidatos fixos por nascimento (R4b).
## Sorteia os K candidatos (x, y) ANTES de filtrar; a escolha não sorteia nada.
class_name DonoSpawnFalso
extends RefCounted

var _camaras: FluxosDeCamaras
var _k: int
var _tamanho: Vector2
var _distancia_minima: float


func _init(camaras: FluxosDeCamaras, k: int, tamanho_da_arena: Vector2, distancia_minima: float) -> void:
	_camaras = camaras
	_k = k
	_tamanho = tamanho_da_arena
	_distancia_minima = distancia_minima


## Ponto de nascimento: primeiro candidato a mais de `distancia_minima` do jogador
## (ou o primeiro candidato, se nenhum servir).
func nascer(regiao: int, profundidade: int, jogador: Vector2) -> Vector2:
	var fluxo: FluxoRng = _camaras.spawn(regiao, profundidade)
	var candidatos: Array[Vector2] = []
	for i: int in _k:
		candidatos.append(Vector2(fluxo.real_entre(0.0, _tamanho.x), fluxo.real_entre(0.0, _tamanho.y)))
	for candidato: Vector2 in candidatos:
		if candidato.distance_to(jogador) > _distancia_minima:
			return candidato
	return candidatos[0]
