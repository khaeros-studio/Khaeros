shader_type canvas_item;
#include "res://assets/shaders/familias/sem_grading.gdshaderinc"
#include "res://assets/shaders/comum/sdf.gdshaderinc"
#include "res://assets/shaders/comum/tracejado.gdshaderinc"

uniform int passada = 0; // 0 = preenchimento (z -5), 1 = contorno (z 5)
uniform int forma = 0; // 0 = circulo, 1 = anel, 2 = retangulo, 3 = setor
uniform vec4 dims = vec4(120.0, 60.0, 80.0, 0.78539816);
uniform float p = 0.5;
uniform int modo_crescimento = 0;
uniform int estado = 0;
uniform bool flash_aceito = true;
uniform int alvo_faccao = 0; // 0 = JOGADOR, 1 = ALIADO/MALDICAO, 2 = ACUADA
uniform float contorno_secundario_raio = 0.0;
uniform float traco_secundario_px = 16.0;
uniform float intervalo_secundario_px = 10.0;
uniform float contorno_px = 4.0;
uniform float largura_anel_px = 6.0;
uniform float opacidade_base_telegrafo = 0.25;
uniform float d_max = 120.0;
uniform float opacidade_estado = 1.0;

varying vec2 v_local;

void vertex() {
	v_local = VERTEX;
}

float calcular_d(vec2 q) {
	if (forma == 0) {
		return sdf_circulo(q, dims.x);
	} else if (forma == 1) {
		return sdf_anel(q, dims.y, dims.z);
	} else if (forma == 2) {
		return sdf_retangulo_ancorado(q, dims.x, dims.y);
	} else {
		return sdf_setor(q, dims.x, dims.w);
	}
}

void fragment() {
	float d = calcular_d(v_local);
	float aa = aa_canvas(d);
	float w = contorno_px;
	float a = largura_anel_px;

	if (passada == 1) {
		float alpha_c = cov_sdf(d, aa) - cov_sdf(d + w, aa);
		vec3 cor_c = COR_TINTA;
		if (alvo_faccao != 0) {
			float r_q = max(length(v_local), 1e-4);
			float s = r_q * (atan(v_local.y, v_local.x) + 3.14159265);
			float on = fase_tracejado(s, 6.2831853 * max(dims.x, 30.0), traco_secundario_px, intervalo_secundario_px, aa);
			alpha_c *= on;
			cor_c = COR_ANEL_TEL;
		}
		if (contorno_secundario_raio > 0.0 && estado != 1) {
			float d_sec = sdf_circulo(v_local, contorno_secundario_raio);
			float aa_sec = aa_canvas(d_sec);
			float alpha_sec = cov_sdf(d_sec, aa_sec) - cov_sdf(d_sec + w, aa_sec);
			float r_q = max(length(v_local), 1e-4);
			float s_sec = contorno_secundario_raio * (atan(v_local.y, v_local.x) + 3.14159265);
			float on_sec = fase_tracejado(s_sec, 6.2831853 * contorno_secundario_raio, traco_secundario_px, intervalo_secundario_px, aa_sec * (contorno_secundario_raio / r_q));
			alpha_sec *= on_sec;
			if (alpha_sec > alpha_c) {
				alpha_c = alpha_sec;
				cor_c = COR_ANEL_TEL;
			}
		}
		if (modo_impacto == 1) {
			cor_c = COR_OSSO_PLENO;
		} else if (modo_impacto == 2) {
			cor_c = COR_TINTA;
		}
		COLOR = vec4(cor_c, clamp(alpha_c * opacidade_estado, 0.0, 1.0));
	} else {
		if (modo_impacto == 1 || modo_impacto == 2) {
			COLOR = vec4(0.0);
		} else {
			float h = -d - w;
			float alpha_a = cov_sdf(d + w, aa) - cov_sdf(d + w + a, aa);
			float h_prime = h - a;
			float d_util = max(d_max - w - a, 1.0);
			float cov_g = 0.0;
			if (p <= 0.0) {
				cov_g = 0.0;
			} else if (p >= 1.0) {
				cov_g = 1.0;
			} else {
				float g = 0.0;
				if (modo_crescimento == 0) {
					g = h_prime - p * d_util;
				} else if (modo_crescimento == 1) {
					if (forma == 1) {
						g = (1.0 - p) * d_util - h_prime;
					} else {
						vec2 q_c = v_local;
						if (forma == 2) {
							q_c = v_local - vec2(0.5 * dims.x, 0.0);
						} else if (forma == 3) {
							float sin_a = max(sin(dims.w), 1e-4);
							q_c = v_local - vec2((w + a) / sin_a, 0.0);
						}
						float d_n = calcular_d(q_c / p) + w + a;
						g = p * d_n;
					}
				} else {
					g = (v_local.x - w - a) - p * max(dims.x - 2.0 * w - 2.0 * a, 1.0);
				}
				cov_g = cov_sdf(g, aa);
			}
			float alpha_n = cov_sdf(a - h, aa) * mix(opacidade_base_telegrafo, 1.0, cov_g);
			float alpha_f = clamp(alpha_a + alpha_n, 0.0, 1.0);
			vec3 cor_f = (alpha_a * COR_ANEL_TEL + alpha_n * COR_NUCLEO_TEL) / max(alpha_f, 1e-5);
			if (estado == 1 && flash_aceito) {
				cor_f = COR_OSSO_PLENO;
			}
			COLOR = vec4(cor_f, alpha_f * opacidade_estado);
		}
	}
}
