class_name CorteDeCamera
extends RefCounted
## Pedido de corte na troca de câmara, na metade do wipe (ADR-0007 §7, GDD R10).
##
## Exemplo:
## [codeblock]
## camera.cortar(CorteDeCamera.new(nova_epoca, jogavel, sangria, spawn, mira_capturada))
## [/codeblock]

## Nova época da câmara (cresce a cada troca).
var epoca: int
## Retângulo jogável da câmara nova (px de mundo).
var jogavel: Rect2
## Sangria lateral de arte `b` da câmara nova.
var sangria: float
## Ponto de spawn do jogador (P_anterior = P_atual = spawn).
var spawn: Vector2
## Entrada capturada (mira/opções válidas); `p_*` são sobrescritos pelo spawn.
## Pode ser `null`: o corte então usa lookahead zero.
var entrada: EntradaCamera


func _init(p_epoca: int, p_jogavel: Rect2, p_sangria: float, p_spawn: Vector2, p_entrada: EntradaCamera = null) -> void:
	epoca = p_epoca
	jogavel = p_jogavel
	sangria = p_sangria
	spawn = p_spawn
	entrada = p_entrada
