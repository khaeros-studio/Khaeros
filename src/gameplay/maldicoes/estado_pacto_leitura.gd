class_name EstadoPactoLeitura
extends RefCounted
## Leitura imutável sem efeito colateral para o Bloco do Pacto no HUD (GDD maldicoes.md R19, AC-ML-28; ADR-0017).


class SlotLeitura extends RefCounted:
	var especie_id: StringName = &""
	var vida: int = 0
	var vida_max: int = 0
	var estado: StringName = &""
	var restante_exausta: int = 0
	var total_exausta: int = 0


var campo: SlotLeitura = null
var reserva: SlotLeitura = null
var recarga_troca_passos: int = 0
var recarga_troca_total: int = 240
var troca_disponivel: bool = false
