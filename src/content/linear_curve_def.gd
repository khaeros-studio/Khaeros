class_name LinearCurveDef
extends DadoDeConteudo
## Curva linear padrão (F8): y = 0 se x < x_min; senão clamp(base + slope * x, y_floor, y_cap)
## (avaliada por [CurvaLinear]). Regra entre campos: y_floor <= y_cap (V2), exceto com
## [member sem_teto].
## Formato: GDD de Conteúdo R1/R1-P (ADR-0004). Valores: GDD dono. Só leitura em execução (R3).
##
## Exemplo:
## [codeblock]
## var c := LinearCurveDef.new(); c.y_floor = piso; c.y_cap = teto
## [/codeblock]

## Ativação (inclusiva).
@export var x_min: float = 0.0
@export var base: float = 0.0
@export var slope: float = 0.0
@export var y_floor: float = 0.0
@export var y_cap: float = 0.0
## Curva sem limite superior (em vez de gravar infinito no .tres; Edge Cases do GDD).
@export var sem_teto: bool = false


func _declarar_regras(e: EsquemaDeDefinicao) -> void:
	for n: StringName in [&"x_min", &"base", &"slope", &"y_floor", &"sem_teto"]:
		e.regra(n).aceita_default()
	e.entre(&"y_floor", &"<=", &"y_cap", &"sem_teto")
