class_name VinculoNulo
extends PortaDoVinculoNaRun
## Variante Nula do Vínculo na run (ADR-0015 §5, §9): comportamento "sem Pactos".
## Overrides com [code]return[/code] explícito (regra Godot 4.7).


func pedir_dupla(_doutrina: StringName) -> bool:
	return false


func planejar_encontro(_doutrina: StringName, _fluxo_pactos: FluxoRng) -> void:
	pass


func encontro_na_camara(_indice: int) -> StringName:
	return &""


func ao_montar_camara(_indice: int, _pedras: Array[ObstaculoCircular] = []) -> Vector2:
	return Vector2.ZERO


func encontro_aguardando() -> bool:
	return false


func consolidar_run(_motivo: StringName, _venceu: bool) -> void:
	pass
