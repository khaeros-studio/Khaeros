class_name IATuning
extends DefinicaoBase
## Parâmetros de tuning da IA de inimigos e elites (GDD ia-de-inimigos-e-elites.md R14, Faixas e IV1–IV9 / IA1–IA14; ADR-0018).

@export var surgimento_s: float = 50.0 / 60.0
@export var espera_inicial_base_s: float = 20.0 / 60.0
@export var espera_inicial_var_s: float = 50.0 / 60.0
@export var espera_base_s: float = 10.0 / 60.0
@export var espera_var_s: float = 30.0 / 60.0
@export var ranged_perto_px: float = 345.0
@export var ranged_longe_px: float = 570.0
@export var ranged_ataque_px: float = 975.0
@export var charger_engaja_px: float = 570.0
@export var charger_reaproxima_px: float = 456.0
@export var fator_recuperacao_andar: float = 0.40
@export var recuperacao_dist_min_px: float = 90.0
@export var fator_contorno: float = 0.50
@export var execucao_melee_passos: int = 10
@export var execucao_ranged_passos: int = 6
@export var avanco_passos: int = 26
@export var avanco_mult_velocidade: float = 3.60
@export var quebrou_recuperacao_s: float = 24.0 / 60.0
@export var fator_lentidao_selo: float = 0.50
@export var fator_cambaleio: float = 0.40
@export var bonus_vida_por_profundidade: float = 0.05
@export var alvo_dano_camera: float = 0.25
@export var margem_visivel_px: float = 0.0


func _init() -> void:
	id = &"ia_tuning"


func tipo_do_catalogo() -> StringName:
	return &"tuning"


static func de_fabrica() -> IATuning:
	return IATuning.new()
