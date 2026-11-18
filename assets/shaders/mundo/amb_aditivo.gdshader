shader_type canvas_item;
render_mode blend_add;
#include "res://assets/shaders/familias/amb_graded.gdshaderinc"

uniform bool recebe_profundidade = false;
uniform float opacidade_max_feixes = 0.20;

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	if (modo_impacto == 1 || modo_impacto == 2) {
		COLOR = vec4(0.0);
	} else {
		vec4 out_c = aplicar_amb_graded(tex, recebe_profundidade);
		out_c.a = min(out_c.a, opacidade_max_feixes);
		COLOR = out_c;
	}
}
