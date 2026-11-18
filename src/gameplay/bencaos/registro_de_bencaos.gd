class_name RegistroDeBencaos
extends RefCounted
## Pool e bênçãos tomadas da run (GDD bencaos-tradicoes.md R2, R8, R9; ADR-0015 §2).
##
## Vive no [code]EscopoDaRun[/code] e morre com ele: a Nova run recria o registro
## (sem [code]reset()[/code]). [method livres] devolve o pool na ordem do manifesto,
## que é o índice usado pelo F7 do sorteio.
##
## Exemplo:
## [codeblock]
## var reg := RegistroDeBencaos.new(catalogo_boons)
## reg.registrar(&"trad_guardian_muro_pedras", SorteioDeOferta.RARA)
## print(reg.restantes())
## [/codeblock]

var _pool: Array[BoonDef] = []
var _tomadas: Array[Dictionary] = []
var _ids_tomados: Dictionary[StringName, bool] = {}


## [param pool]: as [BoonDef] na ordem do manifesto (cópia do catálogo).
func _init(pool: Array[BoonDef]) -> void:
	_pool = pool.duplicate()


## Bênçãos ainda não tomadas, na ordem do manifesto.
func livres() -> Array[BoonDef]:
	var out: Array[BoonDef] = []
	for b: BoonDef in _pool:
		if not _ids_tomados.has(b.id):
			out.append(b)
	return out


## Tamanho do pool (R8; usado pelas Portas para o peso da porta).
func restantes() -> int:
	return _pool.size() - _ids_tomados.size()


## Tomadas na ordem em que foram pegas: [code]{id: StringName, raridade: int}[/code].
## Cópia somente leitura.
func tomadas() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t: Dictionary in _tomadas:
		var c: Dictionary = t.duplicate()
		c.make_read_only()
		out.append(c)
	out.make_read_only()
	return out


## Verdadeiro se a bênção já foi tomada nesta run.
func foi_tomada(id: StringName) -> bool:
	return _ids_tomados.has(id)


## Registra a tomada (R5 passo 2). Recusa (false) id fora do pool ou repetido (R2).
func registrar(id: StringName, raridade: int) -> bool:
	if _ids_tomados.has(id) or not _tem_no_pool(id):
		return false
	_ids_tomados[id] = true
	_tomadas.append({&"id": id, &"raridade": raridade})
	return true


## Devolve a [BoonDef] com [param id], ou null se fora do pool.
func obter_boon(id: StringName) -> BoonDef:
	for b: BoonDef in _pool:
		if b.id == id:
			return b
	return null


func _tem_no_pool(id: StringName) -> bool:
	for b: BoonDef in _pool:
		if b.id == id:
			return true
	return false
