class_name PortasDaBencao
extends RefCounted
## Contratos abstratos e adaptadores de porta entre as Telas de Carta/Pacto e os módulos
## de Gameplay (`Bencaos`, `Combate`, `Vinculo`, `ADR-0012 §5`).

@abstract class PortaDaBencao extends RefCounted:
	@abstract func escolher_carta(indice: int) -> bool
	@abstract func trocar_oferta() -> bool
	@abstract func trocas_restantes() -> int
	@abstract func cartas_atuais() -> Array[DadosDaCarta]


class PortaDaBencaoReal extends PortaDaBencao:
	var _bencaos: Bencaos = null
	var _player_id: int = 1
	var _catalogo_defs: Dictionary = {} # StringName -> BoonDef
	var _cartas_cache: Array[DadosDaCarta] = []
	var _trocas_cache: int = 0

	func _init(bencaos: Bencaos = null, player_id: int = 1, catalogo_defs: Dictionary = {}) -> void:
		_bencaos = bencaos
		_player_id = player_id
		_catalogo_defs = catalogo_defs

	func sincronizar_de_evento(ids: Array[StringName], raridades: Array[int], trocas: int) -> void:
		_trocas_cache = maxi(0, trocas)
		_cartas_cache.clear()
		for i: int in range(ids.size()):
			var id_b: StringName = ids[i]
			var rar: int = raridades[i] if i < raridades.size() else 0
			var def: BoonDef = _catalogo_defs.get(id_b, null)
			var doutrina: StringName = def.doutrina if def != null else &"sangue"
			var preco: int = def.preco_vida if def != null else 0
			_cartas_cache.append(DadosDaCarta.criar_de_bencao(id_b, doutrina, rar, preco))

	func escolher_carta(indice: int) -> bool:
		if indice < 0 or indice >= _cartas_cache.size():
			return false
		if _bencaos != null:
			return _bencaos.escolher(indice, false)
		return true

	func trocar_oferta() -> bool:
		if _trocas_cache <= 0:
			return false
		if _bencaos != null:
			var ok: bool = _bencaos.trocar()
			if ok:
				var ids: Array[StringName] = []
				var rars: Array[int] = []
				for c: CartaDaOferta in _bencaos.cartas():
					ids.append(c.id)
					rars.append(c.raridade)
				sincronizar_de_evento(ids, rars, _bencaos.trocas_restantes())
			return ok
		_trocas_cache -= 1
		return true

	func trocas_restantes() -> int:
		return _trocas_cache

	func cartas_atuais() -> Array[DadosDaCarta]:
		return _cartas_cache
