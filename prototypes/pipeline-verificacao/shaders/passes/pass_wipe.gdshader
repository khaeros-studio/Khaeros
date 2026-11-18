shader_type canvas_item;

uniform float progresso_wipe : hint_range(0.0, 1.0) = 0.0;
uniform bool modo_fade = false;

const vec3 COR_TINTA = vec3(0.051, 0.055, 0.078);

void fragment() {
	if (modo_fade) {
		float a = 1.0 - abs(2.0 * progresso_wipe - 1.0);
		COLOR = vec4(COR_TINTA, clamp(a, 0.0, 1.0));
	} else {
		float cob = 1.0 - abs(2.0 * progresso_wipe - 1.0);
		float a = step(UV.x, cob);
		COLOR = vec4(COR_TINTA, a);
	}
}
