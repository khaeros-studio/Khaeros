shader_type canvas_item;
#include "res://assets/shaders/familias/sem_grading.gdshaderinc"

uniform bool eh_ataque_inimigo = false;
uniform bool eh_numero_ou_letreiro = false;
uniform bool eh_mancha_abate = false;
global uniform int modo_bencao;

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	if (modo_bencao != 0 && eh_numero_ou_letreiro) {
		COLOR = vec4(0.0);
	} else if (modo_impacto == 1) {
		COLOR = eh_ataque_inimigo ? vec4(COR_OSSO_PLENO, tex.a) : vec4(0.0);
	} else if (modo_impacto == 2) {
		if (eh_ataque_inimigo) {
			COLOR = vec4(COR_TINTA, tex.a);
		} else if (eh_mancha_abate) {
			COLOR = tex;
		} else {
			COLOR = vec4(0.0);
		}
	} else {
		COLOR = tex;
	}
}
