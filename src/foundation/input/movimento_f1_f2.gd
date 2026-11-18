class_name MovimentoF1F2
extends RefCounted
## Fórmulas F1 (movimento do teclado) e F2 (zona morta radial com reescala) do GDD input-e-controle,
## e a combinação da R3/R4 (teclado não zero vence o analógico). Funções puras, sem estado.


## F1: soma bruta das direções digitais, normalizada; teclas opostas se anulam.
static func teclado(cima: bool, baixo: bool, esquerda: bool, direita: bool) -> Vector2:
	var v := Vector2(float(direita) - float(esquerda), float(baixo) - float(cima))
	if v == Vector2.ZERO:
		return Vector2.ZERO
	return v.normalized()


## F2: m' = clamp((m − zm) / (1 − ze − zm), 0, 1); saída = (s / m)·m', ou zero se m = 0.
## Exige zm + ze < 1 (validado ao carregar o `InputTuning`).
static func zona_morta_radial(s: Vector2, zona_interna: float, zona_externa: float) -> Vector2:
	var m := s.length()
	if m <= 0.0:
		return Vector2.ZERO
	var faixa := 1.0 - zona_externa - zona_interna
	if faixa <= 0.0:
		return Vector2.ZERO
	var reescalado := clampf((m - zona_interna) / faixa, 0.0, 1.0)
	return (s / m) * reescalado


## R3/R4: o teclado vence quando não é zero; senão vale o analógico (módulo preservado).
static func combinar(movimento_teclado: Vector2, movimento_analogico: Vector2) -> Vector2:
	if movimento_teclado != Vector2.ZERO:
		return movimento_teclado
	return movimento_analogico
