class_name VistaDeInimigo
extends RefCounted
## Vista somente leitura de um inimigo para consultas externas (Input, Movimento, Maldições, Apresentação; ADR-0018 §5).

var id: int = -1
var definicao_id: StringName = &""
var pos: Vector2 = Vector2.ZERO
var raio: float = 24.0
var vida: float = 0.0
var vida_max: float = 0.0
var elite: bool = false
var chefe: bool = false
var armadura_ativa: bool = false
var invocado_pelo_chefe: bool = false
var fase: int = 0
var padrao: int = 0
var em_furia: bool = false
var atraido: bool = false
var imobilizado: bool = false
var subjugado: bool = false
