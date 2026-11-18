class_name EvOfertaAberta
extends EventoDoPasso
## Evento [code]oferta_aberta(cartas, trocas)[/code] (GDD bencaos-tradicoes.md R5;
## ADR-0002). Payload só de dados; imutável por convenção.

## Contrato do tipo.
const TIPO: StringName = &"oferta_aberta"

## Ids das cartas na ordem do sorteio.
var ids: Array[StringName]
## Raridades das cartas, na mesma ordem.
var raridades: Array[int]
## Trocas restantes.
var trocas: int


## Cria o evento (copia as listas).
func _init(p_ids: Array[StringName], p_raridades: Array[int], p_trocas: int) -> void:
	ids = p_ids.duplicate()
	raridades = p_raridades.duplicate()
	trocas = p_trocas


## Devolve [constant TIPO].
func tipo() -> StringName:
	return TIPO
