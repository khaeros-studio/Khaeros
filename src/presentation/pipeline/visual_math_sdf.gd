class_name VisualMathSdf
extends RefCounted
## Espelho em CPU de F3 (escala do traço), F4 (SDF de telégrafo, raio interno, zonas e crescimento)
## e F7 (fase do tracejado com derivada analítica).
## Puro e sem SceneTree (GDD pipeline-visual.md §F3, §F4, §F7; ADR-0011).

enum Forma {
	CIRCULO = 0,
	ANEL = 1,
	RETANGULO = 2,
	SETOR = 3,
}

enum ModoCrescimento {
	BORDA_AO_CENTRO = 0,
	CENTRO_A_BORDA = 1,
	AO_LONGO_DO_EIXO = 2,
}


## F3: `s_tela = min(W / 1920, H / 1080)`.
static func s_tela(w_janela: int, h_janela: int) -> float:
	return minf(float(w_janela) / 1920.0, float(h_janela) / 1080.0)


static func escala_traco(w_janela: int, h_janela: int, z_camera: float = 1.0) -> float:
	return s_tela(w_janela, h_janela) * z_camera


static func px_fisico(w_canvas: float, w_janela: int, h_janela: int, z_camera: float = 1.0) -> float:
	return w_canvas * escala_traco(w_janela, h_janela, z_camera)


static func aa_de_janela(w_janela: int, h_janela: int, z_camera: float = 1.0) -> float:
	return 1.0 / maxf(escala_traco(w_janela, h_janela, z_camera), 1e-6)


static func fit_margin_canvas_group(largura_tracejado_px: float, contorno_silhueta_px: float, esc_traco: float) -> float:
	return (maxf(largura_tracejado_px, contorno_silhueta_px) + 1.0) * esc_traco


static func cov(x: float, aa: float) -> float:
	return clampf(0.5 - x / maxf(aa, 1e-6), 0.0, 1.0)


static func para_espaco_local(pos: Vector2, origem: Vector2, rot: float) -> Vector2:
	return (pos - origem).rotated(-rot)


## F4: SDFs com d < 0 dentro.
## `dims`:
## - CIRCULO: x = r
## - ANEL: y = r_int, z = r_ext
## - RETANGULO: x = L, y = W (ancorado no meio do lado do atacante em (0,0), eixo +x)
## - SETOR: x = R, w = alpha (meio-ângulo em radianos, eixo +x)
static func sdf(forma: int, q: Vector2, dims: Vector4) -> float:
	match forma:
		Forma.CIRCULO:
			return q.length() - dims.x
		Forma.ANEL:
			var r_m := 0.5 * (dims.y + dims.z)
			var t_a := 0.5 * (dims.z - dims.y)
			return absf(q.length() - r_m) - t_a
		Forma.RETANGULO:
			var l := dims.x
			var w := dims.y
			var q_c := q - Vector2(0.5 * l, 0.0)
			var v := Vector2(absf(q_c.x), absf(q_c.y)) - Vector2(0.5 * l, 0.5 * w)
			var v_pos := Vector2(maxf(v.x, 0.0), maxf(v.y, 0.0))
			return v_pos.length() + minf(maxf(v.x, v.y), 0.0)
		Forma.SETOR:
			var r := dims.x
			var alpha := dims.w
			var qs := Vector2(absf(q.y), q.x)
			var ca := Vector2(sin(alpha), cos(alpha))
			var l_d := qs.length() - r
			var proj := clampf(qs.dot(ca), 0.0, r)
			var m := (qs - ca * proj).length()
			var sgn := 1.0 if (ca.y * qs.x - ca.x * qs.y) >= 0.0 else -1.0
			return maxf(l_d, m * sgn)
	return 0.0


## F4: Raio interno máximo D.
static func raio_interno_maximo(forma: int, dims: Vector4) -> float:
	match forma:
		Forma.CIRCULO:
			return dims.x
		Forma.ANEL:
			return 0.5 * (dims.z - dims.y)
		Forma.RETANGULO:
			return 0.5 * minf(dims.x, dims.y)
		Forma.SETOR:
			var r := dims.x
			var alpha := dims.w
			if alpha <= PI * 0.5:
				var sa := sin(alpha)
				return r * sa / (1.0 + sa)
			return 0.5 * r
	return 0.0


## F4: Frente de crescimento g (sem os atalhos p=0 e p>=1, para permitir testar AC-PV-23).
static func calcular_g(forma: int, modo: int, q: Vector2, dims: Vector4, p: float, w: float = 4.0, a: float = 6.0) -> float:
	var d := sdf(forma, q, dims)
	var h := -d - w
	var h_prime := h - a
	var d_max := raio_interno_maximo(forma, dims)
	var d_util := d_max - w - a
	var modo_efetivo := modo
	if forma == Forma.SETOR and modo == ModoCrescimento.AO_LONGO_DO_EIXO:
		modo_efetivo = ModoCrescimento.CENTRO_A_BORDA
	match modo_efetivo:
		ModoCrescimento.BORDA_AO_CENTRO:
			return h_prime - p * d_util
		ModoCrescimento.CENTRO_A_BORDA:
			if forma == Forma.ANEL:
				return (1.0 - p) * d_util - h_prime
			var p_safe := maxf(p, 1e-6)
			var ancora := Vector2.ZERO
			if forma == Forma.RETANGULO:
				ancora = Vector2(0.5 * dims.x, 0.0)
			elif forma == Forma.SETOR:
				var sa := maxf(sin(dims.w), 1e-6)
				ancora = Vector2((w + a) / sa, 0.0)
			var q_c := q - ancora
			var q_scaled := ancora + q_c / p_safe
			var d_n := sdf(forma, q_scaled, dims) + w + a
			return p_safe * d_n
		ModoCrescimento.AO_LONGO_DO_EIXO:
			var l := dims.x
			return (q.x - w - a) - p * (l - 2.0 * w - 2.0 * a)
	return 0.0


## F4: Avalia coberturas e cor das duas passadas num ponto local `q`.
static func avaliar_ponto_telegrafo(
	forma: int,
	modo: int,
	q: Vector2,
	dims: Vector4,
	p_in: float,
	aa: float,
	w: float = 4.0,
	a: float = 6.0,
	opacidade_base: float = 0.25
) -> Dictionary:
	var p := clampf(p_in, 0.0, 1.0)
	var d := sdf(forma, q, dims)
	var h := -d - w
	var h_prime := h - a
	var alpha_c := cov(d, aa) - cov(d + w, aa)
	var alpha_a := cov(d + w, aa) - cov(d + w + a, aa)
	var cov_g := 0.0
	var g_val := 0.0
	if p <= 0.0:
		cov_g = 0.0
		g_val = 1.0
	elif p >= 1.0:
		cov_g = 1.0
		g_val = calcular_g(forma, modo, q, dims, 1.0, w, a)
	else:
		g_val = calcular_g(forma, modo, q, dims, p, w, a)
		cov_g = cov(g_val, aa)
	var alpha_n := cov(a - h, aa) * lerpf(opacidade_base, 1.0, cov_g)
	var alpha_f := alpha_a + alpha_n
	var denom := maxf(alpha_f, 1e-5)
	var c_anel := VisualMath.COR_ANEL_TEL
	var c_nucleo := VisualMath.COR_NUCLEO_TEL
	var r := (alpha_a * c_anel.r + alpha_n * c_nucleo.r) / denom
	var gr := (alpha_a * c_anel.g + alpha_n * c_nucleo.g) / denom
	var b := (alpha_a * c_anel.b + alpha_n * c_nucleo.b) / denom
	return {
		"d": d,
		"h": h,
		"h_prime": h_prime,
		"g": g_val,
		"cov_g": cov_g,
		"alpha_c": alpha_c,
		"alpha_a": alpha_a,
		"alpha_n": alpha_n,
		"alpha_f": alpha_f,
		"cor_f": Color(r, gr, b, alpha_f),
		"cor_255": Vector3(r * 255.0, gr * 255.0, b * 255.0),
	}


## F7: Parâmetros do tracejado periódico ao longo de um perímetro.
static func parametros_tracejado(perimetro: float, traco_px: float = 8.0, intervalo_px: float = 6.0) -> Dictionary:
	var p_base := traco_px + intervalo_px
	var n := maxi(1, int(round(perimetro / p_base)))
	var p_aj := perimetro / float(n)
	var r_t := traco_px / p_base
	return {
		"P": p_base,
		"n": n,
		"P_aj": p_aj,
		"r_t": r_t,
		"traco_aj": p_aj * r_t,
		"intervalo_aj": p_aj * (1.0 - r_t),
		"aviso_vv7": perimetro < 3.0 * p_base,
	}


## F7: Derivada analítica |∇s| no círculo/anel (`r / |q|`) ou retângulo (`1.0`).
static func grad_s_analitico_circulo(r: float, q: Vector2) -> float:
	return r / maxf(q.length(), 1e-6)


static func s_circulo(r: float, q: Vector2) -> float:
	return r * (atan2(q.y, q.x) + PI)


## F7: Avalia `on` ∈ [0, 1] para posição de arco `s`, perímetro e derivada analítica `grad_s`.
static func avaliar_tracejado(
	s: float,
	perimetro: float,
	aa: float,
	grad_s: float = 1.0,
	traco_px: float = 8.0,
	intervalo_px: float = 6.0
) -> Dictionary:
	var p_info := parametros_tracejado(perimetro, traco_px, intervalo_px)
	var p_aj: float = p_info["P_aj"]
	var r_t: float = p_info["r_t"]
	var razao: float = s / p_aj
	var phi: float = razao - floor(razao)
	var u: float = phi - 0.5 * r_t + 0.5
	var delta: float = absf((u - floor(u)) - 0.5)
	var aa_phi: float = aa * grad_s / p_aj
	var on: float = cov(delta - 0.5 * r_t, aa_phi)
	return {
		"phi": phi,
		"delta": delta,
		"aa_phi": aa_phi,
		"on": on,
		"P_aj": p_aj,
		"n": p_info["n"],
	}
