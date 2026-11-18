class_name TelegraphTuning
extends DefinicaoBase
## Parâmetros de tuning e validação de Telégrafos (GDD telegrafos.md R10, Faixas e TV1–TV6 / TL1–TL12; ADR-0014).

@export var preparo_min_s: float = 0.40
@export var teto_telegrafos: int = 24
@export var reacao_ref_s: float = 0.25
@export var folga_min: int = 8
@export var avanco_passos: int = 26


func _init() -> void:
	id = &"telegraph_tuning"


func tipo_do_catalogo() -> StringName:
	return &"tuning"


static func de_fabrica() -> TelegraphTuning:
	return TelegraphTuning.new()
