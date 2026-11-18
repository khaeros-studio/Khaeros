class_name RegrasTb
extends ValidadorDoDono
## TB1–TB10 (Tela de bênção e carta, erros de faixa; GDD tela-de-bencao-e-carta.md
## Tuning Knobs e GDD de Conteúdo R9): um erro por campo de [TelaBencaoTuning] fora da
## faixa, na ordem da tabela, com o texto
## [code]TelaBencaoTuning: <campo> <valor> fora da faixa <min>–<max>[/code].
##
## Exemplo:
## [codeblock]
## var diags := RegrasTb.new().validar(itens)
## [/codeblock]

const FAIXAS: Array[Dictionary] = [
	{"codigo": &"TB1", "campo": "trava_confirmar_ms", "min": 500.0, "max": 800.0, "txt": "500–800"},
	{"codigo": &"TB2", "campo": "trava_troca_ms", "min": 200.0, "max": 500.0, "txt": "200–500"},
	{"codigo": &"TB3", "campo": "entrada_s", "min": 0.3, "max": 0.45, "txt": "0,3–0,45"},
	{"codigo": &"TB4", "campo": "anim_troca_s", "min": 0.15, "max": 0.4, "txt": "0,15–0,4"},
	{"codigo": &"TB5", "campo": "anim_confirmar_s", "min": 0.3, "max": 0.6, "txt": "0,3–0,6"},
	{"codigo": &"TB6", "campo": "foco_escala", "min": 1.03, "max": 1.10, "txt": "1,03–1,10"},
	{"codigo": &"TB7", "campo": "foco_sobe_px", "min": 6.0, "max": 16.0, "txt": "6–16"},
	{"codigo": &"TB8", "campo": "valor_nao_focada", "min": 0.6, "max": 0.8, "txt": "0,6–0,8"},
	{"codigo": &"TB9", "campo": "intervalo_cartas_px", "min": 32.0, "max": 64.0, "txt": "32–64"},
	{"codigo": &"TB10", "campo": "tremor_botao_ms", "min": 0.0, "max": 200.0, "txt": "0–200"},
]


func prefixo() -> StringName:
	return &"TB"


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var item := primeiro_da_classe(itens, "TelaBencaoTuning")
	if item == null:
		return out
	var t := item.definicao as TelaBencaoTuning
	for f: Dictionary in FAIXAS:
		var campo: String = f["campo"]
		var raw: Variant = t.get(campo)
		var v := float(raw)
		var mn: float = f["min"]
		var mx: float = f["max"]
		if v < mn - 1e-9 or v > mx + 1e-9 or not is_finite(v):
			var val_str := str(raw).replace(".", ",") if typeof(raw) == TYPE_FLOAT else str(raw)
			out.append(Diagnostico.de_item(item, f["codigo"], campo, raw,
				"TelaBencaoTuning: %s %s fora da faixa %s" % [campo, val_str, f["txt"]]))
	return out
