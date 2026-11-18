class_name VisualMath
extends RefCounted
## Espelho em CPU de F1 (LUT 32³), F2 (escurecimento por profundidade em luz linear),
## F5 (dessaturação da Bênção), `modo_impacto` (R1/R7) e inversão no CanvasGroup (R6).
## Puro e sem SceneTree (GDD pipeline-visual.md §Formulas, ADR-0011).

const COR_TINTA := Color(13.0 / 255.0, 14.0 / 255.0, 20.0 / 255.0, 1.0)       # #0D0E14
const COR_OSSO_MUNDO := Color(207.0 / 255.0, 198.0 / 255.0, 180.0 / 255.0, 1.0) # #CFC6B4
const COR_OSSO_PLENO := Color(230.0 / 255.0, 223.0 / 255.0, 207.0 / 255.0, 1.0) # #E6DFCF
const COR_ANEL_TEL := Color(1.0, 61.0 / 255.0, 174.0 / 255.0, 1.0)              # #FF3DAE
const COR_NUCLEO_TEL := Color(1.0, 211.0 / 255.0, 238.0 / 255.0, 1.0)           # #FFD3EE


static func canal_srgb_para_linear(c: float) -> float:
	if c <= 0.04045:
		return c / 12.92
	return pow((c + 0.055) / 1.055, 2.4)


static func canal_linear_para_srgb(y: float) -> float:
	var yl := maxf(0.0, y)
	if yl <= 0.0031308:
		return 12.92 * yl
	return 1.055 * pow(yl, 1.0 / 2.4) - 0.055


static func srgb_para_linear(c: Color) -> Vector3:
	return Vector3(
		canal_srgb_para_linear(c.r),
		canal_srgb_para_linear(c.g),
		canal_srgb_para_linear(c.b)
	)


static func linear_para_srgb(lin: Vector3, alpha: float = 1.0) -> Color:
	return Color(
		canal_linear_para_srgb(lin.x),
		canal_linear_para_srgb(lin.y),
		canal_linear_para_srgb(lin.z),
		alpha
	)


static func luminancia_rec709(c: Color) -> float:
	var lin := srgb_para_linear(c)
	return 0.2126 * lin.x + 0.7152 * lin.y + 0.0722 * lin.z


static func luminancia_para_l_star(y: float) -> float:
	var yl := maxf(0.0, y)
	if yl > 0.008856:
		return 116.0 * pow(yl, 1.0 / 3.0) - 16.0
	return 903.3 * yl


static func l_star_para_luminancia(l_star: float) -> float:
	if l_star > 8.0:
		return pow((l_star + 16.0) / 116.0, 3.0)
	return l_star / 903.3


static func cor_para_l_star(c: Color) -> float:
	return luminancia_para_l_star(luminancia_rec709(c))


static func cinza_srgb_de_l_star(l_star: float) -> Color:
	var y := l_star_para_luminancia(l_star)
	var s := canal_linear_para_srgb(y)
	return Color(s, s, s, 1.0)


## F1: coordenadas de amostragem manual na LUT 1024×32.
static func coordenadas_lut(c: Color) -> Dictionary:
	var r := clampf(c.r, 0.0, 1.0)
	var g := clampf(c.g, 0.0, 1.0)
	var b_val := clampf(c.b, 0.0, 1.0) * 31.0
	var s0 := int(floor(b_val))
	var s1 := mini(s0 + 1, 31)
	var t := b_val - float(s0)
	var u0 := (32.0 * float(s0) + 31.0 * r + 0.5) / 1024.0
	var u1 := (32.0 * float(s1) + 31.0 * r + 0.5) / 1024.0
	var v := (31.0 * g + 0.5) / 32.0
	return {
		"b": b_val,
		"s0": s0,
		"s1": s1,
		"t": t,
		"u0": u0,
		"u1": u1,
		"v": v,
	}


static func _amostrar_bilinear_fatia(img: Image, u_norm: float, v_norm: float) -> Vector3:
	var x := u_norm * 1024.0 - 0.5
	var y := v_norm * 32.0 - 0.5
	var x0 := clampi(int(floor(x)), 0, 1023)
	var x1 := clampi(x0 + 1, 0, 1023)
	var y0 := clampi(int(floor(y)), 0, 31)
	var y1 := clampi(y0 + 1, 0, 31)
	var fx := clampf(x - float(x0), 0.0, 1.0)
	var fy := clampf(y - float(y0), 0.0, 1.0)
	var c00 := img.get_pixel(x0, y0)
	var c10 := img.get_pixel(x1, y0)
	var c01 := img.get_pixel(x0, y1)
	var c11 := img.get_pixel(x1, y1)
	var top := Vector3(lerpf(c00.r, c10.r, fx), lerpf(c00.g, c10.g, fx), lerpf(c00.b, c10.b, fx))
	var bot := Vector3(lerpf(c01.r, c11.r, fx), lerpf(c01.g, c11.g, fx), lerpf(c01.b, c11.b, fx))
	return top.lerp(bot, fy)


## F1: amostra a LUT `img` (1024×32 RGBA8) reproduzindo o filtro bilinear do hardware em R/G e `mix` em B.
## Se `img` for null, opera como `lut_passagem` (devolve `c` exato em float).
static func amostrar_lut(img: Image, c: Color) -> Color:
	if img == null:
		return c
	var coords := coordenadas_lut(c)
	var c0 := _amostrar_bilinear_fatia(img, float(coords["u0"]), float(coords["v"]))
	var c1 := _amostrar_bilinear_fatia(img, float(coords["u1"]), float(coords["v"]))
	var m := c0.lerp(c1, float(coords["t"]))
	return Color(m.x, m.y, m.z, c.a)


static func aplicar_f1(c: Color, img: Image, forca: float) -> Color:
	if forca <= 0.0:
		return c
	var l := amostrar_lut(img, c)
	var f := clampf(forca, 0.0, 1.0)
	return Color(
		lerpf(c.r, l.r, f),
		lerpf(c.g, l.g, f),
		lerpf(c.b, l.b, f),
		c.a
	)


## F2: multiplicador `k = max(piso_profundidade, 1 - passo_profundidade * p)` em double.
static func fator_profundidade(p: int, passo_profundidade: float, piso_profundidade: float) -> float:
	if p <= 0:
		return 1.0
	return maxf(piso_profundidade, 1.0 - passo_profundidade * float(p))


static func k_min_chao(l_star_chao_min: float) -> float:
	return pow((22.0 + 16.0) / (l_star_chao_min + 16.0), 3.0)


static func aplicar_f2(c_lut: Color, k: float, recebe_profundidade: bool = true) -> Color:
	if not recebe_profundidade:
		return c_lut
	var lin := srgb_para_linear(c_lut) * k
	return linear_para_srgb(lin, c_lut.a)


## F5: Bênção — luma em linear, mix e valor no sRGB codificado.
static func aplicar_f5(c: Color, saturacao_bencao: float, valor_bencao: float) -> Color:
	var y := luminancia_rec709(c)
	var g := canal_linear_para_srgb(y)
	var r := lerpf(g, c.r, saturacao_bencao) * valor_bencao
	var gr := lerpf(g, c.g, saturacao_bencao) * valor_bencao
	var b := lerpf(g, c.b, saturacao_bencao) * valor_bencao
	return Color(r, gr, b, c.a)


## F8: ULP em float32 para T > 0.
static func ulp_float32(t: float) -> float:
	if t <= 0.0:
		return pow(2.0, -23.0)
	var e := floor(log(t) / log(2.0))
	return pow(2.0, e - 23.0)


static func para_float32(v: float) -> float:
	var arr := PackedFloat32Array([v])
	return float(arr[0])


## Espelho completo da tabela da R1/R7 por shader (`modo_impacto`: 0 normal, 1 recusa, 2 chefe, 3 reduzido).
static func avaliar_shader(
	shader_nome: StringName,
	cor_in: Color,
	lut_img: Image,
	k_profundidade: float,
	modo_bencao: bool,
	modo_impacto: int,
	tuning: VisualTuning,
	opcoes: Dictionary = {}
) -> Color:
	var recebe_prof: bool = bool(opcoes.get("recebe_profundidade", true))
	var papel: int = int(opcoes.get("papel", 1))
	var na_borda: bool = bool(opcoes.get("na_borda", false))
	var passada_tel: int = int(opcoes.get("passada", 0))
	var eh_ataque_inimigo: bool = bool(opcoes.get("eh_ataque_inimigo", false))
	var eh_mancha_abate: bool = bool(opcoes.get("eh_mancha_abate", false))
	var eh_numero_ou_letreiro: bool = bool(opcoes.get("eh_numero_ou_letreiro", false))

	match shader_nome:
		&"amb_sprite", &"amb_mascara":
			var usa_prof := recebe_prof if shader_nome == &"amb_sprite" else false
			var c := aplicar_f1(cor_in, lut_img, 1.0)
			c = aplicar_f2(c, k_profundidade, usa_prof)
			if modo_bencao:
				c = aplicar_f5(c, tuning.saturacao_bencao, tuning.valor_bencao)
			if modo_impacto == 1:
				return Color(COR_TINTA.r, COR_TINTA.g, COR_TINTA.b, cor_in.a)
			if modo_impacto == 2:
				return Color(COR_OSSO_PLENO.r, COR_OSSO_PLENO.g, COR_OSSO_PLENO.b, cor_in.a)
			if modo_impacto == 3:
				return aplicar_f5(c, 0.5, 0.78)
			return c
		&"amb_aditivo":
			if modo_impacto == 1 or modo_impacto == 2:
				return Color(0, 0, 0, 0)
			var c := aplicar_f1(cor_in, lut_img, 1.0)
			if modo_bencao:
				c = aplicar_f5(c, tuning.saturacao_bencao, tuning.valor_bencao)
			if modo_impacto == 3:
				c = aplicar_f5(c, 0.5, 0.78)
			return c
		&"char_sprite":
			var c := aplicar_f1(cor_in, lut_img, tuning.forca_grading_personagem)
			if modo_bencao:
				c = aplicar_f5(c, tuning.saturacao_bencao, tuning.valor_bencao)
			if modo_impacto == 1:
				if papel != 0 and na_borda:
					return Color(COR_OSSO_PLENO.r, COR_OSSO_PLENO.g, COR_OSSO_PLENO.b, 1.0)
				return Color(COR_TINTA.r, COR_TINTA.g, COR_TINTA.b, cor_in.a)
			if modo_impacto == 2:
				return Color(COR_TINTA.r, COR_TINTA.g, COR_TINTA.b, cor_in.a)
			if modo_impacto == 3:
				return aplicar_f5(c, 0.5, 0.85)
			return c
		&"char_grupo":
			if modo_impacto == 1:
				return Color(COR_OSSO_PLENO.r, COR_OSSO_PLENO.g, COR_OSSO_PLENO.b, cor_in.a)
			if modo_impacto == 2:
				return Color(COR_TINTA.r, COR_TINTA.g, COR_TINTA.b, cor_in.a)
			return cor_in
		&"tel_sdf":
			if passada_tel == 0:
				if modo_impacto == 1 or modo_impacto == 2:
					return Color(0, 0, 0, 0)
				return cor_in
			else:
				if modo_impacto == 1:
					return Color(COR_OSSO_PLENO.r, COR_OSSO_PLENO.g, COR_OSSO_PLENO.b, cor_in.a)
				if modo_impacto == 2:
					return Color(COR_TINTA.r, COR_TINTA.g, COR_TINTA.b, cor_in.a)
				return Color(COR_TINTA.r, COR_TINTA.g, COR_TINTA.b, cor_in.a)
		&"traco_sdf":
			if modo_impacto == 1 or modo_impacto == 2:
				return Color(0, 0, 0, 0)
			return cor_in
		&"vfx_sprite":
			if modo_bencao and eh_numero_ou_letreiro:
				return Color(0, 0, 0, 0)
			if modo_impacto == 1:
				if eh_ataque_inimigo:
					return Color(COR_OSSO_PLENO.r, COR_OSSO_PLENO.g, COR_OSSO_PLENO.b, cor_in.a)
				return Color(0, 0, 0, 0)
			if modo_impacto == 2:
				if eh_ataque_inimigo:
					return Color(COR_TINTA.r, COR_TINTA.g, COR_TINTA.b, cor_in.a)
				if eh_mancha_abate:
					return cor_in
				return Color(0, 0, 0, 0)
			return cor_in
		&"ui":
			return cor_in
	return cor_in


## AC-PV-67: Espelho da inversão no CanvasGroup sobre uma `Image` RGBA8.
static func aplicar_inversao_canvas_group(img_in: Image, contorno_silhueta_px: float, escala_traco: float) -> Image:
	var w := img_in.get_width()
	var h := img_in.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var raio_px := contorno_silhueta_px * escala_traco
	var r_ceil := int(ceil(raio_px))
	for y in h:
		for x in w:
			var c := img_in.get_pixel(x, y)
			if c.a > 0.0:
				out.set_pixel(x, y, Color(COR_TINTA.r, COR_TINTA.g, COR_TINTA.b, c.a))
			else:
				var achou := false
				for dy in range(-r_ceil, r_ceil + 1):
					for dx in range(-r_ceil, r_ceil + 1):
						var nx := x + dx
						var ny := y + dy
						if nx >= 0 and nx < w and ny >= 0 and ny < h:
							if sqrt(float(dx * dx + dy * dy)) <= raio_px + 1e-5:
								if img_in.get_pixel(nx, ny).a > 0.0:
									achou = true
									break
					if achou:
						break
				if achou:
					out.set_pixel(x, y, Color(COR_OSSO_MUNDO.r, COR_OSSO_MUNDO.g, COR_OSSO_MUNDO.b, 1.0))
				else:
					out.set_pixel(x, y, Color(0, 0, 0, 0))
	return out
