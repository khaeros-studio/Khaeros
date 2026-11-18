class_name VistaDeTelegrafo
extends RefCounted
## Vista por valor desvinculada publicada para o Pipeline visual (24 slots SDF; ADR-0014 Decisão 8, 11).

var slot: int = 0
var dono_id: int = -1
var seq: int = 0
var forma: TelegrafoTipos.Forma = TelegrafoTipos.Forma.SETOR
var modo: TelegrafoTipos.Modo = TelegrafoTipos.Modo.CENTRO_A_BORDA
var estado: TelegrafoTipos.Estado = TelegrafoTipos.Estado.LIVRE
var pos: Vector2 = Vector2.ZERO
var rot: float = 0.0
var mira: Vector2 = Vector2.RIGHT
var raio: float = 0.0
var r_int: float = 0.0
var r_ext: float = 0.0
var cos_meio: float = TelegrafoTipos.COS_MEIO_SETOR_PADRAO
var meio_angulo_graus: float = TelegrafoTipos.MEIO_ANGULO_SETOR_GRAUS
var x_min: float = 0.0
var comprimento: float = 0.0
var largura: float = 0.0
var p: float = 0.0
var passos_no_estado: int = 0
var alvo_id: int = 0
var alvo_faccao: TelegrafoTipos.FaccaoAlvo = TelegrafoTipos.FaccaoAlvo.JOGADOR
var contorno_alvo: TelegrafoTipos.ContornoAlvo = TelegrafoTipos.ContornoAlvo.PERIGO_JOGADOR
var contorno_secundario_raio: float = 0.0
var ondas_concentricas: int = 1
var leques: int = 1
