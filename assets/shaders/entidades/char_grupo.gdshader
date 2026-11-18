shader_type canvas_item;
render_mode unshaded;
#include "res://assets/shaders/familias/char_tint.gdshaderinc"
#include "res://assets/shaders/comum/tracejado.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform bool inversao_ativa = false;
uniform bool contorno_invuln_ativo = false;
uniform float contorno_silhueta_px = 3.0;
uniform float largura_tracejado_px = 1.75;
uniform float traco_tracejado_px = 8.0;
uniform float intervalo_tracejado_px = 6.0;
uniform float r_ref = 45.0;

void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}
	if (modo_impacto == 1) {
		COLOR = vec4(COR_OSSO_PLENO, c.a);
	} else if (modo_impacto == 2) {
		COLOR = vec4(COR_TINTA, c.a);
	} else if (inversao_ativa) {
		if (c.a > 0.01) {
			COLOR = vec4(COR_TINTA, c.a);
		} else {
			float r_px = contorno_silhueta_px * escala_traco;
			float max_a = 0.0;
			for (int i = 0; i < 8; i++) {
				float ang = float(i) * 0.78539816;
				vec2 off = vec2(cos(ang), sin(ang)) * r_px * SCREEN_PIXEL_SIZE;
				max_a = max(max_a, textureLod(screen_texture, SCREEN_UV + off, 0.0).a);
			}
			COLOR = vec4(COR_OSSO_MUNDO, max_a);
		}
	} else if (contorno_invuln_ativo && c.a <= 0.01) {
		float r_px = largura_tracejado_px * escala_traco;
		float max_a = 0.0;
		for (int i = 0; i < 8; i++) {
			float ang = float(i) * 0.78539816;
			vec2 off = vec2(cos(ang), sin(ang)) * r_px * SCREEN_PIXEL_SIZE;
			max_a = max(max_a, textureLod(screen_texture, SCREEN_UV + off, 0.0).a);
		}
		vec2 q_corpo = (SCREEN_UV - vec2(0.5)) / max(SCREEN_PIXEL_SIZE.x, 1e-5);
		float s = r_ref * (atan(q_corpo.y, q_corpo.x) + 3.14159265);
		float on = fase_tracejado(s, 6.2831853 * r_ref, traco_tracejado_px, intervalo_tracejado_px, 1.0);
		COLOR = vec4(COR_OSSO_MUNDO, max_a * on);
	} else {
		COLOR = c * COLOR;
	}
}
