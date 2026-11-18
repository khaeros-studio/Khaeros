class_name RoomTuning
extends DefinicaoBase
## Constantes de câmaras e nascimento (GDD camaras-e-ondas.md R15, WV1–WV11).
## Formato: GDD de Conteúdo R1/R1-P (ADR-0004). Significado e valores: Câmaras e ondas. Só leitura em execução (R3).
## Único por jogo; entra no manifesto como tipo [code]&"tuning"[/code].
##
## Exemplo:
## [codeblock]
## var t := RoomTuning.new()
## assert(t.tipo_do_catalogo() == &"tuning")
## [/codeblock]

@export var camara_largura_px: float = 0.0
@export var camara_altura_px: float = 0.0
@export var obstaculos_min: int = 0
@export var obstaculos_var: int = 0
@export var obstaculo_raio_min_px: float = 0.0
@export var obstaculo_passos: int = 0
@export var folga_obstaculo_px: float = 0.0
@export var obstaculo_tentativas: int = 0
@export var spawn_candidatos: int = 0
@export var spawn_dist_jogador_px: float = 0.0
@export var spawn_margem_px: float = 0.0
@export var spawn_folga_pedra_px: float = 0.0
@export var portas_espaco_px: float = 0.0
@export var portas_y_px: float = 0.0
@export var porta_raio_px: float = 0.0
@export var entrada_px: PackedFloat64Array = PackedFloat64Array()
@export var interagir_folga_px: float = 0.0
@export var santuario_cura: float = 0.0
@export var spawn_dist_acuada_px: float = 0.0


func tipo_do_catalogo() -> StringName:
	return &"tuning"
