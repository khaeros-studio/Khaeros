class_name EvOfertaTrocada
extends EventoDoPasso
## Evento [code]oferta_trocada[/code] (GDD bencaos-tradicoes.md R5/R6; ADR-0002):
## a nova oferta depois de uma troca. Payload só de dados; imutável por convenção.

## Contrato do tipo.
const TIPO: StringName = &"oferta_trocada"

## Ids das novas cartas na ordem do sorteio.
var ids: Array[StringName]
## Raridades das novas cartas, na mesma ordem.
var raridades: Array[int]
## Trocas restantes depois desta.
var trocas: int


## Cria o evento (copia as listas).
func _init(p_ids: Array[StringName], p_raridades: Array[int], p_trocas: int) -> void:
	ids = p_ids.duplicate()
	raridades = p_raridades.duplicate()
	trocas = p_trocas


## Devolve [constant TIPO].
func tipo() -> StringName:
	return TIPO
