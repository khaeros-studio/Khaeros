class_name FormatoNumerico
extends RefCounted
## Formatação numérica pura do HUD (`ADR-0012`, `design/gdd/hud.md`).
## Usa espaço fixo como separador de milhar (`1 234`) sem string literal de idioma.


static func formatar_inteiro(valor: int) -> String:
	var negativo: bool = valor < 0
	var abs_val: int = absi(valor)
	var s: String = str(abs_val)
	if s.length() <= 3:
		return ("-" + s) if negativo else s

	var partes: PackedStringArray = PackedStringArray()
	var resto: int = s.length() % 3
	if resto > 0:
		partes.append(s.substr(0, resto))
	var idx: int = resto
	while idx < s.length():
		partes.append(s.substr(idx, 3))
		idx += 3
	var resultado: String = " ".join(partes)
	return ("-" + resultado) if negativo else resultado


static func formatar_razao(atual: int, maximo: int) -> String:
	return "%s / %s" % [formatar_inteiro(atual), formatar_inteiro(maximo)]


static func formatar_tempo_mm_ss(segundos_totais: float) -> String:
	var total_int: int = maxi(0, int(floor(segundos_totais)))
	var minutos: int = int(total_int / 60)
	var segundos: int = total_int % 60
	return "%02d:%02d" % [minutos, segundos]
