shader_type canvas_item;

uniform float progresso_morte : hint_range(0.0, 1.0) = 0.0;

const vec3 COR_TINTA = vec3(0.051, 0.055, 0.078);

void fragment() {
	vec2 d = abs(UV - vec2(0.5)) * 2.0;
	float r = max(d.x, d.y);
	float a = step(1.0 - progresso_morte, r);
	COLOR = vec4(COR_TINTA, a);
}
