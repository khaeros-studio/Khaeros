class_name PreferenciasDeArmaEmMemoria
extends PreferenciasDeArma
## Implementação de [PreferenciasDeArma] (ADR-0013 Key Interfaces) para lembrar a última
## arma escolhida entre runs e sessões (TR-run-012, AC-RN-03).
## Também provê a variante nula para builds de playtest (AC-AR-39).

var _ultima: StringName = &""
var _somente_leitura: bool = false


func _init(inicial: StringName = &"", somente_leitura: bool = false) -> void:
	_ultima = inicial
	_somente_leitura = somente_leitura


func ultima_arma() -> StringName:
	return _ultima


func lembrar_arma(id: StringName) -> void:
	if _somente_leitura:
		return
	_ultima = id
