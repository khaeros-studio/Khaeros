shader_type canvas_item;
#include "res://assets/shaders/familias/char_tint.gdshaderinc"

uniform int papel = 1; // 0 = jogador, 1 = inimigo, 2 = aliado / maldicao
uniform float flash = 0.0;
uniform float forca_grading_personagem = 0.15;
uniform bool eh_elite = false;
uniform bool abalo_ativo = false;
uniform float contorno_silhueta_px = 3.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	if (modo_impacto == 1 && papel != 0 && tex.a <= 0.01) {
		float max_a = 0.0;
		for (int i = 0; i < 8; i++) {
			float ang = float(i) * 0.78539816;
			vec2 off = vec2(cos(ang), sin(ang)) * contorno_silhueta_px * TEXTURE_PIXEL_SIZE;
			max_a = max(max_a, texture(TEXTURE, UV + off).a);
		}
		COLOR = vec4(COR_OSSO_PLENO, max_a);
	} else {
		vec4 c = aplicar_char_tint(tex, forca_grading_personagem, flash);
		if (abalo_ativo && modo_impacto == 0) {
			c.rgb *= 0.85;
		}
		COLOR = c;
	}
}
