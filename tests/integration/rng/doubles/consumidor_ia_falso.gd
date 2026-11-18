## Dublê: consumidor de `ia` que invoca reforços no meio da luta (R3, R4b).
class_name ConsumidorIaFalso
extends RefCounted

var _ia: FluxosDeIa


func _init(ia: FluxosDeIa) -> void:
	_ia = ia


## Invoca `quantos` reforços: tipo e posição saem só do fluxo `ia`.
func invocar_reforcos(regiao: int, profundidade: int, quantos: int, n_tipos: int, tamanho: Vector2) -> void:
	var fluxo: FluxoRng = _ia.ia(regiao, profundidade)
	for i: int in quantos:
		fluxo.inteiro(n_tipos)
		fluxo.real_entre(0.0, tamanho.x)
		fluxo.real_entre(0.0, tamanho.y)


## Consome `quantos` números do fluxo `ia` (timers do combate).
func consumir(regiao: int, profundidade: int, quantos: int) -> void:
	var fluxo: FluxoRng = _ia.ia(regiao, profundidade)
	for i: int in quantos:
		fluxo.real_unitario()
