@abstract
class_name Comportamento
extends RefCounted
## Base sem estado para os comportamentos da IA (`corpo_a_corpo`, `distancia`, `arremetida`, `chefe`; ADR-0018 §3).


@abstract func ao_surgir(i: EstadoDeInimigoIA, ia: Object) -> void
@abstract func decidir(i: EstadoDeInimigoIA, alvo: AlvoDeInimigo, ia: Object) -> void
