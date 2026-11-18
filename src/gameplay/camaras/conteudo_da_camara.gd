class_name ConteudoDaCamara
extends RefCounted
## Escopo de câmara (ADR-0015 §2): descartado e recriado a cada [method Camaras.trocar].
## Guarda o índice, o tipo, a profundidade [code]p[/code], a recompensa pendente, a geometria
## (retângulo e pedras), as ondas compostas, o índice da onda atual, os inimigos vivos da câmara,
## a posição da acuada (se houver encontro) e as portas físicas.

var indice: int = 0
var regiao_idx: int = 0
var tipo: StringName = ProfundidadeCamara.TIPO_COMBATE
var profundidade: int = 0
var recompensa_pendente: StringName = &""
var obstaculos: Array[ObstaculoCircular] = []
var geometria: GeometriaDeMovimento = null
var ondas_compostas: Array[Array] = []
var onda_atual: int = -1
var inimigos_vivos: Array[InimigoRef] = []
var especie_encontro: StringName = &""
var acuada_presente: bool = false
var pos_acuada: Vector2 = Vector2.ZERO
var portas: PortasFisicas = null
var limpa_emitida: bool = false


func _init(p_indice: int, p_regiao_idx: int, p_tipo: StringName, p_profundidade: int,
		p_recompensa: StringName, tuning: RoomTuning) -> void:
	indice = p_indice
	regiao_idx = p_regiao_idx
	tipo = p_tipo
	profundidade = p_profundidade
	recompensa_pendente = p_recompensa
	portas = PortasFisicas.new(tuning)
