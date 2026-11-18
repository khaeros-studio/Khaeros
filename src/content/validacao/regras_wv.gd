class_name RegrasWv
extends ValidadorDoDono
## WV1–WV11 (Câmaras e ondas; GDD camaras-e-ondas.md §Validação e GDD de Conteúdo R9):
## WV1–WV4, WV11 (erros); WV5–WV10 (avisos). WV8 avisa na 2ª passada (e na 1ª) se
## [code]ArmasTuning.p_max[/code] divergir do [code]p_max[/code] derivado da [RegionDef].
##
## Exemplo:
## [codeblock]
## var diags := RegrasWv.new().validar(itens)
## [/codeblock]

const CAMARA_LARGURA_MIN: float = 1920.0
const CAMARA_LARGURA_MAX: float = 2880.0
const CAMARA_ALTURA_MIN: float = 1080.0
const CAMARA_ALTURA_MAX: float = 1620.0


func prefixo() -> StringName:
	return &"WV"


func precisa_da_segunda_passada() -> bool:
	return true


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	for item_w in itens_do_tipo(itens, &"wave_rules"):
		var w := item_w.definicao as WaveRules
		if w == null:
			continue
		var limites_crescentes := w.ondas_limites.size() >= 2 and w.ondas_limites[1] > w.ondas_limites[0]
		if w.orcamento_base <= 0.0 or w.max_inimigos_onda < 1 or not limites_crescentes:
			out.append(Diagnostico.de_item(item_w, &"WV1", "wave_rules", w.orcamento_base,
				"WaveRules: orcamento_base <= 0, max_inimigos_onda < 1 ou ondas_limites não crescente"))
		if w.orcamento_base < 2.0 or w.orcamento_base > 5.0 or w.orcamento_por_prof < 0.5 or w.orcamento_por_prof > 1.5 or w.orcamento_por_regiao < 1.0 or w.orcamento_por_regiao > 3.0 or w.max_inimigos_onda < 6 or w.max_inimigos_onda > 12 or w.intervalo_onda_s < 0.0 or w.intervalo_onda_s > 1.0:
			out.append(Diagnostico.de_item(item_w, &"WV9", "wave_rules", null,
				"WaveRules: campo fora da faixa de design", Diagnostico.Nivel.AVISO))
	var item_rt := primeiro_da_classe(itens, "RoomTuning")
	if item_rt != null:
		var rt := item_rt.definicao as RoomTuning
		if rt.spawn_candidatos < 1 or rt.obstaculo_tentativas < 1:
			out.append(Diagnostico.de_item(item_rt, &"WV1", "room_tuning", rt.spawn_candidatos,
				"RoomTuning: spawn_candidatos < 1 ou obstaculo_tentativas < 1"))
		if rt.camara_largura_px < CAMARA_LARGURA_MIN or rt.camara_largura_px > CAMARA_LARGURA_MAX or rt.camara_altura_px < CAMARA_ALTURA_MIN or rt.camara_altura_px > CAMARA_ALTURA_MAX:
			out.append(Diagnostico.de_item(item_rt, &"WV2", "camara_largura_px", rt.camara_largura_px,
				"RoomTuning: tamanho da câmara fora de 1920x1080–2880x1620"))
		if rt.spawn_dist_jogador_px > 0.5 * rt.camara_altura_px:
			out.append(Diagnostico.de_item(item_rt, &"WV6", "spawn_dist_jogador_px", rt.spawn_dist_jogador_px,
				"RoomTuning: spawn_dist_jogador_px > 0,5 * altura da câmara", Diagnostico.Nivel.AVISO))
		if rt.spawn_dist_acuada_px > rt.spawn_dist_jogador_px:
			out.append(Diagnostico.de_item(item_rt, &"WV10", "spawn_dist_acuada_px", rt.spawn_dist_acuada_px,
				"RoomTuning: spawn_dist_acuada_px > spawn_dist_jogador_px", Diagnostico.Nivel.AVISO))
	out.append_array(_validar_cruzadas(itens))
	return out


func validar_segunda_passada(itens: Array[ItemDoCatalogo], _catalogo: Catalogo) -> Array[Diagnostico]:
	return _validar_cruzadas(itens)


func _validar_cruzadas(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var item_run := primeiro_da_classe(itens, "RunTuning")
	var item_armas := primeiro_da_classe(itens, "ArmasTuning")
	for item_reg in itens_do_tipo(itens, &"region"):
		var reg := item_reg.definicao as RegionDef
		if reg == null:
			continue
		var n_jog := reg.camaras.size()
		if item_run != null:
			var rt := item_run.definicao as RunTuning
			if rt.camaras_jogaveis.has(reg.id):
				n_jog = int(rt.camaras_jogaveis[reg.id])
		var n_efetivo := mini(maxi(0, n_jog), reg.camaras.size())
		var n_combate := 0
		var indices_chefe: Array[int] = []
		for idx in n_efetivo:
			if reg.camaras[idx] == &"combate":
				n_combate += 1
			elif reg.camaras[idx] == &"chefe":
				indices_chefe.append(idx)
		if indices_chefe.size() > 1 or (indices_chefe.size() == 1 and indices_chefe[0] != n_efetivo - 1):
			out.append(Diagnostico.de_item(item_reg, &"WV11", "camaras", indices_chefe,
				"RegionDef: câmara chefe fora do último índice jogável ou mais de uma"))
		if item_armas != null and n_combate > 0:
			var at := item_armas.definicao as ArmasTuning
			var p_max_reg := n_combate - 1
			if at.p_max != p_max_reg:
				out.append(Diagnostico.de_item(item_armas, &"WV8", "p_max", at.p_max,
					"ArmasTuning: p_max %d diverge do p_max %d da RegionDef %s" % [at.p_max, p_max_reg, reg.id],
					Diagnostico.Nivel.AVISO))
	return out
