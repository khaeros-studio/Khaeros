class_name RegrasVv
extends ValidadorDoDono
## VV1–VV17 (Pipeline visual; GDD pipeline-visual.md R12, §Validação do VisualTuning e
## GDD de Conteúdo R9): erros VV1, VV2, VV5, VV6, VV11, VV14, VV15 e aviso VV17 de
## faixa segura de [VisualTuning].
##
## Exemplo:
## [codeblock]
## var diags := RegrasVv.new().validar(itens)
## [/codeblock]

const FAIXAS_SEGURAS: Array[Dictionary] = [
	{"campo": "forca_grading_personagem", "min": 0.0, "max": 0.15},
	{"campo": "saturacao_bencao", "min": 0.15, "max": 0.25},
	{"campo": "valor_bencao", "min": 0.55, "max": 0.70},
	{"campo": "passo_profundidade", "min": 0.0, "max": 0.05},
	{"campo": "piso_profundidade", "min": 0.80, "max": 1.0},
	{"campo": "opacidade_max_feixes", "min": 0.0, "max": 0.20},
	{"campo": "ciclo_veio_s", "min": 2.0, "max": 60.0},
	{"campo": "amplitude_veio", "min": 0.0, "max": 0.10},
	{"campo": "duracao_flash_telegrafo_s", "min": 0.03, "max": 0.055},
	{"campo": "contorno_telegrafo_px", "min": 3.5, "max": 6.0},
	{"campo": "contorno_telegrafo_alto_px", "min": 3.5, "max": 8.0},
	{"campo": "traco_secundario_px", "min": 12.0, "max": 24.0},
	{"campo": "intervalo_secundario_px", "min": 6.0, "max": 16.0},
	{"campo": "largura_fio_px", "min": 1.5, "max": 3.0},
	{"campo": "opacidade_fio", "min": 0.4, "max": 0.8},
	{"campo": "ciclo_fio_estourado_s", "min": 0.4, "max": 1.0},
	{"campo": "raio_marca_virote_px", "min": 6.0, "max": 14.0},
	{"campo": "largura_anel_px", "min": 0.0, "max": 12.0},
	{"campo": "opacidade_base_telegrafo", "min": 0.0, "max": 0.4},
	{"campo": "largura_tracejado_px", "min": 1.5, "max": 2.5},
	{"campo": "traco_tracejado_px", "min": 4.0, "max": 16.0},
	{"campo": "intervalo_tracejado_px", "min": 3.0, "max": 12.0},
	{"campo": "contorno_silhueta_px", "min": 2.0, "max": 3.5},
	{"campo": "opacidade_oclusao", "min": 0.30, "max": 0.60},
	{"campo": "duracao_transicao_oclusao_s", "min": 0.016, "max": 0.2},
	{"campo": "margem_histerese_oclusao_px", "min": 0.0, "max": 16.0},
	{"campo": "duracao_wipe_s", "min": 0.2, "max": 0.6},
	{"campo": "duracao_fade_s", "min": 0.1, "max": 0.3},
	{"campo": "dt_max_apres", "min": 0.05, "max": 0.25},
	{"campo": "teto_drawcalls_passes", "min": 2.0, "max": 6.0},
]


func prefixo() -> StringName:
	return &"VV"


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var item := primeiro_da_classe(itens, "VisualTuning")
	if item == null:
		return out
	var t := item.definicao as VisualTuning
	var campos_com_erro: Array[String] = []
	if t.forca_grading_personagem < 0.0 or t.forca_grading_personagem > 0.15 + 1e-9:
		campos_com_erro.append("forca_grading_personagem")
		out.append(Diagnostico.de_item(item, &"VV1", "forca_grading_personagem", t.forca_grading_personagem,
			"VisualTuning: forca_grading_personagem fora de [0; 0,15]"))
	if t.piso_profundidade <= 0.0 or t.piso_profundidade > 1.0 or t.passo_profundidade < 0.0:
		campos_com_erro.append("piso_profundidade")
		out.append(Diagnostico.de_item(item, &"VV2", "piso_profundidade", t.piso_profundidade,
			"VisualTuning: piso_profundidade fora de (0, 1] ou passo_profundidade < 0"))
	if t.contorno_telegrafo_px <= 3.0 or t.contorno_telegrafo_alto_px < t.contorno_telegrafo_px or t.contorno_silhueta_px >= t.contorno_telegrafo_px:
		campos_com_erro.append("contorno_telegrafo_px")
		out.append(Diagnostico.de_item(item, &"VV5", "contorno_telegrafo_px", t.contorno_telegrafo_px,
			"VisualTuning: hierarquia de contorno violada (VV5)"))
	if t.largura_tracejado_px >= 3.0:
		campos_com_erro.append("largura_tracejado_px")
		out.append(Diagnostico.de_item(item, &"VV6", "largura_tracejado_px", t.largura_tracejado_px,
			"VisualTuning: largura_tracejado_px >= 3"))
	if t.duracao_transicao_oclusao_s <= 0.0 or t.opacidade_oclusao <= 0.0 or t.opacidade_oclusao >= 1.0:
		campos_com_erro.append("opacidade_oclusao")
		out.append(Diagnostico.de_item(item, &"VV11", "opacidade_oclusao", t.opacidade_oclusao,
			"VisualTuning: duracao_transicao_oclusao_s <= 0 ou opacidade_oclusao fora de (0, 1)"))
	if t.duracao_fade_s > 0.3 + 1e-9 or t.duracao_wipe_s <= 0.0 or t.dt_max_apres < 1.0 / 60.0 - 1e-9:
		campos_com_erro.append("duracao_fade_s")
		out.append(Diagnostico.de_item(item, &"VV14", "duracao_fade_s", t.duracao_fade_s,
			"VisualTuning: duracao_fade_s > 0,3, duracao_wipe_s <= 0 ou dt_max_apres < 1/60"))
	if t.ciclo_veio_s < 2.0 - 1e-9 or t.amplitude_veio > 0.10 + 1e-9 or t.opacidade_max_feixes > 0.20 + 1e-9:
		campos_com_erro.append("ciclo_veio_s")
		out.append(Diagnostico.de_item(item, &"VV15", "ciclo_veio_s", t.ciclo_veio_s,
			"VisualTuning: ciclo_veio_s < 2, amplitude_veio > 0,10 ou opacidade_max_feixes > 0,20"))
	for f: Dictionary in FAIXAS_SEGURAS:
		var campo: String = f["campo"]
		if campos_com_erro.has(campo):
			continue
		var v := float(t.get(campo))
		if v < float(f["min"]) - 1e-9 or v > float(f["max"]) + 1e-9 or not is_finite(v):
			out.append(Diagnostico.de_item(item, &"VV17", campo, t.get(campo),
				"VisualTuning: %s fora da faixa segura" % campo, Diagnostico.Nivel.AVISO))
	return out
