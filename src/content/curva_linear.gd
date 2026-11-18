class_name CurvaLinear
extends RefCounted
## F8 do GDD de Conteúdo: avalia um [LinearCurveDef].
## [code]y = 0 se x < x_min; senão y = clamp(base + slope × x, y_floor, y_cap)[/code];
## com [member LinearCurveDef.sem_teto] não há limite superior. O piso só vale depois
## da ativação (x < x_min dá 0 mesmo com piso > 0). Função pura, thread-safe; não
## altera a definição (só leitura, R3).
##
## Exemplo:
## [codeblock]
## var chance := CurvaLinear.avaliar(regras_elite.chance, profundidade)
## [/codeblock]


## Valor da curva em [param x].
static func avaliar(curva: LinearCurveDef, x: float) -> float:
	if x < curva.x_min:
		return 0.0
	var y := curva.base + curva.slope * x
	if y < curva.y_floor:
		y = curva.y_floor
	if not curva.sem_teto and y > curva.y_cap:
		y = curva.y_cap
	return y
