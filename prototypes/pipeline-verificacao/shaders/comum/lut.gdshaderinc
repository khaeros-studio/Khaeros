#ifndef COMUM_LUT_INCLUDED
#define COMUM_LUT_INCLUDED

vec3 srgb_para_linear(vec3 c) {
	vec3 lo = c / 12.92;
	vec3 hi = pow((c + vec3(0.055)) / 1.055, vec3(2.4));
	return mix(lo, hi, step(vec3(0.04045), c));
}

vec3 linear_para_srgb(vec3 y) {
	vec3 lo = y * 12.92;
	vec3 hi = 1.055 * pow(max(y, vec3(0.0)), vec3(1.0 / 2.4)) - vec3(0.055);
	return mix(lo, hi, step(vec3(0.0031308), y));
}

float luminancia_rec709(vec3 c_srgb) {
	vec3 lin = srgb_para_linear(c_srgb);
	return dot(lin, vec3(0.2126, 0.7152, 0.0722));
}

vec3 amostrar_lut_manual(sampler2D tex_lut, vec3 c) {
	vec3 cl = clamp(c, 0.0, 1.0);
	float b = cl.b * 31.0;
	float s0 = floor(b);
	float s1 = min(s0 + 1.0, 31.0);
	float t = b - s0;
	float u0 = (32.0 * s0 + 31.0 * cl.r + 0.5) / 1024.0;
	float u1 = (32.0 * s1 + 31.0 * cl.r + 0.5) / 1024.0;
	float v = (31.0 * cl.g + 0.5) / 32.0;
	vec3 c0 = texture(tex_lut, vec2(u0, v)).rgb;
	vec3 c1 = texture(tex_lut, vec2(u1, v)).rgb;
	return mix(c0, c1, t);
}

vec3 aplicar_bencao_f5(vec3 c, float sat_bencao, float val_bencao) {
	float y = luminancia_rec709(c);
	float g = linear_para_srgb(vec3(y)).x;
	return mix(vec3(g), c, sat_bencao) * val_bencao;
}

#endif
