#ifndef COMUM_SDF_INCLUDED
#define COMUM_SDF_INCLUDED

float cov_sdf(float x, float aa) {
	return clamp(0.5 - x / max(aa, 1e-5), 0.0, 1.0);
}

float aa_canvas(float d) {
	return length(vec2(dFdx(d), dFdy(d)));
}

float sdf_circulo(vec2 q, float r) {
	return length(q) - r;
}

float sdf_anel(vec2 q, float r_int, float r_ext) {
	float r_m = 0.5 * (r_int + r_ext);
	float t_a = 0.5 * (r_ext - r_int);
	return abs(length(q) - r_m) - t_a;
}

float sdf_retangulo_ancorado(vec2 q, float L, float W) {
	vec2 q_c = q - vec2(0.5 * L, 0.0);
	vec2 v = abs(q_c) - vec2(0.5 * L, 0.5 * W);
	return length(max(v, vec2(0.0))) + min(max(v.x, v.y), 0.0);
}

float sdf_setor(vec2 q_in, float R, float alpha) {
	vec2 q = vec2(abs(q_in.y), q_in.x);
	vec2 ca = vec2(sin(alpha), cos(alpha));
	float l = length(q) - R;
	float m = length(q - ca * clamp(dot(q, ca), 0.0, R));
	return max(l, m * sign(ca.y * q.x - ca.x * q.y));
}

float sdf_segmento(vec2 p, vec2 a, vec2 b, float r) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-5), 0.0, 1.0);
	return length(pa - ba * h) - r;
}

#endif
