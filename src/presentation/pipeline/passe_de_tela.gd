class_name PasseDeTela
extends RefCounted
## Passe de tela (wipe de tinta ou fade; GDD pipeline-visual.md R7, F6, F8; ADR-0011 §1, §2).
## Avançado pelo orquestrador com `min(dt_real, dt_max_apres)`; não lê `t_apres`,
## portanto o zero dos relógios na metade do wipe não afeta seu progresso (AC-PV-65).

var _tipo: StringName = &"wipe"
var _duracao_s: float = 0.40
var _progresso: float = 0.0
var _eh_fade: bool = false
var _ativo: bool = false


func _init(p_tipo: StringName = &"wipe", p_duracao_s: float = 0.40, p_eh_fade: bool = false) -> void:
	iniciar(p_tipo, p_duracao_s, p_eh_fade)


func iniciar(p_tipo: StringName, p_duracao_s: float, p_eh_fade: bool) -> void:
	_tipo = p_tipo
	_duracao_s = maxf(p_duracao_s, 1e-4)
	_eh_fade = p_eh_fade
	_progresso = 0.0
	_ativo = true


func avancar(dt_apres_limitado: float) -> void:
	if not _ativo:
		return
	var dt := maxf(0.0, dt_apres_limitado)
	_progresso = clampf(_progresso + dt / _duracao_s, 0.0, 1.0)
	if _progresso >= 1.0 - 1e-9:
		_progresso = 1.0
		_ativo = false


func progresso() -> float:
	return _progresso


func eh_fade() -> bool:
	return _eh_fade


func ativo() -> bool:
	return _ativo


func tipo() -> StringName:
	return _tipo
