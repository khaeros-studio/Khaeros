class_name AlvoDeInimigo
extends RefCounted
## Valor pré-alocado que descreve o alvo efetivo de um inimigo num passo (ADR-0018 §4, ADR-0017 §11).

var faccao: TelegrafoTipos.FaccaoAlvo = TelegrafoTipos.FaccaoAlvo.JOGADOR
var id: int = 0
var player_id: int = 0
var pos: Vector2 = Vector2.ZERO
var raio: float = 27.0


func copiar_de(outro: AlvoDeInimigo) -> void:
	faccao = outro.faccao
	id = outro.id
	player_id = outro.player_id
	pos = outro.pos
	raio = outro.raio
