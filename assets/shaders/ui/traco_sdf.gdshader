shader_type canvas_item;
#include "res://assets/shaders/familias/sem_grading.gdshaderinc"
#include "res://assets/shaders/comum/sdf.gdshaderinc"
#include "res://assets/shaders/comum/tracejado.gdshaderinc"

uniform int modo_traco = 0;
uniform vec2 seg_a = vec2(0.0, 0.0);
uniform vec2 seg_b = vec2(200.0, 0.0);
uniform float largura_px = 2.0;
uniform float opacidade = 0.6;
uniform bool tracejado = false;
uniform bool estourado = false;
uniform float traco_px = 8.0;
uniform float intervalo_px = 6.0;
uniform float raio_anel = 150.0;

varying vec2 v_local;

void vertex() {
	v_local = VERTEX;
}

void fragment() {
	if (modo_impacto == 1 || modo_impacto == 2) {
		COLOR = vec4(0.0);
	} else if (modo_traco == 0) {
		float r = 0.5 * largura_px;
		float d = sdf_segmento(v_local, seg_a, seg_b, r);
		float aa = aa_canvas(d);
		float cov = cov_sdf(d, aa);
		float on = 1.0;
		if (tracejado) {
			vec2 ba = seg_b - seg_a;
			float comp = max(length(ba), 1.0);
			float s = clamp(dot(v_local - seg_a, ba / comp), 0.0, comp);
			on = fase_tracejado(s, comp, traco_px, intervalo_px, aa);
		}
		vec3 cor = estourado ? COR_OSSO_PLENO : COR_OSSO_MUNDO;
		COLOR = vec4(cor, cov * on * opacidade);
	} else if (modo_traco == 1) {
		float r_q = max(length(v_local), 1e-4);
		float d = abs(r_q - raio_anel) - 0.5 * largura_px;
		float aa = aa_canvas(d);
		float cov = cov_sdf(d, aa);
		float s = raio_anel * (atan(v_local.y, v_local.x) + 3.14159265);
		float grad_s = aa * (raio_anel / r_q);
		float on = fase_tracejado(s, 6.2831853 * raio_anel, traco_px, intervalo_px, grad_s);
		COLOR = vec4(COR_OSSO_MUNDO, cov * on * opacidade);
	} else if (modo_traco == 3) {
		float r_q = max(length(v_local), 1e-4);
		float d = abs(r_q - raio_anel) - 0.5 * largura_px;
		float aa = aa_canvas(d);
		float cov = cov_sdf(d, aa);
		COLOR = vec4(COR_OSSO_MUNDO, cov * opacidade);
	} else {
		vec4 tex = texture(TEXTURE, UV);
		COLOR = vec4(COR_OSSO_MUNDO, tex.a * opacidade);
	}
}
