class_name RegrasAv
extends ValidadorDoDono
## AV7 e AV9 (Armas das Doutrinas; GDD armas-das-doutrinas.md Tuning Knobs e GDD de
## Conteúdo R9/R9-P): AV9 (erro de carga) para forma [code]chamado[/code] fora do slot
## [code]especial[/code], ou num [WeaponDef] cuja doutrina não é [code]pactos[/code], ou
## [code]chamado[/code] com [code]multiplicadores_combo[/code], [code]status[/code] ou
## [code]guarda_s[/code]; AV7 (aviso de faixa) para campos de [ArmasTuning] fora da
## faixa segura.
##
## Exemplo:
## [codeblock]
## var diags := RegrasAv.new().validar(itens)
## [/codeblock]

## Forma do Chamado (chave do registro formas_de_ataque).
const FORMA_CHAMADO := &"chamado"
## Doutrina que usa o Chamado (id de doutrina do GDD de Armas).
const DOUTRINA_DO_CHAMADO := &"pactos"


func prefixo() -> StringName:
	return &"AV"


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	for item in itens_do_tipo(itens, &"weapon"):
		var w := item.definicao as WeaponDef
		if w == null:
			continue
		if w.ataque != null and w.ataque.forma == FORMA_CHAMADO:
			out.append(_erro(item, "ataque.forma", "forma chamado fora do slot especial"))
		var e := w.especial
		if e == null or e.forma != FORMA_CHAMADO:
			continue
		if w.doutrina != DOUTRINA_DO_CHAMADO:
			out.append(_erro(item, "especial.forma", "chamado numa arma de doutrina %s" % w.doutrina))
		elif not e.multiplicadores_combo.is_empty() or e.status != &"" or e.guarda_s != 0.0:
			out.append(_erro(item, "especial", "chamado com multiplicadores_combo, status ou guarda_s"))
	var item_at := primeiro_da_classe(itens, "ArmasTuning")
	if item_at != null:
		var at := item_at.definicao as ArmasTuning
		if at.meta_paridade < 0.05 - 1e-9 or at.meta_paridade > 0.30 + 1e-9:
			out.append(_aviso_at(item_at, "meta_paridade", at.meta_paridade, "0,05–0,30"))
		if at.margem_fragil < 0 or at.margem_fragil > 5:
			out.append(_aviso_at(item_at, "margem_fragil", at.margem_fragil, "0–5"))
		if at.g_max_fragil < 1 or at.g_max_fragil > 6:
			out.append(_aviso_at(item_at, "g_max_fragil", at.g_max_fragil, "1–6"))
		if at.periodos_trava < 1 or at.periodos_trava > 4:
			out.append(_aviso_at(item_at, "periodos_trava", at.periodos_trava, "1–4"))
		if at.f_esp_min < 0.0 or at.f_esp_max > 1.0 or not (at.f_esp_min < at.f_esp_max):
			out.append(_aviso_at(item_at, "f_esp_min", at.f_esp_min, "0–1 (min < max)"))
		if at.vel_media_min < 342.0 - 1e-9 or at.vel_media_max > 423.0 + 1e-9 or not (at.vel_media_min < at.vel_media_max):
			out.append(_aviso_at(item_at, "vel_media_min", at.vel_media_min, "342–423 (min < max)"))
		if at.p_max < 0 or at.p_max > 20:
			out.append(_aviso_at(item_at, "p_max", at.p_max, "0–20"))
	return out


func _erro(item: ItemDoCatalogo, campo: String, msg: String) -> Diagnostico:
	return Diagnostico.de_item(item, &"AV9", campo, null, "%s: %s" % [rotulo(item), msg])


func _aviso_at(item: ItemDoCatalogo, campo: String, val: Variant, faixa: String) -> Diagnostico:
	return Diagnostico.de_item(item, &"AV7", campo, val, "ArmasTuning: %s %s fora da faixa %s" % [campo, str(val), faixa], Diagnostico.Nivel.AVISO)
