class_name EstadoDoMovimento
extends RefCounted
## Estado tipado do Movimento de um jogador (GDD movimento-e-esquiva R1, R6, R7; ADR-0008 §1). Só o
## [MovimentoDoJogador] escreve; leitores recebem valores pelas consultas dele.

## 0 no solo (co-op preparado).
var player_id: int = 0
## Época da run (vai nos eventos).
var epoca_run: int = 0
## Posição atual em px de mundo.
var pos: Vector2 = Vector2.ZERO
## Posição do passo anterior (par interpolado pela Cena).
var anterior: Vector2 = Vector2.ZERO
## Passos de esquiva restantes (0 = livre).
var esquiva_restante: int = 0
## Direção fixada na largada (unitária).
var esquiva_direcao: Vector2 = Vector2.ZERO
## Cargas e recarga.
var cargas: CargasDeEsquiva = CargasDeEsquiva.new()
## Ids já cortados nesta esquiva (story 007). Chave = id; nunca iterado (só [code]has[/code]).
var cortados: Dictionary[int, bool] = {}


func _init(p_player_id: int = 0) -> void:
	player_id = p_player_id
