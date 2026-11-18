class_name SomDef
extends DefinicaoBase
## Definição de um gancho sonoro (`sfx_*`, `ui_*` ou `mus_*`) conforme ADR-0016 §4.

@export var caminho_stream: String = ""
@export var ganho_db: float = 0.0
@export var variacoes: Array[String] = []
@export var pitch_min: float = 1.0
@export var pitch_max: float = 1.0
@export var barramento: StringName = &"Efeitos"


func tipo_do_catalogo() -> StringName:
	return &"som"


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	super._declarar_regras(e)
	e.regra(&"ganho_db").intervalo(-48.0, 12.0)
	e.regra(&"pitch_min").intervalo(0.25, 4.0)
	e.regra(&"pitch_max").intervalo(0.25, 4.0)
	e.regra(&"variacoes").opcional()
	e.regra(&"barramento").opcional()


## Resolve o caminho de stream usando round-robin determinístico sobre `variacoes`.
func resolver_caminho_stream(contador_rr: int = 0) -> String:
	if variacoes.is_empty():
		return caminho_stream
	var total: int = 1 + variacoes.size()
	var indice: int = posmod(contador_rr, total)
	if indice == 0:
		return caminho_stream
	return variacoes[indice - 1]


## Valida se os parâmetros de pitch e ganho respeitam as faixas seguras do ADR-0016.
func validar_faixas() -> Array[StringName]:
	var erros: Array[StringName] = []
	if id == &"":
		erros.append(&"AU_SOM_ID_VAZIO")
	if pitch_min <= 0.0 or pitch_min < 0.25 or pitch_min > 4.0:
		erros.append(&"AU_PITCH_MIN_FORA_DA_FAIXA")
	if pitch_max <= 0.0 or pitch_max < 0.25 or pitch_max > 4.0 or pitch_max < pitch_min:
		erros.append(&"AU_PITCH_MAX_FORA_DA_FAIXA")
	if ganho_db < -48.0 or ganho_db > 12.0:
		erros.append(&"AU_GANHO_DB_FORA_DA_FAIXA")
	return erros
