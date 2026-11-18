class_name ValidadorPipelineVisual
extends RefCounted
## Validação completa do Pipeline Visual (VV1–VV17 e PV1–PV8 de suporte; GDD pipeline-visual.md
## §Validação do VisualTuning, ADR-0004, ADR-0011).
## Lógica pura, sem SceneTree nem RenderingServer.

const TETOS_GRUPOS_R9: Dictionary = {
	&"ambiente": 40,
	&"sombras_e_telegrafos": 54,
	&"entidades": 200,
	&"vfx": 64,
	&"passes": 6,
	&"ui": 80,
}

const TETOS_MEMORIA_MIB: Dictionary = {
	&"ambiente": 192,
	&"jogador_aliados": 64,
	&"inimigos_ou_chefe": 128,
	&"vfx": 64,
	&"ui": 48,
	&"luts_mascaras": 8,
}


static func validar_tuning(t: VisualTuning, incluir_vv13: bool = false) -> Array[Diagnostico]:
	var item := ItemDoCatalogo.new(&"tuning", "res://teste/tuning/visual_tuning.tres", 0, t)
	var diags: Array[Diagnostico] = RegrasVv.new().validar([item])
	if t.intervalo_tracejado_px < 2.0 * t.largura_tracejado_px - 1e-9 or t.largura_tracejado_px * (2.0 / 3.0) < 1.0 - 1e-9:
		diags.append(Diagnostico.de_item(item, &"VV7", "largura_tracejado_px", t.largura_tracejado_px,
			"VisualTuning: tracejado abaixo de 1 px em 720p ou intervalo < 2 * largura", Diagnostico.Nivel.AVISO))
	if incluir_vv13:
		for d in validar_orcamentos(TETOS_GRUPOS_R9, TETOS_MEMORIA_MIB):
			diags.append(d)
	return diags


static func validar_lut_perfil(largura: int, altura: int, formato: int, mipmaps: bool, repeat: bool, comprimida_perda: bool, ausente: bool = false) -> Array[StringName]:
	if ausente or largura != 1024 or altura != 32 or formato != Image.FORMAT_RGBA8 or mipmaps or repeat or comprimida_perda:
		return [&"VV4"]
	return []


static func validar_chao_lut(lut_img: Image, piso_profundidade: float, cor_escura: Color, cor_clara: Color = Color(-1, -1, -1)) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var c_lut := VisualMath.amostrar_lut(lut_img, cor_escura)
	var y_lin := VisualMath.luminancia_rec709(c_lut) * piso_profundidade
	var l_star := VisualMath.luminancia_para_l_star(y_lin)
	var tem_erro := false
	if l_star < 22.0 - 1e-6:
		out.append({"regra": &"VV3", "nivel": Diagnostico.Nivel.ERRO, "l_star": l_star})
		tem_erro = true
	elif l_star < 22.5 - 1e-6:
		out.append({"regra": &"VV3", "nivel": Diagnostico.Nivel.AVISO, "l_star": l_star})
	if not tem_erro and cor_clara.r >= 0.0:
		var c_clara_lut := VisualMath.amostrar_lut(lut_img, cor_clara)
		var l_clara := VisualMath.cor_para_l_star(c_clara_lut)
		if l_clara > 38.0 + 1e-6:
			out.append({"regra": &"VV3", "nivel": Diagnostico.Nivel.AVISO, "l_star": l_clara})
	return out


static func validar_telegrafo(forma: int, dims: Vector4, modo_crescimento: int, p: float, w: float, a: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var erro_vv8 := false
	if forma == 0: # circulo
		if dims.x <= 0.0 or modo_crescimento == 2:
			erro_vv8 = true
	elif forma == 1: # anel
		if dims.y < 0.0 or dims.z <= 0.0 or dims.y >= dims.z or modo_crescimento == 2:
			erro_vv8 = true
	elif forma == 2: # retangulo
		if dims.x <= 0.0 or dims.y <= 0.0:
			erro_vv8 = true
	elif forma == 3: # setor
		if dims.x <= 0.0 or dims.w <= 0.0 or dims.w >= PI:
			erro_vv8 = true
	if erro_vv8:
		out.append({"regra": &"VV8", "nivel": Diagnostico.Nivel.ERRO})
		return out # Precedência: VV8 suspende VV9 e VV10
	var d_max := VisualMathSdf.raio_interno_maximo(forma, dims)
	var d_util := d_max - w - a
	if d_util <= 0.0:
		out.append({"regra": &"VV9", "nivel": Diagnostico.Nivel.ERRO})
	elif d_util < 8.0:
		out.append({"regra": &"VV9", "nivel": Diagnostico.Nivel.AVISO})
	if p < 0.0 or p > 1.0 or (forma == 1 and is_zero_approx(dims.y)):
		out.append({"regra": &"VV10", "nivel": Diagnostico.Nivel.AVISO})
	return out


static func validar_orcamentos(grupos_dc: Dictionary = TETOS_GRUPOS_R9, grupos_mem_mib: Dictionary = TETOS_MEMORIA_MIB) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var dummy := ItemDoCatalogo.new(&"tuning", "res://teste/tuning/visual_tuning.tres", 0, VisualTuning.new())
	var soma_dc := 0
	for k: Variant in grupos_dc:
		soma_dc += int(grupos_dc[k])
	var reserva := 500 - soma_dc
	if soma_dc > 500:
		out.append(Diagnostico.de_item(dummy, &"VV12", "grupos_draw_calls", soma_dc,
			"VisualTuning: soma dos grupos de draw calls > 500"))
	elif reserva < 50:
		out.append(Diagnostico.de_item(dummy, &"VV12", "reserva_draw_calls", reserva,
			"VisualTuning: reserva de draw calls < 50", Diagnostico.Nivel.AVISO))
	var soma_mem := 0
	for k: Variant in grupos_mem_mib:
		soma_mem += int(grupos_mem_mib[k])
	if soma_mem > 448:
		out.append(Diagnostico.de_item(dummy, &"VV13", "memoria_textura_mib", soma_mem,
			"VisualTuning: soma dos tetos de memória (%d MiB) > alerta de 448 MiB" % soma_mem,
			Diagnostico.Nivel.AVISO))
	return out
