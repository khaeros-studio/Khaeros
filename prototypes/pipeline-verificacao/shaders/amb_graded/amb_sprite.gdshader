shader_type canvas_item;
#include "res://shaders/familias/amb_graded.gdshaderinc"

uniform bool recebe_profundidade = true;
uniform float alfa_oclusao = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	vec4 out_c = aplicar_amb_graded(tex, recebe_profundidade);
	out_c.a *= alfa_oclusao;
	COLOR = out_c;
}
