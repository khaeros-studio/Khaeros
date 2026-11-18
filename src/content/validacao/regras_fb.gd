class_name RegrasFb
extends ValidadorDoDono
## FB1–FB3 (Feedback de combate, erros; GDD feedback-de-combate.md Tuning Knobs e GDD de
## Conteúdo R1/R9): faixas de [FeedbackTuning] e histerese dos limiares de degradação
## (FB3: [code]limiar_retorno <= limiar_degradacao - 0.05[/code],
## [code]retorno_nivel2 <= limiar_nivel2 - 0.05[/code],
## [code]limiar_nivel2 >= limiar_degradacao + 0.03[/code]).
##
## Exemplo:
## [codeblock]
## var diags := RegrasFb.new().validar(itens)
## [/codeblock]

const FAIXAS: Array[Dictionary] = [
	{"campo": "janela_soma_s", "min": 0.2, "max": 0.5, "txt": "0,2–0,5"},
	{"campo": "teto_numeros", "min": 4.0, "max": 8.0, "txt": "4–8"},
	{"campo": "limiar_degradacao", "min": 0.80, "max": 0.95, "txt": "0,80–0,95"},
	{"campo": "limiar_retorno", "min": 0.60, "max": 0.85, "txt": "0,60–0,85"},
	{"campo": "limiar_nivel2", "min": 0.92, "max": 0.99, "txt": "0,92–0,99"},
	{"campo": "retorno_nivel2", "min": 0.70, "max": 0.90, "txt": "0,70–0,90"},
	{"campo": "vozes_max_gancho", "min": 2.0, "max": 8.0, "txt": "2–8"},
	{"campo": "vozes_max_total", "min": 8.0, "max": 32.0, "txt": "8–32"},
	{"campo": "assenta_camara_s", "min": 0.5, "max": 2.0, "txt": "0,5–2,0"},
]
const MARGEM_HISTERESE: float = 0.05
const MARGEM_NIVEL2: float = 0.03


func prefixo() -> StringName:
	return &"FB"


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var item := primeiro_da_classe(itens, "FeedbackTuning")
	if item == null:
		return out
	var t := item.definicao as FeedbackTuning
	for f: Dictionary in FAIXAS:
		var campo: String = f["campo"]
		var raw: Variant = t.get(campo)
		var v := float(raw)
		if v < float(f["min"]) - 1e-9 or v > float(f["max"]) + 1e-9 or not is_finite(v):
			out.append(Diagnostico.de_item(item, &"FB1", campo, raw,
				"FeedbackTuning: %s %s fora da faixa %s" % [campo, str(raw), f["txt"]]))
	if t.limiar_retorno > t.limiar_degradacao - MARGEM_HISTERESE + 1e-9:
		out.append(Diagnostico.de_item(item, &"FB3", "limiar_retorno", t.limiar_retorno,
			"FeedbackTuning: limiar_retorno > limiar_degradacao - 0,05"))
	if t.retorno_nivel2 > t.limiar_nivel2 - MARGEM_HISTERESE + 1e-9:
		out.append(Diagnostico.de_item(item, &"FB3", "retorno_nivel2", t.retorno_nivel2,
			"FeedbackTuning: retorno_nivel2 > limiar_nivel2 - 0,05"))
	if t.limiar_nivel2 < t.limiar_degradacao + MARGEM_NIVEL2 - 1e-9:
		out.append(Diagnostico.de_item(item, &"FB3", "limiar_nivel2", t.limiar_nivel2,
			"FeedbackTuning: limiar_nivel2 < limiar_degradacao + 0,03"))
	return out
