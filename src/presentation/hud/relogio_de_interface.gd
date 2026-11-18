class_name RelogioDeInterface
extends RefCounted
## Relógio monotônico da camada de Interface (`t_ui` e `t_real`, `ADR-0012 §2`).
## - `t_ui` congela em `PAUSA` e avança com `min(delta_real, dt_max)` fora de `PAUSA`.
## - `t_real` nunca congela (usado por animações do menu de Pausa e tela de Opções).

var _t_ui: float = 0.0
var _t_real: float = 0.0
var _dt_ui_ultimo: float = 0.0
var _dt_real_ultimo: float = 0.0


func avancar(delta_real: float, pausado: bool, dt_max: float = 0.1) -> void:
	var dt_seguro: float = clampf(delta_real, 0.0, maxf(0.001, dt_max))
	_dt_real_ultimo = dt_seguro
	_t_real += dt_seguro
	if pausado:
		_dt_ui_ultimo = 0.0
	else:
		_dt_ui_ultimo = dt_seguro
		_t_ui += dt_seguro


func t_ui() -> float:
	return _t_ui


func t_real() -> float:
	return _t_real


func dt_ui() -> float:
	return _dt_ui_ultimo


func dt_real() -> float:
	return _dt_real_ultimo


func zerar() -> void:
	_t_ui = 0.0
	_t_real = 0.0
	_dt_ui_ultimo = 0.0
	_dt_real_ultimo = 0.0
