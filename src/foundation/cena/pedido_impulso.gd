class_name PedidoImpulso
extends RefCounted
## Pedido de impulso de câmera enviado só pelo Feedback (ADR-0007 §8, GDD R8).
##
## Exemplo:
## [codeblock]
## camera.receber_impulso(PedidoImpulso.new(&"pesado", 1.0, Vector2.RIGHT, epoca, t_apres))
## [/codeblock]

## Nome do preset no `CameraTuning` (leve, pesado, chefe, zoom principal…).
var preset: StringName
## Escala finita ≥ 0; multiplica Ak, As e Z.
var escala: float
## Direção unitária do golpe, ou zero (sem chute).
var dir: Vector2
## Época da câmara em que o pedido foi gerado.
var epoca: int
## Instante de início no relógio de apresentação (`t_apres`).
var t_inicio: float


func _init(p_preset: StringName, p_escala: float, p_dir: Vector2, p_epoca: int, p_t_inicio: float) -> void:
	preset = p_preset
	escala = p_escala
	dir = p_dir
	epoca = p_epoca
	t_inicio = p_t_inicio
