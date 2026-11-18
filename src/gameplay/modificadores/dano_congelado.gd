class_name DanoCongelado
extends RefCounted
## M da F2 congelado no disparo (GDD modificadores-e-atributos R12; ADR-0009 §4).
##
## Guarda o fator já avaliado no disparo (P_todo com [code]vida_abaixo[/code], P_slot,
## multiplicadores incondicionais e [code]apos_esquiva[/code]) e, à parte, os
## multiplicadores do 4º acerto, avaliados por alvo no impacto. O teto vem por último.
## Imutável; o projétil carrega o seu sem referência ao portador.
##
## Exemplo:
## [codeblock]
## var congelado := portador.congelar_dano(Modificador.Slot.ATAQUE, ctx)
## var m := congelado.m_no_impacto(contador_do_alvo)
## [/codeblock]

var _fator: float
var _a_cada: PackedInt32Array
var _mult_enesimo: PackedFloat64Array
var _teto: float


## [param fator]: M sem 4º acerto e sem teto. [param a_cada]/[param mult_enesimo]: pares
## do 4º acerto, em ordem canônica. [param teto]: [code]teto_multiplicador_dano[/code].
func _init(fator: float, a_cada: PackedInt32Array, mult_enesimo: PackedFloat64Array, teto: float) -> void:
	_fator = fator
	_a_cada = a_cada
	_mult_enesimo = mult_enesimo
	_teto = teto


## M efetivo no impacto: aplica cada 4º acerto cujo [param contador_acertos] é > 0 e
## múltiplo de [code]a_cada[/code], e só então [code]min(M, teto)[/code] (AC-04b).
func m_no_impacto(contador_acertos: int) -> float:
	var m: float = _fator
	if contador_acertos > 0:
		for i: int in _a_cada.size():
			var n: int = _a_cada[i]
			if n > 0 and contador_acertos % n == 0:
				m *= _mult_enesimo[i]
	return minf(m, _teto)
