class_name RegrasHu
extends ValidadorDoDono
## HU1–HU17 (HUD, erros de faixa; GDD hud.md Tuning Knobs e GDD de Conteúdo R9/R9-P):
## um erro por campo de [HudTuning] fora da faixa, na ordem da tabela do HUD, com o
## texto [code]HudTuning: <campo> <valor> fora da faixa <min>–<max>[/code].
##
## Exemplo:
## [codeblock]
## var diags := RegrasHu.new().validar(itens)
## [/codeblock]

const FAIXAS: Array[Dictionary] = [
	{"codigo": &"HU1", "campo": "vida_por_segmento", "min": 5.0, "max": 20.0, "txt": "5–20"},
	{"codigo": &"HU2", "campo": "segmento_px", "min": 24.0, "max": 40.0, "txt": "24–40"},
	{"codigo": &"HU3", "campo": "barra_max_frac", "min": 0.20, "max": 0.30, "txt": "0,20–0,30"},
	{"codigo": &"HU4", "campo": "vida_baixa_pct", "min": 0.15, "max": 0.35, "txt": "0,15–0,35"},
	{"codigo": &"HU5", "campo": "vida_baixa_histerese", "min": 0.02, "max": 0.10, "txt": "0,02–0,10"},
	{"codigo": &"HU6", "campo": "vinheta_max_borda", "min": 0.0, "max": 0.08, "txt": "0–0,08"},
	{"codigo": &"HU7", "campo": "vinheta_opacidade_max", "min": 0.0, "max": 0.40, "txt": "0–0,40"},
	{"codigo": &"HU8", "campo": "janela_ganho_s", "min": 0.5, "max": 3.0, "txt": "0,5–3"},
	{"codigo": &"HU9", "campo": "fio_visivel_s", "min": 1.0, "max": 4.0, "txt": "1–4"},
	{"codigo": &"HU10", "campo": "largura_fio", "min": 32.0, "max": 72.0, "txt": "32–72"},
	{"codigo": &"HU11", "campo": "fio_elite_escala", "min": 1.0, "max": 2.0, "txt": "1–2"},
	{"codigo": &"HU12", "campo": "esquiva_tremor_ms", "min": 0.0, "max": 200.0, "txt": "0–200"},
	{"codigo": &"HU13", "campo": "fade_estado_s", "min": 0.1, "max": 0.3, "txt": "0,1–0,3"},
	{"codigo": &"HU14", "campo": "margem_segura_px", "min": 24.0, "max": 64.0, "txt": "24–64"},
	{"codigo": &"HU15", "campo": "pacto_tremor_px", "min": 1.0, "max": 8.0, "txt": "1–8"},
	{"codigo": &"HU16", "campo": "pacto_tremor_s", "min": 0.05, "max": 0.40, "txt": "0.05–0.40"},
	{"codigo": &"HU17", "campo": "pacto_intervalo_px", "min": 4.0, "max": 24.0, "txt": "4–24"},
]


func prefixo() -> StringName:
	return &"HU"


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var item := primeiro_da_classe(itens, "HudTuning")
	if item == null:
		return out
	var t := item.definicao as HudTuning
	for f: Dictionary in FAIXAS:
		var campo: String = f["campo"]
		var raw: Variant = t.get(campo)
		var v := float(raw)
		var mn: float = f["min"]
		var mx: float = f["max"]
		if v < mn - 1e-9 or v > mx + 1e-9 or not is_finite(v):
			var codigo: StringName = f["codigo"]
			var val_str := str(raw) if codigo == &"HU16" else (str(raw).replace(".", ",") if typeof(raw) == TYPE_FLOAT else str(raw))
			out.append(Diagnostico.de_item(item, codigo, campo, raw,
				"HudTuning: %s %s fora da faixa %s" % [campo, val_str, f["txt"]]))
	return out
