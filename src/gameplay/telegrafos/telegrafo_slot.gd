class_name TelegrafoSlot
extends RefCounted
## Slot reutilizável do pool fixo de Telégrafos (ADR-0003, ADR-0014 Decisão 2 e 9).

var indice: int = 0
var estado: TelegrafoTipos.Estado = TelegrafoTipos.Estado.LIVRE
var dono_id: int = -1
var seq: int = 0
var preparo: int = 0
var restante: int = 0
var passos_no_estado: int = 0
var mira: Vector2 = Vector2.RIGHT
var ancora_copiada: Vector2 = Vector2.ZERO
var usar_ancora_copiada: bool = false

## Alvo travado (emenda Pactos, R2a).
var alvo_id: int = 0
var alvo_faccao: TelegrafoTipos.FaccaoAlvo = TelegrafoTipos.FaccaoAlvo.JOGADOR
var raio_alvo: float = TelegrafoTipos.RAIO_JOGADOR_PADRAO_PX

## Forma derivada na criação do telégrafo.
var derivada: FormasDeTelegrafo.FormaDerivada = null


func _init(p_indice: int = 0) -> void:
	indice = p_indice


func ocupado() -> bool:
	return estado != TelegrafoTipos.Estado.LIVRE


func em_crescimento() -> bool:
	return estado == TelegrafoTipos.Estado.CRESCENDO


func terminal() -> bool:
	return estado == TelegrafoTipos.Estado.DISPARO \
		or estado == TelegrafoTipos.Estado.QUEBRADO \
		or estado == TelegrafoTipos.Estado.CANCELADO


func progresso() -> float:
	if preparo <= 0:
		return 1.0
	if estado != TelegrafoTipos.Estado.CRESCENDO:
		return 1.0
	return clampf(1.0 - float(restante) / float(preparo), 0.0, 1.0)


func liberar() -> void:
	estado = TelegrafoTipos.Estado.LIVRE
	dono_id = -1
	seq = 0
	preparo = 0
	restante = 0
	passos_no_estado = 0
	mira = Vector2.RIGHT
	ancora_copiada = Vector2.ZERO
	usar_ancora_copiada = false
	alvo_id = 0
	alvo_faccao = TelegrafoTipos.FaccaoAlvo.JOGADOR
	raio_alvo = TelegrafoTipos.RAIO_JOGADOR_PADRAO_PX
	derivada = null
