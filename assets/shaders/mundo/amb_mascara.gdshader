shader_type canvas_item;
#include "res://assets/shaders/familias/amb_graded.gdshaderinc"

uniform bool recebe_profundidade = false;
uniform float limiar_mascara = 0.5;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float d = limiar_mascara - tex.r;
	float aa = max(fwidth(d), 1e-5);
	float cob = clamp(0.5 - d / aa, 0.0, 1.0);
	vec4 base = vec4(COLOR.rgb, COLOR.a * cob);
	COLOR = aplicar_amb_graded(base, recebe_profundidade);
}
