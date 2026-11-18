shader_type canvas_item;
#include "res://shaders/familias/char_tint.gdshaderinc"

uniform int papel = 1; // 0 jogador, 1 inimigo, 2 aliado
uniform float flash = 0.0;
uniform float forca_grading_personagem = 0.15;

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	COLOR = aplicar_char_tint(tex, forca_grading_personagem, flash);
}
