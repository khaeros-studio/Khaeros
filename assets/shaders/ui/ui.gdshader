shader_type canvas_item;
#include "res://assets/shaders/familias/sem_grading.gdshaderinc"

void fragment() {
	COLOR = texture(TEXTURE, UV) * COLOR;
}
