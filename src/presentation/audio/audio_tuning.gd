class_name AudioTuning
extends DefinicaoBase
## Parâmetros de mixagem, polifonia e tons de telégrafo conforme ADR-0016 §4.

@export var vozes_max_gancho: int = 4
@export var vozes_max_total: int = 16
@export var vozes_interface: int = 4
@export var teto_tons_telegrafo: int = 3
@export var tom_pitch_min: float = 1.0
@export var tom_pitch_max: float = 2.0
@export var tom_maldicao_fator_pitch: float = 0.85


func _init() -> void:
	id = &"audio_tuning"


func tipo_do_catalogo() -> StringName:
	return &"audio_tuning"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super._declarar_regras(e)
	e.regra(&"vozes_max_gancho").intervalo(1, 8)
	e.regra(&"vozes_max_total").intervalo(4, 32)
	e.regra(&"vozes_interface").intervalo(1, 8)
	e.regra(&"teto_tons_telegrafo").intervalo(1, 8)
	e.regra(&"tom_pitch_min").intervalo(0.25, 4.0)
	e.regra(&"tom_pitch_max").intervalo(0.25, 4.0)
	e.regra(&"tom_maldicao_fator_pitch").intervalo(0.25, 4.0)


func validar_faixas() -> Array[StringName]:
	var erros: Array[StringName] = []
	if vozes_max_gancho < 1 or vozes_max_gancho > vozes_max_total:
		erros.append(&"AU1_VOZES_GANCHO_INVALIDO")
	if vozes_max_total < 4 or vozes_max_total > 32:
		erros.append(&"AU2_VOZES_TOTAL_INVALIDO")
	if vozes_interface < 1 or vozes_interface > 8:
		erros.append(&"AU3_VOZES_INTERFACE_INVALIDO")
	if teto_tons_telegrafo < 1 or teto_tons_telegrafo > 8:
		erros.append(&"AU4_TETO_TONS_INVALIDO")
	if tom_pitch_min <= 0.0 or tom_pitch_min < 0.25 or tom_pitch_min > 4.0:
		erros.append(&"AU5_TOM_PITCH_MIN_INVALIDO")
	if tom_pitch_max <= 0.0 or tom_pitch_max < 0.25 or tom_pitch_max > 4.0 or tom_pitch_max < tom_pitch_min:
		erros.append(&"AU6_TOM_PITCH_MAX_INVALIDO")
	if tom_maldicao_fator_pitch <= 0.0 or tom_maldicao_fator_pitch < 0.25 or tom_maldicao_fator_pitch > 4.0:
		erros.append(&"AU7_TOM_MALDICAO_FATOR_INVALIDO")
	return erros
