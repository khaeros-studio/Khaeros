class_name RegrasTl
extends ValidadorDoDono
## TL1–TL3 (Telemetria local; GDD telemetria-local.md Tuning Knobs e GDD de Conteúdo
## R1/R9): faixas de [TelemetriaTuning].
##
## Exemplo:
## [codeblock]
## var diags := RegrasTl.new().validar(itens)
## [/codeblock]

const FAIXAS: Array[Dictionary] = [
	{"campo": "max_bytes_sessao", "min": 262144.0, "max": 16777216.0, "txt": "262144–16777216"},
	{"campo": "max_sessoes", "min": 5.0, "max": 100.0, "txt": "5–100"},
	{"campo": "orcamento_linha_ms", "min": 0.2, "max": 5.0, "txt": "0,2–5,0"},
	{"campo": "orcamento_passo_ms", "min": 1.0, "max": 8.0, "txt": "1,0–8,0"},
	{"campo": "casas_decimais_duracao", "min": 1.0, "max": 3.0, "txt": "1–3"},
]


func prefixo() -> StringName:
	return &"TL"


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var item := primeiro_da_classe(itens, "TelemetriaTuning")
	if item == null:
		return out
	var t := item.definicao as TelemetriaTuning
	for f: Dictionary in FAIXAS:
		var campo: String = f["campo"]
		var raw: Variant = t.get(campo)
		var v := float(raw)
		if v < float(f["min"]) - 1e-9 or v > float(f["max"]) + 1e-9 or not is_finite(v):
			out.append(Diagnostico.de_item(item, &"TL1", campo, raw,
				"TelemetriaTuning: %s %s fora da faixa %s" % [campo, str(raw), f["txt"]], Diagnostico.Nivel.AVISO))
	return out
