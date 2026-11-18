class_name ConsultaFalsaBn
extends ConsultaDeAtributos
## Dublê do Modificadores para as Bênçãos: só responde inteiros configurados.

var inteiros: Dictionary[StringName, int] = {}


func _init(trocas_oferta: int = 0) -> void:
	inteiros[Atributos.TROCAS_OFERTA] = trocas_oferta


func valor(atributo: StringName) -> float:
	return float(inteiros.get(atributo, 0))


func inteiro(atributo: StringName) -> int:
	return inteiros.get(atributo, 0)


func congelar_dano(_slot: Modificador.Slot, _ctx: ContextoDeDano) -> DanoCongelado:
	return null


func multiplicador_de_dano(_slot: Modificador.Slot, _ctx: ContextoDeDano) -> float:
	return 0.0


func gatilhos(_tipo: StringName) -> ResumoDeGatilho:
	return null
