class_name CartaDaOferta
extends RefCounted
## Uma carta de uma oferta (GDD bencaos-tradicoes.md R3/R4): a bênção e a raridade
## sorteada. Imutável por convenção depois de criada.

## Índice da carta em [method RegistroDeBencaos.livres] no momento do sorteio.
var indice_livre: int
## Id da [BoonDef].
var id: StringName
## Raridade: [constant SorteioDeOferta.COMUM], [constant SorteioDeOferta.RARA] ou [constant SorteioDeOferta.EPICA].
var raridade: int


## Cria a carta.
func _init(p_indice_livre: int, p_id: StringName, p_raridade: int) -> void:
	indice_livre = p_indice_livre
	id = p_id
	raridade = p_raridade
